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
from .palette import Palette, extract, histogram

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
    """`strength` e a amplitude da matriz em volta de 0.5: 1 e o padrao classico, 0 e a cor mais perto (sem
    dither). Antes, zero empurrava todos os pixels para o meio e pintava meio xadrez (relatorio de 25/10, §7)."""
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
            limit = 0.5 + (matrix[y % len(matrix)][x % len(matrix)] - 0.5) * max(0.0, strength)
            row[x] = (*palette.colors[j if t > limit else i], 255)
    return from_grid(rows)


def reduce(image: Image.Image, count: int, dither: str = "none") -> tuple[Image.Image, Palette]:
    pal = extract(image, count)
    return to_palette(image, pal, dither), pal


def subset(image: Image.Image, palette: Palette, k: int, required=()) -> Palette:
    """`k` cores da paleta para esta imagem: as obrigatorias primeiro, depois as que o k-means aponta.

    Fica sempre dentro da paleta dada (relatorio de 25/10, §8): o orcamento escolhe entre as cores
    autorizadas, nao inventa outras."""
    mapped = to_palette(image, palette)
    used = [c for _, c in histogram(mapped)]
    chosen = list(dict.fromkeys(c for c in required if c in palette))
    if len(set(used) | set(chosen)) <= k:
        return Palette(list(dict.fromkeys(chosen + used)), palette.name)
    for center in extract(mapped, k).colors:
        if len(chosen) >= k:
            break
        free = [c for c in used if c not in chosen]
        if free:
            chosen.append(min(free, key=lambda c: color.delta(c, center)))
    chosen += [c for c in used if c not in chosen][:max(0, k - len(chosen))]
    return Palette(chosen[:k], palette.name)


def apply(image: Image.Image, palette: Palette | None, count: int | None, dither: str = "none",
          required=()) -> tuple[Image.Image, dict | None]:
    """A paleta e o orcamento de cores juntos, sem que um cale o outro.

    Com paleta e `count`, sai um subconjunto da paleta; sem paleta, `count` cores extraidas. `required` (as
    cores protegidas e a do contorno do contrato) entram sempre; se nao cabem no orcamento, ele nao se aplica
    e o conflito fica escrito."""
    if palette is None and not count:
        return image, None
    report = {"name": palette.name, "size": len(palette)} if palette is not None else {"name": "extraida"}
    if not count:
        return to_palette(image, palette, dither), report
    need = list(dict.fromkeys(c for c in required if palette is None or c in palette))
    budget = {"requested": count, "applied": False, "required": [color.to_hex(c) for c in need]}
    report["budget"] = budget
    if len(need) > count:
        budget["conflict"] = (f"o orcamento de {count} cores e menor que as {len(need)} cores obrigatorias "
                              "(protegidas e contorno): nao se aplica")
        return (to_palette(image, palette, dither) if palette is not None else image), report
    if palette is not None:
        chosen = subset(image, palette, count, need)
    else:
        rest = extract(image, count - len(need)).colors if count > len(need) else []
        chosen = Palette(list(dict.fromkeys(need + rest)), "extraida")
    budget.update(applied=True, chosen=chosen.hexes())
    if palette is None:
        report["colors"] = chosen.hexes()
    return to_palette(image, chosen, dither), report


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


def deflicker(frames: list[Image.Image], threshold: float = 0.05, static=None,
              actions=None) -> tuple[list[Image.Image], int]:
    """Prende ao quadro anterior as cores que mudaram quase nada, so nas regioes estaticas (temporal.py).

    Nao e o `drift_threshold` do PixelLab (ver temporal.py). Sem `static`, so diagnostica: nada muda."""
    from . import temporal
    out, report = temporal.stabilize(frames, threshold, static, actions)
    return out, len(report["changed"])


def blink(frames: list[Image.Image], static=None, actions=None) -> tuple[list[Image.Image], int]:
    """Um pixel A -> B -> A volta a A so numa regiao estatica e sem movimento; um piscar declarado fica."""
    from . import temporal
    out, report = temporal.stabilize(frames, 0.0, static, actions)
    return out, len(report["changed"])
