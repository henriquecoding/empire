"""Export the owner's separated compositions as the campaign scenery (ADR 0085).

    python3 tools/export_owner_scenery.py --camadas DIR --pacote ZIP --aprovado ZIP
    python3 tools/export_owner_scenery.py --check

DIR holds one folder per view, written by tools/owner_scenery/separate.py from the
owner's ZIPs: sky, clouds, far, mid, near and strip at full frame size (1280 x 720,
floors already at y517 / y618.5) and meta.json with each plane's loop. This script
checks every source PNG against the ZIP it came from, halves each plane onto the 2 px
grid the game draws it in (nearest, binary alpha), crops it to its rows and writes
art/export/scenery_owner/<view>/ with manifest.json. --check confirms the export against
the manifest without the ZIPs (the inventario-arte gate).
"""
import argparse
from hashlib import sha256
import json
from pathlib import Path
import zipfile

from PIL import Image

ROOT = Path("art/export/scenery_owner")
MANIFEST = ROOT / "manifest.json"
CONFIG = Path("tools/owner_scenery/views.json")
RES = "res://"
W, H = 1280, 720
GROUND, UNDER = 517, 618.5
TERRAIN_Y = 618
SCALE = 2
NEAR_PERIOD = 2560
## Um reino mostra o perto uma vez em cada 2560 px de plano, com o meio da composicao no meio do
## quadro: e esse meio que o SceneryPlane poe atras da sede. Um sitio ancora-se na agua dele.
KINGDOM_SHIFT = (NEAR_PERIOD - W) // 2
PLANES = ("sky", "clouds", "far", "mid", "near")


def digest(path):
    return sha256(Path(path).read_bytes()).hexdigest()


def halve(image):
    """2 x 2 blocks: opaque where at least two of the four are, coloured by those."""
    import numpy as np  # only the export needs it; --check runs on Pillow alone

    a = np.asarray(image.convert("RGBA")).astype(np.int32)
    h, w = a.shape[0] // SCALE * SCALE, a.shape[1] // SCALE * SCALE
    a = a[:h, :w]
    solid = (a[..., 3] >= 128).astype(np.int32)
    blocks = lambda x: x.reshape(h // SCALE, SCALE, w // SCALE, SCALE, *x.shape[2:]).sum(axis=(1, 3))
    n = blocks(solid)
    rgb = blocks(a[..., :3] * solid[..., None])
    out = np.zeros((h // SCALE, w // SCALE, 4), np.uint8)
    keep = n * 2 >= SCALE * SCALE
    out[keep, :3] = (rgb[keep] // n[keep][:, None]).astype(np.uint8)
    out[keep, 3] = 255
    return Image.fromarray(out, "RGBA")


def rows_of(image, top=0, bottom=H):
    """The alpha rows of `image` inside [top, bottom), even, as (y0, y1)."""
    alpha = image.getchannel("A").crop((0, top, image.width, bottom))
    box = alpha.getbbox()
    if box is None:
        return None
    y0 = top + box[1] - (top + box[1]) % SCALE
    y1 = top + box[3] + (top + box[3]) % SCALE
    return y0, min(y1, bottom)


def write(view, layer, image, x, period, out):
    path = ROOT / view / (layer + ".png")
    path.parent.mkdir(parents=True, exist_ok=True)
    small = halve(image)
    small.save(path, optimize=True)
    entry = {
        "file": RES + str(path), "rect": [x, out[0], image.width, out[1] - out[0]],
        "scale": [SCALE, SCALE], "sha256": digest(path),
    }
    if period:
        entry["period"] = period
    return entry


def export_view(view, folder, centred=False):
    meta = json.loads((folder / "meta.json").read_text())
    spans = meta["spans"]
    layers = {}
    sky = Image.open(folder / "sky.png")
    layers["sky"] = write(view, "sky", sky, 0, 0, (0, H))
    for layer in ("clouds", "far", "mid"):
        image = Image.open(folder / (layer + ".png"))
        rows = rows_of(image)
        if rows is None:  # an overcast sky keeps its clouds: the layer is there, and empty
            layers[layer] = write(view, layer, Image.new("RGBA", (SCALE, SCALE)), 0, W, (0, SCALE))
            continue
        x0, x1 = spans.get(layer, [0, W])
        crop = image.crop((0, rows[0], image.width, rows[1]))
        layers[layer] = write(view, layer, crop, x0 if layer != "clouds" else 0,
                              x1 - x0 if layer != "clouds" else W, rows)
    near = Image.open(folder / "near.png")
    rows = rows_of(near)
    if rows is not None:
        pad = meta["near_pad"][0]
        crop = near.crop((0, rows[0], near.width, rows[1]))
        x = -pad + (KINGDOM_SHIFT if centred else 0)
        layers["near"] = write(view, "near", crop, x, meta.get("near_period", NEAR_PERIOD), rows)
    strip = Image.open(folder / "strip.png")
    rows = rows_of(strip, 0, TERRAIN_Y)
    layers["under"] = write(view, "under", strip.crop((0, rows[0], W, TERRAIN_Y)), 0, W,
                            (rows[0], TERRAIN_Y))
    layers["terrain"] = write(view, "terrain", strip.crop((0, TERRAIN_Y, W, H)), 0, W,
                              (TERRAIN_Y, H))
    if (folder / "landmark.png").exists():
        mark = Image.open(folder / "landmark.png")
        box = mark.getbbox()
        if box is not None:
            x0, y0 = box[0] - box[0] % SCALE, box[1] - box[1] % SCALE
            x1, y1 = box[2] + box[2] % SCALE, box[3] + box[3] % SCALE
            layers["landmark"] = write(view, "landmark", mark.crop((x0, y0, x1, y1)), x0, 0, (y0, y1))
    return layers


def source_digests(zips, views):
    """The SHA-256 of each view's PNG inside the ZIP that holds it."""
    found = {}
    for package in zips:
        with zipfile.ZipFile(package) as z:
            names = z.namelist()
            for view, data in views.items():
                for name in names:
                    if name.endswith("/" + data["src"]) or name == data["src"]:
                        found[view] = sha256(z.read(name)).hexdigest()
    return found


def export(camadas, pacotes, config_path=CONFIG):
    config = json.loads(Path(config_path).read_text())
    views = config["views"]
    digests = source_digests(pacotes, views)
    missing = sorted(set(views) - set(digests))
    if missing:
        raise SystemExit("export_owner_scenery: sem fonte nos ZIPs para " + ", ".join(missing))
    manifest = {
        "schema": 1, "generated_by": "tools/export_owner_scenery.py",
        "surface_y": GROUND, "under_y": UNDER,
        "packages": {Path(p).name: digest(p) for p in pacotes},
        "views": {}, "kingdoms": config["kingdoms"], "sites": config["sites"],
        "transitions": config["transitions"],
    }
    reinos = {v for k in config["kingdoms"].values() for v in [k["base"]] + [x["view"] for x in k["variants"]]}
    for view in sorted(views):
        layers = export_view(view, Path(camadas) / view, view in reinos)
        manifest["views"][view] = {"src": views[view]["src"], "src_sha256": digests[view],
                                   "layers": layers}
        print("export_owner_scenery:", view, ", ".join(layers))
    MANIFEST.write_text(json.dumps(manifest, indent=1, ensure_ascii=False) + "\n")


def check():
    manifest = json.loads(MANIFEST.read_text())
    errors = []
    for view, data in manifest["views"].items():
        for layer, entry in data["layers"].items():
            path = Path(entry["file"][len(RES):])
            if not path.exists():
                errors.append("%s/%s: falta %s" % (view, layer, path))
                continue
            if digest(path) != entry["sha256"]:
                errors.append("%s/%s: o PNG nao e o do manifesto" % (view, layer))
            size = Image.open(path).size
            rect = entry["rect"]
            if [size[0] * SCALE, size[1] * SCALE] != rect[2:]:
                errors.append("%s/%s: %s x %d nao e o retangulo %s" % (view, layer, size, SCALE, rect))
    used = {v for k in manifest["kingdoms"].values() for v in [k["base"]] + [x["view"] for x in k["variants"]]}
    used |= {v for s in manifest["sites"].values() for v in [s["base"]] + [x["view"] for x in s["variants"]]}
    used |= {t["view"] for t in manifest["transitions"].values()}
    for view in sorted(used - set(manifest["views"])):
        errors.append("%s: usado no manifesto e nao exportado" % view)
    for path in sorted(ROOT.glob("*/*.png")):
        if path.parent.name not in manifest["views"]:
            errors.append("%s: fora do manifesto" % path)
    if errors:
        raise SystemExit("export_owner_scenery --check:\n  " + "\n  ".join(errors))
    print("export_owner_scenery --check: %d vistas em dia" % len(manifest["views"]))


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--camadas")
    parser.add_argument("--pacote", action="append", default=[])
    parser.add_argument("--aprovado", action="append", default=[])
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--config", default=str(CONFIG))
    args = parser.parse_args()
    if args.check:
        check()
    else:
        export(args.camadas, args.pacote + args.aprovado, args.config)


if __name__ == "__main__":
    main()
