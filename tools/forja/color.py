"""Cor perceptual: sRGB <-> OKLab, distancias e utilitarios de hex.

Toda decisao de "qual cor e mais parecida" da Forja passa por aqui. OKLab
(Bjorn Ottosson, 2020) mede diferencas perto do que o olho ve; RGB euclidiano
confunde verdes e azuis escuros, que e exatamente onde a pixel art vive.
"""
from __future__ import annotations

import math

_LINEAR = [((c / 255) / 12.92) if c / 255 <= 0.04045 else (((c / 255) + 0.055) / 1.055) ** 2.4
           for c in range(256)]
_LAB_CACHE: dict[tuple[int, int, int], tuple[float, float, float]] = {}

# Rec. 601: o mesmo LUMA do shaders/palette_lut.gdshader, para que "claro" e
# "escuro" signifiquem o mesmo aqui e no jogo.
LUMA = (0.299, 0.587, 0.114)


def to_linear(c: int) -> float:
    return _LINEAR[c]


def to_srgb8(v: float) -> int:
    v = 12.92 * v if v <= 0.0031308 else 1.055 * (max(v, 0.0) ** (1 / 2.4)) - 0.055
    return max(0, min(255, round(v * 255)))


def oklab(rgb: tuple[int, int, int]) -> tuple[float, float, float]:
    key = (rgb[0], rgb[1], rgb[2])
    hit = _LAB_CACHE.get(key)
    if hit is not None:
        return hit
    r, g, b = _LINEAR[key[0]], _LINEAR[key[1]], _LINEAR[key[2]]
    l_ = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ** (1 / 3)
    m_ = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ** (1 / 3)
    s_ = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ** (1 / 3)
    lab = (0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_,
           1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_,
           0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_)
    if len(_LAB_CACHE) < 1 << 20:
        _LAB_CACHE[key] = lab
    return lab


def _linear_rgb(lab: tuple[float, float, float]) -> tuple[float, float, float]:
    big_l, a, b = lab
    l_ = big_l + 0.3963377774 * a + 0.2158037573 * b
    m_ = big_l - 0.1055613458 * a - 0.0638541728 * b
    s_ = big_l - 0.0894841775 * a - 1.2914855480 * b
    l, m, s = l_ ** 3, m_ ** 3, s_ ** 3
    return (4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
            -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
            -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s)


def from_oklab(lab: tuple[float, float, float]) -> tuple[int, int, int]:
    """Prende cada canal a [0, 255]: fora do gamut sRGB isso muda o matiz (ver `from_lch(..., gamut=True)`)."""
    r, g, b = _linear_rgb(lab)
    return to_srgb8(r), to_srgb8(g), to_srgb8(b)


def dist2(p: tuple[float, float, float], q: tuple[float, float, float]) -> float:
    return (p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2 + (p[2] - q[2]) ** 2


def delta(c1: tuple[int, int, int], c2: tuple[int, int, int]) -> float:
    """Diferenca perceptual (OKLab euclidiana). 0.02 mal se ve; 0.1 e outra cor."""
    return math.sqrt(dist2(oklab(c1), oklab(c2)))


def lch(rgb: tuple[int, int, int]) -> tuple[float, float, float]:
    """OKLCh: luminosidade, croma e matiz em graus."""
    big_l, a, b = oklab(rgb)
    return big_l, math.hypot(a, b), math.degrees(math.atan2(b, a)) % 360


def from_lch(big_l: float, c: float, h: float, gamut: bool = False) -> tuple[int, int, int]:
    """`gamut`: fora do sRGB, baixa o croma ate caber, com a luminosidade e o matiz fixos — a "preservar a
    luminosidade" de Ottosson (sRGB gamut clipping, 2021). Prender cada canal desviava o matiz de uma rampa ate
    21 graus (FORJA-08, B15)."""
    rad = math.radians(h)
    lab = (big_l, c * math.cos(rad), c * math.sin(rad))
    if gamut and not _inside(lab):
        lo, hi = 0.0, c
        for _ in range(24):
            mid = (lo + hi) / 2
            lo, hi = (mid, hi) if _inside((big_l, mid * math.cos(rad), mid * math.sin(rad))) else (lo, mid)
        lab = (big_l, lo * math.cos(rad), lo * math.sin(rad))
    return from_oklab(lab)


def _inside(lab: tuple[float, float, float], eps: float = 1e-6) -> bool:
    return all(-eps <= v <= 1 + eps for v in _linear_rgb(lab))


def luma(rgb: tuple[int, int, int]) -> float:
    return (LUMA[0] * rgb[0] + LUMA[1] * rgb[1] + LUMA[2] * rgb[2]) / 255


def parse_hex(text: str) -> tuple[int, int, int]:
    s = text.strip().lstrip("#")
    if len(s) == 3:
        s = "".join(ch * 2 for ch in s)
    if len(s) not in (6, 8) or any(ch not in "0123456789abcdefABCDEF" for ch in s):
        raise ValueError(f"cor invalida: {text!r}")
    return int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16)


def to_hex(rgb: tuple[int, ...]) -> str:
    return "#%02X%02X%02X" % (rgb[0], rgb[1], rgb[2])


def mean_color(colors: list[tuple[int, tuple[int, ...]]]) -> tuple[int, int, int]:
    """Media em luz linear de (contagem, cor); a media em sRGB escurece as misturas."""
    total = sum(n for n, _ in colors) or 1
    acc = [0.0, 0.0, 0.0]
    for n, c in colors:
        for i in range(3):
            acc[i] += _LINEAR[c[i]] * n
    return tuple(to_srgb8(v / total) for v in acc)  # type: ignore[return-value]
