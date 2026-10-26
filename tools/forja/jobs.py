"""Jobs de geracao que nao se perdem nem se pagam duas vezes (auditoria F01 e F09).

Cada pedido a um gerador e um ficheiro `<pasta>/jobs/<id>.json`, escrito ANTES
de o POST sair. Estados: planned -> submitting -> [submitted] -> completed, ou
failed, rejected, submission_unknown, timed_out, cancel_requested, cancelled.
`completed` quer dizer operacao concluida, nao arte aprovada (isso e da revisao).

- Um POST sai uma vez. Se a resposta se perde, o job fica `submission_unknown`
  e so se pede outra vez com `force_resubmit` (pode ter sido cobrado).
- Com id remoto, retomar so consulta (GET); nunca volta a pedir.
- O polling tem prazo, limite de consultas, espera crescente com jitter e a
  espera estimada pelo fornecedor; "concluido" sem imagens e erro, nao sucesso.
- Cancelar pede ao fornecedor e escreve a resposta, sem prometer que nao foi cobrado.
- O orcamento conta cada POST antes de sair; custo nao dito fica "desconhecido".
Nada de chaves: guarda-se o descritor do pedido (sem base64), hashes e tempos.
"""
from __future__ import annotations

import io
import json
import random
import time
from typing import Callable

from PIL import Image

from .backends import Call, Result, http, sha
from .jobstore import (FINAL, Ambiguous, Budget, BudgetExceeded, Job, JobError, Timeout, create, listing,
                       load, now as _now, stored)

__all__ = ["FINAL", "Ambiguous", "Budget", "BudgetExceeded", "Job", "JobError", "Timeout", "cancel", "create",
           "execute", "listing", "load", "stored"]


def _settle(job: Job, budget: Budget | None) -> None:
    attempt = job.data["attempts"][-1] if job.data["attempts"] else None
    if attempt is None or attempt.get("cost_settled"):
        return
    attempt["cost_settled"] = True
    if budget:
        budget.settle(job.data["cost"]["usd"])
    job.save()


def _usage(job: Job, result: Result) -> None:
    if result.usage_usd is not None:
        job.data["cost"] = {"usd": result.usage_usd, "status": "reported_by_provider"}


def _submit(job: Job, call: Call, transport, budget: Budget | None, clock, **kw) -> Result:
    req = call.request()  # le a chave: se falta, nada muda
    if budget:
        budget.check(call.estimate_usd)
    attempt = {"n": len(job.data["attempts"]) + 1, "started_utc": _now(), "exchanges": []}
    job.data["attempts"].append(attempt)
    job.mark("submitting", f"POST {attempt['n']}")
    if budget:
        budget.spend()
    t0 = clock()
    try:
        resp = http.send(req, transport, call.service, refused=call.refused, log=attempt["exchanges"],
                         clock=clock, **kw)
    except http.SubmissionUnknown as err:
        attempt.update(outcome="unknown", status=err.status)
        job.mark("submission_unknown", str(err), error=str(err))
        _settle(job, budget)
        raise Ambiguous(job, f"{err}. Confirme no fornecedor; so com force_resubmit se pede outra vez") from err
    except http.ApiError as err:
        attempt.update(outcome="rejected", status=err.status, retry_after_s=err.retry_after)
        job.mark("rejected", str(err), error=str(err))
        _settle(job, budget)
        wait = f"; o servidor pede {err.retry_after:g}s de espera" if err.retry_after else ""
        raise JobError(job, f"{err}{wait}") from err
    attempt.update(outcome="accepted", seconds=round(clock() - t0, 3))
    try:
        result = call.parse(resp.json())
    except (ValueError, KeyError, TypeError) as err:
        job.mark("failed", "resposta ilegivel", error=f"resposta ilegivel: {err}")
        _settle(job, budget)
        raise JobError(job, f"resposta ilegivel: {err}") from err
    _usage(job, result)
    if result.remote_id:
        job.mark("submitted", f"job remoto {result.remote_id}", remote_id=result.remote_id)
    return result


def _poll(job: Job, poll: Callable[[str], Call] | None, transport, deadline: float, every: float,
          max_every: float, max_polls: int, sleep, clock, rand) -> Result:
    if poll is None:
        raise JobError(job, "o fornecedor devolveu um job, mas este adaptador nao o sabe consultar")
    start, delay = clock(), every
    while True:
        if job.data["polls"] >= max_polls or clock() - start >= deadline:
            job.mark("timed_out", f"{job.data['polls']} consultas, {clock() - start:.0f}s")
            raise Timeout(job, "prazo ou limite de consultas esgotado; retome para consultar outra vez")
        q = poll(job.data["remote_id"])
        log: list = []
        job.data["polls"] += 1
        try:
            resp = http.send(q.request(), transport, q.service, deadline=max(1.0, deadline - (clock() - start)),
                             sleep=sleep, clock=clock, rand=rand, log=log)
        except http.ApiError as err:
            if err.status == 404:
                job.mark("failed", "o job remoto nao existe (apagado ou de outra conta)", error=str(err))
                raise JobError(job, str(err)) from err
            job.mark("timed_out", f"consulta falhou: {err}", error=str(err))
            raise Timeout(job, f"consulta falhou: {err}; retome para consultar outra vez") from err
        r = q.parse(resp.json())
        job.data["progress"] = r.detail or None
        _usage(job, r)
        if r.state == "completed":
            return r
        if r.state == "failed":
            job.mark("failed", "o fornecedor diz que falhou", error=json.dumps(r.detail, ensure_ascii=False)[:600])
            raise JobError(job, f"o fornecedor diz que falhou: {r.detail}")
        if r.state != "processing":
            job.mark("submitted", f"estado remoto desconhecido: {r.detail.get('status')!r}")
            raise JobError(job, f"estado remoto desconhecido {r.detail.get('status')!r}; nada foi pedido de novo, "
                                "retome mais tarde")
        hint = r.detail.get("estimated_wait_seconds")
        wait = min(max_every, float(hint) if isinstance(hint, (int, float)) and hint > 0 else delay)
        wait *= 0.85 + 0.3 * rand()
        if clock() - start + wait >= deadline:
            job.mark("timed_out", f"{job.data['polls']} consultas, prazo de {deadline:g}s")
            raise Timeout(job, "prazo esgotado com o job ainda a correr; retome para consultar outra vez")
        job.save()
        sleep(wait)
        delay = min(max_every, delay * 1.5)


def _finish(job: Job, result: Result, budget: Budget | None) -> list[bytes]:
    if not result.images:
        job.mark("failed", "concluido sem imagens", error="empty_result: o fornecedor disse concluido sem imagens")
        _settle(job, budget)
        raise JobError(job, "o fornecedor disse concluido mas nao trouxe imagens")
    outputs = []
    for i, data in enumerate(result.images, 1):
        try:
            with Image.open(io.BytesIO(data)) as im:
                im.load()
                entry = {"index": i, "sha256": sha(data), "size": list(im.size), "format": im.format,
                         "bytes": len(data)}
        except (OSError, SyntaxError) as err:
            job.mark("failed", "imagem invalida", error=f"imagem {i} invalida: {err}")
            _settle(job, budget)
            raise JobError(job, f"imagem {i} invalida: {err}") from err
        if job.path:
            out = job.path.with_suffix("") / f"out_{i:02d}.png"
            out.parent.mkdir(parents=True, exist_ok=True)
            out.write_bytes(data)
            entry["file"] = str(out)
        outputs.append(entry)
    _usage(job, result)
    job.mark("completed", f"{len(outputs)} imagem(ns)", outputs=outputs, error=None,
             response=json.loads(json.dumps(result.detail, default=str)) if result.detail else None)
    _settle(job, budget)
    return list(result.images)


def execute(job: Job, call: Call | None, transport=None, *, poll: Callable[[str], Call] | None = None,
            budget: Budget | None = None, force_resubmit: bool = False, deadline: float = 900.0,
            every: float = 5.0, max_every: float = 30.0, max_polls: int = 200,
            sleep: Callable[[float], None] = time.sleep, clock: Callable[[], float] = time.monotonic,
            rand: Callable[[], float] = random.random) -> list[bytes]:
    """Leva o job ao fim, ou para com um erro que diz porque e como retomar. `call` so e preciso para pedir."""
    if job.state == "completed":
        return stored(job)
    if job.state in ("failed", "cancelled"):
        raise JobError(job, "job terminado; crie um pedido novo")
    if job.state in ("submitting", "submission_unknown") and not force_resubmit:
        raise Ambiguous(job, "o POST anterior pode ter sido aceite e cobrado; confirme no fornecedor e use "
                             "force_resubmit so se nao foi")
    if job.data["remote_id"] is None or force_resubmit:
        if call is None:
            raise JobError(job, "sem id remoto e sem o pedido original: crie um pedido novo")
        result = _submit(job, call, transport, budget, clock, sleep=sleep, rand=rand)
        if not result.remote_id:
            return _finish(job, result, budget)
    try:
        result = _poll(job, poll, transport, deadline, every, max_every, max_polls, sleep, clock, rand)
    except JobError:
        if job.state == "failed":  # definitivo: o custo fecha (desconhecido); prazo ou estado estranho ficam abertos
            _settle(job, budget)
        raise
    return _finish(job, result, budget)


def cancel(job: Job, cancel_call: Callable[[str], Call] | None, transport=None, **kw) -> dict:
    """Pede ao fornecedor para parar. Nunca diz "nao cobrado" sem o fornecedor o dizer."""
    if job.state in FINAL:
        return {"cancelled": False, "state": job.state, "reason": f"o job ja esta {job.state}"}
    if job.data["remote_id"] is None:
        if job.state in ("planned", "rejected"):
            job.mark("cancelled", "cancelado sem pedido em curso: nada mais sera enviado")
            return {"cancelled": True, "state": job.state, "remote": False}
        return {"cancelled": False, "state": job.state,
                "reason": "sem id remoto: este pedido nao se cancela pela API; confirme no painel do fornecedor"}
    if cancel_call is None:
        return {"cancelled": False, "state": job.state, "reason": "este fornecedor nao tem cancelamento pela API"}
    job.mark("cancel_requested")
    q = cancel_call(job.data["remote_id"])
    try:
        http.send(q.request(), transport, q.service, **kw)
    except http.ApiError as err:
        if err.status in (400, 409):
            job.mark("submitted", "terminou antes do cancelamento; retome para buscar o resultado")
        else:
            job.mark("cancel_requested", f"o cancelamento falhou: {err}", error=str(err))
        return {"cancelled": False, "state": job.state, "reason": str(err)}
    job.mark("cancelled", "o fornecedor confirmou; o que a GPU ja fez pode ser cobrado")
    return {"cancelled": True, "state": job.state, "remote": True, "cost": job.data["cost"]}
