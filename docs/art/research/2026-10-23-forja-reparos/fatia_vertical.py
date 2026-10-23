#!/usr/bin/env python3
"""A fatia vertical de 23/10: referencia autorizada -> plano validado -> (geracao) -> revisao -> exportacao -> ida e volta.

Usa a bailarina (royal_64) e a Sombra (royal_80) do elenco V15 ja integrado
(ADR 0087), so para leitura. Sem rede: os planos sao validados e escritos, a
geracao fica registada como bloqueada se faltarem chaves ou teto de gasto, e a
revisao e a exportacao correm sobre os quadros reais do V15 (que NAO sao uma
geracao nova). Grava `fatia/fatia-vertical.json` e as provas 1x/2x e em movimento.

    python3 docs/art/research/2026-10-23-forja-reparos/fatia_vertical.py [--refs build/forja/piloto/ref]

`--refs` grava tambem os quadros de referencia (idle 0) para o piloto (`piloto.json`).
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
sys.path.insert(0, str(ROOT))
from tools.forja import anim, aseprite, contracts, godot, plan, review, royals  # noqa: E402
from tools.forja import palette as palmod  # noqa: E402
from tools.forja.imageops import opaque_bbox, upscale  # noqa: E402

OUT = HERE / "fatia"
BOARD = ROOT / "docs/art/research/2026-10-19-character-animation/referencias/sombra-bailarina-design-aceito.png"
SUBJECTS = {
    "dancarina": "adult red-haired dancer, compact tied-up hair, expressive face, cream blouse, sage bodice, "
                 "asymmetric wine skirt in two masses, opaque stockings, low brown shoes",
    "sombra": "hunched figure under a large charcoal-violet cloak with plum lining, head bowed, simple closed grey "
              "helmet with a small crooked bronze crown, silver gloves and boots, face hidden",
}
KEYS = ("OPENAI_API_KEY", "GEMINI_API_KEY", "GOOGLE_API_KEY", "PIXELLAB_API_KEY", "PIXELLAB_SECRET", "PIXELLAB_API_TOKEN")
LIGHT, DARK = (214, 206, 190, 255), (34, 30, 38, 255)


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def plans(who: str, kind: str, ref: Path, pal) -> list[dict]:
    out = []
    for backend in ("pixellab", "openai", "gemini"):
        for tags in (None, [("walk", 8)]):
            p = plan.make(backend, SUBJECTS[who], kind, tags, references=[("identity", str(ref))], palette=pal)
            d = p.data
            out.append({"backend": backend, "model": d["model"], "tags": d["tags"], "ok": p.ok, "errors": d["errors"],
                        "request": d["request"], "attachments": [(a["role"], a["sha256"][:16]) for a in d["attachments"]],
                        "expect": {k: d["expect"][k] for k in ("size", "cells", "content", "scale", "scale_exact",
                                                                "grid")} if d["expect"] else None,
                        "prompt_sha256": d["prompt_sha256"], "notes": d["notes"], "authoring": d.get("authoring"),
                        "training_permission": d["training_permission"]})
    return out


def measures(pkg: dict) -> dict:
    boxes = [opaque_bbox(f) for f in pkg["frames"]]
    union = [min(b[0] for b in boxes), min(b[1] for b in boxes), max(b[2] for b in boxes), max(b[3] for b in boxes)]
    areas = [sum(1 for a in f.getchannel("A").tobytes() if a) for f in pkg["frames"]]
    idle = boxes[0]
    return {"canvas": pkg["size"], "pivot": pkg["pivot"], "idle_opaque_box": list(idle),
            "idle_opaque_size": [idle[2] - idle[0], idle[3] - idle[1]], "union_opaque_box": union,
            "opaque_area_min_max": [min(areas), max(areas)],
            "head": "medida humana pendente: a Forja nao localiza a cabeca", "world_scale": "ver ADR 0087 e o jogo"}


def contact(frames: list[Image.Image], scale: int) -> Image.Image:
    w, h = frames[0].size
    sheet = Image.new("RGBA", (w * len(frames), h * 2))
    for i, f in enumerate(frames):
        for row, bg in enumerate((LIGHT, DARK)):
            tile = Image.new("RGBA", (w, h), bg)
            tile.alpha_composite(f)
            sheet.paste(tile, (i * w, row * h))
    return upscale(sheet, scale)


def roundtrip(pkg: dict, folder: Path, engine: str | None) -> dict:
    files = anim.export(pkg["frames"], folder, pkg["who"], pkg["durations"], pkg["tags"], tuple(pkg["pivot"]),
                        previews=False)
    data = json.loads(Path(files["json"]).read_text(encoding="utf-8"))
    with Image.open(files["sheet"]) as im:
        strip = im.convert("RGBA")
    same = all(strip.crop((e["frame"]["x"], e["frame"]["y"], e["frame"]["x"] + e["frame"]["w"],
                           e["frame"]["y"] + e["frame"]["h"])).tobytes() == f.tobytes()
               for f, e in zip(pkg["frames"], data["frames"]))
    path = aseprite.from_frames(folder / f"{pkg['who']}.aseprite", pkg["frames"], durations=pkg["durations"],
                                tags=pkg["tags"], pivot=tuple(pkg["pivot"]))
    check = aseprite.verify(path, pkg["frames"])
    out = {"strip_json_frames_identical": same,
           "json_durations_equal": [e["duration"] for e in data["frames"]] == pkg["durations"],
           "aseprite_pixel_equal": check["pixel_equal"], "aseprite_durations_equal": check["durations"] == pkg["durations"],
           "aseprite_opened_in_app": False, "godot": None}
    if engine:
        _, rects = anim.strip(pkg["frames"])
        strip.save(folder / "s.png")
        godot.write(folder / "s.tres", godot.sprite_frames("res://s.png", rects, pkg["durations"], pkg["tags"], 10,
                                                           {t: pkg["loops"].get(t, True) for t, *_ in pkg["tags"]}))
        (folder / "check.gd").write_text(godot.CHECK_SCRIPT)
        (folder / "project.godot").write_text('config_version=5\n\n[application]\nconfig/name="forja"\n')
        subprocess.run([engine, "--headless", "--path", str(folder), "--import"], capture_output=True, timeout=300)
        run = subprocess.run([engine, "--headless", "--path", str(folder), "-s", "check.gd", "--", "res://s.tres"],
                             capture_output=True, text=True, timeout=120)
        line = next((x for x in run.stdout.splitlines() if x.startswith("FORJA_OK")), "")
        anims = {a[0]: a for a in json.loads(line.split("spriteframes", 1)[1])} if line else {}
        ok = bool(anims) and all(
            [round(x) for x, _ in anims[n][4]] == [rects[i][0] for i in range(a, b + 1)]
            and [round(ms * 100) for _, ms in anims[n][4]] == pkg["durations"][a:b + 1] for n, a, b, _ in pkg["tags"])
        out["godot"] = {"engine": "4.7.2-stable (tools/verify_godot.py)", "order_and_timing_equal": ok}
    return out


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--refs", type=Path, help="pasta onde gravar as referencias do piloto")
    args = parser.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    engine = os.environ.get("GODOT") or shutil.which("godot")
    present = [k for k in KEYS if os.environ.get(k)]
    result = {"date": "2026-10-23", "scope": "fatia vertical local; sem rede nem gasto",
              "commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
              "accepted_design_board": {"path": str(BOARD.relative_to(ROOT)), "sha256": sha(BOARD),
                                        "state": "design aceito para continuar (19/10); nao e spritesheet final"},
              "generation": {"status": "bloqueada" if not present else "chaves presentes, nao executada sem teto aprovado",
                             "credentials_present": present, "spend_limit_approved_by_owner": False,
                             "paid_calls": 0, "cost_usd": 0.0},
              "characters": {}}
    pal = palmod.load(palmod.ROOT / contracts.get("royal_64").palette)
    with tempfile.TemporaryDirectory(prefix="forja-fatia-") as tmp:
        for who, kind in (("dancarina", "royal_64"), ("sombra", "royal_80")):
            pkg = royals.load(who)
            ref = Path(tmp) / f"{who}-idle-0.png"
            pkg["frames"][0].save(ref)
            if args.refs:
                args.refs.mkdir(parents=True, exist_ok=True)
                pkg["frames"][0].save(args.refs / f"{who}-idle-0.png")
            moved = review.motion(pkg["frames"], pkg["tags"], pkg["holds"], "preserve", pkg["loops"])
            per_tag = {}
            for name, a, b, _ in pkg["tags"]:
                part = review.motion(pkg["frames"][a:b + 1], [(name, 0, b - a, "forward")],
                                     [{**h, "frame": h["frame"] - a, "same_as": h["same_as"] - a} for h in pkg["holds"]
                                      if a <= h["frame"] <= b and a <= h["same_as"] <= b], "preserve",
                                     pkg["loops"].get(name, True))
                per_tag[name] = {"frames": b - a + 1, "ms": sum(pkg["durations"][a:b + 1]),
                                 "flags": sorted({c["check"] for c in part["motion_checks"] if c["status"] == "flag"}),
                                 "blocking": [c["check"] for c in part["blocking"]]}
            idle_walk = pkg["frames"][:12]
            for scale in (1, 2):
                contact(idle_walk, scale).save(OUT / f"{who}-idle-walk-{scale}x.png")
            a, b = next((x[1], x[2]) for x in pkg["tags"] if x[0] == "walk")
            anim.save_gif(pkg["frames"][a:b + 1], pkg["durations"][a:b + 1], OUT / f"{who}-walk@2x.gif", scale=2)
            folder = Path(tmp) / who
            folder.mkdir()
            result["characters"][who] = {
                "kind": kind, "reference": {"source": f"art/export/royals/{who}.png quadro 0 (idle_right)",
                                            "rgba_sha256": pkg["rgba_sha256"][0],
                                            "state": "integrado (ADR 0087); animacao sem aprovacao artistica"},
                "atlas_sha256": pkg["atlas_sha256"], "measures": measures(pkg), "plans": plans(who, kind, ref, pal),
                "review": {"frames": len(pkg["frames"]), "declared_repeats": len(pkg["holds"]),
                           "unique_rasters": len({f.tobytes() for f in pkg["frames"]}),
                           "hidden_duplicates": sum(c["check"] == "hidden_duplicate" for c in moved["motion_checks"]),
                           "blocking": [c["check"] for c in moved["blocking"]], "per_tag": per_tag,
                           "artistic_approval": "pendente", "source": "quadros V15 existentes, nao geracao nova"},
                "roundtrip": roundtrip(pkg, folder, engine),
                "previews": [f"fatia/{who}-idle-walk-1x.png", f"fatia/{who}-idle-walk-2x.png", f"fatia/{who}-walk@2x.gif"]}
    (OUT / "fatia-vertical.json").write_text(json.dumps(result, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps({who: {"plans_ok": [p["ok"] for p in c["plans"]], "roundtrip": c["roundtrip"],
                            "review": {k: c["review"][k] for k in ("frames", "declared_repeats", "hidden_duplicates")}}
                      for who, c in result["characters"].items()}, indent=1))


if __name__ == "__main__":
    main()
