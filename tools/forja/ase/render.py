"""Renderizar um quadro como o Aseprite o renderiza (FORJA-14), portado de `render/render.cpp` e
`doc/render_plan.cpp` do Aseprite 1.3.18.6 (licenca MIT; o aviso esta no NOTICE.md).

O plano: as camadas pela ordem do ficheiro (o indice), cada cel deslocada pelo seu z-index (NOTE.5), as escondidas
(contando os pais) e as de referencia fora; duas passagens, a camada de fundo e depois as transparentes; a opacidade
e a da cel vezes a da camada; os grupos achatam-se (a omissao `compose_groups` falsa do Aseprite) ou compoem-se a
parte com a mistura e a opacidade deles. `native` da a imagem no modo do sprite, como o export do Aseprite: RGBA,
Grayscale (misturas de cinzento) ou Indexed (copia o indice; a opacidade e a mistura nao contam). Sem `native`, a
pre-visualizacao RGBA de qualquer modo.
"""
from __future__ import annotations

from PIL import Image

from .blend import blend, mul
from .model import BYTES, Sprite


def _pixels(sprite: Sprite, raw: bytes) -> list:
    n = BYTES[sprite.depth]
    return list(raw) if n == 1 else [tuple(raw[i:i + n]) for i in range(0, len(raw), n)]


def _tile(sprite: Sprite, layer, value: int, cel) -> tuple[list, int, int] | None:
    t = cel.tilemap
    ts = sprite.tilesets[layer.tileset or 0]
    index = value & t["id"]
    if index == 0 and ts.flags & 4 or index >= ts.count:
        return None
    w, h, n = ts.tile_w, ts.tile_h, BYTES[sprite.depth]
    px = _pixels(sprite, ts.pixels[index * w * h * n:(index + 1) * w * h * n])
    grid = [px[y * w:(y + 1) * w] for y in range(h)]
    if value & t["dflip"]:
        grid = [list(row) for row in zip(*grid)]
    if value & t["xflip"]:
        grid = [row[::-1] for row in grid]
    if value & t["yflip"]:
        grid = grid[::-1]
    return [p for row in grid for p in row], len(grid[0]), len(grid)


def _images(sprite: Sprite, index: int, frame: int) -> list[tuple[int, int, list, int, int]]:
    """Os blocos (x, y, pixels, largura, altura) de uma cel: a imagem, ou cada peca de um tilemap."""
    cel = sprite.cels.get((index, frame))
    if cel is None:
        return []
    src = sprite.cels[(index, cel.link)] if cel.link is not None else cel
    if src.tilemap is None:
        return [(cel.x, cel.y, _pixels(sprite, src.pixels), src.width, src.height)]
    layer = sprite.layers[index]
    ts = sprite.tilesets[layer.tileset or 0]
    tiles = [int.from_bytes(src.pixels[i:i + 4], "little") for i in range(0, len(src.pixels), 4)]
    out = []
    for i, value in enumerate(tiles):
        found = _tile(sprite, layer, value, src)
        if found:
            out.append((cel.x + i % src.width * ts.tile_w, cel.y + i // src.width * ts.tile_h, *found))
    return out


def _chain(index: int | None, parents: list) -> list[int]:
    out = []
    while index is not None:
        out.append(index)
        index = parents[index]
    return out


def forced(only: set | None, parents: list) -> set:
    """As camadas que o `--layer` da CLI torna visiveis: as escolhidas e os grupos acima delas."""
    return {j for c in only or () for j in _chain(c, parents)}


def _visible(sprite: Sprite, index: int, parents: list, only: set | None) -> bool:
    """Visivel com todos os pais; com `only`, a camada ou um grupo acima dela tem de estar escolhido, e o escolhido
    e os pais dele contam como visiveis (os descendentes escondidos continuam escondidos)."""
    chain, shown = _chain(index, parents), forced(only, parents)
    visible = all(sprite.layers[i].has("visible") or i in shown for i in chain)
    return visible and (only is None or bool(only & set(chain)))


def _draw(sprite: Sprite, canvas: list, frame: int, index: int, opacity: int, mode: str, pal: list) -> None:
    w, h = sprite.width, sprite.height
    layer = sprite.layers[index]
    for x0, y0, px, cw, ch in _images(sprite, index, frame):
        for i, p in enumerate(px):
            x, y = x0 + i % cw, y0 + i // cw
            if not (0 <= x < w and 0 <= y < h):
                continue
            k = y * w + x
            if sprite.depth == 8:
                if p == sprite.transparent or p >= len(pal):
                    continue
                canvas[k] = p if mode == "indexed" else blend(layer.blend, canvas[k], pal[p][:4], opacity)
            elif p != (0,) * len(p):  # a cor de mascara (transparente a zero) nao se desenha
                if mode == "rgba" and sprite.depth == 16:
                    p = (p[0], p[0], p[0], p[1])
                canvas[k] = blend(layer.blend, canvas[k], p, opacity)


def _plan(sprite: Sprite, frame: int, members: list[int], parents: list, only, show_reference: bool) -> list[int]:
    items = []
    for index in members:
        cel = sprite.cels.get((index, frame))
        items.append((index + (cel.z if cel else 0), cel.z if cel else 0, index))
    if any(z for _, z, _ in items):  # o Aseprite so reordena quando ha algum z-index
        items.sort()
    return [i for _, _, i in items if _visible(sprite, i, parents, only)
            and (show_reference or not sprite.layers[i].has("reference"))]


def _layers(sprite, canvas, frame, members, parents, only, mode, pal, compose, show_reference, blank) -> None:
    order = _plan(sprite, frame, members, parents, only, show_reference)
    for background in (True, False):
        for index in order:
            layer = sprite.layers[index]
            if layer.kind == "group":
                if background:
                    continue
                kids = [i for i in range(len(sprite.layers)) if parents[i] == index]
                sub = [blank] * len(canvas)
                _layers(sprite, sub, frame, kids, parents, only, mode, pal, compose, show_reference, blank)
                op = layer.opacity if sprite.flags & 2 else 255
                for k, p in enumerate(sub):
                    if p != blank:
                        canvas[k] = p if mode == "indexed" else blend(layer.blend if sprite.flags & 2 else 0,
                                                                     canvas[k], p, op)
            elif layer.has("background") == background and (index, frame) in sprite.cels:
                cel = sprite.cels[(index, frame)]
                op = mul(cel.opacity, layer.opacity if sprite.flags & 1 else 255)
                _draw(sprite, canvas, frame, index, op, mode, pal)


def _blank(mode: str):
    return {"rgba": (0, 0, 0, 0), "grayscale": (0, 0), "indexed": None}[mode]


def render(sprite: Sprite, frame: int = 0, only: set[int] | None = None, native: bool = False,
           compose_groups: bool = False, show_reference: bool = False) -> Image.Image:
    """O quadro `frame`; `only` restringe as camadas (como o --layer da CLI)."""
    mode = sprite.mode if native else "rgba"
    pal = sprite.palette(frame)
    parents = sprite.parents()
    blank = sprite.transparent if mode == "indexed" else _blank(mode)
    ground = any(layer.has("background") and _visible(sprite, i, parents, only)
                 for i, layer in enumerate(sprite.layers))
    fill = pal[sprite.transparent][:4] if sprite.depth == 8 and mode == "rgba" and ground and pal else blank
    canvas = [fill] * (sprite.width * sprite.height)
    if compose_groups:
        members = [i for i in range(len(sprite.layers)) if parents[i] is None]
    else:
        members = [i for i, layer in enumerate(sprite.layers) if layer.kind != "group"]
    _layers(sprite, canvas, frame, members, parents, only, mode, pal, compose_groups, show_reference, blank)
    if mode == "indexed":  # o PNG do Aseprite: o alfa de cada entrada; sem fundo visivel, o indice transparente a 0
        img = Image.frombytes("P", (sprite.width, sprite.height), bytes(canvas))
        img.putpalette([v for c in pal for v in c[:3]])
        img.info["transparency"] = bytes(0 if i == sprite.transparent and not ground else c[3]
                                         for i, c in enumerate(pal))
        return img
    raw = b"".join(bytes(p) for p in canvas)
    return Image.frombytes("LA" if mode == "grayscale" else "RGBA", (sprite.width, sprite.height), raw)
