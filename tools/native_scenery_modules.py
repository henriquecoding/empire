"""Lossless 64 px module atlases and layered editable OpenRaster sources."""
import json
from pathlib import Path
from xml.etree.ElementTree import Element, SubElement, tostring
from zipfile import ZipFile, ZIP_DEFLATED
from io import BytesIO
from PIL import Image
from native_scenery_pixels import frame, put

ROOT = Path("art/export/scenery_native")
LAYERS = ("under", "terrain", "crossings", "water", "structures", "props", "foreground")


def png(image):
    stream = BytesIO()
    image.save(stream, format="PNG", optimize=True)
    return stream.getvalue()


def expanded(layer):
    image = Image.open(layer["file"].removeprefix("res://")).convert("RGBA")
    return put(frame(), image, tuple(layer["rect"]))


def tile_set(path, height, coords):
    lines = [
        '[gd_resource type="TileSet" load_steps=3 format=3]',
        '[ext_resource type="Texture2D" path="res://' + path.as_posix() + '" id="1"]',
        '[sub_resource type="TileSetAtlasSource" id="Atlas"]',
        'texture = ExtResource("1")', 'texture_region_size = Vector2i(64, 64)',
    ]
    for x, y in coords:
        lines.append(f'{x}:{y}/0 = 0')
    lines += ['[resource]', 'tile_size = Vector2i(64, 64)',
              'sources/0 = SubResource("Atlas")']
    path.with_suffix(".tres").write_text("\n".join(lines) + "\n")


def export_modules(data):
    for family, item in data["families"].items():
        folder = ROOT / family
        unique, cells, placements = {}, [], {}
        for name in LAYERS:
            image = expanded(item["layers"][name])
            placements[name] = []
            for y in range(0, 720, 64):
                for x in range(0, 1280, 64):
                    tile = image.crop((x, y, x + 64, y + 64))
                    if not tile.getbbox():
                        continue
                    key = tile.tobytes()
                    if key not in unique:
                        unique[key] = len(cells)
                        cells.append(tile)
                    index = unique[key]
                    placements[name].append({"world": [x, y],
                                             "atlas": [index % 16, index // 16]})
        height = max(1, (len(cells) + 15) // 16) * 64
        atlas = Image.new("RGBA", (1024, height))
        coords = []
        for i, tile in enumerate(cells):
            coord = [i % 16, i // 16]
            coords.append(coord)
            atlas.alpha_composite(tile, (coord[0] * 64, coord[1] * 64))
        path = folder / "modules_64.png"
        atlas.save(path, optimize=True)
        tile_set(path, height, coords)
        (folder / "module_placements.json").write_text(
            json.dumps({"tile_size": [64, 64], "layers": placements}, indent=2) + "\n")
        editable(folder, item)


def editable(folder, item):
    root = Element("image", {"w": "1280", "h": "720", "name": item["name"],
                            "version": "0.0.3"})
    stack = SubElement(root, "stack")
    composite = frame()
    with ZipFile(folder / "layers.ora", "w", ZIP_DEFLATED) as archive:
        archive.writestr("mimetype", "image/openraster", compress_type=0)
        for name in ("sky", "clouds", "far", "mid", "near", "water", "under",
                     "terrain", "crossings", "structures", "props", "foreground"):
            layer = item["layers"][name]
            image = expanded(layer)
            composite.alpha_composite(image)
            source = "data/" + name + ".png"
            SubElement(stack, "layer", {"name": name, "src": source,
                                       "opacity": "1.0", "visibility": "visible",
                                       "composite-op": "svg:src-over", "x": "0", "y": "0"})
            archive.writestr(source, png(image))
        # OpenRaster stacks are top first; the manifest supplies drawing order to Godot.
        stack[:] = list(reversed(list(stack)))
        archive.writestr("stack.xml", tostring(root, encoding="utf-8"))
        archive.writestr("mergedimage.png", png(composite))
