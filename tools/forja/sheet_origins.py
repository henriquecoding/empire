"""Celulas conhecidas conservam coordenadas: um salto nao vira uma pose parada."""
from __future__ import annotations

from PIL import Image

from . import color, grid, matte, resample
from .sheet import Figure


def extract(image: Image.Image, indices: list[int], layout: tuple[int, int],
            scale: float | None, bg: tuple[int, int, int] | None) -> list[Figure]:
    if scale is None or scale < 1:
        raise ValueError("preservar origem exige --layout e --scale conhecidos")
    cols, rows = layout
    cw, ch = image.width / cols, image.height / rows
    w, h = round(cw / scale), round(ch / scale)
    if min(w, h) < 1 or abs(cw / scale - w) > .02 or abs(ch / scale - h) > .02:
        raise ValueError("celulas nao correspondem a uma tela nativa inteira")
    figures = []
    for i in indices:
        x, y = i % cols, i // cols
        box = (round(x * cw), round(y * ch), round((x + 1) * cw), round((y + 1) * ch))
        crop = image.crop(box)
        sampled = resample.resample(crop, grid.known(crop.size, scale))
        native, _ = matte.remove(sampled.image, color.to_hex(bg) if bg else None)
        figures.append(Figure(box, native, scale, sampled.purity, ["origem da celula preservada"]))
    return figures
