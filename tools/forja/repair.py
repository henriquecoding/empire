"""Reparo deterministico de uma linha fina, como a corda de um arco: 1 px e reta entre duas ancoras (FORJA-03).

Uma linha simples conserta-se na grade sem gastar outra geracao. A linha nova segue a reta entre as
ancoras, um pixel por passo do eixo maior, na cor dominante da linha antiga. Onde um oclusor declarado
cruza a linha (o braco por cima da corda), nao se desenha por cima dele: fica o pixel da propria linha
mais perto da reta. Cada pixel antigo que sai fica transparente se toca o vazio; se esta cercado por
outra peca (corda por cima do braco), herda a cor dos vizinhos e fica registado como inferido, porque
o que estava por baixo nao se ve. O resultado e um candidato: quem o pousa e o compose, so na mascara.
"""
from __future__ import annotations

import math
from collections import Counter

from PIL import Image

from . import color, masks
from .imageops import CLEAR


def _steep(a, b) -> bool:
    return abs(b[1] - a[1]) >= abs(b[0] - a[0])


def ideal(a: tuple[int, int], b: tuple[int, int]) -> list[tuple[int, float, tuple[int, int]]]:
    """(coordenada maior, menor exata, pixel arredondado) de a ate b, um por passo do eixo maior."""
    steep = _steep(a, b)
    (ma, na), (mb, nb) = ((a[1], a[0]), (b[1], b[0])) if steep else (a, b)
    out = []
    for m in range(min(ma, mb), max(ma, mb) + 1):
        n = na + (nb - na) * (m - ma) / (mb - ma) if mb != ma else float(na)
        r = math.floor(n + 0.5)
        out.append((m, n, (r, m) if steep else (m, r)))
    return out


def straighten(image: Image.Image, line, a: tuple[int, int], b: tuple[int, int],
               keep=frozenset()) -> tuple[Image.Image, frozenset, dict]:
    """(candidato, zona editavel, relatorio). `keep` sao os pixels de oclusores onde nao se desenha."""
    img = image.convert("RGBA")
    px = img.load()
    line, keep = frozenset(line), frozenset(keep)
    if not line:
        raise ValueError("linha vazia: nada para endireitar")
    paint = Counter(px[p] for p in line).most_common(1)[0][0]
    steep = _steep(a, b)
    by_major: dict[int, list[tuple[int, int]]] = {}
    for p in line:
        by_major.setdefault(p[1] if steep else p[0], []).append(p)
    new, reused_under = set(), []
    for m, n, p in ideal(a, b):
        if p in keep:
            here = by_major.get(m, [])
            if here:
                q = min(here, key=lambda q: abs((q[0] if steep else q[1]) - n))
                new.add(q)
                reused_under.append(list(q))
            continue
        new.add(p)
    candidate = img.copy()
    out = candidate.load()
    for p in new - line:
        out[p] = paint
    inferred = []
    for p in sorted(line - new):
        around = [px[q] for q in ((p[0] + dx, p[1] + dy) for dx, dy in masks.N4)
                  if 0 <= q[0] < img.width and 0 <= q[1] < img.height and q not in line and q not in new]
        if len(around) >= 2 and all(c[3] >= 128 for c in around):
            out[p] = Counter(around).most_common(1)[0][0]
            inferred.append(list(p))
        else:
            out[p] = CLEAR
    zone = frozenset(line | new)
    info = {"anchors": [list(a), list(b)], "color": color.to_hex(paint[:3]), "line_pixels": len(new),
            "kept": len(new & line), "drawn": len(new - line), "cleared": len(line - new) - len(inferred),
            "inferred": inferred, "reused_under_occluder": reused_under,
            "note": "pixels inferidos: a cor da peca vizinha, porque o que estava por baixo da linha nao se ve"
            if inferred else None}
    return candidate, zone, info
