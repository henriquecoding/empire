"""Autoridade e quadros sintéticos; não são novos desenhos aprovados do elenco."""
import hashlib
import json

from PIL import Image

from tools.forja import contracts, palette, quantize
from tools.forja.backends import http
from tools.forja.equipment import image_sha
from tools.forja.imageops import png_bytes
from tools.forja.tests.helpers import framed, tempdir


def fixture():
    root = tempdir()
    pal = palette.load(palette.ROOT / contracts.get("royal_64").palette)
    master = quantize.to_palette(framed(4, (64, 64), (32, 62)), pal)
    master.save(root / "first.png")
    master.save(root / "concept.png")
    ch = {"id": "test_squire", "pose": "idle", "role": "squire", "kind": "royal_64",
          "target_canvas": [64, 64], "authority_crop_xyxy": [0, 0, 64, 64],
          "invariants": ["keep face and equipment"], "critical_regions": [], "pixel_pins": []}
    contract = {"schema": "forja.fidelity/1", "authority": {"file": "concept.png", "size": [64, 64],
        "sha256": hashlib.sha256((root / "concept.png").read_bytes()).hexdigest()}, "characters": [ch]}
    (root / "fidelity.json").write_text(json.dumps(contract))
    return root, master, ch


def frames(master, n=8):
    out = []
    for i in range(n):
        im = master.copy()
        im.putpixel((27 + i % 8, 40), (0, 0, 0, 255))
        out.append(im)
    return out


def skeleton(master, count=5):
    from tools.forja.backends.pixellab_animation import JOINTS
    pose = [{"label": label, "x": 0.4, "y": 0.5} for label in JOINTS]
    return {"schema": "forja.skeleton_animation/1", "first_frame_pixels_sha256": image_sha(master),
            "observer": {"author": "test", "method": "synthetic fixture", "date": "2026-10-30"},
            "first_frame_keypoints": pose, "keypoints": [pose for _ in range(count)], "template_id": "mannequin"}


def response(images):
    return {"status": "completed", "last_response": {"images": [
        {"type": "base64", "format": "png", "base64": http.b64(png_bytes(im))} for im in images],
        "usage": {"type": "usd", "usd": 0.12}}}
