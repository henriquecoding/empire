"""A contact sheet of the separated views (ADR 0086).

    python3 tools/owner_scenery/contact.py CAMADAS SAIDA.jpg

For each view, the owner's painting on the left and, on the right, its planes stacked the way
the game stacks them with the camera where the painting was framed: sky, clouds, far, mid and
near from CAMADAS/<view>/ (separate.py), then the ground. It reviews the separation; the game
itself is captured by tools/owner_scenery/capture.sh.
"""
import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw

CONFIG = Path("tools/owner_scenery/views.json")
THUMB = (480, 270)
LABEL = 16
W = 1280


def tile(image, x0, period):
    """The plane laid over the frame: the loop that starts at x0 repeated every period."""
    out = Image.new("RGBA", (W, image.height))
    start = x0 - ((x0 // period) + 1) * period
    for x in range(start, W, period):
        out.alpha_composite(image, (max(0, x), 0), (max(0, -x), 0))
    return out


def stack(folder, meta):
    frame = Image.open(folder / "sky.png").convert("RGBA")
    frame.alpha_composite(Image.open(folder / "clouds.png").convert("RGBA"))
    for layer in ("far", "mid"):
        x0, x1 = meta["spans"][layer]
        frame.alpha_composite(tile(Image.open(folder / (layer + ".png")).convert("RGBA"), x0, x1 - x0))
    near = Image.open(folder / "near.png").convert("RGBA")
    frame.alpha_composite(near, (0, 0), (meta["near_pad"][0], 0))
    frame.alpha_composite(Image.open(folder / "strip.png").convert("RGBA"))
    return frame.convert("RGB")


def main():
    camadas, saida = Path(sys.argv[1]), Path(sys.argv[2])
    views = json.loads(CONFIG.read_text())["views"]
    names = [v for v in views if (camadas / v / "meta.json").exists()]
    sheet = Image.new("RGB", (THUMB[0] * 2, (THUMB[1] + LABEL) * len(names)), (16, 16, 16))
    draw = ImageDraw.Draw(sheet)
    for row, view in enumerate(names):
        y = row * (THUMB[1] + LABEL)
        folder = camadas / view
        meta = json.loads((folder / "meta.json").read_text())
        left = Image.open(folder / "source.png").convert("RGB")
        sheet.paste(left.resize(THUMB, Image.LANCZOS), (0, y))
        sheet.paste(stack(folder, meta).resize(THUMB, Image.LANCZOS), (THUMB[0], y))
        draw.text((4, y + THUMB[1] + 2), "%s  (%s)" % (view, meta["src"]), fill=(230, 230, 230))
    saida.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(saida, quality=85, optimize=True)
    print("contact:", len(names), "vistas em", saida)


if __name__ == "__main__":
    main()
