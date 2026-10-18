"""Read the original RGBA/normal-blend Aseprite sources without changing pixels.

This intentionally limited reader rejects unsupported visible content. It is
an offline exporter, never a game dependency. Pillow is already pinned by QA.
"""
import struct
import zlib
from pathlib import Path

from PIL import Image


def read(path):
    data = Path(path).read_bytes()
    count, width, height, depth = struct.unpack_from('<4H', data, 6)
    if struct.unpack_from('<H', data, 4)[0] != 0xA5E0 or depth != 32:
        raise ValueError('Only RGBA Aseprite sources are supported')
    layers, frames, durations, tags = [], [], [], {}
    pos = 128
    for frame in range(count):
        size, magic, old, duration = struct.unpack_from('<I3H', data, pos)
        if magic != 0xF1FA:
            raise ValueError('Invalid frame')
        chunks = struct.unpack_from('<I', data, pos + 12)[0] or old
        cur, cels = pos + 16, {}
        for _ in range(chunks):
            length, kind = struct.unpack_from('<IH', data, cur)
            chunk = data[cur + 6:cur + length]
            if kind == 0x2004:
                flags, typ, level = struct.unpack_from('<3H', chunk)
                blend = struct.unpack_from('<H', chunk, 10)[0]
                name = chunk[18:18 + struct.unpack_from('<H', chunk, 16)[0]].decode()
                layers.append(dict(name=name, flags=flags, type=typ, level=level,
                                   blend=blend, opacity=chunk[12]))
            elif kind == 0x2005:
                layer, x, y, opacity, typ = struct.unpack_from('<HhhBH', chunk)
                if typ in (0, 2):
                    w, h = struct.unpack_from('<HH', chunk, 16)
                    raw = chunk[20:] if typ == 0 else zlib.decompress(chunk[20:])
                    image = Image.frombytes('RGBA', (w, h), raw)
                elif typ == 1:
                    linked = struct.unpack_from('<H', chunk, 16)[0]
                    image = frames[linked][layer][2].copy()
                else:
                    raise ValueError('Tilemap cels require Aseprite CLI')
                if opacity != 255:
                    image.putalpha(image.getchannel('A').point(lambda a: a * opacity // 255))
                cels[layer] = (x, y, image)
            elif kind == 0x2018:
                offset = 10
                for _ in range(struct.unpack_from('<H', chunk)[0]):
                    first, last = struct.unpack_from('<HH', chunk, offset)
                    n = struct.unpack_from('<H', chunk, offset + 17)[0]
                    name = chunk[offset + 19:offset + 19 + n].decode().lower()
                    tags[name] = dict(from_frame=first, to_frame=last, direction=chunk[offset + 4])
                    offset += 19 + n
            cur += length
        frames.append(cels)
        durations.append(duration)
        pos += size
    return dict(size=(width, height), layers=layers, frames=frames, durations=durations, tags=tags)


def composite(source, frame, indices, bounds=None):
    canvas = Image.new('RGBA', source['size'])
    for index in indices:
        layer = source['layers'][index]
        if not layer['flags'] & 1 or index not in source['frames'][frame]:
            continue
        if layer['blend'] != 0 or layer['opacity'] != 255:
            raise ValueError(f'Unsupported layer blend/opacity: {layer["name"]}')
        x, y, image = source['frames'][frame][index]
        canvas.alpha_composite(image, (x, y))
    return canvas.crop(bounds) if bounds else canvas
