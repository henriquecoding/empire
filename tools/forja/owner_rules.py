"""Regras versionadas do dono; a mesma fonte chega ao terminal, prompts, MCP e entrega."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

from PIL import Image

from .equipment import image_sha

ROOT = Path(__file__).resolve().parents[2]
BOOK = Path(__file__).with_name("owner_rules.json")
CHARACTERS = ("royal_64", "royal_80", "troop_64", "character_s1", "character_s2", "character_s3")
COMMON = ("authority", "native_grid", "proportions", "contour", "hands_grip", "face",
          "equipment_shape", "materials", "revisions", "delivery_gate")


def load() -> dict:
    data = json.loads(BOOK.read_text(encoding="utf-8"))
    if data.get("schema") != "forja.owner_rules/1":
        raise ValueError("regras do dono: schema invalido")
    return data


def context(authority: dict | None = None) -> dict:
    data = load()
    documents = {name: hashlib.sha256((ROOT / name).read_bytes()).hexdigest()
                 for name in data["required_reading"]}
    digest = hashlib.sha256(BOOK.read_bytes() + json.dumps(documents, sort_keys=True).encode()).hexdigest()
    record = authority or {}
    return {"schema": data["schema"], "revision": digest, "required_reading": list(documents),
            "documents_sha256": documents, "character": record.get("character"),
            "authority_crop_sha256": record.get("crop_pixels_sha256"),
            "authority_sha256": record.get("authority_sha256")}


def prompt_rules(kind: str, animated: bool = False) -> list[dict]:
    ids = set(COMMON if kind in CHARACTERS else ("authority", "materials", "revisions", "scene_scale", "delivery_gate"))
    if animated:
        ids.add("animations")
    return [{"id": "owner_" + r["id"], "origin": "owner:Henrique", "text": r["prompt"]}
            for r in load()["rules"] if r["id"] in ids]


def bind_character(ch: dict, contract: dict) -> dict:
    if not contract.get("base") or not contract.get("authority", {}).get("file"):
        return ch
    with Image.open(Path(contract["base"]) / contract["authority"]["file"]) as source:
        crop = source.convert("RGBA").crop(tuple(ch["authority_crop_xyxy"]))
    ch["_authority_crop_sha256"] = image_sha(crop)
    return ch


def rejected(pixels_sha256: str) -> dict | None:
    return next((r for r in load().get("rejected_native_candidates", [])
                 if r["pixels_sha256"] == pixels_sha256), None)
