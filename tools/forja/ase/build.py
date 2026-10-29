"""Montar um sprite a partir de imagens (FORJA-14): cada cel recortada ao conteudo, como o Aseprite a guarda, e as
cels repetidas na mesma camada ligadas ao primeiro quadro igual (as cels ligadas do Aseprite: a mesma imagem e a
mesma posicao, editadas uma vez). Os modos de cor sao os do formato: RGBA, Grayscale (valor e alfa) e Indexed (o
indice; a paleta e a do sprite, e o indice transparente nunca e uma cor desenhada).
"""
from __future__ import annotations

from PIL import Image

from .model import BYTES, Cel, Layer, Sprite


def raw(img: Image.Image, depth: int, palette: list[tuple] | None = None, transparent: int = 0) -> bytes:
    """Os pixels crus de uma imagem no modo do sprite. Em Indexed, cada cor tem de estar na paleta."""
    if depth == 32:
        return img.convert("RGBA").tobytes()
    if depth == 16:
        return img.convert("LA").tobytes()
    if img.mode == "P":
        return img.tobytes()
    index = {tuple(c[:4]): i for i, c in enumerate(palette or []) if i != transparent}
    out = bytearray()
    for p in img.convert("RGBA").getdata():
        if p[3] == 0:
            out.append(transparent)
        elif p in index:
            out.append(index[p])
        else:
            raise ValueError(f"cor {p} fora da paleta: o modo Indexed nao inventa cores")
    return bytes(out)


def cel(img: Image.Image, depth: int = 32, palette=None, transparent: int = 0, trim: bool = True) -> Cel | None:
    """Uma cel com a imagem recortada ao que nao e transparente (None se a imagem esta vazia)."""
    rgba = img.convert("RGBA")
    box = rgba.getchannel("A").getbbox() if trim else (0, 0, img.width, img.height)
    if box is None:
        return None
    part = img.crop(box)
    return Cel(box[0], box[1], width=part.width, height=part.height, pixels=raw(part, depth, palette, transparent))


def image(sprite: Sprite, c: Cel) -> Image.Image:
    """A imagem RGBA de uma cel (do seu tamanho), para conferir e exportar."""
    if c.link is not None:
        raise ValueError("uma cel ligada le-se pela cel do quadro de origem")
    size = (c.width, c.height)
    if sprite.depth == 32:
        return Image.frombytes("RGBA", size, c.pixels)
    if sprite.depth == 16:
        return Image.frombytes("LA", size, c.pixels).convert("RGBA")
    pal = sprite.palette(0)
    px = [(0, 0, 0, 0) if i == sprite.transparent or i >= len(pal) else pal[i][:4] for i in c.pixels]
    out = Image.new("RGBA", size)
    out.putdata(px)
    return out


def sprite(size: tuple[int, int], layers: list[tuple[str, list[Image.Image | None]]] | list[tuple],
           durations: list[int] | None = None, depth: int = 32, palette: list[tuple] | None = None,
           transparent: int = 0, link: bool = True) -> Sprite:
    """`layers`: (nome, [imagem por quadro]) ou (Layer, [imagens]), de baixo para cima; None e um quadro vazio."""
    frames = max(len(images) for _, images in layers)
    out = Sprite(size[0], size[1], depth, transparent=transparent, durations=list(durations or [100] * frames))
    if palette:
        out.palettes[0] = [tuple(c[:4]) + (c[4] if len(c) > 4 else None,) for c in palette]
    for index, (spec, images) in enumerate(layers):
        out.layers.append(spec if isinstance(spec, Layer) else Layer(spec))
        seen: dict[tuple, int] = {}
        for frame, img in enumerate(images):
            if img is None:
                continue
            c = cel(img, depth, out.palette(0), transparent)
            if c is None:
                continue
            key = (c.x, c.y, c.width, c.height, c.pixels)
            if link and key in seen:
                out.cels[(index, frame)] = Cel(c.x, c.y, link=seen[key])
            else:
                seen.setdefault(key, frame)
                out.cels[(index, frame)] = c
    return out


def bytes_per_pixel(s: Sprite) -> int:
    return BYTES[s.depth]
