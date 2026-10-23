"""Imagens-guia para anexar ao pedido: a grelha da prancha e a amostra da paleta.

Um gerador segue melhor uma imagem do que uma frase sobre medidas. O molde tem
o tamanho exato do pedido, as celulas, a linha de chao de cada uma e o eixo do
meio, em tons da propria cor de chave (o recorte apaga-os se o gerador os
copiar). A amostra da paleta sao quadrados grandes, sem texto.
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

from . import color
from .palette import Palette, swatch


def _shade(rgb: tuple[int, int, int], amount: float) -> tuple[int, int, int]:
    return tuple(max(0, min(255, round(c * (1 - amount)))) for c in rgb)  # type: ignore[return-value]


def template(expect: dict, pivot_row: int | None = None, grid: bool = False) -> Image.Image:
    """O molde do pedido: `expect` e o bloco do prompts.build (tamanho, grelha logica, margens, celulas).

    Desenha-se em coordenadas logicas e converte-se para o tamanho da imagem, para a
    margem (Gemini) e uma escala nao inteira caberem sem esticar nada.
    """
    w, h = expect["size"]
    cols, rows = expect["layout"]
    lw, lh = expect.get("cells") or (w / expect["scale"], h / expect["scale"])
    x0, y0, x1, y1 = expect.get("content") or (0, 0, lw, lh)
    sx, sy = w / lw, h / lh
    bg = expect["background"]
    base = color.parse_hex(bg) if bg != "transparent" else (255, 255, 255)
    img = Image.new("RGBA", (w, h), (*base, 255 if bg != "transparent" else 0))
    line = (*_shade(base, 0.25), 255)
    faint = (*_shade(base, 0.08), 255)
    draw = ImageDraw.Draw(img)

    def px(lx: float, ly: float) -> tuple[int, int]:
        return min(w - 1, round(lx * sx)), min(h - 1, round(ly * sy))

    if grid:
        for lx in range(int(x0), int(x1) + 1):
            draw.line([px(lx, y0), px(lx, y1)], fill=faint)
        for ly in range(int(y0), int(y1) + 1):
            draw.line([px(x0, ly), px(x1, ly)], fill=faint)
    cw, ch = (x1 - x0) / cols, (y1 - y0) / rows
    for j in range(rows):
        for i in range(cols):
            cx0, cy0 = x0 + i * cw, y0 + j * ch
            draw.rectangle([px(cx0, cy0), px(cx0 + cw, cy0 + ch)], outline=line)
            if pivot_row is not None:
                yb = px(0, cy0 + pivot_row + 1)[1] - 1
                draw.line([(px(cx0 + 1, 0)[0], yb), (px(cx0 + cw - 1, 0)[0], yb)], fill=line)
            mid = px(cx0 + cw / 2, 0)[0]
            for ly in range(int(cy0) + 1, int(cy0 + ch) - 1, 2):
                draw.line([(mid, px(0, ly)[1]), (mid, px(0, ly + 1)[1] - 1)], fill=faint)
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
