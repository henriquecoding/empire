"""Separar o boneco do fundo, na resolucao nativa.

Um gerador entrega fundo transparente (alfa), fundo de chave (#FF00FF pedido no
prompt) ou fundo liso qualquer. Na resolucao nativa a decisao e barata e limpa:
cada celula ja votou a sua cor, e o fundo e uma cor so.

- alfa: a imagem ja tem transparencia na borda — so se binariza.
- chave: cor muito saturada (magenta, verde, ciano) — sai em TODO o lado, porque
  o prompt garantiu que o boneco nao a usa. Tambem apanha o halo (o "spill").
- liso: enchimento a partir da borda, com tolerancia em OKLab — buracos fechados
  da mesma cor ficam, porque podem ser desenho.
"""
from __future__ import annotations

from collections import Counter, deque

from PIL import Image, ImageChops

from . import color
from .imageops import CLEAR, grid as to_grid, from_grid

KEY_CHROMA = 0.15


def border_pixels(rows: list[list[tuple[int, int, int, int]]]) -> list[tuple[int, int, int, int]]:
    h, w = len(rows), len(rows[0])
    out = rows[0] + rows[-1]
    for y in range(1, h - 1):
        out += [rows[y][0], rows[y][w - 1]]
    return out


def detect(image: Image.Image) -> dict:
    """{'mode': 'alpha'|'key'|'flat'|'none', 'color': hex|None, 'share': fracao da borda}."""
    rows = to_grid(image)
    border = border_pixels(rows)
    clear = sum(1 for p in border if p[3] < 128)
    if clear / len(border) > 0.3:
        return {"mode": "alpha", "color": None, "share": clear / len(border)}
    counts = Counter(p[:3] for p in border if p[3] >= 128)
    top = counts.most_common(1)[0][0]
    share = sum(n for c, n in counts.items() if color.delta(c, top) < 0.06) / len(border)
    if share < 0.5:
        return {"mode": "none", "color": None, "share": share}
    chroma = color.lch(top)[1]
    return {"mode": "key" if chroma >= KEY_CHROMA else "flat", "color": color.to_hex(top), "share": share}


def remove(image: Image.Image, bg: str | tuple[int, int, int] | None = None,
           tolerance: float = 0.09, mode: str | None = None) -> tuple[Image.Image, dict]:
    """A imagem com o fundo transparente, e o que foi decidido. `bg="keep"`: um plano opaco (ceu, terreno) nao tem
    fundo a tirar; so se binariza o alfa (FORJA-09)."""
    if bg == "keep":
        bg, mode = None, "none"
    info = detect(image) if bg is None and mode is None else {"mode": mode or "flat", "share": None}
    if bg is not None:
        rgb = color.parse_hex(bg) if isinstance(bg, str) else tuple(bg)
        info["color"] = color.to_hex(rgb)
        if mode is None:
            info["mode"] = "key" if color.lch(rgb)[1] >= KEY_CHROMA else "flat"
    rows = to_grid(image)
    if info["mode"] in ("alpha", "none") or not info.get("color"):
        return from_grid([[p if p[3] >= 128 else CLEAR for p in row] for row in rows]), info
    key = color.parse_hex(info["color"])
    if info["mode"] == "key":
        removed = _key(rows, key, tolerance)
    else:
        removed = _flood(rows, key, tolerance)
    info["removed"] = removed
    return from_grid(rows), info


def _close(p: tuple[int, int, int, int], key: tuple[int, int, int], tol: float) -> bool:
    return p[3] >= 128 and color.delta(p[:3], key) <= tol


def _key(rows: list[list[tuple[int, int, int, int]]], key: tuple[int, int, int], tol: float) -> int:
    removed = 0
    _, key_chroma, key_hue = color.lch(key)
    for row in rows:
        for x, p in enumerate(row):
            if p[3] < 128:
                row[x] = CLEAR
            elif _close(p, key, tol) or _spill(p, key_chroma, key_hue):
                row[x] = CLEAR
                removed += 1
    return removed


def _spill(p: tuple[int, int, int, int], key_chroma: float, key_hue: float) -> bool:
    """O halo da chave: quase tao saturado como ela e do mesmo matiz."""
    _, chroma, hue = color.lch(p[:3])
    return chroma >= 0.6 * key_chroma and abs((hue - key_hue + 180) % 360 - 180) < 12


KEYS = ("#FF00FF", "#00FF00", "#00FFFF", "#0000FF", "#FF0000", "#FFFF00")


def best_key(colors: list[tuple[int, int, int]]) -> str:
    """A cor de chave mais longe de todas as cores da paleta (para o prompt pedir)."""
    if not colors:
        return KEYS[0]
    return max(KEYS, key=lambda k: min(color.delta(color.parse_hex(k), c) for c in colors))


def _flood(rows: list[list[tuple[int, int, int, int]]], key: tuple[int, int, int], tol: float) -> int:
    h, w = len(rows), len(rows[0])
    seen = [[False] * w for _ in range(h)]
    queue = deque((x, y) for y in range(h) for x in (0, w - 1)) + deque((x, y) for x in range(w) for y in (0, h - 1))
    removed = 0
    while queue:
        x, y = queue.popleft()
        if seen[y][x]:
            continue
        seen[y][x] = True
        p = rows[y][x]
        if p[3] >= 128 and not _close(p, key, tol):
            continue
        if p[3] >= 128:
            removed += 1
        rows[y][x] = CLEAR
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and not seen[ny][nx]:
                queue.append((nx, ny))
    for row in rows:
        for x, p in enumerate(row):
            if p[3] < 128:
                row[x] = CLEAR
    return removed


def mask(image: Image.Image, bg: tuple[int, int, int] | None, tolerance: int = 40) -> Image.Image:
    """Mascara 'L' do que NAO e fundo, na resolucao cheia, pelo canal mais diferente.

    Serve para achar figuras numa folha sem andar pixel a pixel em Python.
    """
    rgba = image.convert("RGBA")
    if bg is None:
        return rgba.getchannel("A").point(lambda a: 255 if a >= 128 else 0)
    solid = Image.new("RGB", rgba.size, bg)
    diff = ImageChops.difference(rgba.convert("RGB"), solid)
    r, g, b = diff.split()
    strongest = ImageChops.lighter(ImageChops.lighter(r, g), b)
    keep = strongest.point(lambda v: 255 if v > tolerance else 0)
    return ImageChops.multiply(keep, rgba.getchannel("A").point(lambda a: 255 if a >= 128 else 0))
