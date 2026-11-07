#!/usr/bin/env python3
"""Bake the Pixel Art Lighter surface data for the existing V15 runtime atlases."""
from __future__ import annotations

import argparse
import json
from hashlib import sha256
from pathlib import Path

from PIL import Image

from .forja import pixel_lighter

ROOT = Path(__file__).resolve().parents[1]
ALBEDOS = ROOT / "art/export/royals"
OUTPUT = ROOT / "src/actors/lighting_maps"
NEUTRAL = (128, 128, 255)


def _sources():
    return json.loads((ALBEDOS / "manifest.json").read_text(encoding="utf-8"))["assets"].values()


def _hash(p: Path) -> str:
    return sha256(p.read_bytes()).hexdigest()


def _surface_path(item: dict) -> Path:
    return OUTPUT / (Path(item["texture"]).stem + "_surface.png")


def _mirrored(surface: Image.Image) -> Image.Image:
    flipped = surface.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    r, g, b = flipped.split()
    r = r.point([128 if x == 128 else 255 - x for x in range(256)])
    return Image.merge("RGB", (r, g, b))


def _bake(item: dict, atlas: Image.Image) -> Image.Image:
    w, h = item["size"]
    cells = [(x, y, x + w, y + h) for x, y in item["frame_origins"]]
    mirrored = {int(left): int(right) for right, left in item["mirrors"].items()}
    result = Image.new("RGB", atlas.size, NEUTRAL)
    for frame, box in enumerate(cells):
        image = atlas.crop(box)
        original = mirrored.get(frame)
        if original is not None and original < frame and image.tobytes() == atlas.crop(
                cells[original]).transpose(Image.Transpose.FLIP_LEFT_RIGHT).tobytes():
            surface = _mirrored(result.crop(cells[original]))
        else:
            surface = pixel_lighter.pack_surface(*pixel_lighter.generate(image))
        result.paste(surface, box[:2])
    return result


def _stamp(item: dict) -> dict:
    # Hash the alignment inputs as well as both images so an atlas change cannot leave stale maps.
    layout = {k: item[k] for k in ("size", "frame_origins", "mirrors")}
    path = _surface_path(item)
    with Image.open(path) as atlas:
        surface = sha256(atlas.convert("RGB").tobytes()).hexdigest()
    return {"albedo": _hash(ALBEDOS / item["texture"]), "surface_pixels": surface,
            "layout": sha256(json.dumps(layout, sort_keys=True).encode()).hexdigest()}


def check() -> bool:
    try:
        expected = json.loads((OUTPUT / "atlas.json").read_text(encoding="utf-8"))
        return expected == {item["texture"]: _stamp(item) for item in _sources()}
    except (OSError, ValueError):
        return False


def bake() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    manifest = {}
    for item in _sources():
        with Image.open(ALBEDOS / item["texture"]) as atlas:
            _bake(item, atlas.convert("RGBA")).save(_surface_path(item), optimize=True)
        manifest[item["texture"]] = _stamp(item)
    (OUTPUT / "atlas.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    if args.check:
        if not check():
            parser.exit(1, "Mapas desatualizados. Corre python3 -m tools.bake_royal_lighting\n")
    else:
        bake()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
