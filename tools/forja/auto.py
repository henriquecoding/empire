"""O ciclo fechado com um gerador: plano -> job -> raster medido -> forja -> revisao -> corrigir.

Nada sai para a rede antes de o plano passar (F02/F03). Cada tentativa e um job
duravel com teto de gasto (F01/F09). O que chega e medido, nao assumido: o
tamanho recebido contra o pedido e a grade detetada contra a pedida — a escala so
e dada como conhecida quando o fornecedor desenha no tamanho nativo e o tamanho
recebido o confirma. O ciclo para quando o contrato passa e a revisao automatica
do movimento nao pede outra geracao (F07); a aprovacao artistica fica sempre
pendente, para o autor.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
from statistics import median

from . import jobs, pipeline, prompts, review as review_mod, sheetforge
from .backends import http, poller
from .plan import Plan


def _sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def raster_check(expect: dict, received: list[int]) -> dict:
    """O tamanho que chegou contra o pedido. No Gemini o pedido e estimado: so se regista o desvio."""
    want = expect["size"]
    out = {"requested": list(want), "received": list(received), "matches": list(received) == list(want),
           "requested_is_estimate": not expect.get("scale_exact", True)}
    lw, lh = expect["cells"]
    out["expected_period"] = round(received[0] / lw, 3) if expect["grid"] != "native" else 1.0
    out["aspect_deviation"] = round(abs(received[0] / received[1] - want[0] / want[1]) / (want[0] / want[1]), 4)
    return out


def region(expect: dict, received: list[int]) -> tuple[int, int, int, int] | None:
    """A caixa da prancha (sem margens) no raster recebido, pelas proporcoes logicas do plano."""
    lw, lh = expect["cells"]
    x0, y0, x1, y1 = expect.get("content") or (0, 0, lw, lh)
    if (x0, y0, x1, y1) == (0, 0, lw, lh):
        return None
    w, h = received
    return round(x0 * w / lw), round(y0 * h / lh), round(x1 * w / lw), round(y1 * h / lh)


def _grid_finding(check: dict, detected: float | None, cells: list[int]) -> dict | None:
    """`detail` e para quem le o relatorio; `hint` (em ingles) vai para o gerador no prompt corretivo."""
    if detected is None or check["expected_period"] <= 1:
        return None
    want = check["expected_period"]
    deviation = abs(detected - want) / want
    check["detected_period"], check["period_deviation"] = round(detected, 3), round(deviation, 3)
    if deviation > 0.12:
        return {"code": "grid_not_followed", "detail": f"grade detetada {detected:.2f} px, pedida "
                f"{want:.2f} px: o gerador nao seguiu o pedido de grade",
                "hint": f"Use exactly {cells[0]}x{cells[1]} logical pixels for the whole image: every logical pixel "
                        f"is one solid block of about {want:.0f}x{want:.0f} image pixels, not {detected:.0f}x"
                        f"{detected:.0f}."}
    return None


def forge_attempt(plan: Plan, raw: Path, received: list[int], out: Path, prompt: str, generator: str,
                  palette: str | None) -> dict:
    exp = plan.data["expect"]
    check = raster_check(exp, received)
    findings = []
    if exp["grid"] == "native" and not check["matches"]:
        findings.append({"code": "native_size_mismatch", "detail": f"pedido {exp['size']}, recebido {received}: "
                         "nao se trata como nativo; a grade e detetada"})
    elif exp.get("scale_exact", True) and not check["matches"]:
        findings.append({"code": "size_mismatch", "detail": f"pedido {exp['size']}, recebido {received}",
                         "hint": f"The image must be exactly {exp['size'][0]}x{exp['size'][1]} pixels."})
    opts = pipeline.Options(kind=plan.data["kind"], palette=palette,
                            bg=None if exp["background"] == "transparent" else exp["background"])
    if exp["grid"] == "native" and check["matches"]:
        opts.scale = 1.0
    if exp["frames"] > 1:
        sopts = sheetforge.SheetOptions(tags=[tuple(t) for t in exp["tags"]] if exp.get("tags") else None,
                                        layout=tuple(exp["layout"]), region=region(exp, received))
        r = sheetforge.forge_sheet(raw, out, opts, sopts, prompt=prompt, generator=generator)
        periods = [f["period"] for f in r["frames"] if f["period"] > 1]
        detected = median(periods) if periods else None
        review, feedback = r["review"], r["prompt_feedback"]
    else:
        r = pipeline.forge(raw, out, opts, prompt=prompt, generator=generator)
        detected = r["snap"]["grid"]["period"][0]
        review = review_mod.verdict(r["lint"]["ok"], None)
        feedback = r["lint"]["prompt_feedback"]
    grid = _grid_finding(check, detected, exp["cells"])
    if grid:
        findings.append(grid)
    hard = [f for f in findings if f["code"] in ("native_size_mismatch", "size_mismatch")]
    if hard:
        review = {**review, "contract_valid": False, "needs_regeneration": True,
                  "verdicts": {**review["verdicts"], "raster_contract": "fail"}}
    return {"raster": check, "findings": findings, "review": review, "prompt_feedback": feedback,
            "files": r["files"]}


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
