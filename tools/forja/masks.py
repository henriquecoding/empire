"""Regioes de pixels: o que a Forja edita, protege e mede (FORJA-03).

Uma regiao e um conjunto de (x, y) em pixels nativos. Sai de um seletor escrito por quem observa
(caixa com ou sem cores, lista de pixels, mascara PNG) e e o mesmo objeto para o reparo, o contorno
e a geometria. Uma regiao nao sabe o que e: chamar-lhe corda ou lamina e da observacao.

As mascaras para geradores seguem a convencao de cada um: na OpenAI o alfa 0 marca o que se edita;
no inpaint-v3 do PixelLab o branco gera e o preto preserva (documentacao lida a 24/10/2026).
"""
from __future__ import annotations

import hashlib
from pathlib import Path

from PIL import Image

from . import color
from .imageops import png_bytes

Region = frozenset
N8 = ((-1, -1), (0, -1), (1, -1), (-1, 0), (1, 0), (-1, 1), (0, 1), (1, 1))
N4 = ((0, -1), (-1, 0), (1, 0), (0, 1))
CONVENTIONS = ("openai", "pixellab")


def box(b, size: tuple[int, int] | None = None) -> Region:
    x0, y0, x1, y1 = b
    if size:
        x0, y0, x1, y1 = max(0, x0), max(0, y0), min(size[0], x1), min(size[1], y1)
    return frozenset((x, y) for y in range(y0, y1) for x in range(x0, x1))


def select(image: Image.Image, spec: dict, base: Path | None = None) -> Region:
    """Um seletor de observacao: {"pixels": [[x, y]...]}, {"mask": "f.png"} ou {"box": [...], "colors": [...]}.

    Com caixa, so contam os pixels opacos; com cores, so os dessas cores. "exclude" tira outro seletor."""
    img = image.convert("RGBA")
    px = img.load()
    if "pixels" in spec:
        out = frozenset((int(x), int(y)) for x, y in spec["pixels"])
    elif "mask" in spec:
        path = Path(spec["mask"]) if base is None else base / spec["mask"]
        with Image.open(path) as im:
            marked = marks(im)
        out = frozenset((x, y) for y in range(marked.height) for x in range(marked.width) if marked.getpixel((x, y)))
    elif "box" in spec:
        wanted = {color.parse_hex(c) for c in spec.get("colors") or []}
        out = frozenset(p for p in box(spec["box"], img.size)
                        if px[p][3] >= 128 and (not wanted or px[p][:3] in wanted))
    else:
        raise ValueError(f"seletor sem pixels, mask nem box: {sorted(spec)}")
    if "exclude" in spec:
        out = out - select(img, spec["exclude"], base)
    bad = [p for p in out if not (0 <= p[0] < img.width and 0 <= p[1] < img.height)]
    if bad:
        raise ValueError(f"seletor fora da imagem {img.size}: {sorted(bad)[:4]}")
    return out


def marks(mask: Image.Image) -> Image.Image:
    """O que uma mascara PNG marca, como 'L' (0 ou 255): o alfa, se ela tem transparencia; senao o claro.

    Uma mascara branca sobre preto sem canal alfa (a convencao do PixelLab, e a de quase todos os editores)
    era lida pelo alfa, todo opaco, e marcava a imagem inteira (auditoria de 26/10, A07)."""
    rgba = mask.convert("RGBA")
    alpha = rgba.getchannel("A")
    if alpha.getextrema()[0] < 255:
        return alpha.point(lambda a: 255 if a else 0)
    return rgba.convert("L").point(lambda v: 255 if v >= 128 else 0)


def dilate(region, n: int = 1, size: tuple[int, int] | None = None) -> Region:
    out = set(region)
    for _ in range(n):
        out |= {(x + dx, y + dy) for x, y in out for dx, dy in N8}
    if size:
        out = {(x, y) for x, y in out if 0 <= x < size[0] and 0 <= y < size[1]}
    return frozenset(out)


def bbox(region) -> list[int] | None:
    if not region:
        return None
    xs, ys = [p[0] for p in region], [p[1] for p in region]
    return [min(xs), min(ys), max(xs) + 1, max(ys) + 1]


def components(region, through=frozenset()) -> list[Region]:
    """Pecas ligadas (8 vizinhos) da regiao. Pixels de `through` (um oclusor) ligam pecas mas nao contam:
    uma corda tapada a meio pela mao continua a ser uma corda."""
    todo, out = set(region) | set(through), []
    region = set(region)
    while todo & region:
        start = next(iter(todo & region))
        todo.discard(start)
        group, stack = {start}, [start]
        while stack:
            x, y = stack.pop()
            for dx, dy in N8:
                q = (x + dx, y + dy)
                if q in todo:
                    todo.discard(q)
                    group.add(q)
                    stack.append(q)
        out.append(frozenset(group & region))
    return sorted(out, key=lambda g: (-len(g), min(g)))


def distance(a, b) -> int | None:
    """A menor distancia de Chebyshev entre duas regioes (1 = encostadas, 0 = sobrepostas)."""
    if not a or not b:
        return None
    small, big = (a, b) if len(a) <= len(b) else (b, a)
    return min(max(abs(x - u), abs(y - v)) for x, y in small for u, v in big)


def to_png(size: tuple[int, int], region, convention: str, k: int = 1) -> bytes:
    """A mascara da regiao para um gerador, ampliada k vezes."""
    if convention not in CONVENTIONS:
        raise ValueError(f"convencao de mascara desconhecida: {convention} (use {', '.join(CONVENTIONS)})")
    if convention == "openai":
        img = Image.new("RGBA", size, (0, 0, 0, 255))
        for p in region:
            img.putpixel(p, (0, 0, 0, 0))
    else:
        img = Image.new("L", size, 0)
        for p in region:
            img.putpixel(p, 255)
    return png_bytes(img.resize((size[0] * k, size[1] * k), Image.Resampling.NEAREST) if k > 1 else img)


def from_png(image: Image.Image, convention: str, k: int = 1) -> Region:
    """A regiao editavel lida de volta de uma mascara na convencao dada (o centro de cada celula k x k)."""
    if convention not in CONVENTIONS:
        raise ValueError(f"convencao de mascara desconhecida: {convention}")
    rgba = image.convert("RGBA")
    out = set()
    for y in range(rgba.height // k):
        for x in range(rgba.width // k):
            r, g, b, a = rgba.getpixel((x * k + k // 2, y * k + k // 2))
            if (a < 128) if convention == "openai" else (r + g + b) / 3 >= 128:
                out.add((x, y))
    return frozenset(out)


def changed(a: Image.Image, b: Image.Image, inside=None) -> list[tuple[int, int]]:
    """Pixels RGBA diferentes entre duas imagens do mesmo tamanho, fora de `inside` se dado."""
    if a.size != b.size:
        raise ValueError(f"tamanhos diferentes: {a.size} e {b.size}")
    pa, pb = a.convert("RGBA").load(), b.convert("RGBA").load()
    skip = inside or ()
    return [(x, y) for y in range(a.height) for x in range(a.width)
            if (x, y) not in skip and pa[x, y] != pb[x, y]]


def digest(image: Image.Image, region) -> str:
    """Hash dos pixels RGBA de uma regiao, por ordem: prova de que uma zona protegida nao mudou."""
    px = image.convert("RGBA").load()
    h = hashlib.sha256()
    for x, y in sorted(region):
        h.update(bytes((x & 255, x >> 8, y & 255, y >> 8, *px[x, y])))
    return h.hexdigest()
