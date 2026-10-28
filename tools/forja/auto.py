"""O ciclo fechado com um gerador: plano -> job -> raster medido -> forja -> revisao -> corrigir.

Nada sai para a rede antes de o plano passar (F02/F03). Cada tentativa e um job
duravel com teto de gasto (F01/F09). O que chega e medido, nao assumido: o
tamanho recebido contra o pedido e a grade detetada contra a pedida — a escala so
e dada como conhecida quando o fornecedor desenha no tamanho nativo e o tamanho
recebido o confirma (expectation.py: a mesma conta do `forge` e do `sheet` manuais,
FORJA-06). O ciclo para quando o contrato passa e a revisao automatica
do movimento nao pede outra geracao (F07); a aprovacao artistica fica sempre
pendente, para o autor.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

from . import expectation, jobs, pipeline, prompts, review as review_mod, sheetforge
from .backends import http, poller
from .plan import Plan


def _sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def forge_attempt(plan: Plan, raw: Path, received: list[int], out: Path, prompt: str, generator: str,
                  palette: str | None) -> dict:
    exp = plan.data["expect"]
    canvas, pivot, origin, grid = expectation.frame(exp)  # a tela, o pivot e a origem de uma cena (FORJA-11)
    opts = pipeline.Options(kind=plan.data["kind"], palette=palette, canvas=canvas, pivot=pivot, origin=origin,
                            origin_grid=grid, bg=None if exp["background"] == "transparent" else exp["background"],
                            useful_box=tuple(exp["target_useful_bbox"]) if exp.get("target_useful_bbox") else None)
    if expectation.native(exp, received):
        opts.scale = 1.0
    if exp["frames"] > 1:
        sopts = sheetforge.SheetOptions(tags=[tuple(t) for t in exp["tags"]] if exp.get("tags") else None,
                                        layout=tuple(exp["layout"]), region=expectation.region(exp, received))
        r = sheetforge.forge_sheet(raw, out, opts, sopts, prompt=prompt, generator=generator)
        detected = expectation.from_period(r["frames"])
        review, feedback = r["review"], r["prompt_feedback"]
    else:
        r = pipeline.forge(raw, out, opts, prompt=prompt, generator=generator)
        detected = r["snap"]["grid"]["period"][0]
        review = review_mod.verdict(r["lint"]["ok"], None)
        feedback = r["lint"]["prompt_feedback"]
    cmp = expectation.compare(exp, received, detected)
    return {"raster": cmp["raster"], "findings": cmp["findings"], "review": expectation.mark(review, cmp),
            "prompt_feedback": feedback, "files": r["files"]}


def run(plan: Plan, out: Path, attempts: int, budget: jobs.Budget, palette: str | None = None,
        transport=None, **kw) -> dict:
    """Tenta ate `attempts` vezes (e nunca para la do teto). Devolve o historico completo."""
    plan_file = plan.write(out / "plan")
    plan_sha = _sha(plan_file)
    prompt, history = plan.data["prompt"], []
    for attempt in range(1, attempts + 1):
        call = plan.call(prompt)
        try:
            budget.check(call.estimate_usd)  # antes do job: um teto atingido nao deixa um pedido `planned` orfao
        except jobs.BudgetExceeded as err:
            history.append({"attempt": attempt, "state": "not_sent", "error": str(err), "review": None})
            break
        job = jobs.create(call, out, extra={
            "attempt": attempt, "backend": plan.data["backend"], "model": plan.data["model"],
            "plan_sha256": plan_sha, "prompt_sha256": hashlib.sha256(prompt.encode("utf-8")).hexdigest(),
            "authoring": plan.data["authoring"], "training_permission": plan.data["training_permission"],
            "review": {"design": "pendente", "motion": "pendente", "integration": "pendente"}})
        entry = {"attempt": attempt, "job": str(job.path), "prompt_sha256": job.data["prompt_sha256"]}
        try:
            images = jobs.execute(job, call, transport, poll=poller(call.service), budget=budget, **kw)
        except (jobs.JobError, jobs.BudgetExceeded, http.MissingKey) as err:
            history.append({**entry, "state": job.state, "error": str(err), "review": None})
            break
        output = job.data["outputs"][0]
        raw = Path(output["file"])
        generator = f"{plan.data['backend']}/{plan.data['model']}"
        entry.update(state=job.state, image=str(raw), extra_images=len(images) - 1)
        try:
            res = forge_attempt(plan, raw, output["size"], out / f"try{attempt}", prompt, generator, palette)
        except Exception as err:  # noqa: BLE001 — a imagem paga fica no job; o erro e da Forja, nao do gerador
            history.append({**entry, "error": f"forja: {type(err).__name__}: {err}", "review": None})
            break
        history.append({**entry, **res})
        if not res["review"]["needs_regeneration"]:
            break
        if plan.data["model"] == "image-to-pixelart":
            history.append({"attempt": attempt + 1, "state": "not_sent", "review": None,
                            "error": "conversion has no corrective text field: review the native result; "
                                     "an identical paid request is not repeated"})
            break
        hints = " ".join(f["hint"] for f in res["findings"] if f.get("hint"))
        prompt = prompts.corrective(plan.data["prompt"], (res["prompt_feedback"] + " " + hints).strip())
    return _close(out, plan_file, history, budget)


def _close(out: Path, plan_file: Path, history: list[dict], budget: jobs.Budget) -> dict:
    """O resultado diz a ultima tentativa forjada, e porque o ciclo parou se parou depois dela (A03)."""
    forged = [h for h in history if h.get("review")]
    last = forged[-1] if forged else {}
    review = last.get("review") or {}
    stopped = history[-1].get("error") if history and history[-1] is not last else None
    if not review:
        step = "nada foi forjado; ver o erro do job e o plano"
    elif review.get("needs_regeneration"):
        step = "a ultima tentativa forjada ainda pede outra geracao" + (f"; o ciclo parou: {stopped}" if stopped
                                                                        else " e as tentativas acabaram")
    else:
        step = "revisao humana: design, movimento e integracao continuam pendentes"
    result = {"ok": bool(review) and not review.get("needs_regeneration", True), "attempts": history,
              "plan": str(plan_file), "budget": budget.as_dict(),
              "best": str(out / f"try{last['attempt']}") if review else None,
              "review": review or None, "stopped": stopped, "next": step}
    (out / "auto.json").write_text(json.dumps(result, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    return result
