"""Contact sheet of actual renderer captures, preserving pixel edges."""
import json
from pathlib import Path
from shutil import copy2
from PIL import Image, ImageDraw

folder = Path("build/scenery-native")
data = json.loads(Path("art/source/scenery_native/production_sources.json").read_text())
first = {}
for view in data["variants"]:
    first.setdefault(view["family"].removesuffix("_especial"), view["key"])
thumbs = Image.new("RGB", (1280, 4 * 204), "#151b19")
draw = ImageDraw.Draw(thumbs)
for index, (family, key) in enumerate(first.items()):
    image = Image.open(folder / (key + "_surface.png"))
    image = image.resize((320, 180), Image.Resampling.NEAREST).convert("RGB")
    x, y = index % 4 * 320, index // 4 * 204
    thumbs.paste(image, (x, y))
    draw.text((x + 8, y + 184), family, fill="#eadfc2")
preview = Path("docs/art/scenery_native_previews")
preview.mkdir(parents=True, exist_ok=True)
thumbs.save(preview / "contact.png", optimize=True)
for key in ("porto_crepusculo", "lago_outono", "rio_chuva", "enramados_base"):
    for state in ("surface", "underground", "empty"):
        copy2(folder / (key + "_" + state + ".png"), preview)
copy2(folder / "captures.json", preview)
