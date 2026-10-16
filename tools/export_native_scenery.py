"""Export the approved scene compositions as reusable native Godot layers."""
import argparse
from hashlib import sha256
import json
from pathlib import Path
from PIL import Image
from native_scenery_access import close_water_border
from native_scenery_pixels import (
    campaign_ground_layers, cell, clean, export_layer, frame, hero, ladder, legacy_layer, natural,
    palette, props, structure_group, terrain, verify_layer, warp_structures, water_layers,
)

ROOT = Path("art/export/scenery_native")
SOURCE = Path("art/source/scenery_native")
MANIFEST = ROOT / "manifest.json"
SPLIT = {
    "bruma": ([[32, 400], [896, 1248]], [272, 1040]),
    "fenda": ([[32, 352], [928, 1248]], [224, 1040]),
    "lago": ([[32, 400], [896, 1248]], [288, 1040]),
    "rio": ([[32, 352], [928, 1248]], [240, 1040]),
    "enramados_bruma": ([[32, 432], [896, 1248]], [304, 1040]),
    "fenda_geada": ([[32, 352], [928, 1248]], [224, 1040]),
}
ALIASES = {"porto": "coast", "lago": "ancient_forest", "rio": "marsh",
           "enramados_bruma": "ancient_forest", "fenda_geada": "canyon"}
HERO = {"porto": "portuarios", "lago": "enramados", "rio": "bruma",
        "enramados_bruma": "enramados", "fenda_geada": "fenda"}
ARCH = {"porto": (640, 782), "lago": (557, 701), "rio": (578, 735)}
TINTS = {
    "enramados_lua": "#616785", "bruma_nevoa": "#b5c9bc",
    "horta_colheita": "#ead3b0", "portuarios_mare_baixa": "#e6bd94",
    "fenda_luar": "#637085", "fornalha_brasas": "#8e6353",
    "geada_aurora": "#607a86", "sobraiz_umida": "#83a79b",
    "porto_crepusculo": "#e0ad89", "porto_noite": "#5c6986",
    "lago_outono": "#dfc494", "lago_geada": "#bad3da",
    "rio_chuva": "#98b2b5", "rio_luar": "#67758c",
    "enramados_bruma": "#b7c5ac", "fenda_geada": "#c3d0d3",
}


def family_layers(job, legacy):
    family = job["key"]
    # Drop superseded campaign layers and their import sidecars before rebuilding.
    for path in (ROOT / family).glob("campaign_*.png"):
        path.unlink()
        path.with_suffix(".png.import").unlink(missing_ok=True)
    atlas = Image.open(SOURCE / "atlas" / (family + ".png"))
    plates = [cell(atlas, index, family) for index in range(8)]
    spans, mouths = SPLIT.get(family, ([[32, 1248]], [784]))
    under, bottom, crossing = terrain(plates[4], spans)
    water_back, water_front = water_layers(plates[5]) if job["water"] else (frame(), frame())
    if family == "lago":
        # Close transparent atlas padding and remove the warm divider bleed.
        water_front = close_water_border(water_front)
    landmark = Image.open(SOURCE / "hero" / (HERO.get(family, family) + ".png"))
    architecture = structure_group(plates[6], family)
    if family in ARCH:
        architecture = warp_structures(
            Image.open(SOURCE / "architecture" / (family + ".png")), *ARCH[family])
    images = {"far": natural(plates[1], -112), "mid": natural(plates[2], 128),
              "near": hero(landmark, 420 if family == "horta" else 500),
              "under": under, "terrain": bottom, "crossings": crossing,
              "structures": architecture, "props": props(plates[7]), "foreground": frame(),
              "water_back": water_back, "water": water_front}
    biome = job.get("biome", ALIASES.get(family))
    for layer in ("sky", "clouds"):
        images[layer] = legacy_layer(legacy, biome, layer)
    layers = {layer: export_layer(ROOT, family, layer, image,
                                4 if layer in ("sky", "clouds", "far", "mid") else 2)
              for layer, image in images.items()}
    access = palette(ladder(cell(Image.open(SOURCE / "atlas/lago.png"), 7, "lago")))
    ladder_path = ROOT / "common/access_ladder.png"
    ladder_path.parent.mkdir(parents=True, exist_ok=True)
    access.save(ladder_path, optimize=True)
    obsolete = ROOT / family / "access_ladder.png"
    obsolete.unlink(missing_ok=True)
    obsolete.with_suffix(".png.import").unlink(missing_ok=True)
    campaign = {}
    if "biome" in job:
        for layer in ("far", "mid", "near"):
            original = images[layer]
            wide = Image.new("RGBA", (2560, 720))
            wide.alpha_composite(original, (1280 if layer == "near" else 0, 0))
            if layer != "near":
                wide.alpha_composite(original, (1280, 0))
            campaign[layer] = export_layer(ROOT, family, "campaign_" + layer, wide,
                                            2 if layer == "near" else 4)
        ground_ids = ("enramados", "bruma", "horta", "portuarios",
                      "fenda", "fornalha", "geada", "sobraiz")
        ground_atlas = Image.open(SOURCE / "ground/campaign_grounds.png")
        ground = cell(ground_atlas, ground_ids.index(family), "campaign")
        for layer, original in campaign_ground_layers(ground).items():
            wide = Image.new("RGBA", (2560, 720))
            wide.alpha_composite(original)
            wide.alpha_composite(original, (1280, 0))
            campaign[layer] = export_layer(ROOT, family, "campaign_" + layer, wide, 2)
    return {"name": job["name"], "biome": biome, "canvas": [1280, 720],
            "campaign_layers": campaign,
            "lower_spans": spans, "passages": mouths, "layers": layers,
            "ladder": "res://" + ladder_path.as_posix(),
            "ladder_sha256": sha256(ladder_path.read_bytes()).hexdigest(),
            "construction_condition": "registered_structure_exists",
            "source_atlas": (SOURCE / "atlas" / (family + ".png")).as_posix()}


def scenes_and_variants(items):
    result = {}
    folder = Path("scenes/scenery_native")
    folder.mkdir(parents=True, exist_ok=True)
    for item in items:
        key = item["key"]
        recipe = {"tint": TINTS.get(key, "#ffffff"), "autumn": "outono" in key or
                  key == "horta_colheita", "frost": key == "lago_geada",
                  "aurora": key == "geada_aurora", "warm_lights": "noite" in key or
                  "luar" in key or key in ("fornalha_brasas", "enramados_lua"),
                  "water_offset_y": 12 if key == "portuarios_mare_baixa" else 0}
        result[key] = {**item, "family": item["family"].removesuffix("_especial"),
                       "recipe": recipe, "scene": "res://" + (folder / (key + ".tscn")).as_posix()}
        (folder / (key + ".tscn")).write_text(
            '[gd_scene load_steps=2 format=3]\n\n'
            '[ext_resource type="Script" path="res://src/world/native_scenery_stage.gd" id="1"]\n\n'
            f'[node name="{key}" type="Node2D"]\nscript = ExtResource("1")\n'
            f'view_id = "{key}"\n', encoding="utf-8")
    return result


def export():
    source = json.loads((SOURCE / "production_sources.json").read_text())
    legacy = json.loads(Path("art/export/scenery/manifest.json").read_text())
    families = {job["key"]: family_layers(job, legacy) for job in source["families"]}
    result = {key: source[key] for key in
              ("schema_version", "canvas", "surface_y", "underground_y",
               "playable_frame", "worker_frame", "module")}
    result.update(families=families, variants=scenes_and_variants(source["variants"]))
    MANIFEST.write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n")
    from native_scenery_modules import export_modules
    export_modules(result)
    check()


def check():
    data = json.loads(MANIFEST.read_text())
    assert len(data["families"]) == 13 and len(data["variants"]) == 24
    total = 0
    for family, item in data["families"].items():
        for layer in item["layers"].values():
            total += verify_layer(layer)
            x, y, width, height = layer["rect"]
            assert x >= 0 and y >= 0 and x + width <= 1280 and y + height <= 720
        for layer in item.get("campaign_layers", {}).values():
            total += verify_layer(layer)
            assert layer["rect"][0] + layer["rect"][2] <= 2560
        assert Path(item["source_atlas"]).is_file()
        for left, right in item["lower_spans"]:
            assert right - left >= 128 and any(left + 32 <= x <= right - 32
                                              for x in item["passages"]), family
        access = Path(item["ladder"].removeprefix("res://"))
        assert access.is_file() and sha256(access.read_bytes()).hexdigest() == item["ladder_sha256"]
        with Image.open(access) as image:
            assert image.size == (24, 51)
    for item in data["variants"].values():
        assert item["family"] in data["families"]
        assert Path(item["scene"].removeprefix("res://")).is_file()
    print(json.dumps({"families": len(data["families"]), "variants": len(data["variants"]),
                      "optimized_layer_bytes": total, "binary_alpha": True,
                      "max_colors_per_layer": 96, "sampling": "nearest"}))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    check() if args.check else export()
