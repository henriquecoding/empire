"""A prancha pela grelha pedida: cada mancha pertence a celula onde esta a maior parte dela (auditoria A08).

Cortar pela linha da celula separa figuras que se tocam, mas tambem cortava a ponta de uma lanca que entra na
celula vizinha e colava-a na figura do lado, sem aviso. Aqui as manchas (8 vizinhos, numa versao reduzida da
mascara) contam-se por celula:
- toda numa celula: e dessa celula;
- quase toda numa (a parte de fora abaixo de SPILL): vai inteira para ela, `reassigned` — a ponta volta a figura
  dona e a vizinha fica sem ela;
- dividida: corta-se pela linha, como antes, `split` — figuras que se tocam ou uma que invade a outra.
As duas ficam escritas: o gerador nao manteve a pose dentro da celula, e isso so se resolve gerando de novo.
"""
from __future__ import annotations

from collections import Counter

from PIL import Image, ImageChops, ImageFilter

from . import lint, matte

SPILL = 0.25


def cell_rects(size: tuple[int, int], layout: tuple[int, int]) -> list[tuple[int, int, int, int]]:
    cols, rows = layout
    cw, ch = size[0] / cols, size[1] / rows
    return [(round(i * cw), round(j * ch), round((i + 1) * cw), round((j + 1) * ch))
            for j in range(rows) for i in range(cols)]


def blobs(mask: Image.Image) -> list[tuple[tuple[int, int, int, int], list[int]]]:
    """Manchas ligadas (8 vizinhos) de uma mascara: (caixa, indices dos pixels)."""
    w, h = mask.size
    getter = getattr(mask, "get_flattened_data", None) or mask.getdata
    on = [v > 0 for v in getter()]
    seen = bytearray(w * h)
    out = []
    for start in range(w * h):
        if not on[start] or seen[start]:
            continue
        stack, members = [start], []
        seen[start] = 1
        x0, y0, x1, y1 = w, h, 0, 0
        while stack:
            i = stack.pop()
            members.append(i)
            x, y = i % w, i // w
            x0, y0, x1, y1 = min(x0, x), min(y0, y), max(x1, x + 1), max(y1, y + 1)
            for ny in (y - 1, y, y + 1):
                for nx in (x - 1, x, x + 1):
                    j = ny * w + nx
                    if 0 <= nx < w and 0 <= ny < h and on[j] and not seen[j]:
                        seen[j] = 1
                        stack.append(j)
        out.append(((x0, y0, x1, y1), members))
    return out


def _region(members: list[int], small: Image.Image, factor: int, full: Image.Image) -> Image.Image:
    """Os pixels da mascara cheia que caem nesta mancha reduzida."""
    mark = Image.new("L", small.size, 0)
    for i in members:
        mark.putpixel((i % small.width, i // small.width), 255)
    big = mark.resize((small.width * factor, small.height * factor), Image.Resampling.NEAREST)
    return ImageChops.multiply(big.crop((0, 0, full.width, full.height)), full)


def split(image: Image.Image, bg: tuple[int, int, int] | None, layout: tuple[int, int], tolerance: int = 48):
    """(caixa por celula ou None, mascaras por caixa, manchas que atravessam celulas)."""
    full = matte.mask(image, bg, tolerance).filter(ImageFilter.MinFilter(3)).filter(ImageFilter.MaxFilter(3))
    rects = cell_rects(image.size, layout)
    cols, rows = layout
    factor = max(1, -(-max(image.size) // 512))
    small = full.resize((-(-image.width // factor), -(-image.height // factor)), Image.Resampling.BOX)
    small = small.point(lambda v: 255 if v > 24 else 0)
    cw, ch = image.width / cols, image.height / rows
    plus: dict[int, Image.Image] = {}
    minus: dict[int, Image.Image] = {}
    crossings = []
    for _, members in blobs(small):
        where = Counter(min(cols - 1, int((i % small.width + 0.5) * factor // cw))
                        + cols * min(rows - 1, int((i // small.width + 0.5) * factor // ch)) for i in members)
        if len(where) < 2:
            continue
        (owner, n), total = where.most_common(1)[0], len(members)
        if 1 - n / total >= SPILL:
            crossings.append({"action": "split", "cells": sorted(where), "share": {c: round(k / total, 3)
                                                                                    for c, k in where.items()}})
            continue
        region = _region(members, small, factor, full)
        plus[owner] = ImageChops.lighter(plus[owner], region) if owner in plus else region
        for c in where:
            if c != owner:
                minus[c] = ImageChops.lighter(minus[c], region) if c in minus else region
        crossings.append({"action": "reassigned", "cell": owner, "from": sorted(c for c in where if c != owner),
                          "outside": round(1 - n / total, 3)})
    boxes, masks = [], {}
    for c, rect in enumerate(rects):
        own = Image.new("L", image.size, 0)
        own.paste(full.crop(rect), rect[:2])
        own = ImageChops.subtract(own, minus[c]) if c in minus else own
        own = ImageChops.lighter(own, plus[c]) if c in plus else own
        bb = own.getbbox()
        if not bb:
            boxes.append(None)
            continue
        allowed = Image.new("L", image.size, 0)
        allowed.paste(255, rect)
        if c in plus:
            allowed = ImageChops.lighter(allowed, plus[c].filter(ImageFilter.MaxFilter(5)))
        grown = ImageChops.multiply(own.filter(ImageFilter.MaxFilter(5)), allowed)
        boxes.append(bb)
        masks[bb] = (ImageChops.subtract(grown, minus[c]) if c in minus else grown, 1)
    return boxes, masks, crossings


def by_frame(found: list, crossings: list[dict]) -> dict[int, list[dict]]:
    """As travessias de cada quadro: o indice conta so as celulas com figura, como os quadros."""
    index = {c: j for j, c in enumerate(i for i, b in enumerate(found) if b)}
    out: dict[int, list[dict]] = {}
    for x in crossings:
        for c in [x["cell"]] if x["action"] == "reassigned" else x["cells"]:
            if c in index:
                out.setdefault(index[c], []).append(x)
    return out


def finding(records: list[dict]) -> dict:
    """O achado do lint de um quadro que atravessou a celula: aviso, com o pedido ao gerador."""
    split = any(r["action"] == "split" for r in records)
    what = ("uma mancha atravessa a fronteira entre celulas e foi cortada pela linha: figuras que se tocam ou uma "
            "que invade a outra" if split else "uma parte da figura entrava noutra celula e voltou a ela")
    return lint.finding("cell_crossing", "warn", what, [r.get("cells") or [r["cell"], *r["from"]] for r in records],
                        "gerar de novo com espaco entre as poses",
                        "Keep every pose completely inside its own cell, with clear empty space between poses.")
