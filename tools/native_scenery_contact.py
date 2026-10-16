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

# Temporary textual transport for visual review through the repository connector.
from base64 import b64encode
review = preview / "review_transport"
review.mkdir(exist_ok=True)
for name in ("contact", "enramados_base_underground", "porto_crepusculo_underground",
             "lago_outono_underground", "rio_chuva_underground",
             "campaign_surface", "campaign_underground"):
    path = preview / (name + ".png")
    if path.exists():
        (review / (name + ".b64.txt")).write_text(b64encode(path.read_bytes()).decode("ascii"))
