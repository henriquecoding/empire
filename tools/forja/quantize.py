"""Levar cada pixel opaco a uma paleta, com ou sem dithering ordenado.

O dithering daqui e posicional entre as DUAS cores mais proximas: o pixel cai
num ponto do segmento entre elas, e a matriz de Bayer decide qual das duas
vence naquela posicao. Sai um padrao de duas cores, limpo, sem a poeira do
Floyd-Steinberg. No Empire so vale em efeitos e no ceu (Asset Bible §1).
"""
from __future__ import annotations

from PIL import Image

from . import color
from .imageops import CLEAR, grid as to_grid, from_grid
from .palette import Palette, extract

DITHERS = ("none", "bayer2", "bayer4", "bayer8")


def bayer(n: int) -> list[list[float]]:
    """Matriz de Bayer n x n (n potencia de 2), limiares em ]0, 1[."""
    m = [[0]]
    while len(m) < n:
        size = len(m)
        m = [[4 * m[y % size][x % size] + (0, 2, 3, 1)[(y // size) * 2 + (x // size)]
              for x in range(size * 2)] for y in range(size * 2)]
    total = n * n
    return [[(v + 0.5) / total for v in row] for row in m]


def to_palette(image: Image.Image, palette: Palette, dither: str = "none",
               strength: float = 1.0) -> Image.Image:
    if dither not in DITHERS:
        raise ValueError(f"dithering desconhecido: {dither} (use {', '.join(DITHERS)})")
    rows = to_grid(image)
    matrix = bayer(int(dither[5:])) if dither != "none" else None
    for y, row in enumerate(rows):
        for x, p in enumerate(row):
            if p[3] < 128:
                row[x] = CLEAR
                continue
            if matrix is None:
                row[x] = (*palette.nearest(p), 255)
                continue
            i, j, t = palette.two_nearest(p)
            t = 0.5 + (t - 0.5) * strength if strength != 1 else t
            limit = matrix[y % len(matrix)][x % len(matrix)]
            row[x] = (*palette.colors[j if t > limit else i], 255)
    return from_grid(rows)


def reduce(image: Image.Image, count: int, dither: str = "none") -> tuple[Image.Image, Palette]:
    pal = extract(image, count)
    return to_palette(image, pal, dither), pal


def shared_palette(frames: list[Image.Image], count: int) -> Palette:
    """Uma paleta para todos os quadros: o mesmo material nao muda de cor a meio do passo."""
    if not frames:
        return Palette([])
    w = max(f.width for f in frames)
    sheet = Image.new("RGBA", (w, sum(f.height for f in frames)))
    y = 0
    for f in frames:
        sheet.paste(f, (0, y))
        y += f.height
    return extract(sheet, count)


def off_palette(image: Image.Image, palette: Palette) -> list[tuple[int, int, int, int]]:
    """(x, y, contagem, cor mais proxima em hex) — so a primeira ocorrencia de cada cor fora."""
    allowed = set(palette.colors)
    seen: dict[tuple[int, int, int], list] = {}
    for y, row in enumerate(to_grid(image)):
        for x, p in enumerate(row):
            if p[3] >= 128 and p[:3] not in allowed:
                hit = seen.setdefault(p[:3], [x, y, 0])
                hit[2] += 1
    return [(x, y, n, color.to_hex(palette.nearest(c))) for c, (x, y, n) in seen.items()]


def deflicker(frames: list[Image.Image], threshold: float = 0.05) -> tuple[list[Image.Image], int]:
    """Prende ao quadro anterior as cores que mudaram quase nada.

    E o `drift_threshold` do PixelLab feito as claras: um pixel que no quadro
    seguinte tem uma cor a menos de `threshold` (OKLab) da que tinha herda-a; um
    pixel que mudou de verdade (outra cor, outro material) fica.
    """
    if not frames:
        return [], 0
    out = [frames[0].copy()]
    fixed = 0
    prev = to_grid(frames[0])
    for frame in frames[1:]:
        rows = to_grid(frame)
        for y, row in enumerate(rows):
            if y >= len(prev):
                break
            for x, p in enumerate(row):
                if x >= len(prev[y]):
                    break
                q = prev[y][x]
                if p[3] >= 128 and q[3] >= 128 and p[:3] != q[:3] and color.delta(p[:3], q[:3]) < threshold:
                    row[x] = q
                    fixed += 1
        out.append(from_grid(rows))
        prev = rows
    out, blips = blink(out)
    return out, fixed + blips


def blink(frames: list[Image.Image]) -> tuple[list[Image.Image], int]:
    """Pixel que pisca A -> B -> A com os 8 vizinhos parados: ruido do gerador, volta a A.

    Num movimento verdadeiro os vizinhos mudam com o pixel; num piscar isolado
    nao. So entre quadros consecutivos da mesma tela.
    """
    if len(frames) < 3:
        return frames, 0
    grids = [to_grid(f) for f in frames]
    h, w = len(grids[0]), len(grids[0][0])
    fixed = 0
    for i in range(1, len(grids) - 1):
        a, b, c = grids[i - 1], grids[i], grids[i + 1]
        for y in range(1, h - 1):
            for x in range(1, w - 1):
                if a[y][x] != c[y][x] or b[y][x] == a[y][x] or a[y][x][3] < 128 or b[y][x][3] < 128:
                    continue
                still = sum(a[y + dy][x + dx] == b[y + dy][x + dx]
                            for dy in (-1, 0, 1) for dx in (-1, 0, 1) if dx or dy)
                if still >= 7:
                    b[y][x] = a[y][x]
                    fixed += 1
    return [from_grid(g) for g in grids], fixed
