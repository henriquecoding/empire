"""Tiles: conferir emendas e gerar um conjunto Wang de 16 por cantos.

Codificacao dos cantos igual a do PixelLab (`corner/4`): indice =
NW<<3 | NE<<2 | SW<<1 | SE, e um bit a 1 quer dizer "terreno de cima" (upper).
Os 16 tiles cobrem todas as combinacoes; e tambem o conjunto da "dual grid".

A fronteira e um campo bilinear dos quatro cantos mais ruido periodico com o
periodo do tile: na aresta partilhada o campo so depende dos dois cantos dessa
aresta, e o ruido repete-se de tile para tile — por isso quaisquer dois tiles
com os mesmos cantos na aresta encaixam. Fora do tile o campo prolonga a aresta
(coordenadas presas a [0, 1]); e o que deixa o "rebordo" (relva por cima, sombra
por baixo) continuar certo atraves da emenda.
"""
from __future__ import annotations

import hashlib
import math

from PIL import Image

from .imageops import CLEAR, flat

CORNERS = ("NW", "NE", "SW", "SE")


def corners(index: int) -> dict[str, int]:
    return {"NW": index >> 3 & 1, "NE": index >> 2 & 1, "SW": index >> 1 & 1, "SE": index & 1}


def _lattice(i: int, j: int, period: int, seed: int) -> float:
    key = f"{i % period}:{j % period}:{seed}".encode()
    return int.from_bytes(hashlib.blake2s(key, digest_size=2).digest(), "little") / 65535 - 0.5


def noise(x: float, y: float, size: int, cells: int, seed: int) -> float:
    """Ruido de valor periodico (periodo `size` px), em [-0.5, 0.5]."""
    fx, fy = x / size * cells, y / size * cells
    i, j = math.floor(fx), math.floor(fy)
    tx, ty = fx - i, fy - j
    sx, sy = tx * tx * (3 - 2 * tx), ty * ty * (3 - 2 * ty)
    a, b = _lattice(i, j, cells, seed), _lattice(i + 1, j, cells, seed)
    c, d = _lattice(i, j + 1, cells, seed), _lattice(i + 1, j + 1, cells, seed)
    return (a + (b - a) * sx) * (1 - sy) + (c + (d - c) * sx) * sy


def field(index: int, x: float, y: float, size: int, rag: float, seed: int, cells: int = 4) -> bool:
    """O pixel (x, y) do tile `index` e do terreno de cima?"""
    c = corners(index)
    u = min(1.0, max(0.0, (x + 0.5) / size))
    v = min(1.0, max(0.0, (y + 0.5) / size))
    f = (c["NW"] * (1 - u) * (1 - v) + c["NE"] * u * (1 - v)
         + c["SW"] * (1 - u) * v + c["SE"] * u * v)
    return f + rag * noise(x, y, size, cells, seed) > 0.5


def mask(index: int, size: int, rag: float = 0.35, seed: int = 0, cluster: int = 1,
         pad: int = 0) -> list[list[bool]]:
    """A mascara do terreno de cima, com `pad` pixels de prolongamento a toda a volta."""
    step = max(1, cluster)
    return [[field(index, (x // step) * step + step / 2 - 0.5, (y // step) * step + step / 2 - 0.5,
                   size, rag, seed)
             for x in range(-pad, size + pad)] for y in range(-pad, size + pad)]


def _texel(texture: Image.Image | None, x: int, y: int):
    if texture is None:
        return CLEAR
    return texture.getpixel((x % texture.width, y % texture.height))


def tile(index: int, size: int, lower: Image.Image | None, upper: Image.Image | None,
         rim: Image.Image | None = None, rim_width: int = 0, rim_side: str = "top",
         rag: float = 0.35, seed: int = 0, cluster: int = 1) -> Image.Image:
    """Um tile: textura de baixo, de cima, e o rebordo do terreno de cima junto a fronteira."""
    pad = max(1, rim_width)
    m = mask(index, size, rag, seed, cluster, pad)
    out = Image.new("RGBA", (size, size), CLEAR)
    px = out.load()
    for y in range(size):
        for x in range(size):
            up = m[y + pad][x + pad]
            value = _texel(upper if up else lower, x, y)
            if up and rim is not None and rim_width:
                if rim_side == "top":
                    near = any(not m[y + pad - k][x + pad] for k in range(1, rim_width + 1))
                else:
                    near = any(not m[y + pad + dy][x + pad + dx]
                               for dy in range(-rim_width, rim_width + 1)
                               for dx in range(-rim_width, rim_width + 1))
                if near:
                    value = _texel(rim, x, y)
            px[x, y] = value
    return out


def wang16(size: int, lower: Image.Image | None, upper: Image.Image | None, **kw) -> tuple[Image.Image, list[dict]]:
    """A folha 4x4 (indice = linha*4 + coluna) e os metadados de cada tile."""
    sheet = Image.new("RGBA", (size * 4, size * 4), CLEAR)
    meta = []
    for index in range(16):
        x, y = (index % 4) * size, (index // 4) * size
        sheet.paste(tile(index, size, lower, upper, **kw), (x, y))
        meta.append({"index": index, "bounding_box": {"x": x, "y": y, "width": size, "height": size},
                     "corners": {k: "upper" if v else "lower" for k, v in corners(index).items()}})
    return sheet, meta


def demo_map(sheet: Image.Image, size: int, cols: int = 12, rows: int = 8, seed: int = 1) -> Image.Image:
    """Um mapa de exemplo: cantos sorteados (de forma fixa) e o tile certo em cada celula."""
    grid = [[_lattice(i, j, 1 << 16, seed) > -0.1 for i in range(cols + 1)] for j in range(rows + 1)]
    out = Image.new("RGBA", (cols * size, rows * size), CLEAR)
    for j in range(rows):
        for i in range(cols):
            index = grid[j][i] << 3 | grid[j][i + 1] << 2 | grid[j + 1][i] << 1 | grid[j + 1][i + 1]
            x, y = (index % 4) * size, (index // 4) * size
            out.paste(sheet.crop((x, y, x + size, y + size)), (i * size, j * size))
    return out


def seams(image: Image.Image) -> dict:
    """A textura repete sem emenda? Diferenca media das bordas opostas contra o interior."""
    rgba = image.convert("RGBA")
    w, h = rgba.size

    def col(x):
        return flat(rgba.crop((x, 0, x + 1, h)))

    def row(y):
        return flat(rgba.crop((0, y, w, y + 1)))

    def gap(a, b):
        return sum(sum(abs(p[i] - q[i]) for i in range(4)) for p, q in zip(a, b)) / max(1, len(a)) / 4

    wrap_x, wrap_y = gap(col(w - 1), col(0)), gap(row(h - 1), row(0))
    inner_x = sum(gap(col(x), col(x + 1)) for x in range(w - 1)) / max(1, w - 1)
    inner_y = sum(gap(row(y), row(y + 1)) for y in range(h - 1)) / max(1, h - 1)
    return {"wrap_x": round(wrap_x, 2), "wrap_y": round(wrap_y, 2), "inner_x": round(inner_x, 2),
            "inner_y": round(inner_y, 2),
            "seamless": wrap_x <= 1.5 * inner_x + 1 and wrap_y <= 1.5 * inner_y + 1}


def repeat(image: Image.Image, nx: int = 3, ny: int = 3) -> Image.Image:
    out = Image.new("RGBA", (image.width * nx, image.height * ny), CLEAR)
    for j in range(ny):
        for i in range(nx):
            out.paste(image, (i * image.width, j * image.height))
    return out
