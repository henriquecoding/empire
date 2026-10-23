"""Operacoes pequenas de imagem que todos os passos usam."""
from __future__ import annotations

import io

import hashlib
from pathlib import Path

from PIL import Image

NEAREST = Image.Resampling.NEAREST
CLEAR = (0, 0, 0, 0)


def open_rgba(path: str | Path) -> Image.Image:
    with Image.open(path) as im:
        im.seek(0)
        return im.convert("RGBA")


def sha256(path: str | Path) -> str:
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def binarize(image: Image.Image, threshold: int = 128) -> Image.Image:
    """Alfa 0 ou 255, e os pixels vazios zerados: nada de cor escondida no transparente."""
    rgba = image.convert("RGBA")
    alpha = rgba.getchannel("A").point(lambda a: 255 if a >= threshold else 0)
    out = Image.new("RGBA", rgba.size, CLEAR)
    out.paste(rgba.convert("RGB"), (0, 0), alpha)
    out.putalpha(alpha)
    return out


def is_binary_alpha(image: Image.Image) -> bool:
    hist = image.convert("RGBA").getchannel("A").histogram()
    return sum(hist[1:255]) == 0


def opaque_bbox(image: Image.Image) -> tuple[int, int, int, int] | None:
    return image.convert("RGBA").getchannel("A").point(lambda a: 255 if a >= 128 else 0).getbbox()


def upscale(image: Image.Image, factor: int) -> Image.Image:
    if factor <= 1:
        return image.copy()
    return image.resize((image.width * factor, image.height * factor), NEAREST)


def checker(size: tuple[int, int], cell: int = 8, a=(58, 52, 64), b=(74, 68, 82)) -> Image.Image:
    out = Image.new("RGBA", size, (*a, 255))
    for y in range(0, size[1], cell):
        for x in range((y // cell) % 2 * cell, size[0], cell * 2):
            out.paste((*b, 255), (x, y, x + cell, y + cell))
    return out


def on_background(image: Image.Image, bg: tuple[int, int, int] | None = None,
                  cell: int = 8) -> Image.Image:
    base = checker(image.size, cell) if bg is None else Image.new("RGBA", image.size, (*bg, 255))
    base.alpha_composite(image.convert("RGBA"))
    return base


def flat(image: Image.Image) -> list:
    """Os pixels por ordem de linha (getdata sai do Pillow 14)."""
    getter = getattr(image, "get_flattened_data", None) or image.getdata
    return list(getter())


def grid(image: Image.Image) -> list[list[tuple[int, int, int, int]]]:
    """A imagem como linhas de pixels RGBA, para os passos que andam pixel a pixel."""
    rgba = image.convert("RGBA")
    data = flat(rgba)
    w = rgba.width
    return [data[y * w:(y + 1) * w] for y in range(rgba.height)]


def from_grid(rows: list[list[tuple[int, int, int, int]]]) -> Image.Image:
    h = len(rows)
    w = len(rows[0]) if h else 0
    out = Image.new("RGBA", (w, h))
    out.putdata([p for row in rows for p in row])
    return out


def count_colors(image: Image.Image) -> int:
    rgba = image.convert("RGBA")
    found = rgba.getcolors(rgba.width * rgba.height) or []
    return len({p[:3] for _, p in found if p[3] >= 128})


def place(sprite: Image.Image, canvas: tuple[int, int], anchor: tuple[int, int],
          target: tuple[int, int]) -> tuple[Image.Image, int]:
    """Cola `sprite` numa tela vazia com `anchor` (no sprite) sobre `target` (na tela).

    Devolve a tela e quantos pixels opacos ficaram de fora: um corte silencioso e
    o defeito mais caro de descobrir depois.
    """
    out = Image.new("RGBA", canvas, CLEAR)
    dx, dy = target[0] - anchor[0], target[1] - anchor[1]
    out.alpha_composite(sprite, (max(dx, 0), max(dy, 0)),
                        (max(-dx, 0), max(-dy, 0)))
    inside = _opaque_count(out)
    return out, _opaque_count(sprite) - inside


def _opaque_count(image: Image.Image) -> int:
    hist = image.getchannel("A").histogram()
    return sum(hist[128:])


def foot_point(image: Image.Image, rows: int = 3) -> tuple[int, int] | None:
    """O ponto de contacto: a linha opaca mais baixa e o centro das ultimas `rows` linhas.

    E a definicao de pivot da Asset Bible §1 — contacto dos pes com o chao, ao
    centro horizontal do corpo — medida, em vez de adivinhada pela caixa.
    """
    box = opaque_bbox(image)
    if not box:
        return None
    alpha = image.getchannel("A")
    bottom = box[3] - 1
    xs = [x for y in range(max(box[1], bottom - rows + 1), bottom + 1)
          for x in range(box[0], box[2]) if alpha.getpixel((x, y)) >= 128]
    return (round((min(xs) + max(xs)) / 2), bottom) if xs else None


def png_bytes(image: Image.Image) -> bytes:
    buf = io.BytesIO()
    image.save(buf, "PNG")
    return buf.getvalue()
