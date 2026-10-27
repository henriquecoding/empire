"""O que a amostragem deitou fora: a celula inteira contra o pixel que ficou (FORJA-07; auditoria de 27/10, §12).

A pureza mede so o miolo amostrado (o recuo de 18% deixa de fora 61% de uma celula de 16x16) e so as celulas que
ficaram opacas. Por isso um traco de 3 px na borda de uma celula, uma marca clara de 4x4 que perde o voto ou uma linha
fina sobre o vazio desapareciam com pureza 1,0 e sem aviso. Aqui cada celula le-se inteira, depois da escolha da cor:

- o conteudo opaco longe (OKLab >= NEAR) do pixel que ficou e `lost`; numa celula que ficou vazia, todo o opaco;
- o perdido que um vizinho (os 8 pixels a volta) ja tem, ou que e uma mistura do pixel com um vizinho (a borda
  suavizada, a fase de uma grade estimada), foi `absorbed`: a fronteira mexeu, o traco nao sumiu;
- o resto e `erased`: uma cor que nao ficou em lado nenhum ali. Conta-se quando passa de MIN_SHARE da celula.

Cada celula apagada diz a razao (`outside_core`: so fora do miolo; `minority`: estava no miolo e perdeu o voto;
`alpha_discarded`: a cobertura ficou abaixo do limiar e a celula saiu vazia), a cor perdida e as partes na celula e
no miolo. Nao ha limiar global: uma so celula conta, porque um olho e uma celula. Isto e evidencia de perda, nao
reconhecimento: a ferramenta nao sabe se a cor apagada e um dente ou ruido; quem declara a regiao (`fidelity.py`) sabe.
"""
from __future__ import annotations

import math

from PIL import Image

from . import color
from .grid import Grid
from .imageops import flat
from .resample import NEAR, _inner

MIN_SHARE = 0.04
KINDS = ("outside_core", "minority", "alpha_discarded")


def _segment(c, a, b) -> float:
    """A distancia OKLab de `c` ao segmento a-b: perto dele e uma mistura das duas cores."""
    p, u, v = color.oklab(c), color.oklab(a), color.oklab(b)
    d = [v[i] - u[i] for i in range(3)]
    n = sum(x * x for x in d)
    t = 0.0 if not n else max(0.0, min(1.0, sum((p[i] - u[i]) * d[i] for i in range(3)) / n))
    return math.sqrt(sum((p[i] - u[i] - t * d[i]) ** 2 for i in range(3)))


def _kept(c, here, around: list) -> bool:
    if any(color.delta(c, nb) < NEAR for nb in around):
        return True
    anchors = ([here] if here else []) + around
    return any(_segment(c, a, b) < NEAR for i, a in enumerate(anchors) for b in anchors[i + 1:]
               if here is None or a == here)


def observe(image: Image.Image, grid: Grid, native: Image.Image, inset: float = 0.18) -> dict:
    """As celulas cujo conteudo sumiu do pixel nativo `native` (a saida da amostragem, antes do fundo e do recorte)."""
    rgba = image.convert("RGBA")
    cols, rows = grid.size
    if (cols, rows) == rgba.size:
        return summary([], 0, cols * rows)
    px = native.load()
    erased, absorbed = [], 0
    for j in range(rows):
        y0, y1 = grid.ys[j], grid.ys[j + 1]
        for i in range(cols):
            x0, x1 = grid.xs[i], grid.xs[i + 1]
            region = rgba.crop((x0, y0, x1, y1))
            area = region.width * region.height
            found = region.getcolors(area) or []
            out = px[i, j]
            if len(found) <= 1 and (not found or (found[0][1][3] >= 128) == (out[3] >= 128)):
                continue
            here = out[:3] if out[3] >= 128 else None
            solid = [(n, p[:3]) for n, p in found if p[3] >= 128]
            lost = [(n, c) for n, c in solid if here is None or color.delta(c, here) >= NEAR]
            if sum(n for n, _ in lost) < MIN_SHARE * area:
                continue
            around = list(dict.fromkeys(px[a, b][:3] for a in range(max(0, i - 1), min(cols, i + 2))
                                        for b in range(max(0, j - 1), min(rows, j + 2))
                                        if (a, b) != (i, j) and px[a, b][3] >= 128))
            gone = [(n, c) for n, c in lost if not _kept(c, here, around)]
            share = sum(n for n, _ in gone) / area
            if share < MIN_SHARE:
                absorbed += 1
                continue
            erased.append(_record(rgba, (x0, y0, x1, y1), inset, (i, j), here, gone, share))
    return summary(erased, absorbed, cols * rows)


def _record(rgba, box, inset, cell, here, gone, share) -> dict:
    core = _inner(*box, inset)
    lost = {c for _, c in gone}
    region = rgba.crop(core)
    inner = sum(n for n, p in region.getcolors(region.width * region.height) or [] if p[3] >= 128 and p[:3] in lost)
    core_share = inner / max(1, region.width * region.height)
    kind = "alpha_discarded" if here is None else ("minority" if inner else "outside_core")
    main = max(gone)[1]
    return {"cell": list(cell), "kind": kind, "color": color.to_hex(main), "kept": color.to_hex(here) if here else None,
            "cell_share": round(share, 3), "core_share": round(core_share, 3), "source_box": list(box)}


def summary(erased: list[dict], absorbed: int, cells: int) -> dict:
    by = {k: sum(1 for e in erased if e["kind"] == k) for k in KINDS}
    return {"erased_cells": len(erased), "absorbed_cells": absorbed, "cells": cells, "by_kind": by,
            "erased": erased, "basis": "celula inteira contra o pixel escolhido; cor apagada = sem vizinho nem mistura"}


def crop(info: dict, box: tuple[int, int, int, int]) -> dict:
    """As celulas apagadas com as coordenadas tambem no recorte nativo (o `snap` corta ao opaco). Uma celula que saiu
    vazia pode ficar fora do recorte: continua nos dados, com `inside_crop` falso (a linha sobre o vazio)."""
    out = []
    for e in info["erased"]:
        x, y = e["cell"][0] - box[0], e["cell"][1] - box[1]
        out.append({**e, "native": [x, y], "inside_crop": 0 <= x < box[2] - box[0] and 0 <= y < box[3] - box[1]})
    return {**info, "erased": out}


def groups(info: dict) -> list[list[int]]:
    """As caixas (no recorte nativo) dos grupos de celulas apagadas vizinhas, da maior para a menor."""
    cells = {tuple(e["native"]) for e in info["erased"]}
    seen, out = set(), []
    for start in sorted(cells):
        if start in seen:
            continue
        group, stack = [], [start]
        seen.add(start)
        while stack:
            x, y = stack.pop()
            group.append((x, y))
            for nb in ((x + a, y + b) for a in (-1, 0, 1) for b in (-1, 0, 1)):
                if nb in cells and nb not in seen:
                    seen.add(nb)
                    stack.append(nb)
        out.append((len(group), [min(x for x, _ in group), min(y for _, y in group),
                                 max(x for x, _ in group) + 1, max(y for _, y in group) + 1]))
    return [b for _, b in sorted(out, key=lambda t: -t[0])]


def subgrid(native: Image.Image, impure: list[tuple[int, int]], box: tuple[int, int, int, int]) -> dict:
    """A maior zona de celulas misturadas: o gerador desenhou ali mais fino do que a propria grade.

    Costuma ser o rosto. O voto nao recupera um traco mais fino que a celula; diz-se onde e,
    para o gerador, como desenhar (ou corrige-se essa caixa com `forja inpaint`).
    """
    alpha = native.getchannel("A")
    cells = {(x - box[0], y - box[1]) for x, y in impure
             if 0 <= x - box[0] < native.width and 0 <= y - box[1] < native.height
             and alpha.getpixel((x - box[0], y - box[1])) >= 128}
    solid = sum(1 for v in flat(alpha) if v >= 128) or 1
    best: list[tuple[int, int]] = []
    seen: set = set()
    for start in cells:
        if start in seen:
            continue
        group, stack = [], [start]
        seen.add(start)
        while stack:
            x, y = stack.pop()
            group.append((x, y))
            for nx in range(x - 1, x + 2):
                for ny in range(y - 1, y + 2):
                    if (nx, ny) in cells and (nx, ny) not in seen:
                        seen.add((nx, ny))
                        stack.append((nx, ny))
        best = max(best, group, key=len)
    region = ([min(x for x, _ in best), min(y for _, y in best), max(x for x, _ in best) + 1,
               max(y for _, y in best) + 1] if best else None)
    return {"cells": len(cells), "share": round(len(cells) / solid, 3), "largest": len(best), "box": region,
            "_coords": sorted(cells)}
