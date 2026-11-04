"""Ensaio de autoria repetivel: a mesma receita de entrada/estado/camara e os pixels exatos."""
from __future__ import annotations

import json
from pathlib import Path

from . import action_export, cast, fidelity, proof_io, study
from .review_evidence import text


def recipe(manifest: dict, given: dict | None = None) -> dict:
    actions = {a["name"]: a for a in manifest["actions"]}
    steps = [{"action": n, "cycles": 1, "input": "preview", "state": n, "camera": [0, 0]} for n in actions]
    if len(steps) > 1:
        steps.append(dict(steps[0]))
    data = given if given is not None else {"schema": "forja.replay/1", "steps": steps}
    if not isinstance(data, dict) or data.get("schema") != "forja.replay/1" or not isinstance(data.get("steps"), list) or not data["steps"]:
        raise ValueError("receita de ensaio invalida")
    events, at = [], 0
    for step in data["steps"]:
        if not isinstance(step, dict) or step.get("action") not in actions:
            raise ValueError("receita: acao desconhecida")
        cycles, camera = step.get("cycles"), step.get("camera")
        if type(cycles) is not int or not 1 <= cycles <= 20 or not all(text(step.get(k)) for k in ("input", "state")):
            raise ValueError("receita: ciclos 1..20, entrada e estado obrigatorios")
        if not isinstance(camera, list) or len(camera) != 2 or any(type(v) is not int for v in camera):
            raise ValueError("receita: camara em pixels inteiros")
        for _ in range(cycles):
            for i in actions[step["action"]]["playback"]:
                ms = manifest["frames"][i]["duration_ms"]
                events.append({"frame": i, "action": step["action"], "start_ms": at, "duration_ms": ms,
                               "input": step["input"], "state": step["state"], "camera": camera})
                at += ms
    if {e["action"] for e in events} != set(actions):
        raise ValueError("receita deve ensaiar todas as acoes exportadas")
    return {"recipe": data, "recipe_sha256": proof_io.digest(data), "events": events, "duration_ms": at,
            "scale": 1, "engine": "authoring_preview", "godot_test": "not_evaluated"}


def authority(ident: str | None, kind: str, out: Path, face_states: dict | None = None) -> tuple[dict, list[str]]:
    if not ident:
        if face_states:
            raise ValueError("estados faciais precisam de --character")
        return {}, []
    catalog = cast.load()
    entry = cast.character(catalog, ident)
    contract = cast.authority(catalog, entry)
    ch = fidelity.character(contract, entry["id"], entry.get("pose"))
    if ch["kind"] != kind:
        raise ValueError("o kind nao corresponde ao personagem do elenco")
    crop = fidelity.authority_crop(contract, ch)
    crop.save(out / "authority.png")
    decision = entry["design_decision"]
    states = (face_states or {}).get("states", [])
    if face_states and (face_states.get("character") != ch["id"] or
                        face_states.get("authority_crop_sha256") != ch["_authority_crop_sha256"]):
        raise ValueError("estados faciais de outro personagem ou autoridade")
    if not states:
        states = [{"id": ch["pose"], "orientation": "concept", "reference_sha256": ch["_authority_crop_sha256"],
                   "authorized_by": decision["by"], "date": decision["date"],
                   "instruction": "preservar a pose do conceito escolhido",
                   "invariants": [m["id"] for m in (ch.get("face_sheet") or {}).get("landmarks", [])]}]
    return {"character": ch["id"], "authority_crop_sha256": ch["_authority_crop_sha256"],
            "reference": "authority.png", "face_states": states,
            "shared_props": ch.get("shared_prop_constraints", []),
            "invariants": ch.get("prompt_invariants", [])}, ["authority.png"]


def create(source, out, kind, effect_layers=(), trim=False, character=None, replay=None, face_states=None) -> dict:
    from . import rehearsal_review, rehearsal_view
    out = Path(out)
    manifest = action_export.export(source, out, kind, effect_layers, trim)
    auth, files = authority(character, kind, out, face_states)
    manifest.update(authority=auth, replay=recipe(manifest, replay), study=study.context("adapt_concept"))
    manifest.pop("manifest_sha256")
    proof_io.seal(manifest, out, list(manifest["files"]) + files)
    proof_io.save(out / "review.template.json", rehearsal_review.template(manifest))
    proof_io.save(out / "recipe.json", manifest["replay"]["recipe"])
    rehearsal_view.write(out, manifest)
    return {"ok": action_export.verify(out / "manifest.json")["ok"], "manifest": str(out / "manifest.json"),
            "preview": str(out / "index.html"), "review_template": str(out / "review.template.json"),
            "recipe": str(out / "recipe.json"), "release_ready": False, "visual_review": "pending"}


def verify_replay(manifest: dict) -> bool:
    replay = manifest.get("replay")
    try:
        return isinstance(replay, dict) and replay == recipe(manifest, replay.get("recipe"))
    except (ValueError, KeyError, TypeError):
        return False


def compare(before, after) -> dict:
    a, b = (json.loads(Path(p).read_text(encoding="utf-8")) for p in (before, after))
    same = a.get("replay", {}).get("recipe_sha256") == b.get("replay", {}).get("recipe_sha256")
    return {"ok": action_export.verify(before)["ok"] and action_export.verify(after)["ok"] and same and
            a["canvas"] == b["canvas"] and a["pivot"] == b["pivot"] and verify_replay(a) and verify_replay(b) and
            a["replay"]["events"] == b["replay"]["events"] and len(a["frames"]) == len(b["frames"]),
            "same_recipe": same, "before": a["manifest_sha256"], "after": b["manifest_sha256"],
            "changed_frames": [i for i, pair in enumerate(zip(a["frames"], b["frames"])) if pair[0] != pair[1]],
            "same_frame_count": len(a["frames"]) == len(b["frames"]), "artistic_improvement": "not_evaluated"}
