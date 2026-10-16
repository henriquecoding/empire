"""Assemble the compiled production overlay and real Godot capture evidence."""
import json
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

ROOTS = ["art/source/scenery_native", "art/export/scenery_native", "scenes/scenery_native"]
CODE = [
    "src/world/scenery_art.gd", "export_presets.cfg",
    "src/world/native_scenery_catalog.gd", "src/world/native_actor_fit.gd",
    "src/world/native_scenery_actor.gd", "src/world/native_scenery_stage.gd",
    "shaders/native_scenery_variant.gdshader", "tools/native_scenery_pixels.py",
    "tools/export_native_scenery.py", "tools/native_scenery_modules.py",
    "tools/native_scenery_walker.gd", "tools/native_scenery_review.gd",
    "tools/native_scenery_review.tscn", "tools/verify_native_scenery.gd",
    "tools/verify_native_scenery.tscn", "tools/capture_native_scenery.gd",
    "tools/capture_native_scenery.tscn", "tests/native_scenery_test.gd",
    "docs/art/NATIVE_SCENERY.md", "docs/art/scenery_native_validation.json",
]

out = Path("build/EMPIRE-Cenarios-Producao-Nativa-2026-10-16.zip")
with ZipFile(out, "w", ZIP_DEFLATED) as archive:
    for root in ROOTS + ["build/scenery-native"]:
        for path in sorted(Path(root).rglob("*")):
            if path.is_file() and ".godot" not in path.parts and path.suffix != ".import":
                archive.write(path)
    for name in CODE:
        path = Path(name)
        archive.write(path)
        uid = Path(name + ".uid")
        if uid.exists():
            archive.write(uid)
print(json.dumps({"package": out.as_posix(), "bytes": out.stat().st_size}))
