"""Fixtures comuns: sprites sinteticos, pastas temporarias."""
from __future__ import annotations

import tempfile
from pathlib import Path

from PIL import Image

from tools.forja import synth


def sprite(seed: int = 7, size: tuple[int, int] = (24, 32)) -> Image.Image:
    return synth.sprite(seed, size)


def framed(seed: int = 7, canvas: tuple[int, int] = (64, 64), pivot: tuple[int, int] = (32, 56)) -> Image.Image:
    s = synth.sprite(seed, (24, 34))
    box = s.getchannel("A").getbbox()
    s = s.crop(box)
    out = Image.new("RGBA", canvas)
    out.alpha_composite(s, (pivot[0] - s.width // 2, pivot[1] - s.height + 1))
    return out


def tempdir() -> Path:
    return Path(tempfile.mkdtemp(prefix="forja-test-"))
