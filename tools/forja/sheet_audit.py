"""Auditar a prancha sem confundir acoes, ocultar perdas ou aprovar movimento pela exportacao."""
from __future__ import annotations

from . import anim, guard, lineage, masks, motion, temporal, timeline
from .equipment import image_sha

SCHEMA = "forja.animation_lineage/1"


def validate(opts, sopts, size):
    timeline.declarations(sopts.tags)
    if opts.reduce and not (opts.scale or opts.cells):
        raise ValueError("--reduce pede --scale ou --cells")
    scale = opts.scale
    if opts.cells:
        sx, sy = (size[i] / opts.cells[i] for i in (0, 1))
        if abs(sx - sy) > 0.001 or scale is not None and abs(scale - sx) > 0.001:
            raise ValueError("prancha: --cells precisa de pixels quadrados e de concordar com --scale")
        scale = sx
    return scale


def correct(frames, tags, sopts, keep):
    """O primeiro quadro de cada acao e a referencia dela; nunca cola idle em hit/die."""
    out = [f.copy() for f in frames]
    fixes, counts, changed = {}, {s: 0 for s in temporal.STATUSES}, 0
    locks = []
    lock_keep = keep | frozenset().union(*[masks.box(b) for b in sopts.actions or []])
    for name, first, last, _ in tags:
        part = frames[first:last + 1]
        if sopts.deflicker:
            part, info = temporal.stabilize(part, sopts.deflicker, sopts.static, sopts.actions, keep)
            changed += len(info["changed"])
            for status, n in info["counts"].items():
                counts[status] += n
        if sopts.lock:
            part, reports = motion.lock(part, sopts.lock, keep=lock_keep)
            locks += [{**r, "frame": first + r["frame"], "tag": name} for r in reports]
        out[first:last + 1] = part
    if sopts.deflicker:
        fixes["deflicker"] = {"changed": changed, "counts": counts, "static": sopts.static or [],
            "actions": sopts.actions or [], "scope": "within_each_tag",
            "note": "correcao so dentro de cada acao" if sopts.static else
            "nenhuma regiao estatica declarada: nada foi alterado"}
    if sopts.lock:
        fixes["lock"] = locks
    return out, fixes


def chain(source, frames, figures, details, placed, opts, region=None):
    sha_in = image_sha(source)
    parent = opts.lineage
    if parent and parent.get("output_sha256") != sha_in:
        raise ValueError("a cadeia nao liga: esta prancha nao e a saida da etapa anterior")
    inherited = parent or {}
    frame_records = []
    for i, (f, d, p, im) in enumerate(zip(figures, details, placed, frames)):
        snap = f.snap or {}
        info = guard.placed(d, p["offset"])
        losses = []
        for lost in (snap.get("loss") or {}).get("erased", []):
            xy = [lost["cell"][j] - snap["crop_origin"][j] for j in (0, 1)]
            target = list(guard.final_xy(xy, info)) if lost.get("inside_crop", True) else None
            losses.append({**lost, "target_pixel": target, "status": "open"})
        frame_records.append({"frame": i, "output_sha256": image_sha(im), "snap": snap,
                              "finish": d, "placement": p, "losses": losses})
    sheet, _ = anim.strip(frames)
    reduced = any((f.snap or {}).get("grid", {}).get("origin") == "deliberately_reduced" for f in figures)
    diagnostic = reduced or inherited.get("diagnostic_only", False) or any(
        s.get("transform", {}).get("grid", {}).get("origin") == "deliberately_reduced"
        for s in inherited.get("stages", []))
    return {"schema": SCHEMA, "input_sha256": sha_in, "output_sha256": image_sha(sheet),
            "owner_rules": inherited.get("owner_rules") if parent else opts.owner_rules,
            "native_root_declared": inherited.get("native_root_declared", False) or
                inherited.get("root", {}).get("kind") == "native_root_declared" or bool(opts.native_root and not parent),
            "diagnostic_only": bool(diagnostic), "source_region": list(region) if region else None,
            "animation_plan": inherited.get("animation_plan") if parent else opts.animation_plan,
            "parent": parent, "frames": frame_records,
            "note": "perdas por quadro e origem preservadas; revisao de movimento e aprovacao continuam pendentes"}


def delivery(raster_ok, chain):
    return {**lineage.delivery(raster_ok, None), "diagnostic_only": chain["diagnostic_only"],
            "closure": "rever a sequencia exata por acao, continuidade, identidade e perdas de cada quadro"}


def metrics(frames, pivot, tags):
    result = anim.metrics(frames, pivot)
    per_tag = {}
    for p in timeline.playback(tags):
        part = [frames[i] for i in p["indices"]]
        measures = anim.metrics(part, pivot)
        measures["flicker"] = anim.flicker(part, loop=p["loop"])
        per_tag[p["name"]] = measures
    result["by_tag"] = per_tag
    result["flicker"] = sum(m["flicker"] for m in per_tag.values())
    result["flicker_scope"] = "within_each_tag"
    return result
