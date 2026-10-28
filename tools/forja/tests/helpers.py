"""Fixtures comuns: sprites sinteticos, pastas temporarias."""
from __future__ import annotations

import struct
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


def _s15(v: float) -> bytes:
    return struct.pack(">i", round(v * 65536))


def linear_profile(name: str = "Linear RGB (teste)") -> bytes:
    """Um perfil ICC v2 de monitor com os primarios do sRGB e gama 1.0: um perfil que NAO e sRGB, escrito aqui
    para o teste nao depender de ficheiros do sistema. O cinzento 128 nele e o 188 em sRGB."""
    def xyz(x, y, z):
        return b"XYZ \0\0\0\0" + _s15(x) + _s15(y) + _s15(z)
    ascii_name = name.encode("ascii") + b"\0"
    tags = [(b"desc", b"desc\0\0\0\0" + struct.pack(">I", len(ascii_name)) + ascii_name + b"\0" * 79),
            (b"wtpt", xyz(0.9642, 1.0, 0.8249)), (b"rXYZ", xyz(0.4360747, 0.2225045, 0.0139322)),
            (b"gXYZ", xyz(0.3850649, 0.7168786, 0.0971045)), (b"bXYZ", xyz(0.1430804, 0.0606169, 0.7141733)),
            (b"rTRC", b"curv\0\0\0\0" + struct.pack(">I", 0)), (b"gTRC", b"curv\0\0\0\0" + struct.pack(">I", 0)),
            (b"bTRC", b"curv\0\0\0\0" + struct.pack(">I", 0)), (b"cprt", b"text\0\0\0\0CC0\0")]
    offset, table, body = 128 + 4 + 12 * len(tags), b"", b""
    for sig, data in tags:
        data += b"\0" * (-len(data) % 4)
        table += sig + struct.pack(">II", offset + len(body), len(data))
        body += data
    size = 128 + 4 + len(table) + len(body)
    header = (struct.pack(">I", size) + b"\0" * 4 + struct.pack(">I", 0x02100000) + b"mntrRGB XYZ "
              + struct.pack(">6H", 2026, 10, 27, 0, 0, 0) + b"acsp" + b"\0" * 24 + struct.pack(">I", 0)
              + _s15(0.9642) + _s15(1.0) + _s15(0.8249) + b"\0" * 48)
    return header + struct.pack(">I", len(tags)) + table + body
