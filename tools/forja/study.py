"""Metodo do estudo recebido: inferencias com fontes, nunca uma nova autoridade artistica."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

BOOK = Path(__file__).with_name("penusbmic_study.json")
ROOT = Path(__file__).resolve().parents[2]


def load() -> dict:
    data = json.loads(BOOK.read_text(encoding="utf-8"))
    if data.get("schema") != "forja.penusbmic/1":
        raise ValueError("estudo Penusbmic: schema invalido")
    if hashlib.sha256((ROOT / data["study"]).read_bytes()).hexdigest() != data["study_sha256"]:
        raise ValueError("estudo Penusbmic mudou: atualizar o indice de fontes")
    return data


def context(mode: str = "stylized") -> dict:
    data = load()
    return {"schema": data["schema"], "revision": hashlib.sha256(BOOK.read_bytes()).hexdigest(),
            "source": data["study"], "design_mode": "explore_unapproved" if mode == "stylized" else
            "scene_pilot" if mode == "scene" else "preserve_and_repair",
            "proposals": [p["id"] for p in data["proposals"]], "artistic_approval": "not_granted"}


def rules(mode: str, animated: bool = False) -> list[dict]:
    rows = []
    if mode == "scene":
        rows += [("P1-02", "Prove a small side-view scene at game scale before expanding: actor ruler, doorway or "
                  "bank, functional lower access, three depth planes, material junctions, day/night and seams."),
                 ("R2-03", "Build masses and circulation before texture. Woodland moss, fungi and mushrooms form "
                  "recognizable groups; confine procedural detail to chosen regions, then clean overlaps. "
                  "No universal density percentage and no isometric camera substitution.")]
    else:
        rows += [("P0-01", "Review wrist, hand, grip, object orientation and occluder together in every critical "
                  "pose. Preserve the same absolute shared-prop size; a hidden object is not a missing arm."),
                 ("P0-02", "Act within authorized facial states and orientations: preserve identity, asymmetry, "
                  "nose, beard and moustache through effort and damage. Missing reference evidence stays pending.")]
        if mode == "stylized":
            rows.append(("P1-01", "Only for designs without an accepted authority, compare native-scale alternatives "
                         "along silhouette, body proportions, facial acting and function. Avoid one repeated face. "
                         "An accepted concept must instead be preserved and repaired; rejected designs are never guides."))
        else:
            rows.append(("P1-01", "Preserve and repair the accepted design. Do not use variation exploration to replace "
                         "its face, silhouette or function, and never promote a rejected candidate to authority."))
    if animated:
        rows += [("P0-03", "Prove contact/support, leading and following parts, occlusion, entry and recovery before "
                  "effects. Inspect the body without VFX and the final composition; effects cannot hide known defects."),
                 ("R2-02", "Intentional glitch, flashes and particles need an explicit region and frame interval; "
                  "outside that window changes still need review. Never stabilize intentional acting globally."),
                 ("R2-01", "Keep native canvas, pivot, support and exact frame durations across action exports. "
                  "Storage trim must reconstruct the original canvas, never rescale the actor for larger VFX."),
                 ("P1-03", "Replay the same input/state/camera sequence after each edit, binding proof to exact "
                  "PNG, JSON and Aseprite hashes. An authoring preview is not a Godot runtime test.")]
    sources = {p["id"]: p["sources"] for p in load()["proposals"]}
    return [{"id": "penusbmic_" + key, "origin": "study:Penusbmic:" + key,
             "text": text, "sources": sources[key]} for key, text in rows]
