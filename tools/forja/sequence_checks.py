"""Contrato e origem da sequência. Os sinais automáticos não substituem a observação por quadro."""
from __future__ import annotations

from . import animation_plan, contracts, fidelity, lint, owner_rules, palette, review, sequence_losses, timeline
from .equipment import image_sha


def chain_findings(node: dict) -> tuple[list[str], list[str]]:
    blocked, pending = [], []
    if node.get("diagnostic_only"):
        blocked.append("reducao herdada na cadeia: a sequencia e diagnostica")
    for stage in node.get("stages", []):
        grid = stage.get("grid") or stage.get("transform", {}).get("grid", {})
        if grid.get("origin") == "deliberately_reduced":
            blocked.append("reducao deliberada numa etapa anterior")
    for record in node.get("frames", []):
        grid = (record.get("snap") or {}).get("grid") or record.get("grid") or {}
        if grid.get("origin") == "deliberately_reduced":
            blocked.append("quadro reduzido deliberadamente")
        if (record.get("placement") or {}).get("clipped_pixels"):
            blocked.append(f"quadro {record.get('frame')}: pixels cortados na colocacao ancestral")
    if isinstance(node.get("parent"), dict):
        b, p = chain_findings(node["parent"])
        blocked += b
        pending += p
    return blocked, pending


def automatic(clip, ch: dict, resolutions: dict | None = None) -> dict:
    d, frames = clip.data, clip.frames
    blocked, pending = chain_findings(d["lineage"])
    losses = sequence_losses.check(clip, resolutions)
    blocked += losses["blocked"]
    pending += losses["pending"]
    c = contracts.get(ch["kind"])
    if d["canvas"] != ch["target_canvas"] or d["contract"]["kind"] != ch["kind"]:
        blocked.append("tela ou classe difere do personagem")
    if d["pivot"] != list(c.pivot or []):
        blocked.append("pivot difere do contrato do personagem")
    if d.get("character") and d["character"] != ch["id"]:
        blocked.append("sequencia de outro personagem")
    ctx = d["lineage"].get("owner_rules") or {}
    current = owner_rules.context()
    if ctx.get("revision") != current["revision"] or ctx.get("character") != ch["id"] or \
            ctx.get("authority_crop_sha256") != ch.get("_authority_crop_sha256"):
        blocked.append("consulta das regras ou autoridade desatualizada/ausente")
    pal = palette.load(palette.ROOT / c.palette)
    rasters = [lint.check(f, c, pal) for f in frames]
    if any(not r["ok"] for r in rasters):
        blocked.append("um ou mais quadros falham o contrato raster")
    if any(owner_rules.rejected(image_sha(f)) or fidelity.rejected(ch, f) for f in frames):
        blocked.append("a sequencia contem pixels de um candidato rejeitado pelo dono")
    for name, first, last, _ in d["tags"]:
        base = name.removesuffix("_left").removesuffix("_right")
        spec = contracts.tag(base)
        if not spec or spec["frames"] != last - first + 1 or any(
                ms != round(1000 / spec["fps"]) for ms in d["durations"][first:last + 1]):
            blocked.append(name + ": contagem/cadencia de estudo, fora do contrato de runtime")
    loops = {p["name"]: p["loop"] for p in timeline.playback(d["tags"])}
    motion = review.motion(frames, d["tags"], d.get("holds"), "preserve", loops)
    if motion["blocking"]:
        blocked.append("movimento obrigatorio ausente")
    origin = d["lineage"]
    while origin.get("origin") == "pixel_patch":
        origin = origin["parent"]
    if origin.get("origin") == "generated_native":
        source = d.get("source") or {}
        if clip.source is None:
            blocked.append("referencia nativa em falta")
        else:
            blocked += animation_plan.source_errors(ch, clip.source, origin.get("parent"),
                                                    source.get("native_root", False), source.get("resolutions", []))
            if owner_rules.rejected(image_sha(clip.source)) or fidelity.rejected(ch, clip.source):
                blocked.append("referencia inicial rejeitada pelo dono")
        end = source.get("last")
        if end and clip.last is not None:
            blocked += animation_plan.source_errors(ch, clip.last, end.get("lineage"),
                                                    end.get("native_root", False), end.get("resolutions", []))
            if owner_rules.rejected(image_sha(clip.last)) or fidelity.rejected(ch, clip.last):
                blocked.append("referencia final rejeitada pelo dono")
    elif not d["lineage"].get("native_root_declared") and any(
            max((f.get("snap") or {}).get("grid", {}).get("period") or [1]) <= 1 for f in d["lineage"]["frames"]):
        pending.append("origem nativa da prancha nao declarada")
    node = origin if origin.get("origin") != "generated_native" else {}
    while node:
        if any(o.get("critical") or o.get("regions") for o in node.get("occurrences", [])):
            pending.append("perdas criticas do mestre ancestral: conservar a prova individual antes da prancha")
        node = node.get("parent") or {}
    return {"blocked": blocked, "pending": pending, "rasters": rasters, "motion": motion}
