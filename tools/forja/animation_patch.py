"""Reparo de quadros por máscara: zero rede, ordem e cadência preservadas, revisão antiga invalidada."""
from __future__ import annotations

import copy
import json
from pathlib import Path

from . import anim, animation_files, animation_pack, contracts, durable, lint, palette, pixel_patch
from . import review, sheet_audit, timeline
from .equipment import image_sha


def apply(clip, patch: dict, ch: dict, folder: str | Path) -> dict:
    if not isinstance(patch, dict) or patch.get("schema") != "forja.animation_patch/1" or \
            patch.get("sequence_sha256") != clip.sha:
        raise ValueError("patch de outra sequencia: esperado forja.animation_patch/1 e hash atual")
    rows = patch.get("frames")
    if not isinstance(rows, list) or not rows or any(not isinstance(r, dict) for r in rows):
        raise ValueError("patch precisa da lista dos quadros a reparar")
    ids = [r.get("frame") for r in rows]
    if any(type(i) is not int or not 0 <= i < len(clip.frames) for i in ids) or len(set(ids)) != len(ids):
        raise ValueError("quadro ausente, duplicado ou fora da sequencia")
    c = contracts.get(ch["kind"])
    if clip.data["contract"]["kind"] != ch["kind"] or clip.data["canvas"] != ch["target_canvas"]:
        raise ValueError("personagem ou tela diferentes do contrato do patch")
    pal = palette.load(palette.ROOT / c.palette)
    frames, repairs = list(clip.frames), []
    for r in rows:
        frames[r["frame"]], info = pixel_patch.apply(frames[r["frame"]], r["patch"], pal.colors)
        repairs.append({**info, "frame": r["frame"], "mask": r["patch"].get("mask")})
    out = animation_files.destination(folder)
    if out == clip.path.parent.resolve():
        raise ValueError("conservar a sequencia original; usar uma pasta nova em build/forja/")
    if out.exists() and any(out.iterdir()):
        raise ValueError("a pasta do patch deve estar vazia para conservar a origem")
    d = copy.deepcopy(clip.data)
    atlas, _ = anim.strip(frames)
    d["schema"] = "forja.animation/1"
    d["lineage"] = {"schema": sheet_audit.SCHEMA, "origin": "pixel_patch",
        "input_sha256": clip.data["lineage"]["input_sha256"], "output_sha256": image_sha(atlas),
        "owner_rules": clip.data["lineage"].get("owner_rules"),
        "diagnostic_only": clip.data["lineage"].get("diagnostic_only", False),
        "native_root_declared": clip.data["lineage"].get("native_root_declared", False),
        "parent_sequence_sha256": clip.sha, "parent": clip.data["lineage"],
        "patches": repairs, "frames": [{"frame": i, "output_sha256": image_sha(f), "losses": []}
                                      for i, f in enumerate(frames)]}
    checks = [lint.check(f, c, pal) for f in frames]
    loops = {p["name"]: p["loop"] for p in timeline.playback(d["tags"])}
    moved = review.motion(frames, d["tags"], d.get("holds"), "preserve", loops)
    d["review"] = review.verdict(all(c["ok"] for c in checks), moved, [c["coherence"] for c in checks])
    d.update(ok=not d["review"]["needs_regeneration"], ready_for_review=False, release_ready=False,
             summary="quadros reparados por mascara; rever de novo a sequencia completa",
             metrics=sheet_audit.metrics(frames, tuple(d["pivot"]), d["tags"]))
    d["frames"] = [{"frame": i, "pixels_sha256": image_sha(f), "lint": c}
                   for i, (f, c) in enumerate(zip(frames, checks))]
    out.mkdir(parents=True, exist_ok=True)
    if clip.source is not None:
        clip.source.save(out / "source.png")
    if clip.last is not None:
        clip.last.save(out / "source-last.png")
    files = animation_pack.export(frames, d, out)
    durable.write_text(out / "patch.json", json.dumps(patch, ensure_ascii=False, indent=1) + "\n")
    return {"ok": d["ok"], "files": files, "patches": repairs, "ready_for_review": False, "release_ready": False}
