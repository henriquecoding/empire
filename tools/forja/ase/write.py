"""Escrever um .aseprite inteiro (FORJA-14), na ordem do `dio/aseprite_encoder.cpp` do Aseprite 1.3.18.6 (MIT;
NOTICE.md).

No primeiro quadro: ficheiros externos, perfil de cor, paleta (a antiga 0x0004 quando cabe: ate 256 cores, todas
opacas e sem nomes; senao a nova 0x2019), dados do sprite, tilesets (com os dados de cada peca), tags (com os dados
de cada tag, sempre), camadas (com os dados) e slices; em cada quadro, a paleta se mudou e as cels pela ordem das
camadas, com a cel extra e os dados da cel. O que se le com `read` e se escreve com `write` volta igual.
"""
from __future__ import annotations

import struct
import zlib
from pathlib import Path

from .binio import FIXED, pack_user, string
from .model import LAYER_KINDS, TILE_DFLIP, TILE_ID, TILE_XFLIP, TILE_YFLIP, Sprite, UserData


def _chunk(kind: int, body: bytes) -> bytes:
    return struct.pack("<IH", len(body) + 6, kind) + body


def _palette(pal: list[tuple], previous: list[tuple] | None) -> bytes:
    first, last = 0, len(pal) - 1
    if previous is not None:  # so o intervalo que mudou, como o Aseprite
        diff = [i for i in range(len(pal)) if i >= len(previous) or pal[i] != previous[i]]
        if not diff and len(pal) == len(previous):
            return b""
        first, last = (min(diff), max(diff)) if diff else (0, len(pal) - 1)
    if len(pal) <= 256 and all(c[3] == 255 and not c[4] for c in pal) and previous is None:
        body = struct.pack("<HBB", 1, 0, len(pal) % 256) + b"".join(struct.pack("<3B", *c[:3]) for c in pal)
        return _chunk(0x0004, body)
    body = struct.pack("<III8x", len(pal), first, last)
    for c in pal[first:last + 1]:
        body += struct.pack("<H4B", 1 if c[4] else 0, *c[:4]) + (string(c[4]) if c[4] else b"")
    return _chunk(0x2019, body)


def _layer(layer, flags: int) -> bytes:
    kind = LAYER_KINDS.index(layer.kind)
    blend_ok = kind != 1 or flags & 2  # sem a bandeira 2 os grupos nao guardam mistura nem opacidade
    body = struct.pack("<6HB3x", layer.flags, kind, layer.level, 0, 0, layer.blend if blend_ok else 0,
                       layer.opacity if blend_ok else 0) + string(layer.name)
    if layer.kind == "tilemap":
        body += struct.pack("<I", layer.tileset or 0)
    if flags & 4:
        body += layer.uuid or bytes(16)
    return _chunk(0x2004, body)


def _cel(index: int, cel) -> bytes:
    head = struct.pack("<HhhBHh5x", index, cel.x, cel.y, cel.opacity,
                       1 if cel.link is not None else 3 if cel.tilemap else 2, cel.z)
    if cel.link is not None:
        return _chunk(0x2005, head + struct.pack("<H", cel.link))
    if cel.tilemap:
        t = cel.tilemap
        head += struct.pack("<HHHIIII10x", cel.width, cel.height, t.get("bits", 32), t.get("id", TILE_ID),
                            t.get("xflip", TILE_XFLIP), t.get("yflip", TILE_YFLIP), t.get("dflip", TILE_DFLIP))
        return _chunk(0x2005, head + zlib.compress(cel.pixels))
    return _chunk(0x2005, head + struct.pack("<HH", cel.width, cel.height) + zlib.compress(cel.pixels))


def _tags(tags) -> bytes:
    body = struct.pack("<H8x", len(tags))
    for t in tags:
        rgb = t.user.color[:3] if t.user.color else (0, 0, 0)  # o encoder escreve a cor da tag no campo antigo
        body += struct.pack("<HHBH6x3Bx", t.first, t.last, t.direction, t.repeat, *rgb) + string(t.name)
    return _chunk(0x2018, body)


def _slice(s) -> bytes:
    flags = (1 if any(k.center for k in s.keys) else 0) | (2 if any(k.pivot for k in s.keys) else 0)
    body = struct.pack("<III", len(s.keys), flags, 0) + string(s.name)
    for k in s.keys:
        body += struct.pack("<IiiII", k.frame, k.x, k.y, k.w, k.h)
        if flags & 1:
            body += struct.pack("<iiII", *(k.center or (0, 0, 0, 0)))
        if flags & 2:
            body += struct.pack("<ii", *(k.pivot or (0, 0)))
    return _chunk(0x2022, body)


def _tileset(ts) -> bytes:
    body = struct.pack("<IIIHHh14x", ts.id, ts.flags, ts.count, ts.tile_w, ts.tile_h, ts.base_index) + string(ts.name)
    if ts.flags & 1:
        body += struct.pack("<II", *ts.external)
    if ts.flags & 2:
        data = zlib.compress(ts.pixels)
        body += struct.pack("<I", len(data)) + data
    return _chunk(0x2023, body)


def _first(sprite: Sprite) -> list[bytes]:
    out = []
    if sprite.external_files:
        body = struct.pack("<I8x", len(sprite.external_files))
        for eid, etype, name in sprite.external_files:
            body += struct.pack("<IB7x", eid, etype) + string(name)
        out.append(_chunk(0x2008, body))
    if sprite.color_profile:
        p = sprite.color_profile
        body = struct.pack("<HHi8x", p["type"], p["flags"], round(p["gamma"] * FIXED))
        out.append(_chunk(0x2007, body + (struct.pack("<I", len(p["icc"])) + p["icc"] if p["type"] == 2 else b"")))
    return out


def _objects(sprite: Sprite, ext_ids: dict[str, int]) -> list[bytes]:
    user = lambda u: _chunk(0x2020, pack_user(u, ext_ids))  # noqa: E731
    out = [user(sprite.user)] if not sprite.user.empty() else []
    for ts in sprite.tilesets:
        out.append(_tileset(ts))
        if (ts.user and not ts.user.empty()) or any(not u.empty() for u in ts.tile_users):
            out += [user(ts.user or UserData())] + [user(u) for u in ts.tile_users]
    if sprite.tags:
        out += [_tags(sprite.tags)] + [user(t.user) for t in sprite.tags]
    for layer in sprite.layers:
        out.append(_layer(layer, sprite.flags))
        out += [user(layer.user)] if not layer.user.empty() else []
    for s in sprite.slices:
        out += [_slice(s)] + ([user(s.user)] if not s.user.empty() else [])
    return out


def _cels(sprite: Sprite, frame: int, ext_ids: dict[str, int]) -> list[bytes]:
    out = []
    for index, layer in enumerate(sprite.layers):
        cel = sprite.cels.get((index, frame))
        if cel is None or layer.kind == "group":
            continue
        out.append(_cel(index, cel))
        if cel.extra:
            f, x, y, w, h = cel.extra
            out.append(_chunk(0x2006, struct.pack("<Iiiii16x", f, *(round(v * FIXED) for v in (x, y, w, h)))))
        if cel.link is None and not cel.user.empty():
            out.append(_chunk(0x2020, pack_user(cel.user, ext_ids)))
    return out


def write(sprite: Sprite, path: str | Path | None = None) -> bytes:
    """O ficheiro em bytes (e escrito em `path`, se dado)."""
    ext_ids = {name: eid for eid, etype, name in sprite.external_files if etype == 2}
    palettes = sprite.palettes or {0: [(0, 0, 0, 255, None)]}  # o Aseprite conta sempre com uma paleta
    frames = []
    for frame in range(sprite.frames):
        chunks = _first(sprite) if frame == 0 else []
        if frame in palettes:
            pal = _palette(palettes[frame], None if frame == 0 else sprite.palette(frame - 1))
            chunks += [pal] if pal else []
        chunks += _objects(sprite, ext_ids) if frame == 0 else []
        chunks += _cels(sprite, frame, ext_ids)
        body = b"".join(chunks)
        frames.append(struct.pack("<IHHH2xI", 16 + len(body), 0xF1FA, min(len(chunks), 0xFFFF),
                                  sprite.durations[frame], len(chunks)) + body)
    data = b"".join(frames)
    pal0 = palettes[min(palettes)]
    header = struct.pack("<IHHHHHIHIIB3xHBBhhHH84x", 128 + len(data), 0xA5E0, sprite.frames, sprite.width,
                         sprite.height, sprite.depth, sprite.flags, sprite.durations[0] if sprite.durations else
                         sprite.speed, 0, 0, sprite.transparent, len(pal0), *sprite.pixel_ratio, *sprite.grid)
    out = header + data
    if path is not None:
        Path(path).parent.mkdir(parents=True, exist_ok=True)
        Path(path).write_bytes(out)
    return out
