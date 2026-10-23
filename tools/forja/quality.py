"""Diagnostico nao destrutivo por tag e por regiao de identidade.

Medidas locais, nao um juiz estetico. Uma regiao protegida e um contrato
explicito de pixels imoveis, nunca uma tentativa de reconhecer uma cara.
Flicker e descontinuidade sao candidatos a revisao, nao erros provados.
"""
from __future__ import annotations

from statistics import median

from PIL import Image

from . import contracts, lint
from .imageops import flat, opaque_bbox

POLICY = {"loop_jump_ratio": 3.0, "loop_jump_min_share": 0.15}


def pixels(image: Image.Image) -> list[tuple]:
    return [p if p[3] else (0, 0, 0, 0) for p in flat(image.convert("RGBA"))]


def difference(a: Image.Image, b: Image.Image) -> dict:
    if a.size != b.size:
        raise ValueError("comparacao exige a mesma tela; nao se redimensionam referencias")
    pa, pb = pixels(a), pixels(b)
    union = sum(bool(p[3] or q[3]) for p, q in zip(pa, pb))
    overlap = sum(bool(p[3] and q[3]) for p, q in zip(pa, pb))
    changed = sum(p != q for p, q in zip(pa, pb))
    return {"changed_pixels": changed, "changed_share": round(changed / max(1, union), 6),
            "silhouette_iou": round(overlap / max(1, union), 6)}


def _flicker(frames: list[Image.Image], loop: bool) -> int:
    if len(frames) < 3:
        return 0
    data = [pixels(f) for f in frames]
    count = 0
    for i in range(len(data) if loop else len(data) - 2):
        a, b, c = (data[(i + n) % len(data)] for n in range(3))
        count += sum(p == r and p != q and bool(p[3] and q[3]) for p, q, r in zip(a, b, c))
    return count


def review(frames: list[Image.Image], tags: list[tuple] | None = None,
           reference: Image.Image | None = None, region: tuple[int, int, int, int] | None = None) -> dict:
    if not frames or len({f.size for f in frames}) != 1:
        raise ValueError("revisao exige quadros nao vazios numa tela comum")
    if reference is not None and reference.size != frames[0].size:
        raise ValueError("referencia e quadros devem ter a mesma tela nativa")
    if region and (reference is None or not (0 <= region[0] < region[2] <= frames[0].width
                                           and 0 <= region[1] < region[3] <= frames[0].height)):
        raise ValueError("regiao protegida exige referencia e uma caixa dentro da tela")
    findings, per_tag = [], []
    for name, start, end, direction in tags or [("review", 0, len(frames) - 1, "forward")]:
        if not 0 <= start <= end < len(frames):
            raise ValueError("intervalo de tag fora dos quadros")
        group = frames[start:end + 1]
        rasters = {tuple(pixels(f)) for f in group}
        crops = [(f.crop(opaque_bbox(f)) if opaque_bbox(f) else f) for f in group]
        shapes = {(f.size, tuple(pixels(f))) for f in crops}
        action = name.removesuffix("_right").removesuffix("_left")
        loop = bool((contracts.tag(action) or {}).get("loop", False))
        changes = [difference(a, b)["changed_share"] for a, b in zip(group, group[1:])]
        seam = difference(group[-1], group[0])["changed_share"] if loop else None
        per_tag.append({"name": name, "from": start, "to": end, "direction": direction, "loop": loop,
                        "distinct_rasters": len(rasters), "distinct_shapes": len(shapes),
                        "adjacent_change_share": changes, "loop_change_share": seam,
                        "flicker_candidates": _flicker(group, loop)})
        if len(group) > 1 and len(rasters) == 1:
            findings.append(lint.finding("static_sequence", "warn", f"{name}: todos os quadros sao iguais; confirmar pausa",
                                         hint="Draw distinct articulated key poses for the requested action; do not repeat one static sprite."))
        elif len(group) > 1 and len(shapes) == 1:
            findings.append(lint.finding("rigid_translation", "warn", f"{name}: so a posicao mudou, sem articulacao",
                                         hint="Animate joints, weight and secondary motion, not just translation of the same raster."))
        if seam is not None and changes and seam > max(POLICY["loop_jump_min_share"],
                                                       POLICY["loop_jump_ratio"] * median(changes)):
            findings.append(lint.finding("loop_jump", "warn", f"{name}: salto na emenda do ciclo ({seam:.1%})",
                                         hint="Match the last-to-first transition to the timing and motion of the rest of the loop."))
    comparison = None
    if reference is not None:
        comparison = {"frames": [difference(reference, f) for f in frames], "region": list(region) if region else None}
        if region:
            comparison["regions"] = [difference(reference.crop(region), f.crop(region)) for f in frames]
            changed = [i for i, r in enumerate(comparison["regions"]) if r["changed_pixels"]]
            if changed:
                findings.append(lint.finding("protected_region", "error", f"regiao protegida mudou nos quadros {changed}",
                                             [list(region)], hint="Keep the explicitly protected region pixel-identical to the reference."))
    return {"ready": not findings, "artistic_approval": False, "policy": POLICY, "by_tag": per_tag,
            "reference": comparison, "findings": findings,
            "prompt_feedback": " ".join(dict.fromkeys(f["prompt_hint"] for f in findings if f["prompt_hint"]))}
