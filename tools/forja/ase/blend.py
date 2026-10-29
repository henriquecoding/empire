"""Os modos de mistura do Aseprite, pixel a pixel, na mesma aritmetica inteira (FORJA-13).

Portado de `src/doc/blend_funcs.cpp` do Aseprite 1.3.18.6 (Copyright (c) 2019-2025 Igara Studio S.A., Copyright
(c) 2001-2017 David Capello; licenca MIT, como as macros MUL_UN8/DIV_UN8 do pixman que ele usa; o aviso esta no
NOTICE.md). A mistura «nova» (`newBlend`, a omissao do Aseprite) envolve cada modo em `_n`: sobre um fundo opaco, o
modo; sobre o transparente, o normal; e a transicao pela alfa do fundo. Uma cor e um tuplo (r, g, b, a) ou, em
Grayscale, (v, a), de 0 a 255.
Em Grayscale o Aseprite mistura os modos HSL como normal e — tal como esta no `get_graya_blender` dele — a adicao
com a mistura nova como exclusao; a Forja reproduz o mesmo, para o export bater pixel a pixel.
"""
from __future__ import annotations

import math

MODES = ("normal", "multiply", "screen", "overlay", "darken", "lighten", "color_dodge", "color_burn", "hard_light",
         "soft_light", "difference", "exclusion", "hue", "saturation", "color", "luminosity", "addition", "subtract",
         "divide")


def mul(a: int, b: int) -> int:
    """MUL_UN8: a*b/255 com o arredondamento do pixman (a pode ser negativo, como no C)."""
    t = a * b + 0x80
    return ((t >> 8) + t) >> 8


def div(a: int, b: int) -> int:
    """DIV_UN8: a*255/b arredondado."""
    return (a * 255 + b // 2) // b


def _tdiv(a: int, b: int) -> int:
    """Divisao inteira do C (trunca para zero)."""
    q = abs(a) // abs(b)
    return q if (a >= 0) == (b >= 0) else -q


def normal(b: tuple, s: tuple, opacity: int) -> tuple:
    if not b[-1]:
        return (*s[:-1], mul(s[-1], opacity))
    if not s[-1]:
        return b
    sa = mul(s[-1], opacity)
    ra = sa + b[-1] - mul(b[-1], sa)
    return (*(b[i] + _tdiv((s[i] - b[i]) * sa, ra) for i in range(len(b) - 1)), ra)


def merge(b: tuple, s: tuple, opacity: int) -> tuple:
    n = len(b) - 1
    if b[-1] == 0:
        c = s[:n]
    elif s[-1] == 0:
        c = b[:n]
    else:
        c = tuple(b[i] + mul(s[i] - b[i], opacity) for i in range(n))
    ra = b[-1] + mul(s[-1] - b[-1], opacity)
    return (0,) * (n + 1) if ra == 0 else (*c, ra)


def _hard_light(b: int, s: int) -> int:
    return mul(b, s << 1) if s < 128 else b + ((s << 1) - 255) - mul(b, (s << 1) - 255)


def _dodge(b: int, s: int) -> int:
    if b == 0:
        return 0
    s = 255 - s
    return 255 if b >= s else div(b, s)


def _burn(b: int, s: int) -> int:
    if b == 255:
        return 255
    b = 255 - b
    return 0 if b >= s else 255 - div(b, s)


def _soft(b: int, s: int) -> int:
    fb, fs = b / 255.0, s / 255.0
    d = ((16 * fb - 12) * fb + 4) * fb if fb <= 0.25 else math.sqrt(fb)
    r = fb - (1.0 - 2.0 * fs) * fb * (1.0 - fb) if fs <= 0.5 else fb + (2.0 * fs - 1.0) * (d - fb)
    return int(r * 255 + 0.5)


CHANNEL = {
    "multiply": mul,
    "screen": lambda b, s: b + s - mul(b, s),
    "overlay": lambda b, s: _hard_light(s, b),
    "darken": min,
    "lighten": max,
    "color_dodge": _dodge,
    "color_burn": _burn,
    "hard_light": _hard_light,
    "soft_light": _soft,
    "difference": lambda b, s: abs(b - s),
    "exclusion": lambda b, s: b + s - 2 * mul(b, s),
    "addition": lambda b, s: min(b + s, 255),
    "subtract": lambda b, s: max(b - s, 0),
    "divide": lambda b, s: 0 if b == 0 else 255 if b >= s else div(b, s),
}


def _lum(r: float, g: float, b: float) -> float:
    return 0.3 * r + 0.59 * g + 0.11 * b


def _clip(c: list[float]) -> list[float]:
    lum, n, x = _lum(*c), min(c), max(c)
    if n < 0:
        c = [lum + ((v - lum) * lum) / (lum - n) for v in c]
    if x > 1:
        c = [lum + ((v - lum) * (1 - lum)) / (x - lum) for v in c]
    return c


def _set_lum(c: list[float], lum: float) -> list[float]:
    d = lum - _lum(*c)
    return _clip([v + d for v in c])


def _set_sat(c: list[float], sat: float) -> list[float]:
    lo, rng = min(c), max(c) - min(c)
    return [((v - lo) * sat) / rng for v in c] if rng > 0.0 else [0.0, 0.0, 0.0]


def _hsl(mode: str, b: tuple, s: tuple) -> tuple:
    fb, fs = [v / 255.0 for v in b[:3]], [v / 255.0 for v in s[:3]]
    if mode == "hue":
        out = _set_lum(_set_sat(fs, max(fb) - min(fb)), _lum(*fb))
    elif mode == "saturation":
        out = _set_lum(_set_sat(fb, max(fs) - min(fs)), _lum(*fb))
    elif mode == "color":
        out = _set_lum(fs, _lum(*fb))
    else:  # luminosity
        out = _set_lum(fb, _lum(*fs))
    return tuple(int(255.0 * v) for v in out)


def _mode(mode: str, b: tuple, s: tuple, opacity: int) -> tuple:
    """O modo sem o envelope `_n` (o `rgba_blender_<modo>` ou `graya_blender_<modo>` do Aseprite)."""
    if mode in CHANNEL:
        f = CHANNEL[mode]
        c = tuple(f(b[i], s[i]) for i in range(len(b) - 1))
    else:
        c = _hsl(mode, b, s)
    return normal(b, (*c, s[-1]), opacity)


def blend(mode: str | int, b: tuple, s: tuple, opacity: int) -> tuple:
    """Um pixel da fonte `s` sobre o fundo `b`, com a opacidade 0-255 e a mistura nova do Aseprite."""
    mode = MODES[mode] if isinstance(mode, int) else mode
    if len(b) == 2:  # Grayscale: o get_graya_blender do Aseprite
        mode = "normal" if mode in ("hue", "saturation", "color", "luminosity") else \
            "exclusion" if mode == "addition" else mode
    if mode == "normal" or not b[-1]:
        return normal(b, s, opacity)
    plain = normal(b, s, opacity)
    mixed = _mode(mode, b, s, opacity)
    through = merge(plain, mixed, b[-1])
    return merge(through, mixed, mul(b[-1], mul(s[-1], opacity)))
