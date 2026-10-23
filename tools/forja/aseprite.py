"""Escrever um .aseprite RGBA: camadas, quadros com duracao, tags, paleta e slices.

Segue a especificacao publica do formato (aseprite/docs/ase-file-specs.md). O
leitor do projeto, tools/aseprite_source.py, le o que isto escreve — e o
teste de ida e volta. Abrir no aplicativo Aseprite e outra verificacao, que
este ambiente nao tem: o guia de personagens (§6) pede que se registe a
diferenca entre "conferido como ficheiro" e "aberto no aplicativo".
"""
from __future__ import annotations

import importlib.util
import struct
import zlib
from pathlib import Path

from PIL import Image

DIRECTIONS = {"forward": 0, "reverse": 1, "pingpong": 2, "pingpong_reverse": 3}


def _string(text: str) -> bytes:
    raw = text.encode("utf-8")
    return struct.pack("<H", len(raw)) + raw


def _chunk(kind: int, data: bytes) -> bytes:
    return struct.pack("<IH", len(data) + 6, kind) + data


def _palette(colors: list[tuple[int, int, int]]) -> bytes:
    body = struct.pack("<III8x", len(colors), 0, max(0, len(colors) - 1))
    for r, g, b in colors:
        body += struct.pack("<H4B", 0, r, g, b, 255)
    return _chunk(0x2019, body)


def _layer(name: str) -> bytes:
    return _chunk(0x2004, struct.pack("<6HB3x", 3, 0, 0, 0, 0, 0, 255) + _string(name))


def _cel(index: int, image: Image.Image) -> bytes | None:
    rgba = image.convert("RGBA")
    box = rgba.getchannel("A").getbbox()
    if not box:
        return None
    part = rgba.crop(box)
    head = struct.pack("<HhhBHh5x", index, box[0], box[1], 255, 2, 0)
    return _chunk(0x2005, head + struct.pack("<HH", part.width, part.height)
                  + zlib.compress(part.tobytes(), 9))


def _tags(tags: list[tuple[str, int, int, str]]) -> bytes:
    body = struct.pack("<H8x", len(tags))
    for name, first, last, direction in tags:
        body += struct.pack("<HHBH6x3Bx", first, last, DIRECTIONS.get(direction, 0), 0, 0, 0, 0)
        body += _string(name)
    return _chunk(0x2018, body)


def _slice(name: str, box: tuple[int, int, int, int], pivot: tuple[int, int] | None) -> bytes:
    flags = 2 if pivot else 0
    body = struct.pack("<III", 1, flags, 0) + _string(name)
    body += struct.pack("<IiiII", 0, box[0], box[1], box[2], box[3])
    if pivot:
        body += struct.pack("<ii", pivot[0] - box[0], pivot[1] - box[1])
    return _chunk(0x2022, body)


def write(path: str | Path, size: tuple[int, int], layers: list[str],
          frames: list[dict[int, Image.Image]], durations: list[int] | None = None,
          tags: list[tuple[str, int, int, str]] | None = None,
          palette: list[tuple[int, int, int]] | None = None,
          slices: list[tuple[str, tuple[int, int, int, int], tuple[int, int] | None]] | None = None,
          grid: tuple[int, int] = (0, 0)) -> Path:
    """`frames[i]` mapeia indice de camada -> imagem do tamanho da tela."""
    durations = durations or [100] * len(frames)
    blobs = []
    for i, cels in enumerate(frames):
        chunks = []
        if i == 0:
            chunks.append(_chunk(0x2007, struct.pack("<HHI8x", 1, 0, 0)))
            if palette:
                chunks.append(_palette(palette))
            chunks += [_layer(name) for name in layers]
            if tags:
                chunks.append(_tags(tags))
            for name, box, pivot in slices or []:
                chunks.append(_slice(name, box, pivot))
        for index in sorted(cels):
            cel = _cel(index, cels[index])
            if cel:
                chunks.append(cel)
        body = b"".join(chunks)
        blobs.append(struct.pack("<IHHH2xI", 16 + len(body), 0xF1FA, min(len(chunks), 0xFFFF),
                                 durations[i], len(chunks)) + body)
    frames_bytes = b"".join(blobs)
    header = struct.pack("<IHHHHHIHII B3x HBBhhHH84x", 128 + len(frames_bytes), 0xA5E0, len(frames),
                         size[0], size[1], 32, 1, 100, 0, 0, 0, len(palette or []), 1, 1,
                         0, 0, grid[0], grid[1])
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(header + frames_bytes)
    return path


def from_frames(path: str | Path, frames: list[Image.Image], layer: str = "body",
                durations: list[int] | None = None, tags=None, palette=None, pivot=None) -> Path:
    """O caso comum: uma camada, um quadro por imagem; o pivot vira um slice."""
    size = frames[0].size
    slices = [("pivot", (0, 0, size[0], size[1]), pivot)] if pivot else None
    return write(path, size, [layer], [{0: f} for f in frames], durations, tags, palette, slices)


def reader():
    """O leitor do projeto (tools/aseprite_source.py), carregado pelo caminho."""
    source = Path(__file__).resolve().parents[1] / "aseprite_source.py"
    spec = importlib.util.spec_from_file_location("aseprite_source", source)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def verify(path: str | Path, frames: list[Image.Image]) -> dict:
    """Le o ficheiro com o leitor do projeto e compara pixel a pixel com os quadros."""
    src = reader().read(path)
    equal = all(reader().composite(src, i, range(len(src["layers"]))).tobytes()
                == frames[i].convert("RGBA").tobytes() for i in range(len(frames)))
    return {"frames": len(src["frames"]), "layers": [layer["name"] for layer in src["layers"]],
            "tags": src["tags"], "durations": src["durations"], "pixel_equal": equal,
            "opened_in_aseprite_app": False}
