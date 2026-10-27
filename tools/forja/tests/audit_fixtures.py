"""As fixtures sinteticas da auditoria de 27/10 (§12): uma grade conhecida de 16x16 celulas de 16 px e marcas menores
que uma celula, de tamanho e posicao declarados. Nao sao personagens: isolam a amostragem.
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image

K, N = 16, 16
SKIN, DARK, WHITE = (225, 178, 128, 255), (10, 8, 12, 255), (250, 240, 215, 255)
CELL = (8, 8)
MARKS = {"borda": ((0, 0, 3, 16), DARK), "centro_4": ((6, 0, 10, 16), DARK), "centro_6": ((5, 0, 11, 16), DARK),
         "dente": ((6, 6, 10, 10), WHITE), "pixel_inteiro": ((0, 0, 16, 16), DARK)}
LINE_CELLS = [(10, y) for y in range(2, 14)]
AUDIT = Path(__file__).resolve().parents[3] / "docs/art/research/2026-10-27-forja-auditoria-fidelidade"


def base() -> Image.Image:
    tiny = Image.new("RGBA", (N, N))
    browns = [(101, 74, 54, 255), (120, 91, 64, 255), (140, 111, 83, 255)]
    for y in range(N):
        for x in range(N):
            tiny.putpixel((x, y), SKIN if 4 <= x <= 11 and 4 <= y <= 11 else browns[(x + 2 * y) % 3])
    return tiny.resize((K * N, K * N), Image.Resampling.NEAREST)


def marked(name: str) -> Image.Image:
    box, color = MARKS[name]
    image = base()
    ox, oy = CELL[0] * K, CELL[1] * K
    image.paste(color, (ox + box[0], oy + box[1], ox + box[2], oy + box[3]))
    return image


def line() -> Image.Image:
    """Uma linha clara de 4 px sobre o vazio, ao lado de um bloco de pele."""
    tiny = Image.new("RGBA", (N, N))
    for y in range(2, 14):
        for x in range(2, 6):
            tiny.putpixel((x, y), SKIN)
    image = tiny.resize((K * N, K * N), Image.Resampling.NEAREST)
    image.paste(WHITE, (10 * K + 6, 2 * K, 10 * K + 10, 14 * K))
    return image


def cases() -> dict[str, Image.Image]:
    return {**{name: marked(name) for name in MARKS}, "fio_alfa": line()}


def rejected(name: str) -> Image.Image:
    return Image.open(AUDIT / "fixtures" / f"{name}.png").convert("RGBA")
