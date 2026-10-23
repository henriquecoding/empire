"""Revisao por ficheiros nativos; nao modifica nem realinha os pixels."""
from __future__ import annotations

import json
from pathlib import Path

from . import contracts, lint, palette, provenance, quality, report, sheetforge
from .cli import box, command
from .imageops import open_rgba


def do_review(args) -> dict:
    frames = [open_rgba(p) for p in args.frames]
    tags = sheetforge.parse_tags(args.tags)
    if tags and sum(n for _, n in tags) != len(frames):
        raise ValueError("as contagens das tags devem corresponder aos quadros recebidos")
    timeline, durations = sheetforge._timeline(tags, len(frames))
    reference = open_rgba(args.reference) if args.reference else None
    check = quality.review(frames, timeline, reference, args.protected_box)
    contract = contracts.get(args.kind)
    pal = palette.load(palette.ROOT / contract.palette) if args.kind != "free" else None
    verdicts = [lint.check(f, contract, pal) for f in frames]
    findings = check["findings"] + [f for v in verdicts for f in v["findings"]]
    result = {"ok": all(v["ok"] for v in verdicts) and not any(f["severity"] == "error" for f in findings),
              "ready": not findings, "artistic_approval": False, "name": "revisao",
              "summary": f"{len(frames)} quadros nativos; revisao artistica pendente", "metrics": check,
              "findings": findings, "files": {}, "frames": verdicts,
              "prompt_feedback": " ".join(dict.fromkeys(f["prompt_hint"] for f in findings if f["prompt_hint"])),
              "provenance": provenance.record(args.reference, None, None, {"frames": args.frames})}
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    result["files"]["report"] = str(report.animation(out / "report.html", frames, durations, result))
    result["files"]["json"] = str(out / "review.json")
    (out / "review.json").write_text(json.dumps(result, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    return result


def register(sub) -> None:
    p = command(sub, "review", "Rever quadros nativos, ciclos e identidade sem modificar pixels", do_review)
    p.add_argument("frames", nargs="+")
    p.add_argument("--tags")
    p.add_argument("--kind", default="free", choices=contracts.kinds())
    p.add_argument("--reference", help="PNG nativo na mesma tela dos quadros")
    p.add_argument("--protected-box", type=box, help="regiao explicitamente imovel e identica, x0,y0,x1,y1")
    p.add_argument("-o", "--out", required=True)
