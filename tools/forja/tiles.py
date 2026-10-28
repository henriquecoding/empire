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


EDGES = {"horizontal": ("right", "left", lambda a, b: (a["NE"], a["SE"]) == (b["NW"], b["SW"])),
         "vertical": ("bottom", "top", lambda a, b: (a["SW"], a["SE"]) == (b["NW"], b["NE"]))}


def _edge(sheet: Image.Image, index: int, size: int, side: str, cls) -> list[int]:
    x0, y0 = (index % 4) * size, (index // 4) * size
    pts = {"right": [(x0 + size - 1, y0 + i) for i in range(size)], "left": [(x0, y0 + i) for i in range(size)],
           "bottom": [(x0 + i, y0 + size - 1) for i in range(size)], "top": [(x0 + i, y0) for i in range(size)]}
    return [cls(sheet.getpixel(p)) for p in pts[side]]


def _cuts(profile: list[int]) -> list[int]:
    return [i for i in range(1, len(profile)) if profile[i] != profile[i - 1]]


def pairs(sheet: Image.Image, size: int, cls=None, tol: int = 2) -> dict:
    """Os 64 pares horizontais e os 64 verticais que a codificacao por cantos deixa juntar, cada um conferido pela
    topologia da emenda (FORJA-09): as duas arestas tem o mesmo numero de mudancas de terreno, nas mesmas alturas
    (ate `tol` px), e a mesma classe onde nao muda. `cls(pixel)` da 1 ao terreno de cima; por omissao, o opaco (a
    plataforma lateral). A heuristica do `seams` (contraste medio) nao prova isto."""
    sheet = sheet.convert("RGBA")
    cls = cls or (lambda p: int(p[3] >= 128))
    out: dict = {}
    for axis, (side_a, side_b, match) in EDGES.items():
        bad, n = [], 0
        for a in range(16):
            for b in range(16):
                if not match(corners(a), corners(b)):
                    continue
                n += 1
                pa, pb = _edge(sheet, a, size, side_a, cls), _edge(sheet, b, size, side_b, cls)
                ca, cb = _cuts(pa), _cuts(pb)
                if len(ca) != len(cb) or any(abs(x - y) > tol for x, y in zip(ca, cb)) or pa[0] != pb[0]:
                    bad.append({"a": a, "b": b, "cuts": [ca, cb]})
        out[axis] = {"pairs": n, "bad_count": len(bad), "bad": bad[:16]}
    out["ok"] = not (out["horizontal"]["bad_count"] or out["vertical"]["bad_count"])
    return out


def upper_class(*textures: Image.Image | None):
    """A classe do terreno de cima pelas cores das texturas dele (a de cima e o rebordo)."""
    colors = {p[:3] for t in textures if t is not None for p in flat(t.convert("RGBA")) if p[3] >= 128}
    return lambda p: int(p[3] >= 128 and p[:3] in colors)


def _crop(sheet: Image.Image, index: int, size: int) -> Image.Image:
    x, y = (index % 4) * size, (index // 4) * size
    return sheet.crop((x, y, x + size, y + size))


def _broken(img: Image.Image, cluster: int, seam_x: int | None, seam_y: int | None, border: bool) -> list[list]:
    """Manchas de cor menores que cluster x cluster que atravessam as emendas dadas (e, com `border`, que nao tocam a
    borda da janela: essas continuam fora dela)."""
    from .cleanup import components
    from .imageops import grid as to_grid
    w, h = img.size
    out = []
    for _, m in components(to_grid(img)):
        xs, ys = {x for x, _ in m}, {y for _, y in m}
        across = (seam_x is None or {seam_x - 1, seam_x} <= xs) and (seam_y is None or {seam_y - 1, seam_y} <= ys)
        cut = border and (min(xs) == 0 or min(ys) == 0 or max(xs) == w - 1 or max(ys) == h - 1)
        if len(m) < cluster * cluster and across and not cut:
            out.append([min(xs), min(ys), len(m)])
    return out


def junctions(sheet: Image.Image, size: int, cluster: int = 2) -> dict:
    """Os cachos partidos pelas emendas (FORJA-09; relatorio B, V2): nos 128 pares compativeis, uma mancha menor do que
    o cacho que atravessa a emenda; nos 512 blocos 2x2 (a grelha 3x3 de cantos), uma que atravessa o cruzamento."""
    sheet = sheet.convert("RGBA")
    tiles_ = [_crop(sheet, i, size) for i in range(16)]
    seam: list[dict] = []
    for axis, (_, _, match) in EDGES.items():
        for a in range(16):
            for b in range(16):
                if not match(corners(a), corners(b)):
                    continue
                pair = Image.new("RGBA", (size * 2, size) if axis == "horizontal" else (size, size * 2))
                pair.paste(tiles_[a], (0, 0))
                pair.paste(tiles_[b], (size, 0) if axis == "horizontal" else (0, size))
                found = _broken(pair, cluster, size if axis == "horizontal" else None,
                                None if axis == "horizontal" else size, False)
                seam += [{"axis": axis, "a": a, "b": b, "at": f} for f in found]
    corner: list[dict] = []
    r = 2 * cluster
    for code in range(512):
        bit = [code >> k & 1 for k in range(9)]
        quad = [bit[0] << 3 | bit[1] << 2 | bit[3] << 1 | bit[4], bit[1] << 3 | bit[2] << 2 | bit[4] << 1 | bit[5],
                bit[3] << 3 | bit[4] << 2 | bit[6] << 1 | bit[7], bit[4] << 3 | bit[5] << 2 | bit[7] << 1 | bit[8]]
        block = Image.new("RGBA", (2 * r, 2 * r))
        for i, t in enumerate(quad):
            part = tiles_[t].crop((size - r, size - r, size, size) if i == 0 else (0, size - r, r, size) if i == 1
                                  else (size - r, 0, size, r) if i == 2 else (0, 0, r, r))
            block.paste(part, ((i % 2) * r, (i // 2) * r))
        corner += [{"tiles": quad, "at": f} for f in _broken(block, cluster, r, r, True)]
    return {"pairs_checked": 128, "seam_islands": len(seam), "seam": seam[:16], "blocks_checked": 512,
            "corner_islands": len(corner), "corner": corner[:16], "ok": not seam and not corner}
