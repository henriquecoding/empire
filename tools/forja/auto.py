"""Ciclo limitado; guarda pedido, job e tentativas, e escolhe por erros/avisos."""
from __future__ import annotations

from pathlib import Path

from . import contracts, generation, guides, pipeline, prompts, sheetforge


def run(args, palette, transport=None) -> dict:
    from .cmd_ai import _save
    tags = sheetforge.parse_tags(args.tags)
    target = {"openai": "gpt-image", "gemini": "gemini", "pixellab": "pixellab"}[args.backend]
    built = prompts.build(args.subject, args.kind, tags, args.facing, bool(args.reference), palette, target)
    exp, out = built["expect"], Path(args.out)
    if (out / "run.json").exists():
        raise ValueError("esta pasta ja tem tentativas; escolha outra para preservar a proveniencia")
    refs = [Path(r).read_bytes() for r in args.reference or []]
    proposal = generation.plan(built, args.backend, args.model, refs, palette, getattr(args, "seed", None), args.attempts)
    generation.save_json(out / "plan.json", proposal)
    generation.save_json(out / "expect.json", exp)
    (out / "prompt.txt").write_text(built["prompt"], encoding="utf-8")
    c = contracts.get(args.kind)
    guides.write(out, exp, palette, c.pivot[1] // c.cluster if c.pivot else None)
    if getattr(args, "dry_run", False):
        return {"ok": True, "dry_run": True, "plan": proposal, "files": {"plan": str(out / "plan.json")}}
    history, prompt = [], built["prompt"]
    state = {"ok": False, "plan": proposal, "attempts": history, "artistic_approval": False}
    generation.save_json(out / "run.json", state)
    for attempt in range(1, args.attempts + 1):
        entry = {"attempt": attempt, "status": "submitting", "prompt": prompt}
        history.append(entry)
        generation.save_json(out / "run.json", state)
        def checkpoint(job: str) -> None:
            entry.update(status="processing", job_id=job)
            generation.save_json(out / "run.json", state)
        try:
            res = generation.execute({**built, "prompt": prompt}, proposal, refs, palette, transport, checkpoint)
            paths = _save(res["images"], out / "raw", f"try{attempt}")
            path = paths[0]
            generation.save_json(out / "raw" / f"try{attempt}.generation.json",
                                 {k: v for k, v in res.items() if k != "images"} | {"prompt": prompt, "files": paths})
            opts = pipeline.Options(kind=args.kind, palette=args.palette, scale=exp["scale"],
                                    request_size=tuple(exp.get("generator_size", exp["size"])),
                                    source_box=tuple(exp["content_box"]) if exp.get("content_box") else None,
                                    bg=None if exp["background"] == "transparent" else exp["background"])
            if exp["frames"] > 1:
                r = sheetforge.forge_sheet(path, out / f"try{attempt}", opts, sheetforge.SheetOptions(
                    tags=tags, layout=tuple(exp["layout"])), prompt=prompt, generator=res["model"])
                findings, feedback = r["findings"], r["prompt_feedback"]
                structural = r["ok"]
            else:
                r = pipeline.forge(path, out / f"try{attempt}", opts, prompt=prompt, generator=res["model"])
                findings, feedback = r["lint"]["findings"], r["lint"]["prompt_feedback"]
                structural = r["lint"]["ok"]
            errors = sum(f["severity"] == "error" for f in findings)
            warnings = sum(f["severity"] == "warn" for f in findings)
            entry.update(status="reviewed", ok=structural and warnings == 0, structural_ok=structural,
                         score=[errors + int(not structural), warnings], image=path, feedback=feedback,
                         files=r["files"], request=res.get("request"), usage=res.get("usage"))
        except Exception as exc:
            entry.update(status="interrupted", error=str(exc))
            generation.save_json(out / "run.json", state)
            raise
        reviewed = [h for h in history if h["status"] == "reviewed"]
        best = min(reviewed, key=lambda h: h["score"])
        state.update(ok=best["ok"], best=str(out / f"try{best['attempt']}"), best_attempt=best["attempt"],
                     files=best["files"])
        generation.save_json(out / "run.json", state)
        if entry["ok"]:
            break
        if not feedback.strip():
            state["stop_reason"] = "achados sem correcao automatica; revisao manual necessaria"
            break
        prompt = prompts.corrective(built["prompt"], feedback)
    generation.save_json(out / "run.json", state)
    return state
