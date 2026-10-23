"""Limpeza na resolucao nativa: pixels soltos, ruido de cor, aglomerados pequenos
e cantos dobrados nos tracos de 1 px.

A Asset Bible distingue: no cenario um pixel solto e proibido (cluster minimo
2x2); num personagem um pixel isolado pode ser o olho. Por isso o ruido de cor
so se corrige quando o pixel e QUASE da cor dos vizinhos (ruido do gerador),
nunca quando contrasta (intencao).
"""
from __future__ import annotations

from collections import Counter

from PIL import Image

from . import color
from .imageops import CLEAR, grid as to_grid, from_grid

N8 = ((-1, -1), (0, -1), (1, -1), (-1, 0), (1, 0), (-1, 1), (0, 1), (1, 1))
N4 = ((0, -1), (-1, 0), (1, 0), (0, 1))


def _neighbors(rows, x: int, y: int, offsets=N8):
    h, w = len(rows), len(rows[0])
    for dx, dy in offsets:
        nx, ny = x + dx, y + dy
        if 0 <= nx < w and 0 <= ny < h:
            yield rows[ny][nx]


def despeckle(image: Image.Image, noise: float = 0.08, holes: bool = True,
              orphans: bool = True) -> tuple[Image.Image, dict]:
    """Tira pixels opacos sem vizinhos opacos, tapa furos de 1 px e alisa o ruido de cor."""
    rows = to_grid(image)
    src = [row[:] for row in rows]
    stats = {"orphans": 0, "holes": 0, "noise": 0}
    for y, row in enumerate(src):
        for x, p in enumerate(row):
            around = list(_neighbors(src, x, y))
            solid = [q for q in around if q[3] >= 128]
            if p[3] >= 128 and not solid and orphans:
                rows[y][x] = CLEAR
                stats["orphans"] += 1
            elif p[3] < 128 and holes and len(around) == 8 and len(solid) == 8:
                rows[y][x] = Counter(solid).most_common(1)[0][0]
                stats["holes"] += 1
            elif p[3] >= 128 and solid:
                top, n = Counter(q[:3] for q in solid).most_common(1)[0]
                if p[:3] != top and n >= 5 and p[:3] not in {q[:3] for q in solid} \
                        and color.delta(p[:3], top) < noise:
                    rows[y][x] = (*top, 255)
                    stats["noise"] += 1
    return from_grid(rows), stats


def components(rows, key=lambda p: p[:3] if p[3] >= 128 else None, offsets=N4):
    """Componentes ligados de pixels com a mesma chave: [(chave, [(x, y), ...])]."""
    h, w = len(rows), len(rows[0])
    seen = [[False] * w for _ in range(h)]
    out = []
    for y in range(h):
        for x in range(w):
            k = key(rows[y][x])
            if seen[y][x] or k is None:
                continue
            stack, members = [(x, y)], []
            seen[y][x] = True
            while stack:
                cx, cy = stack.pop()
                members.append((cx, cy))
                for dx, dy in offsets:
                    nx, ny = cx + dx, cy + dy
                    if 0 <= nx < w and 0 <= ny < h and not seen[ny][nx] and key(rows[ny][nx]) == k:
                        seen[ny][nx] = True
                        stack.append((nx, ny))
            out.append((k, members))
    return out


def min_cluster(image: Image.Image, size: int = 2) -> tuple[Image.Image, int]:
    """Funde na cor vizinha mais comum cada mancha de cor com menos de size x size pixels."""
    rows = to_grid(image)
    merged = 0
    for _ in range(3):
        changed = 0
        for k, members in components(rows):
            if len(members) >= size * size:
                continue
            spots = set(members)
            around = Counter(rows[ny][nx][:3] for x, y in members for nx, ny in
                             ((x + dx, y + dy) for dx, dy in N4)
                             if 0 <= nx < len(rows[0]) and 0 <= ny < len(rows)
                             and (nx, ny) not in spots and rows[ny][nx][3] >= 128)
            if not around:
                continue
            fill = around.most_common(1)[0][0]
            for x, y in members:
                rows[y][x] = (*fill, 255)
            changed += len(members)
        merged += changed
        if not changed:
            break
    return from_grid(rows), merged


def small_islands(image: Image.Image, size: int = 2) -> list[tuple[int, int, int]]:
    """Manchas de cor menores que size x size: (x, y, pixels) do primeiro pixel de cada uma."""
    rows = to_grid(image)
    return [(m[0][0], m[0][1], len(m)) for _, m in components(rows) if len(m) < size * size]


def pixel_perfect(image: Image.Image, line: tuple[int, int, int] = (0, 0, 0)) -> tuple[Image.Image, int]:
    """Tira os cantos em L dos tracos de 1 px da cor `line` (o "pixel perfect" do Aseprite).

    Um pixel do traco sai quando tem um vizinho do traco na horizontal e outro na
    vertical (que se tocam na diagonal) e os restantes vizinhos do traco tocam um
    desses dois: o traco continua ligado pela diagonal e perde o degrau duplo.
    """
    rows = to_grid(image)
    h, w = len(rows), len(rows[0])
    removed = 0

    def is_line(x: int, y: int) -> bool:
        return 0 <= x < w and 0 <= y < h and rows[y][x][3] >= 128 and rows[y][x][:3] == line

    for y in range(h):
        for x in range(w):
            if not is_line(x, y):
                continue
            hor = [dx for dx in (-1, 1) if is_line(x + dx, y)]
            ver = [dy for dy in (-1, 1) if is_line(x, y + dy)]
            if len(hor) != 1 or len(ver) != 1 or is_line(x + hor[0], y + ver[0]):
                continue
            a, c = (x + hor[0], y), (x, y + ver[0])
            others = [(x + dx, y + dy) for dx, dy in N8 if is_line(x + dx, y + dy)
                      and (x + dx, y + dy) not in (a, c)]
            if all(any(max(abs(o[0] - q[0]), abs(o[1] - q[1])) <= 1 for q in (a, c)) for o in others):
                rows[y][x] = _fill_from(rows, x, y, line)
                removed += 1
    return from_grid(rows), removed


def _fill_from(rows, x: int, y: int, line: tuple[int, int, int]):
    near = list(_neighbors(rows, x, y, N4))
    if len(near) < 4 or any(q[3] < 128 for q in near):
        return CLEAR
    around = [q for q in near if q[:3] != line]
    return Counter(around).most_common(1)[0][0] if around else CLEAR


def binarize_rows(rows, threshold: int = 128):
    return [[p if p[3] >= threshold else CLEAR for p in row] for row in rows]
