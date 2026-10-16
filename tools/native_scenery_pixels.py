"""Mechanical export: integer sampling, palette reduction and binary alpha only."""
from hashlib import sha256
from pathlib import Path
from PIL import Image, ImageChops

SIZE = (1280, 720)
NEAREST = Image.Resampling.NEAREST


def clean(image):
    image = image.convert("RGBA")
    alpha = image.getchannel("A").point(lambda a: 255 if a >= 128 else 0)
    image.putalpha(alpha)
    return Image.composite(image, Image.new("RGBA", image.size), alpha)


def frame():
    return Image.new("RGBA", SIZE)


def cell(atlas, index, family):
    width, height = atlas.size
    rows = [0, 317, 662, 895, height] if family == "enramados" else [
        round(height * i / 4) for i in range(5)
    ]
    col, row = index % 2, index // 2
    return clean(atlas.crop((col * width // 2 + 3, rows[row] + 3,
                            (col + 1) * width // 2 - 3, rows[row + 1] - 3)))


def put(canvas, plate, rect):
    x, y, width, height = rect
    canvas.alpha_composite(plate.resize((width, height), NEAREST), (x, y))
    return canvas


def natural(plate, offset=0):
    return put(frame(), plate, (0, offset, 1280, 720))


def hero(plate, height=500):
    plate = clean(plate)
    box = plate.getbbox()
    if not box:
        return frame()
    plate = plate.crop(box)
    width = round(plate.width * height / plate.height / 2) * 2
    return put(frame(), plate, (16, 517 - height, width, height))


def floor_lines(plate):
    alpha = plate.getchannel("A")
    rows = []
    for y in range(plate.height):
        line = alpha.crop((0, y, plate.width, y + 1))
        rows.append(sum(line.getdata()) / (255 * plate.width))
    upper = next((y for y, coverage in enumerate(rows) if coverage > .45),
                 round(plate.height * .58))
    lower = min(plate.height - 3, max(upper + 16, round(plate.height * .83)))
    return upper, lower


def terrain(plate, spans):
    upper, lower = floor_lines(plate)
    under = put(frame(), plate.crop((0, upper, plate.width, lower)),
                (0, 516, 1280, 104))
    bottom = put(frame(), plate.crop((0, lower, plate.width, plate.height)),
                 (0, 618, 1280, 102))
    mask = Image.new("L", SIZE)
    for left, right in spans:
        mask.paste(255, (left, 0, right, 720))
    for image in (under, bottom):
        image.putalpha(ImageChops.multiply(image.getchannel("A"), mask))
    strip = plate.crop((0, upper, plate.width, min(lower, upper + 6)))
    opaque = [p for p in strip.getdata() if p[3] >= 128]
    sample = opaque[len(opaque) // 2] if opaque else (86, 69, 43, 255)
    shelf = Image.new("RGBA", (1280, 6), sample)
    for left, right in spans:
        bottom.alpha_composite(shelf.crop((left, 0, right, 6)), (left, 618))
    crossing = put(frame(), strip, (0, 516, 1280, 6))
    # Dry paths remain legible across a bridge even with active buildings hidden.
    crossing.alpha_composite(Image.new("RGBA", (1280, 2), sample), (0, 516))
    return under, bottom, crossing


def structure_group(plate, family):
    box = plate.getbbox()
    if not box:
        return frame()
    plate = plate.crop(box)
    height = 132 if "_" in family else 300
    width = min(1248, round(plate.width * height / plate.height / 2) * 2)
    left = 16 if family == "fenda" else 1280 - width
    return put(frame(), plate, (left, 517 - height, width, height))


def warp_structures(plate, upper, lower):
    plate = clean(plate)
    result = frame()
    scale = 1280 / plate.width
    top_height = round(upper * scale)
    put(result, plate.crop((0, 0, plate.width, upper)),
        (0, 517 - top_height, 1280, top_height))
    put(result, plate.crop((0, upper, plate.width, lower)), (0, 517, 1280, 102))
    put(result, plate.crop((0, lower, plate.width, plate.height)),
        (0, 619, 1280, round((plate.height - lower) * scale)))
    return result


def ladder(plate):
    # Atlas prop 1 is the separately generated access ladder.
    part = plate.crop((0, 0, round(plate.width * .29), plate.height))
    box = part.getbbox()
    return part.crop(box).resize((24, 51), NEAREST) if box else Image.new("RGBA", (24, 51))


def props(plate):
    part = plate.crop((round(plate.width * .32), 0, plate.width, plate.height))
    box = part.getbbox()
    if not box:
        return frame()
    part = part.crop(box)
    width = min(220, round(part.width * 32 / part.height))
    return put(frame(), part, (1024, 485, width, 32))


def palette(image, colors=96):
    image = clean(image)
    alpha = image.getchannel("A")
    result = image.convert("RGB").quantize(colors=colors, method=Image.Quantize.MEDIANCUT,
                                          dither=Image.Dither.NONE).convert("RGBA")
    result.putalpha(alpha)
    return clean(result)


def export_layer(root, family, layer, image, grid=2):
    name = layer.removeprefix("campaign_")
    colors = 16 if name == "far" else 32 if name in ("mid", "sky", "clouds", "foreground") else 64 if name in ("under", "terrain") else 96
    sampled = palette(image.resize((image.width // grid, image.height // grid), NEAREST), colors)
    box = sampled.getbbox()
    if box:
        cropped = sampled.crop(box)
        rect = [box[0] * grid, box[1] * grid,
                cropped.width * grid, cropped.height * grid]
    else:
        cropped, rect = Image.new("RGBA", (1, 1)), [0, 0, grid, grid]
    path = root / family / (layer + ".png")
    path.parent.mkdir(parents=True, exist_ok=True)
    cropped.save(path, optimize=True)
    return {"file": "res://" + path.as_posix(), "rect": rect,
            "scale": [grid, grid], "size": list(cropped.size),
            "sha256": sha256(path.read_bytes()).hexdigest()}


def legacy_layer(manifest, biome, layer):
    data = manifest["scenes"][biome]["layers"][layer]
    image = Image.open(data["file"].removeprefix("res://"))
    x, y, width, height = data["rect"]
    # One existing sky/cloud period fits the new camera; no cloud is painted twice.
    return put(frame(), image, (x // 2, y, width // 2, height))


def verify_layer(layer):
    path = Path(layer["file"].removeprefix("res://"))
    assert sha256(path.read_bytes()).hexdigest() == layer["sha256"], path
    with Image.open(path) as image:
        assert image.mode == "RGBA" and list(image.size) == layer["size"], path
        pixels = list(image.getdata())
        assert all(p[3] in (0, 255) for p in pixels), path
        assert len({p[:3] for p in pixels if p[3]}) <= 96, path
    assert layer["rect"][2:] == [n * layer["scale"][0] for n in layer["size"]], path
    return path.stat().st_size


def water_layers(plate):
    image = put(frame(), plate, (0, 426, 1280, 294))
    back, front = image.copy(), image.copy()
    back.paste((0, 0, 0, 0), (0, 518, 1280, 720))
    front.paste((0, 0, 0, 0), (0, 0, 1280, 518))
    return back, front


def legacy_campaign_layer(manifest, biome, layer):
    entry = manifest["scenes"][biome]["layers"][layer]
    image = Image.new("RGBA", (2560, 720))
    source = Image.open(entry["file"].removeprefix("res://"))
    return put(image, source, tuple(entry["rect"]))
