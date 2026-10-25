"""Contornos: pôr, tirar e medir.

Empire (Asset Bible §1): preto puro #000000; 1 px em personagens, 2 px na
silhueta do cenario e dos edificios, nenhum no parallax distante. O contorno
global engrossa uma corda de 1 px para 3 e fecha um vazio de 2 px (sonda do
relatorio de 24-25/10): `keep` sao os pixels onde ele nao entra — linhas finas
e vazios declarados, uma excecao que fica escrita no relatorio. O "sel-out"
(contorno seletivo, a cor escura do proprio material em vez do preto) e a opcao
"selective outline" do PixelLab; fica disponivel para estudos, nao e o contrato.
"""
from __future__ import annotations

from collections import Counter

from PIL import Image

from . import color
from .cleanup import N4, N8
from .imageops import CLEAR, grid as to_grid, from_grid
from .palette import Palette

MODES = ("outer", "inner", "selective")


def _inside(rows, x: int, y: int) -> bool:
    return 0 <= y < len(rows) and 0 <= x < len(rows[0]) and rows[y][x][3] >= 128


def edge_pixels(rows, offsets=N4) -> list[tuple[int, int]]:
    """Pixels opacos que tocam o vazio (ou a borda da tela)."""
    out = []
    for y, row in enumerate(rows):
        for x, p in enumerate(row):
            if p[3] >= 128 and any(not _inside(rows, x + dx, y + dy) for dx, dy in offsets):
                out.append((x, y))
    return out


def add(image: Image.Image, rgb: tuple[int, int, int] = (0, 0, 0), width: int = 1,
        mode: str = "outer", corners: bool = True, palette: Palette | None = None,
        keep=None) -> Image.Image:
    if mode not in MODES:
        raise ValueError(f"modo de contorno desconhecido: {mode}")
    rows = to_grid(image)
    offsets = N8 if corners else N4
    keep = keep or frozenset()
    for _ in range(max(1, width)):
        src = [row[:] for row in rows]
        if mode == "inner":
            for x, y in edge_pixels(src, offsets):
                if (x, y) not in keep:
                    rows[y][x] = (*rgb, 255)
            continue
        for y, row in enumerate(src):
            for x, p in enumerate(row):
                if p[3] >= 128 or (x, y) in keep:
                    continue
                solid = [src[y + dy][x + dx] for dx, dy in offsets if _inside(src, x + dx, y + dy)]
                if not solid:
                    continue
                if mode == "selective":
                    base = Counter(q[:3] for q in solid).most_common(1)[0][0]
                    rows[y][x] = (*darken(base, palette), 255)
                else:
                    rows[y][x] = (*rgb, 255)
    return from_grid(rows)


def darken(rgb: tuple[int, int, int], palette: Palette | None = None, amount: float = 0.45) -> tuple[int, int, int]:
    """A sombra do material: mais escura, um pouco mais fria; na paleta, se houver."""
    big_l, c, h = color.lch(rgb)
    shade = color.from_lch(max(0.04, big_l * (1 - amount)), c * 0.8, (h - 12) % 360)
    if palette is None or not len(palette):
        return shade
    darker = [p for p in palette.colors if color.oklab(p)[0] < big_l - 0.05]
    pool = Palette(darker) if darker else palette
    return pool.nearest(shade)


def strip(image: Image.Image, rgb: tuple[int, int, int] | None = None) -> tuple[Image.Image, tuple[int, int, int] | None]:
    """Tira o anel exterior do contorno. Sem cor dada, usa a mais comum na borda."""
    rows = to_grid(image)
    edges = edge_pixels(rows)
    if not edges:
        return image.copy(), None
    if rgb is None:
        rgb = Counter(rows[y][x][:3] for x, y in edges).most_common(1)[0][0]
    for x, y in edges:
        if rows[y][x][:3] == rgb:
            rows[y][x] = CLEAR
    return from_grid(rows), rgb


def measure(image: Image.Image, rgb: tuple[int, int, int] = (0, 0, 0), skip=None) -> dict:
    """Quanto da borda e contorno, e com que espessura (aneis consecutivos da cor). `skip`: bordas isentas."""
    rows = to_grid(image)
    edges = [e for e in edge_pixels(rows) if not skip or e not in skip]
    if not edges:
        return {"edge_pixels": 0, "outline_share": 0.0, "thickness": 0, "color": color.to_hex(rgb)}
    share = sum(rows[y][x][:3] == rgb for x, y in edges) / len(edges)
    thickness, work = 0, [row[:] for row in rows]
    while thickness < 4:
        ring = edge_pixels(work)
        if not ring or sum(work[y][x][:3] == rgb for x, y in ring) / len(ring) < 0.6:
            break
        thickness += 1
        for x, y in ring:
            work[y][x] = CLEAR
    return {"edge_pixels": len(edges), "outline_share": round(share, 3), "thickness": thickness,
            "color": color.to_hex(rgb)}


def interior_lines(image: Image.Image, rgb: tuple[int, int, int] = (0, 0, 0)) -> int:
    """Pixels da cor do contorno que nao tocam o vazio: o detalhe interno desenhado a traco."""
    rows = to_grid(image)
    edge = set(edge_pixels(rows, N8))
    return sum(1 for y, row in enumerate(rows) for x, p in enumerate(row)
               if p[3] >= 128 and p[:3] == rgb and (x, y) not in edge)


def normalize(image: Image.Image, rgb: tuple[int, int, int] = (0, 0, 0), darkest: float = 0.2) -> tuple[Image.Image, int]:
    """Os pixels da borda quase pretos passam a ser o preto do contrato.

    O gerador desenha o contorno em #141414, #1E1A22...; quantizado na paleta,
    cairia em #0B0B0B ou #0F1110 em vez de #000000. Isto decide antes.
    """
    rows = to_grid(image)
    changed = 0
    for x, y in edge_pixels(rows, N8):
        p = rows[y][x]
        if p[:3] != rgb and color.oklab(p[:3])[0] < darkest:
            rows[y][x] = (*rgb, 255)
            changed += 1
    return from_grid(rows), changed
