"""Separar as figuras de uma prancha gerada e devolve-las como quadros nativos.

O guia de personagens (§5) pede: contar as figuras reais antes de extrair,
nao inventar um quadro em falta, juntar a arma solta ao seu dono, fixar a escala
por uma medida estavel e alinhar pelo apoio. E o que isto faz, e diz o que fez:
quantas figuras achou contra quantas se pediram, onde, com que escala, quantos
pixels ficaram de fora da tela.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from statistics import median

from PIL import Image, ImageChops, ImageFilter

from . import color, grid as gridmod, matte, resample
from .imageops import opaque_bbox
from .placement import ALIGNS, ANCHORS, anchor_point, frames

__all__ = ["ALIGNS", "ANCHORS", "Figure", "anchor_point", "by_cells", "cell_rects", "extract", "find",
           "find_cells", "find_masks", "frames", "mask_for", "reading_order"]



@dataclass
class Figure:
    box: tuple[int, int, int, int]
    native: Image.Image | None = None
    period: float = 0.0
    purity: float = 0.0
    notes: list[str] = field(default_factory=list)
    origin_raw: tuple[int, int] | None = None
    periods: tuple[float, float] = (0.0, 0.0)
    origin: tuple[int, int] | None = None


def find(image: Image.Image, bg: tuple[int, int, int] | None, gap: int = 12,
         min_share: float = 0.02, tolerance: int = 48) -> tuple[list[tuple[int, int, int, int]], list]:
    """Caixas das figuras (ordem de leitura) e as manchas pequenas deixadas de lado."""
    boxes, stray, _ = find_masks(image, bg, gap, min_share, tolerance)
    return boxes, stray


def find_masks(image: Image.Image, bg: tuple[int, int, int] | None, gap: int = 12,
               min_share: float = 0.02, tolerance: int = 48):
    """Como `find`, e a mascara de cada figura: o que e de outra figura nao entra no recorte."""
    full = matte.mask(image, bg, tolerance)
    factor = max(1, -(-max(image.size) // 256))
    small = full.resize((-(-image.width // factor), -(-image.height // factor)), Image.Resampling.BOX)
    small = small.point(lambda v: 255 if v > 24 else 0)
    reach = max(1, gap // factor)
    grown = small.filter(ImageFilter.MaxFilter(2 * reach + 1)) if reach else small
    boxes, masks = [], {}
    for (x0, y0, x1, y1), members in _blobs(grown):
        box = (x0 * factor, y0 * factor, min(image.width, x1 * factor), min(image.height, y1 * factor))
        tight = full.crop(box).getbbox()
        if tight:
            box = (box[0] + tight[0], box[1] + tight[1], box[0] + tight[2], box[1] + tight[3])
            boxes.append(box)
            own = Image.new("L", grown.size, 0)
            for i in members:
                own.putpixel((i % grown.width, i // grown.width), 255)
            masks[box] = (own, factor)
    if not boxes:
        return [], [], {}
    biggest = max((b[2] - b[0]) * (b[3] - b[1]) for b in boxes)
    keep = [b for b in boxes if (b[2] - b[0]) * (b[3] - b[1]) >= min_share * biggest]
    stray = [b for b in boxes if b not in keep]
    return reading_order(keep), stray, masks


def cell_rects(size: tuple[int, int], layout: tuple[int, int]) -> list[tuple[int, int, int, int]]:
    cols, rows = layout
    cw, ch = size[0] / cols, size[1] / rows
    return [(round(i * cw), round(j * ch), round((i + 1) * cw), round((j + 1) * ch))
            for j in range(rows) for i in range(cols)]


def find_cells(image: Image.Image, bg: tuple[int, int, int] | None, layout: tuple[int, int],
               tolerance: int = 48) -> tuple[list, list, dict]:
    """Com a grelha pedida: cada celula e uma figura (ou None, se vazia), mesmo que se toquem.

    E o caminho robusto para pranchas densas: o prompt pede celulas iguais, e o que
    esta numa celula pertence a essa figura. Manchas de 1-2 px de ruido nao contam.
    """
    full = matte.mask(image, bg, tolerance).filter(ImageFilter.MinFilter(3)).filter(ImageFilter.MaxFilter(3))
    boxes, masks = [], {}
    for cell in cell_rects(image.size, layout):
        part = full.crop(cell)
        bb = part.getbbox()
        if not bb:
            boxes.append(None)
            continue
        box = (cell[0] + bb[0], cell[1] + bb[1], cell[0] + bb[2], cell[1] + bb[3])
        own = Image.new("L", image.size, 0)
        own.paste(part.filter(ImageFilter.MaxFilter(5)), cell[:2])
        boxes.append(box)
        masks[box] = (own, 1)
    return boxes, [], masks


def mask_for(masks: dict, box: tuple[int, int, int, int], region: tuple[int, int, int, int]) -> Image.Image | None:
    """A mascara (resolucao cheia, recortada a `region`) das manchas que cabem em `box`."""
    out = None
    for b, (small, factor) in masks.items():
        if not (b[0] >= box[0] and b[1] >= box[1] and b[2] <= box[2] and b[3] <= box[3]):
            continue
        x0, y0, x1, y1 = region
        sx0, sy0, sx1, sy1 = x0 // factor, y0 // factor, -(-x1 // factor), -(-y1 // factor)
        part = small.crop((sx0, sy0, sx1, sy1)).resize(((sx1 - sx0) * factor, (sy1 - sy0) * factor),
                                                       Image.Resampling.NEAREST)
        ox, oy = x0 - sx0 * factor, y0 - sy0 * factor
        part = part.crop((ox, oy, ox + x1 - x0, oy + y1 - y0))
        out = part if out is None else ImageChops.lighter(out, part)
    return out


def _blobs(mask: Image.Image) -> list[tuple[tuple[int, int, int, int], list[int]]]:
    w, h = mask.size
    getter = getattr(mask, "get_flattened_data", None) or mask.getdata
    on = [v > 0 for v in getter()]
    seen = bytearray(w * h)
    out = []
    for start in range(w * h):
        if not on[start] or seen[start]:
            continue
        stack = [start]
        seen[start] = 1
        x0, y0, x1, y1 = w, h, 0, 0
        members = []
        while stack:
            i = stack.pop()
            members.append(i)
            x, y = i % w, i // w
            x0, y0, x1, y1 = min(x0, x), min(y0, y), max(x1, x + 1), max(y1, y + 1)
            for dy in (-1, 0, 1):
                ny = y + dy
                if 0 <= ny < h:
                    for dx in (-1, 0, 1):
                        nx = x + dx
                        j = ny * w + nx
                        if 0 <= nx < w and on[j] and not seen[j]:
                            seen[j] = 1
                            stack.append(j)
        out.append(((x0, y0, x1, y1), members))
    return out


def reading_order(boxes: list[tuple[int, int, int, int]]) -> list[tuple[int, int, int, int]]:
    """Linhas pela sobreposicao vertical, e dentro de cada linha da esquerda para a direita."""
    rows: list[list[tuple[int, int, int, int]]] = []
    for b in sorted(boxes, key=lambda b: (b[1] + b[3]) / 2):
        for row in rows:
            top, bottom = min(r[1] for r in row), max(r[3] for r in row)
            overlap = min(bottom, b[3]) - max(top, b[1])
            if overlap > 0.5 * min(b[3] - b[1], bottom - top):
                row.append(b)
                break
        else:
            rows.append([b])
    return [b for row in rows for b in sorted(row, key=lambda b: b[0])]


def by_cells(boxes: list[tuple[int, int, int, int]], size: tuple[int, int],
             layout: tuple[int, int]) -> list[tuple[int, int, int, int] | None]:
    """Com a grelha pedida (colunas x linhas): uma caixa por celula, juntando pedacos."""
    cols, rows = layout
    cw, ch = size[0] / cols, size[1] / rows
    cells: list[tuple[int, int, int, int] | None] = [None] * (cols * rows)
    for b in boxes:
        i = min(cols - 1, int(((b[0] + b[2]) / 2) // cw)) + cols * min(rows - 1, int(((b[1] + b[3]) / 2) // ch))
        old = cells[i]
        cells[i] = b if old is None else (min(old[0], b[0]), min(old[1], b[1]), max(old[2], b[2]), max(old[3], b[3]))
    return cells


def extract(image: Image.Image, boxes: list, bg: tuple[int, int, int] | None, pad: int = 6,
            scale: float | None = None, same_height: bool = False, masks: dict | None = None) -> list[Figure]:
    """Cada caixa vira uma figura nativa. A escala e comum: a mediana das medidas."""
    figures = [Figure(b) for b in boxes if b]
    crops = []
    for f in figures:
        region = (max(0, f.box[0] - pad), max(0, f.box[1] - pad),
                  min(image.width, f.box[2] + pad), min(image.height, f.box[3] + pad))
        crop = image.crop(region)
        own = mask_for(masks, f.box, region) if masks else None
        if own is not None:
            crop.putalpha(ImageChops.darker(crop.getchannel("A"), own))
        crops.append(crop)
    if same_height and crops:
        target = median(f.box[3] - f.box[1] for f in figures)
        crops = [c.resize((max(1, round(c.width * target / (f.box[3] - f.box[1]))),
                           max(1, round(c.height * target / (f.box[3] - f.box[1])))), Image.Resampling.LANCZOS)
                 for c, f in zip(crops, figures)]
    periods = [gridmod.detect(c).period[0] for c in crops]
    shared = scale or (median(p for p in periods if p > 1) if any(p > 1 for p in periods) else 1.0)
    for f, crop, own in zip(figures, crops, periods):
        g = gridmod.detect(crop, scale=shared) if shared > 1 else gridmod.detect(crop)
        sampled = resample.resample(crop, g)
        native, _ = matte.remove(sampled.image, color.to_hex(bg) if bg else None)
        box = opaque_bbox(native) or (0, 0, native.width, native.height)
        f.native = native.crop(box)
        f.period, f.purity, f.periods = g.period[0], sampled.purity, g.period
        region = (max(0, f.box[0] - pad), max(0, f.box[1] - pad))
        f.origin_raw = (region[0] + g.xs[box[0]], region[1] + g.ys[box[1]])
        if own > 1 and abs(own - shared) / shared > 0.08:
            f.notes.append(f"escala propria {own:.2f} difere da comum {shared:.2f}")
    return figures
