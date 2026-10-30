"""Empacotar quadros nativos sem amostrar, limpar, recentrar ou substituir o desenho do fornecedor."""
from __future__ import annotations

import io
import json
from pathlib import Path

from PIL import Image

from . import anim, aseprite, contracts, durable, lint, palette, report, review, sheet_audit, timeline
from .equipment import image_sha


def package(plan, job, images: list[bytes], folder: str | Path) -> dict:
    out = Path(folder)
    d = plan.data
    frames = []
    formats = []
    for data in images:
        with Image.open(io.BytesIO(data)) as im:
            formats.append(im.format)
            frames.append(im.convert("RGBA"))
    if len(frames) != d["frame_count"] or any(list(f.size) != d["canvas"] for f in frames) or \
            any(fmt != "PNG" for fmt in formats):
        return {"ok": False, "job": str(job.path), "received_frames": len(frames),
                "ready_for_review": False, "release_ready": False, "raw_outputs": job.data["outputs"],
                "error": "retorno fora do contrato: contagem/tela/formato incorreto; brutos conservados no job, "
                         "sem cortar, redimensionar ou inventar quadros"}
    c = contracts.get(d["character"]["kind"])
    pal = palette.load(palette.ROOT / c.palette)
    tags, durations = timeline.build([(d["tag"], d["frame_count"])], len(frames), strict=True)
    pivot = tuple(d["pivot"])
    (out / "source.png").write_bytes(plan.first)
    if plan.last is not None:
        (out / "source-last.png").write_bytes(plan.last)
    checks = [lint.check(f, c, pal) for f in frames]
    loops = {p["name"]: p["loop"] for p in timeline.playback(tags)}
    moved = review.motion(frames, tags, align="preserve", loop=loops)
    rv = review.verdict(all(c["ok"] for c in checks), moved, [c["coherence"] for c in checks])
    atlas, _ = anim.strip(frames)
    chain = {"schema": sheet_audit.SCHEMA, "input_sha256": d["source_pixels_sha256"],
             "output_sha256": image_sha(atlas), "owner_rules": d["owner_rules"], "diagnostic_only": False,
             "animation_plan": d["animation_plan"], "parent": d["source_lineage"],
             "native_root_declared": False, "origin": "generated_native",
             "job": {"id": job.id, "request_sha256": job.data["request_sha256"],
                     "operation": job.data["operation"], "service": job.data["service"]},
             "frames": [{"frame": i, "output_sha256": image_sha(f), "losses": [],
                         "grid": {"origin": "provider_native_size_checked", "period": [1, 1]}}
                        for i, f in enumerate(frames)],
             "note": "geracao de novas poses: perdas de identidade nao sao medidas por igualdade com a pose inicial"}
    data = {"schema": "forja.animation/1", "name": d["character"]["id"] + ":" + d["tag"],
            "character": d["character"]["id"], "fidelity_file": d["fidelity_file"], "contract": c.as_dict(),
            "canvas": d["canvas"], "pivot": d["pivot"], "tags": [list(t) for t in tags],
            "durations": durations, "holds": [], "lineage": chain, "review": rv, "ok": not rv["needs_regeneration"],
            "source": {"pixels_sha256": d["source_pixels_sha256"], "reference": d["reference"],
                       "native_root": d["native_root"], "resolutions": d["source_resolutions"],
                       "last": d["last_source"]},
            "ready_for_review": False, "release_ready": False,
            "summary": f"{len(frames)} quadros nativos recebidos; revisao da sequencia pendente",
            "frames": [{"frame": i, "pixels_sha256": image_sha(f), "lint": check}
                       for i, (f, check) in enumerate(zip(frames, checks))],
            "metrics": sheet_audit.metrics(frames, pivot, tags)}
    files = export(frames, data, out)
    return {"ok": data["ok"], "files": files, "job": str(job.path), "received_frames": len(frames),
            "ready_for_review": False, "release_ready": False, "review": rv,
            "next": "forja animacao animation.forja.json --template-out review.json; rever antes de entrega-anim"}


def export(frames: list, data: dict, out: Path) -> dict:
    """Mesmos pixels e metadados em todos os formatos; tanto a geração como o patch usam este caminho."""
    for i, frame in enumerate(frames):
        frame.save(out / f"frame_{i:03d}.png")
    files = anim.export(frames, out, "animation", data["durations"], data["tags"], tuple(data["pivot"]))
    files["aseprite"] = str(aseprite.from_frames(out / "animation.aseprite", frames,
        durations=data["durations"], tags=data["tags"], pivot=tuple(data["pivot"])))
    files.update(forja_json=str(out / "animation.forja.json"), report=str(out / "report.html"))
    if (out / "source.png").exists():
        files["source"] = str(out / "source.png")
    if (out / "source-last.png").exists():
        files["source_last"] = str(out / "source-last.png")
    data["files"] = {k: Path(v).name for k, v in files.items()}
    report.animation(out / "report.html", frames, data["durations"], data)
    durable.write_text(out / "animation.forja.json", json.dumps(data, ensure_ascii=False, indent=1) + "\n")
    return files
