"""Escalas de pixel art: Scale2x (EPX), RotSprite e reducao por voto.

Rodar pixel art com vizinho-mais-proximo parte os tracos. O RotSprite amplia
8x com Scale2x (que preserva diagonais), roda nessa escala e volta a 1x por
voto da cor dominante em cada bloco 8x8: a arma rodada 30 graus continua a
parecer desenhada a mao. A rotacao e uma ferramenta de trabalho — o resultado
pede revisao (fluxo do Aseprite, §3).
"""
from __future__ import annotations

from PIL import Image

from .grid import known
from .imageops import CLEAR, flat
from .resample import resample


def scale2x(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    w, h = rgba.size
    src = flat(rgba)
    out = [CLEAR] * (4 * w * h)
    for y in range(h):
        for x in range(w):
            p = src[y * w + x]
            a = src[(y - 1) * w + x] if y > 0 else p
            b = src[y * w + x + 1] if x < w - 1 else p
            c = src[y * w + x - 1] if x > 0 else p
            d = src[(y + 1) * w + x] if y < h - 1 else p
            e0 = a if c == a and c != d and a != b else p
            e1 = b if a == b and a != c and b != d else p
            e2 = c if d == c and d != b and c != a else p
            e3 = d if b == d and b != a and d != c else p
            i = (2 * y) * (2 * w) + 2 * x
            out[i], out[i + 1] = e0, e1
            out[i + 2 * w], out[i + 2 * w + 1] = e2, e3
    big = Image.new("RGBA", (2 * w, 2 * h))
    big.putdata(out)
    return big


def rotsprite(image: Image.Image, degrees: float, expand: bool = True) -> Image.Image:
    """Roda `degrees` (sentido anti-horario, como o Pillow) sem partir os tracos."""
    big = image.convert("RGBA")
    for _ in range(3):
        big = scale2x(big)
    turned = big.rotate(degrees, resample=Image.Resampling.NEAREST, expand=expand, fillcolor=CLEAR)
    w, h = turned.size
    pad_w, pad_h = (-w) % 8, (-h) % 8
    if pad_w or pad_h:
        canvas = Image.new("RGBA", (w + pad_w, h + pad_h), CLEAR)
        canvas.paste(turned, (pad_w // 2, pad_h // 2))
        turned = canvas
    small = resample(turned, known(turned.size, 8), "dominant", inset=0.0).image
    box = small.getchannel("A").getbbox()
    return small.crop(box) if box and expand else small


def downscale(image: Image.Image, factor: int) -> Image.Image:
    """Reducao inteira pela cor exata mais frequente de cada bloco (nunca a media, que inventa cores; o voto
    dominante fazia a media de cores parecidas — auditoria de 26/10)."""
    return resample(image, known(image.size, factor), "mode", inset=0.0).image
