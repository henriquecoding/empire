"""Pixel art "falsa" fabricada, com a verdade conhecida.

Os testes e o `forja prova` precisam de saber o que a ferramenta devia
devolver. Aqui desenha-se um sprite nativo pequeno e depois estraga-se como um
gerador de imagens o estragaria: ampliacao fracionaria com celulas de largura
desigual, desfoque nas fronteiras, ruido por pixel e fundo liso. A pergunta do
teste e se a Forja devolve o sprite nativo pixel a pixel.
"""
from __future__ import annotations

import random

from PIL import Image, ImageFilter

from .imageops import CLEAR

SKIN = [(242, 196, 150), (196, 140, 98)]
CLOTH = [(186, 52, 60), (120, 30, 44), (58, 92, 160), (34, 52, 104), (220, 186, 72), (150, 112, 40)]


def sprite(seed: int = 7, size: tuple[int, int] = (24, 32)) -> Image.Image:
    """Um boneco simetrico com contorno preto, 2 tons por material, fundo vazio."""
    rnd = random.Random(seed)
    w, h = size
    img = Image.new("RGBA", size, CLEAR)
    cx = w // 2
    body = rnd.sample(range(0, len(CLOTH), 2), 2)
    head_r = max(3, w // 6)
    shapes = []
    for y in range(h):
        if y < 2 * head_r + 1:
            half = int(((head_r + 0.5) ** 2 - (y - head_r) ** 2) ** 0.5) if abs(y - head_r) <= head_r else 0
            mat = SKIN
        elif y < int(h * 0.7):
            half = int(w * 0.3) + (y % 3 == 0)
            mat = CLOTH[body[0]:body[0] + 2]
        else:
            half = int(w * 0.22)
            mat = CLOTH[body[1]:body[1] + 2]
        shapes.append((half, mat))
    for y, (half, mat) in enumerate(shapes):
        for x in range(cx - half, cx + half):
            if 0 <= x < w:
                shade = mat[1] if x >= cx + half // 3 else mat[0]
                img.putpixel((x, y), (*shade, 255))
    if h > 6:
        for x in range(cx - 1, cx + 1):
            for y in range(int(h * 0.7), h):
                img.putpixel((x, y), CLEAR)
    eye_y = head_r
    img.putpixel((cx - 2, eye_y), (20, 20, 30, 255))
    img.putpixel((cx + 1, eye_y), (20, 20, 30, 255))
    return outline(img)


def outline(img: Image.Image) -> Image.Image:
    w, h = img.size
    src = img.copy()
    for y in range(h):
        for x in range(w):
            if src.getpixel((x, y))[3]:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and src.getpixel((nx, ny))[3]:
                    img.putpixel((x, y), (0, 0, 0, 255))
                    break
    return img


def cuts(n: int, scale: float, jitter: float, rnd: random.Random) -> list[int]:
    out = [0]
    for k in range(1, n + 1):
        out.append(max(out[-1] + 2, int(round(k * scale + rnd.uniform(-jitter, jitter)))))
    return out


def fake(native: Image.Image, scale: float = 15.6, jitter: float = 1.2, blur: float = 0.9,
         noise: int = 6, bg: tuple[int, int, int] = (255, 0, 255), margin: int = 3,
         seed: int = 11) -> tuple[Image.Image, list[int], list[int]]:
    """A imagem estragada e as linhas de corte verdadeiras (sem a margem)."""
    rnd = random.Random(seed)
    padded = Image.new("RGBA", (native.width + 2 * margin, native.height + 2 * margin), (*bg, 255))
    padded.alpha_composite(native, (margin, margin))
    xs = cuts(padded.width, scale, jitter, rnd)
    ys = cuts(padded.height, scale, jitter, rnd)
    big = Image.new("RGB", (xs[-1], ys[-1]))
    for j in range(padded.height):
        for i in range(padded.width):
            big.paste(padded.getpixel((i, j))[:3], (xs[i], ys[j], xs[i + 1], ys[j + 1]))
    if blur:
        big = big.filter(ImageFilter.GaussianBlur(blur))
    if noise:
        px = big.load()
        for y in range(big.height):
            for x in range(big.width):
                r, g, b = px[x, y]
                n = rnd.randint(-noise, noise)
                px[x, y] = (min(255, max(0, r + n)), min(255, max(0, g + n)), min(255, max(0, b + n)))
    return big.convert("RGBA"), xs, ys


def sheet(frames: list[Image.Image], cols: int, scale: float = 6.0, gap: int = 40,
          bg: tuple[int, int, int] = (255, 0, 255), seed: int = 3) -> Image.Image:
    """Uma prancha como as que o gerador devolve: figuras espalhadas, cada uma ampliada."""
    rnd = random.Random(seed)
    bigs = [fake(f, scale=scale, jitter=0.6, blur=0.6, noise=4, bg=bg, margin=0, seed=rnd.randint(0, 999))[0]
            for f in frames]
    cell_w = max(b.width for b in bigs) + gap
    cell_h = max(b.height for b in bigs) + gap
    rows = -(-len(bigs) // cols)
    out = Image.new("RGBA", (cell_w * cols, cell_h * rows), (*bg, 255))
    for i, b in enumerate(bigs):
        cx, cy = (i % cols) * cell_w, (i // cols) * cell_h
        out.alpha_composite(b, (cx + (cell_w - b.width) // 2 + rnd.randint(-5, 5),
                                cy + cell_h - gap // 2 - b.height))
    return out
