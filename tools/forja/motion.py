"""Ajudas deterministicas de animacao: travar a cabeca, respirar, piscar, dissolver.

Nenhuma destas substitui desenhar uma pose: a Animation Bible proibe squash e
stretch na cabeca e no rosto, e o fluxo do Aseprite lembra que transladar um
componente e uma ferramenta de trabalho. O `lock` e o "fixed head" do PixelLab
feito localmente: o rosto aceite e colado em cada quadro onde melhor encaixa,
para que a identidade nao derive de quadro para quadro.
"""
from __future__ import annotations

from PIL import Image

from .imageops import CLEAR, flat
from .quantize import bayer


def _mismatch(template: Image.Image, frame: Image.Image, at: tuple[int, int]) -> float:
    w, h = template.size
    window = frame.crop((at[0], at[1], at[0] + w, at[1] + h))
    t, f = flat(template), flat(window)
    solid = [(p, q) for p, q in zip(t, f) if p[3] >= 128]
    if not solid:
        return 1.0
    return sum(1 for p, q in solid if q[3] < 128 or p[:3] != q[:3]) / len(solid)


def lock(frames: list[Image.Image], box: tuple[int, int, int, int], ref: int = 0, search: int = 3,
         max_mismatch: float = 0.65, keep=frozenset()) -> tuple[list[Image.Image], list[dict]]:
    """Cola a regiao `box` do quadro `ref` em cada quadro, no deslocamento que melhor encaixa."""
    if not frames or not 0 <= ref < len(frames) or len({f.size for f in frames}) != 1 or search < 0 or not (
            0 <= box[0] < box[2] <= frames[ref].width and 0 <= box[1] < box[3] <= frames[ref].height):
        raise ValueError("lock: quadros, regiao e pesquisa invalidos")
    template = frames[ref].crop(box)
    out, report = [], []
    for i, frame in enumerate(frames):
        if i == ref:
            out.append(frame.copy())
            report.append({"frame": i, "offset": [0, 0], "before": 0.0, "locked": False})
            continue
        best = min(((dx, dy) for dy in range(-search, search + 1) for dx in range(-search, search + 1)),
                   key=lambda d: (_mismatch(template, frame, (box[0] + d[0], box[1] + d[1])),
                                  abs(d[0]) + abs(d[1])))
        at = (box[0] + best[0], box[1] + best[1])
        before = _mismatch(template, frame, at)
        result = frame.copy()
        window = frame.crop((*at, at[0] + template.width, at[1] + template.height))
        same_shape = window.getchannel("A").tobytes() == template.getchannel("A").tobytes()
        inside = 0 <= at[0] <= frame.width - template.width and 0 <= at[1] <= frame.height - template.height
        locked = inside and same_shape and before <= max_mismatch
        if locked:
            result.paste(template, at)
            for x, y in keep:
                if 0 <= x < frame.width and 0 <= y < frame.height:
                    result.putpixel((x, y), frame.getpixel((x, y)))
        out.append(result)
        report.append({"frame": i, "offset": list(best), "before": round(before, 3),
                       "locked": locked, "reason": "matching silhouette" if locked else
                       "silhouette changed or occluded: review the pose" if not same_shape else
                       "outside canvas" if not inside else "mismatch above limit"})
    return out, report


def shift_above(frame: Image.Image, split_y: int, dy: int) -> Image.Image:
    """Desloca tudo acima de `split_y` por `dy` pixels; os pes ficam no chao."""
    if dy == 0:
        return frame.copy()
    w, h = frame.size
    top = frame.crop((0, 0, w, split_y))
    out = frame.copy()
    out.paste(CLEAR, (0, 0, w, split_y))
    out.alpha_composite(top, (0, max(0, dy)), (0, max(0, -dy)))
    if dy > 0:
        out.alpha_composite(frame.crop((0, split_y, w, h)), (0, split_y))
    return out


def breathe(frame: Image.Image, split_y: int, pattern: tuple[int, ...] = (0, 0, -1, -1, -1, 0)) -> list[Image.Image]:
    """Um idle de respiracao: o tronco e a cabeca sobem um pixel, inteiros, sem deformar.

    O padrao por omissao tem 6 quadros, a contagem do `idle` do dossie (§22).
    """
    return [shift_above(frame, split_y, dy) for dy in pattern]


def flash(frame: Image.Image, rgb: tuple[int, int, int] = (255, 255, 255)) -> Image.Image:
    """A silhueta cheia de uma cor (o golpe recebido; no jogo e o shader flash_white)."""
    solid = Image.new("RGBA", frame.size, (*rgb, 255))
    return Image.composite(solid, Image.new("RGBA", frame.size, CLEAR),
                           frame.getchannel("A").point(lambda a: 255 if a >= 128 else 0))


def dissolve(frame: Image.Image, steps: int = 6, size: int = 4) -> list[Image.Image]:
    """Quadros que perdem pixels pela matriz de Bayer: a dissolucao em dither de 2 px do §60."""
    matrix = bayer(size)
    w, h = frame.size
    out = []
    for k in range(steps + 1):
        level = k / steps
        img = frame.copy()
        px = img.load()
        for y in range(h):
            for x in range(w):
                if matrix[(y // 2) % size][(x // 2) % size] < level:
                    px[x, y] = CLEAR
        out.append(img)
    return out


def knockback(frame: Image.Image, dx: int = -3) -> Image.Image:
    """O empurrao de 3 px do §24, so visual."""
    out = Image.new("RGBA", frame.size, CLEAR)
    out.alpha_composite(frame, (max(0, dx), 0), (max(0, -dx), 0))
    return out
