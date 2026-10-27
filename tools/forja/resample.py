"""De uma imagem ampliada e da sua grade para a resolucao nativa.

Cada celula vira UM pixel. Por omissao vota a cor dominante no miolo da celula
(as bordas trazem a suavizacao do gerador): agrupa as cores em baldes de 16
niveis por canal, escolhe o balde mais cheio e, dentro dele, a cor exata mais
frequente se ela pesar; senao a media em luz linear da vizinhanca do balde. Assim
uma cor chapada sai exatamente igual, e uma cor ruidosa sai limpa. `mode` e so a cor
exata mais frequente (para reduzir pixel art que ja e limpa, sem misturar).

Os baldes procuram-se em oito grelhas, deslocadas meio balde em cada canal (o
histograma deslocado medio de Scott, 1985): numa grelha so, uma cor ruidosa que cai
numa fronteira (128 = 8 x 16) divide-se por dois a oito baldes e perde para a minoria
— 86 das 112 cores da paleta tem um canal a 3 niveis de uma fronteira (auditoria de
27/10, B02). A media faz-se depois na vizinhanca centrada no balde (um passo de
deslocamento da media), que a fronteira ja nao corta.
"""
from __future__ import annotations

import itertools
from dataclasses import dataclass, field

from PIL import Image

from . import color
from .grid import Grid
from .imageops import CLEAR, binarize

METHODS = ("dominant", "mode", "center", "median", "mean")
SHIFTS = tuple(itertools.product((0, 8), repeat=3))
REACH = 8


@dataclass
class Sampled:
    image: Image.Image
    purity: float
    mixed: int
    impure: list = field(default_factory=list)

    def as_dict(self) -> dict:
        return {"size": list(self.image.size), "purity": round(self.purity, 3), "mixed_cells": self.mixed}


def resample(image: Image.Image, grid: Grid, method: str = "dominant", inset: float = 0.18,
             coverage: float = 0.5) -> Sampled:
    if method not in METHODS:
        raise ValueError(f"metodo desconhecido: {method} (use {', '.join(METHODS)})")
    rgba = image.convert("RGBA")
    cols, rows = grid.size
    if (cols, rows) == rgba.size and grid.xs[0] == 0 and grid.ys[0] == 0:
        return Sampled(binarize(rgba), 1.0, 0, [])  # uma celula por pixel: o voto de cada uma e o proprio pixel
    out: list[tuple[int, int, int, int]] = []
    purities: list[float] = []
    impure: list[tuple[int, int]] = []
    for j in range(rows):
        y0, y1 = grid.ys[j], grid.ys[j + 1]
        for i in range(cols):
            x0, x1 = grid.xs[i], grid.xs[i + 1]
            pixel, purity = _cell(rgba, _inner(x0, y0, x1, y1, inset), method, coverage)
            out.append(pixel)
            if pixel[3]:
                purities.append(purity)
                if purity < 0.7:
                    impure.append((i, j))
    native = Image.new("RGBA", (cols, rows))
    native.putdata(out)
    return Sampled(native, sum(purities) / len(purities) if purities else 1.0, len(impure), impure)


def _inner(x0: int, y0: int, x1: int, y1: int, inset: float) -> tuple[int, int, int, int]:
    mx = max(1, round((x1 - x0) * inset)) if inset and x1 - x0 > 3 else 0
    my = max(1, round((y1 - y0) * inset)) if inset and y1 - y0 > 3 else 0
    return x0 + mx, y0 + my, max(x0 + mx + 1, x1 - mx), max(y0 + my + 1, y1 - my)


def _cell(rgba: Image.Image, box: tuple[int, int, int, int], method: str,
          coverage: float) -> tuple[tuple[int, int, int, int], float]:
    region = rgba.crop(box)
    area = region.width * region.height
    found = region.getcolors(area) or []
    solid = [(n, p[:3]) for n, p in found if p[3] >= 128]
    covered = sum(n for n, _ in solid)
    if not area or covered / area < coverage:
        return CLEAR, 1.0
    if method == "mode":  # a cor exata mais frequente: nunca uma cor que nao estava la
        return (*max(solid)[1], 255), 1.0
    if method == "center":
        p = region.getpixel((region.width // 2, region.height // 2))
        if p[3] < 128:
            p = max(solid)[1] + (255,)
        return (p[0], p[1], p[2], 255), 1.0
    if method == "mean":
        return (*color.mean_color(solid), 255), 1.0
    if method == "median":
        return (*_median(solid, covered), 255), 1.0
    best = _bucket(solid)
    weight = sum(n for n, _ in best)
    exact = max(best)
    pick = exact[1] if exact[0] >= 0.35 * weight else color.mean_color(_around(solid, color.mean_color(best)) or best)
    near = sum(n for n, c in solid if color.delta(c, pick) < 0.08)
    return (pick[0], pick[1], pick[2], 255), near / covered


def _bucket(solid: list[tuple[int, tuple[int, int, int]]]) -> list[tuple[int, tuple[int, int, int]]]:
    """O balde mais cheio nas oito grelhas deslocadas; no empate fica a grelha sem deslocamento (a de antes)."""
    best: list = []
    weight = -1
    for s in SHIFTS:
        buckets: dict[tuple[int, int, int], list[tuple[int, tuple[int, int, int]]]] = {}
        for n, c in solid:
            buckets.setdefault(((c[0] + s[0]) >> 4, (c[1] + s[1]) >> 4, (c[2] + s[2]) >> 4), []).append((n, c))
        top = max(buckets.values(), key=lambda items: sum(n for n, _ in items))
        w = sum(n for n, _ in top)
        if w > weight:
            best, weight = top, w
    return best


def _around(solid, center: tuple[int, int, int]) -> list[tuple[int, tuple[int, int, int]]]:
    """As cores a REACH niveis (por canal) do centro do balde: a vizinhanca que a fronteira nao corta."""
    return [(n, c) for n, c in solid if max(abs(c[i] - center[i]) for i in range(3)) <= REACH]


def _median(solid: list[tuple[int, tuple[int, int, int]]], total: int) -> tuple[int, int, int]:
    out = []
    for ch in range(3):
        acc, half = 0, total / 2
        for n, c in sorted(solid, key=lambda t: t[1][ch]):
            acc += n
            if acc >= half:
                out.append(c[ch])
                break
    return out[0], out[1], out[2]


def blockify(native: Image.Image, block: int) -> Image.Image:
    """Forca blocos block x block de uma cor (a lei dos 2 px do cenario, Asset Bible §1)."""
    if block <= 1:
        return native.copy()
    w, h = native.size
    cols, rows = -(-w // block), -(-h // block)
    xs = [min(w, i * block) for i in range(cols + 1)]
    ys = [min(h, j * block) for j in range(rows + 1)]
    small = resample(native, Grid(xs, ys, (block, block), 1.0), "dominant", inset=0.0).image
    return small.resize((cols * block, rows * block), Image.Resampling.NEAREST).crop((0, 0, w, h))
