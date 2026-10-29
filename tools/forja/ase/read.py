"""Ler um .aseprite inteiro (FORJA-13), como o `dio/aseprite_decoder.cpp` do Aseprite 1.3.18.6 o le (MIT; NOTICE.md).

Cada chunk da especificacao: camadas (normal, grupo, tilemap; com UUID), cels (crua, ligada, comprimida, tilemap),
cel extra, perfil de cor, ficheiros externos, tags (direcao, repeticao), paletas nova e antigas, dados de utilizador
com propriedades, slices (9-patch e pivo por chave) e tilesets. Os dados de utilizador vao para o ultimo objeto lido;
depois das tags, um por tag; depois de um tileset, o do tileset e um por peca; antes de tudo, o do sprite. A mascara
(0x2016, obsoleta) e o caminho (0x2017, nunca usado) ignoram-se, como no Aseprite.
"""
from __future__ import annotations

import zlib
from pathlib import Path

from .binio import FIXED, Reader, read_user
from .model import (BYTES, LAYER_KINDS, Cel, Layer, Slice, SliceKey, Sprite, Tag, Tileset, UserData)


def _palette(sprite: Sprite, frame: int, entries: dict[int, tuple], size: int | None = None) -> None:
    prev = list(sprite.palette(frame))
    size = max(size or 0, len(prev), max(entries, default=-1) + 1)
    pal = [prev[i] if i < len(prev) else (0, 0, 0, 255, None) for i in range(size)]
    for i, c in entries.items():
        pal[i] = c
    sprite.palettes[frame] = pal[:size]


def _old_palette(r: Reader, six_bits: bool) -> dict[int, tuple]:
    out, index = {}, 0
    for _ in range(r.take("<H")):
        index += r.take("<B")
        count = r.take("<B") or 256
        for _ in range(count):
            rgb = r.take("<3B")
            if six_bits:
                rgb = tuple((v << 2) | (v >> 4) for v in rgb)
            out[index] = (*rgb, 255, None)
            index += 1
    return out


def _layer(r: Reader, sprite: Sprite) -> Layer:
    flags, kind, level, _, _, blend = r.take("<6H")
    opacity = r.take("<B")
    r.raw(3)
    name = r.string()
    tileset = r.take("<I") if kind == 2 else None
    uuid = r.raw(16) if sprite.flags & 4 else None
    return Layer(name, LAYER_KINDS[kind], level, flags, blend, opacity, tileset, uuid)


def _cel(r: Reader, sprite: Sprite, end: int) -> tuple[int, Cel]:
    index, x, y, opacity, kind, z = r.take("<HhhBHh")
    r.raw(5)
    cel = Cel(x, y, opacity, z)
    if kind == 1:
        cel.link = r.take("<H")
    elif kind in (0, 2):
        cel.width, cel.height = r.take("<HH")
        rest = r.raw(end - r.pos)
        cel.pixels = rest[:cel.width * cel.height * BYTES[sprite.depth]] if kind == 0 else zlib.decompress(rest)
    elif kind == 3:
        cel.width, cel.height, bits = r.take("<HHH")
        tile_id, xflip, yflip, dflip = r.take("<4I")
        r.raw(10)
        cel.tilemap = {"bits": bits, "id": tile_id, "xflip": xflip, "yflip": yflip, "dflip": dflip}
        cel.pixels = zlib.decompress(r.raw(end - r.pos))
    else:
        raise ValueError(f"tipo de cel desconhecido: {kind}")
    return index, cel


def _tags(r: Reader) -> list[Tag]:
    n = r.take("<H")
    r.raw(8)
    out = []
    for _ in range(n):
        first, last, direction, repeat = r.take("<HHBH")
        r.raw(6)
        rgb = r.take("<3B")
        r.raw(1)
        # A cor RGB do chunk vale opaca ate um chunk de dados a substituir inteira (o decoder do Aseprite)
        out.append(Tag(r.string(), first, last, direction, repeat, UserData(color=(*rgb, 255))))
    return out


def _slice(r: Reader) -> Slice:
    count, flags, _ = r.take("<III")
    s = Slice(r.string(), [])
    for _ in range(count):
        frame, x, y, w, h = r.take("<IiiII")
        center = r.take("<iiII") if flags & 1 else None
        pivot = r.take("<ii") if flags & 2 else None
        s.keys.append(SliceKey(frame, x, y, w, h, center, pivot))
    return s


def _tileset(r: Reader) -> Tileset:
    tid, flags, count, tw, th, base = r.take("<IIIHHh")
    r.raw(14)
    ts = Tileset(tid, r.string(), tw, th, count, flags, base)
    if flags & 1:
        ts.external = r.take("<II")
    if flags & 2:
        ts.pixels = zlib.decompress(r.raw(r.take("<I")))
    return ts


def _profile(r: Reader) -> dict:
    kind, flags, gamma = r.take("<HHi")
    r.raw(8)
    return {"type": kind, "flags": flags, "gamma": gamma / FIXED, "icc": r.raw(r.take("<I")) if kind == 2 else b""}


def read(source: str | Path | bytes) -> Sprite:
    data = source if isinstance(source, bytes) else Path(source).read_bytes()
    r = Reader(data)
    _, magic, frames, width, height, depth, flags, speed = r.take("<IHHHHHIH")
    if magic != 0xA5E0:
        raise ValueError("nao e um ficheiro .aseprite (numero magico)")
    r.take("<II")
    transparent = r.take("<B")
    r.raw(3)
    _, pw, ph, gx, gy, gw, gh = r.take("<HBBhhHH")
    sprite = Sprite(width, height, depth, flags, speed, transparent, (pw, ph), (gx, gy, gw, gh), color_profile=None)
    ext: dict[int, str] = {}
    pos, new_palette = 128, False
    target, tag_queue, tile_queue = sprite, [], None
    for frame in range(frames):
        size, fmagic, old, duration = Reader(data, pos).take("<IHHH")
        if fmagic != 0xF1FA:
            raise ValueError(f"quadro {frame}: numero magico errado")
        count = Reader(data, pos + 12).take("<I") or old
        sprite.durations.append(duration or speed)
        cur = pos + 16
        for _ in range(count):
            csize, kind = Reader(data, cur).take("<IH")
            end, c = cur + csize, Reader(data, cur + 6)
            if kind in (0x0004, 0x0011) and not new_palette:
                _palette(sprite, frame, _old_palette(c, kind == 0x0011))
            elif kind == 0x2019:
                psize, first, last = c.take("<III")
                c.raw(8)
                entries = {}
                for i in range(first, last + 1):
                    eflags, *rgba = c.take("<H4B")
                    entries[i] = (*rgba, c.string() if eflags & 1 else None)
                _palette(sprite, frame, entries, psize)
                new_palette = True
            elif kind == 0x2004:
                sprite.layers.append(_layer(c, sprite))
                target, tag_queue, tile_queue = sprite.layers[-1], [], None
            elif kind == 0x2005:
                index, cel = _cel(c, sprite, end)
                sprite.cels[(index, frame)] = cel
                target, tag_queue, tile_queue = cel, [], None
            elif kind == 0x2006 and isinstance(target, Cel):
                f, x, y, w, h = c.take("<Iiiii")
                target.extra = (f, x / FIXED, y / FIXED, w / FIXED, h / FIXED)
            elif kind == 0x2007:
                sprite.color_profile = _profile(c)
            elif kind == 0x2008:
                n = c.take("<I")
                c.raw(8)
                for _ in range(n):
                    eid, etype = c.take("<IB")
                    c.raw(7)
                    sprite.external_files.append((eid, etype, c.string()))
                    ext[eid] = sprite.external_files[-1][2]
            elif kind == 0x2018:
                sprite.tags = _tags(c)
                tag_queue, target, tile_queue = list(sprite.tags), None, None
            elif kind == 0x2022:
                sprite.slices.append(_slice(c))
                target, tag_queue, tile_queue = sprite.slices[-1], [], None
            elif kind == 0x2023:
                sprite.tilesets.append(_tileset(c))
                target, tag_queue, tile_queue = sprite.tilesets[-1], [], None
            elif kind == 0x2020:
                user = read_user(c, ext)
                if tag_queue:
                    tag_queue.pop(0).user = user
                elif tile_queue is not None:
                    tile_queue.tile_users.append(user)
                    tile_queue = tile_queue if len(tile_queue.tile_users) < tile_queue.count else None
                elif isinstance(target, Tileset):
                    target.user, tile_queue, target = user, (target if target.count else None), None
                elif target is not None:  # como o Aseprite: o ultimo objeto continua o alvo
                    target.user = user
            cur = end
        pos += size
    return sprite
