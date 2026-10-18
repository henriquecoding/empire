"""Read PNG and Aseprite independently and compare their actual pixels."""
import json
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def png(path):
    raw = path.read_bytes()
    assert raw[:8] == b"\x89PNG\r\n\x1a\n", path
    offset, compressed = 8, bytearray()
    while offset < len(raw):
        size = struct.unpack_from(">I", raw, offset)[0]
        kind = raw[offset + 4:offset + 8]
        block = raw[offset + 8:offset + 8 + size]
        crc = struct.unpack_from(">I", raw, offset + 8 + size)[0]
        assert zlib.crc32(kind + block) & 0xFFFFFFFF == crc, path
        if kind == b"IHDR":
            width, height, depth, colour, _, _, interlace = struct.unpack(">IIBBBBB", block)
            assert (depth, colour, interlace) == (8, 6, 0), path
        if kind == b"IDAT":
            compressed.extend(block)
        offset += size + 12
    decoded = zlib.decompress(compressed)
    stride, previous, result = width * 4, bytearray(width * 4), bytearray()
    for y in range(height):
        start = y * (stride + 1)
        mode, row = decoded[start], bytearray(decoded[start + 1:start + 1 + stride])
        for x in range(stride):
            left = row[x - 4] if x >= 4 else 0
            up, upper_left = previous[x], previous[x - 4] if x >= 4 else 0
            if mode == 1:
                predictor = left
            elif mode == 2:
                predictor = up
            elif mode == 3:
                predictor = (left + up) // 2
            elif mode == 4:
                p = left + up - upper_left
                errors = [abs(p - left), abs(p - up), abs(p - upper_left)]
                predictor = [left, up, upper_left][errors.index(min(errors))]
            else:
                assert mode == 0
                predictor = 0
            row[x] = (row[x] + predictor) & 255
        result.extend(row)
        previous = row
    return width, height, result


def aseprite(path):
    raw = path.read_bytes()
    total, magic, frames, width, height, depth = struct.unpack_from("<I5H", raw)
    assert total == len(raw) and (magic, frames, depth) == (0xA5E0, 1, 32), path
    frame_size, frame_magic, count = struct.unpack_from("<IHH", raw, 128)
    assert frame_magic == 0xF1FA and frame_size + 128 == total
    result, names, offset = bytearray(width * height * 4), [], 144
    for _ in range(count):
        size, kind = struct.unpack_from("<IH", raw, offset)
        block = raw[offset + 6:offset + size]
        if kind == 0x2004:
            length = struct.unpack_from("<H", block, 16)[0]
            names.append(block[18:18 + length].decode())
        if kind == 0x2005:
            layer, x, y, opacity, cel_type = struct.unpack_from("<HhhBH", block)
            cw, ch = struct.unpack_from("<HH", block, 16)
            assert cel_type == 2 and opacity == 255 and layer < len(names)
            pixels = zlib.decompress(block[20:])
            assert len(pixels) == cw * ch * 4 and x == y == 0
            assert (cw, ch) == (width, height)
            for n in range(0, len(pixels), 4):
                assert pixels[n + 3] in (0, 255)
                if pixels[n + 3]:
                    result[n:n + 4] = pixels[n:n + 4]
        offset += size
    assert offset == len(raw)
    assert names == ["corpo", "acabamento-nativo"]
    return width, height, result


manifest = json.loads((ROOT / "manifest.json").read_text())
expected = {"rei": 80, "arqueiro": 80, "sombra": 80,
            "nia": 64, "escudeiro": 64, "bardo": 64,
            "intendente": 64, "dancarina": 64}
atlas_meta = json.loads((ROOT / "atlas.json").read_text())
aw, ah, atlas = png(ROOT / atlas_meta["image"])
assert (aw, ah) == (320, 160)
checks = []
for c in manifest["frames"]:
    width, height, rgba = png(ROOT / c["file"])
    assert (width, height) == (expected[c["id"]],) * 2
    assert set(rgba[3::4]) == {0, 255}
    colours = {bytes(rgba[n:n + 3]) for n in range(0, len(rgba), 4) if rgba[n + 3]}
    assert len(colours) == c["colours"] and len(colours) <= 48
    assert (width, height, rgba) == aseprite(ROOT / c["source"])
    rect = atlas_meta["frames"][c["id"]]["frame"]
    for y in range(height):
        start = ((rect["y"] + y) * aw + rect["x"]) * 4
        assert atlas[start:start + width * 4] == rgba[y * width * 4:(y + 1) * width * 4]
    checks.append({"id": c["id"], "size": [width, height], "colours": len(colours),
                   "alpha_binary": True, "aseprite_pixels_match": True, "atlas_pixels_match": True})
assert set(expected) == {c["id"] for c in manifest["frames"]}
report = {"result": "pass", "scope": "Integridade e correspondência de pixels; não certifica aprovação artística.", "characters": checks}
(ROOT / "verification.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
print(json.dumps(report, ensure_ascii=False))
