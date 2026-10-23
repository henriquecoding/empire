"""Ler o pacote de monarcas do projeto (V15, ADR 0087) para rever e exportar com a Forja — so leitura.

O atlas e os metadados por personagem vivem em `art/export/royals/` e
`art/source/royals_v15/`. Cada quadro diz de que pose comum veio; quando uma pose
volta (o levantar que reutiliza a queda invertida, uma pausa), isso e uma
repeticao DECLARADA, e a revisao trata-a como tal em vez de a chamar duplicado
escondido. Nada aqui escreve em `art/`.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
EXPORT = ROOT / "art/export/royals"
SOURCE = ROOT / "art/source/royals_v15"
KINDS = {64: "royal_64", 80: "royal_80"}


def load(who: str, direction: str = "right") -> dict:
    """Os quadros de uma direcao, na ordem do atlas, com tags, duracoes e repeticoes declaradas."""
    meta = json.loads((SOURCE / f"{who}.json").read_text(encoding="utf-8"))
    with Image.open(EXPORT / f"{who}.png") as im:
        atlas = im.convert("RGBA")
    frames, durations, tags, holds, hashes, seen = [], [], [], [], [], {}
    for action in meta["animations"]:
        if action["direction"] != direction:
            continue
        start = len(frames)
        for f in action["frames"]:
            r = f["rect"]
            frame = atlas.crop((r["x"], r["y"], r["x"] + r["w"], r["y"] + r["h"]))
            src = f["source"]
            key = (src["kind"], src["frame"])
            i = len(frames)
            if key in seen:
                why = "pausa declarada" if src.get("held") else (
                    "reutilizacao invertida declarada" if action.get("reusedInReverse") else "pose comum reutilizada")
                holds.append({"frame": i, "same_as": seen[key], "ms": None,
                              "reason": f"V15 {action['name']}: {why} ({src['kind']} {src['frame']})"})
            seen.setdefault(key, i)
            frames.append(frame)
            durations.append(f["durationMs"])
            hashes.append(f["rgbaSha256"])
        tags.append((action["action"], start, len(frames) - 1, "forward"))
    return {"who": who, "kind": KINDS.get(meta["width"]), "size": [meta["width"], meta["height"]],
            "pivot": meta["animations"][0]["pivot"], "frames": frames, "durations": durations, "tags": tags,
            "holds": holds, "rgba_sha256": hashes, "loops": {a["action"]: a["loop"] for a in meta["animations"]},
            "unique_raster_frames": meta["uniqueRasterFrames"], "frame_count": meta["frameCount"],
            "atlas_sha256": hashlib.sha256((EXPORT / f"{who}.png").read_bytes()).hexdigest()}
