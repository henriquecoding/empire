"""Animacao nativa com primeiro/ultimo quadro e retoma de trabalhos remotos."""
from __future__ import annotations

import hashlib
from pathlib import Path

from . import anim, aseprite, contracts, generation, lint, palette, quality, report
from .backends import jobs, pixellab_api
from .cli import command
from .imageops import open_rgba


def do_job(args) -> dict:
    from .cmd_ai import _save
    data = jobs.poll_job(args.job_id, pixellab_api.auth(), timeout=args.timeout)
    result = pixellab_api.result(data, "resumed-job", {}, args.job_id)
    out = Path(args.out)
    files = _save(result.pop("images"), out, "resumed")
    result.update(ok=True, files=files, artistic_approval=False)
    generation.save_json(out / "resumed.generation.json", result)
    return result


def do_native(args, transport=None) -> dict:
    from .cmd_ai import _save
    first = Path(args.image).read_bytes()
    c = contracts.get(args.kind)
    if c.canvas and open_rgba(args.image).size != c.canvas:
        raise ValueError("primeiro quadro fora da tela do contrato; escolha o tipo correto antes de gerar")
    last = Path(args.last_frame).read_bytes() if args.last_frame else None
    body = pixellab_api.animation_payload(first, args.action, args.frames, last, args.seed)
    plan = {"endpoint": "/v2/animate-with-text-v3", "frame_count": args.frames, "action": args.action,
            "seed": args.seed, "first_sha256": hashlib.sha256(first).hexdigest(),
            "last_sha256": hashlib.sha256(last).hexdigest() if last else None, "max_submissions": 1}
    out = Path(args.out)
    if (out / "native-job.json").exists():
        raise ValueError("trabalho ja registado nesta pasta; retome pelo job_id ou use outra pasta")
    generation.save_json(out / "native-plan.json", plan)
    if args.dry_run:
        return {"ok": True, "dry_run": True, "plan": plan}
    state = {"status": "submitting", "plan": plan}
    def checkpoint(job: str) -> None:
        state.update(status="processing", job_id=job)
        generation.save_json(out / "native-job.json", state)
    generation.save_json(out / "native-job.json", state)
    try:
        res = pixellab_api.animate(first, args.action, args.frames, last, args.seed, transport, checkpoint)
        paths = _save(res["images"], out / "raw", "frame")
        frames = [open_rgba(p) for p in paths]
        reference = open_rgba(args.image)
        tags = [(args.tag, 0, len(frames) - 1, "forward")]
        pal = palette.load(palette.ROOT / c.palette) if args.kind != "free" else None
        verdicts = [lint.check(f, c, pal) for f in frames]
        review = quality.review(frames, tags, reference)
        findings = review["findings"] + [f for v in verdicts for f in v["findings"]]
        first_change = quality.difference(reference, frames[0])
        if first_change["changed_pixels"]:
            findings.append(lint.finding("first_frame_changed", "error", "primeiro quadro nao preserva a referencia"))
        durations = [round(1000 / (contracts.tag(args.tag) or {}).get("fps", 10))] * len(frames)
        files = {f"frame_{i}": path for i, path in enumerate(paths)}
        structural = not any(f["severity"] == "error" for f in findings)
        if structural:
            files.update(anim.export(frames, out, args.tag, durations, tags, c.pivot))
            files["aseprite"] = str(aseprite.from_frames(out / f"{args.tag}.aseprite", frames,
                                                        durations=durations, tags=tags, pivot=c.pivot))
        state.update(status="reviewed", ok=structural, ready=structural and not findings, files=files,
                     name=args.tag, summary=f"{len(frames)} quadros nativos, sem realinhamento nem limpeza",
                     findings=findings, metrics=review, first_frame_change=first_change,
                     artistic_approval=False, request={k: v for k, v in body.items() if not k.endswith("_frame")},
                     usage=res.get("usage"),
                     prompt_feedback=" ".join(dict.fromkeys(f["prompt_hint"] for f in findings if f["prompt_hint"])))
        files["report"] = str(report.animation(out / "report.html", frames, durations, state))
    except Exception as exc:
        state.update(status="interrupted", error=str(exc))
        generation.save_json(out / "native-job.json", state)
        raise
    generation.save_json(out / "native-job.json", state)
    return state


def register(sub) -> None:
    p = command(sub, "animate-native", "Animar uma referencia nativa pelo PixelLab v3, com revisao sem alterar pixels", do_native)
    p.add_argument("image")
    p.add_argument("--action", required=True)
    p.add_argument("--frames", type=int, default=8)
    p.add_argument("--last-frame")
    p.add_argument("--tag", default="walk")
    p.add_argument("--kind", default="royal_64", choices=contracts.kinds())
    p.add_argument("--seed", type=int, default=0)
    p.add_argument("--dry-run", action="store_true")
    p.add_argument("-o", "--out", required=True)
    p = command(sub, "job", "Retomar o mesmo trabalho PixelLab por id, sem submeter outra geracao", do_job)
    p.add_argument("--job-id", required=True)
    p.add_argument("--timeout", type=float, default=600)
    p.add_argument("-o", "--out", required=True)
