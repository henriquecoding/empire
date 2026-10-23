"""Imagens-guia para anexar ao pedido: a grelha da prancha e a amostra da paleta.

Um gerador segue melhor uma imagem do que uma frase sobre medidas. O molde tem
o tamanho exato do pedido, as celulas, a linha de chao de cada uma e o eixo do
meio, em tons da propria cor de chave (o recorte apaga-os se o gerador os
copiar). A amostra da paleta sao quadrados grandes, sem texto.
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image

from . import color
from .palette import Palette, swatch


def _shade(rgb: tuple[int, int, int], amount: float) -> tuple[int, int, int]:
    return tuple(max(0, min(255, round(c * (1 - amount)))) for c in rgb)  # type: ignore[return-value]


def template(expect: dict, pivot_row: int | None = None, grid: bool = False) -> Image.Image:
    """O molde do pedido: `expect` e o bloco do prompts.build."""
    w, h = expect["size"]
    cols, rows = expect["layout"]
    k = expect["scale"]
    bg = expect["background"]
    base = color.parse_hex(bg) if bg != "transparent" else (255, 255, 255)
    img = Image.new("RGBA", (w, h), (*base, 255 if bg != "transparent" else 0))
    line = (*_shade(base, 0.25), 255)
    faint = (*_shade(base, 0.08), 255)
    cell_w, cell_h = w // cols, h // rows
    px = img.load()
    for j in range(rows):
        for i in range(cols):
            x0, y0 = i * cell_w, j * cell_h
            if grid:
                for x in range(x0, x0 + cell_w, k):
                    for y in range(y0, y0 + cell_h):
                        px[x, y] = faint
                for y in range(y0, y0 + cell_h, k):
                    for x in range(x0, x0 + cell_w):
                        px[x, y] = faint
            for x in range(x0, x0 + cell_w):
                px[x, y0] = line
            for y in range(y0, y0 + cell_h):
                px[x0, y] = line
            if pivot_row is not None:
                yb = y0 + pivot_row * k + k - 1
                for x in range(x0 + k, x0 + cell_w - k):
                    px[x, min(yb, h - 1)] = line
            mid = x0 + cell_w // 2
            for y in range(y0 + k, y0 + cell_h - k, 2 * k):
                for dy in range(min(k, h - y)):
                    px[mid, y + dy] = faint
    return img


def palette_swatch(palette: Palette, cell: int = 48, columns: int = 8) -> Image.Image:
    return swatch(palette, columns=columns, cell=cell)


def write(out_dir: str | Path, expect: dict, palette: Palette | None, pivot_row: int | None) -> dict:
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    files = {}
    template(expect, pivot_row).save(out / "guide_layout.png")
    files["layout"] = str(out / "guide_layout.png")
    if palette is not None and len(palette):
        palette_swatch(palette).save(out / "guide_palette.png")
        files["palette"] = str(out / "guide_palette.png")
    return files
