"""Previa local autocontida; dados do ensaio escapados, sem pedidos de rede."""
from __future__ import annotations

import base64
import json
from pathlib import Path

from PIL import Image

from . import action_export
from .imageops import png_bytes


def write(out: Path, manifest: dict) -> None:
    images = {}
    for variant in ("actor", "final"):
        images[variant] = {}
        for action in manifest["actions"]:
            meta = json.loads((out / action[variant]["json"]).read_text(encoding="utf-8"))
            with Image.open(out / action[variant]["png"]) as im:
                sheet = im.convert("RGBA")
            for row in meta["frames"]:
                index = str(row["forja"]["source_frame"])
                frame = action_export.reconstruct(sheet, row)
                images[variant][index] = "data:image/png;base64," + base64.b64encode(png_bytes(frame)).decode()
    data = {"manifest": manifest, "images": images}
    ref = manifest.get("authority", {}).get("reference")
    if ref:
        data["reference"] = "data:image/png;base64," + base64.b64encode((out / ref).read_bytes()).decode()
    template = Path(__file__).with_name("rehearsal_view.html").read_text(encoding="utf-8")
    script = Path(__file__).with_name("rehearsal_view.js").read_text(encoding="utf-8")
    payload = json.dumps(data, ensure_ascii=False).replace("<", "\\u003c").replace(">", "\\u003e").replace("&", "\\u0026")
    (out / "index.html").write_text(template.replace("/*PLAYER*/", script).replace("/*DATA*/", payload),
                                    encoding="utf-8")
