"""Tons por limiar perceptual: juntar o ruido de compressao de uma recuperacao sem impor um numero de cores (FORJA-10).

A prancha de autoridade e um JPEG: cada material plano chega com dezenas de cores quase iguais. Quantizar para a
paleta de trabalho (112 cores tiradas de dois cenarios) troca o material: a tunica vinho do escudeiro virava
castanha, a pele manchava. Aqui as cores juntam-se pela distancia OKLab (abaixo de `threshold` sao o mesmo tom), o
centro de cada tom e a media pesada das cores dele, e um tom pequeno so se junta ao vizinho maior se estiver perto
(`reach`): uma pupila ou um brilho de um pixel, longe de tudo, fica. Escuros sem croma viram o contorno (#000000).
O numero de tons sai da imagem, nao de um teto. A cor do projeto substitui o tom so quando e indistinguivel dele
(`snap`); o resto e uma rampa proposta, que o dono aceita ou nao.
"""
from __future__ import annotations

from collections import Counter

from PIL import Image

from . import color


def _groups(counts: Counter, threshold: float) -> list[list]:
    labs = {c: color.oklab(c) for c in counts}
    groups: list[list] = []
    for c, _ in sorted(counts.items(), key=lambda kv: (-kv[1], kv[0])):
        best = min(groups, key=lambda g: color.dist2(g[0], labs[c]), default=None)
        if best is not None and color.dist2(best[0], labs[c]) ** 0.5 < threshold:
            best[2].append(c)
        else:
            groups.append([labs[c], counts[c], [c]])
    for _ in range(3):
        for g in groups:
            g[1] = sum(counts[c] for c in g[2])
            g[0] = tuple(sum(labs[c][i] * counts[c] for c in g[2]) / g[1] for i in range(3))
        members = [c for g in groups for c in g[2]]
        for g in groups:
            g[2] = []
        for c in members:
            min(groups, key=lambda g: color.dist2(g[0], labs[c]))[2].append(c)
        groups = [g for g in groups if g[2]]
    return groups


def organize(image: Image.Image, threshold: float = 0.035, small: int = 3, reach: float = 0.07,
             dark: float = 0.18, palette=None, snap: float = 0.02) -> tuple[Image.Image, dict]:
    """A imagem com cada cor no seu tom, e o relatorio: tons, peso, origem (projeto ou proposta)."""
    rgba = image.convert("RGBA")
    px = rgba.load()
    counts = Counter(px[x, y][:3] for y in range(rgba.height) for x in range(rgba.width) if px[x, y][3])
    if not counts:
        return rgba.copy(), {"tones": [], "input_colors": 0}
    groups = _groups(counts, threshold)
    big = [g for g in groups if g[1] > small] or groups
    for g in [g for g in groups if g[1] <= small and g not in big]:
        near = min(big, key=lambda b: color.dist2(b[0], g[0]))
        if color.dist2(near[0], g[0]) ** 0.5 < reach:
            near[2] += g[2]
            near[1] += g[1]
        else:
            big.append(g)
    project = [(p, color.oklab(p)) for p in (palette.colors if palette else [])]
    mapping, tones = {}, []
    for g in big:
        chroma = (g[0][1] ** 2 + g[0][2] ** 2) ** 0.5
        rgb, origin = color.from_oklab(g[0]), "proposed"
        if g[0][0] < dark and chroma < 0.03:
            rgb, origin = (0, 0, 0), "outline"
        elif project:
            near, lab = min(project, key=lambda p: color.dist2(p[1], g[0]))
            if color.dist2(lab, g[0]) ** 0.5 < snap:
                rgb, origin = near, "project"
        for c in g[2]:
            mapping[c] = rgb
        tones.append({"hex": color.to_hex(rgb), "pixels": g[1], "inputs": len(g[2]), "origin": origin})
    out = rgba.copy()
    opx = out.load()
    for y in range(out.height):
        for x in range(out.width):
            if opx[x, y][3]:
                opx[x, y] = mapping[opx[x, y][:3]] + (255,)
    merged: dict[str, dict] = {}
    for t in tones:
        m = merged.setdefault(t["hex"], {**t, "pixels": 0, "inputs": 0})
        m["pixels"] += t["pixels"]
        m["inputs"] += t["inputs"]
    return out, {"input_colors": len(counts), "tones": sorted(merged.values(), key=lambda t: -t["pixels"]),
                 "threshold": threshold, "small": small, "reach": reach, "snap": snap,
                 "note": "o numero de tons sai da imagem; nenhum teto de cores foi imposto"}
