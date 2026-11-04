"""Revisao semantica de cada quadro/acao, ligada ao ensaio e sem conceder aprovacao do dono."""
from __future__ import annotations

from . import effect_windows, pose_evidence, study
from .review_evidence import Review, pending

SCHEMA = "forja.rehearsal_review/1"
ACTION_CHECKS = ("entry", "support_changes", "occlusion_transitions", "recovery", "loop_or_exit",
                 "weapon_trajectory", "secondary_motion", "body_without_vfx", "final_composition")


def template(manifest: dict) -> dict:
    return {"schema": SCHEMA, "manifest_sha256": manifest["manifest_sha256"],
            "observer": {"author": "", "method": "", "date": ""},
            "views": {"native_1x": False, "integer_zoom": None, "light_background": False,
                      "dark_background": False, "side_by_side": False},
            "frames": [{**frame, **pose_evidence.template(), "shared_props": [
                {"id": p["id"], **pending(), "visibility": None, "dimensions": None}
                for p in manifest.get("authority", {}).get("shared_props", [])]} for frame in manifest["frames"]],
            "actions": [{"name": a["name"], "checks": {k: pending() for k in ACTION_CHECKS}}
                        for a in manifest["actions"]],
            "effect_windows": [], "effects_review": pending(), "replay_review": pending(),
            "note": "Evidencia incompleta fica pendente. A previa nao prova autoria nativa nem integracao Godot."}


def check(manifest: dict, doc: dict, actor=None, final=None) -> dict:
    r = Review()
    r.require(isinstance(doc, dict) and doc.get("schema") == SCHEMA, "schema de revisao invalido", True)
    if not isinstance(doc, dict):
        return r.result()
    r.require(doc.get("manifest_sha256") == manifest.get("manifest_sha256"), "revisao de outro ensaio", True)
    r.require(manifest.get("study", {}).get("revision") == study.context()["revision"], "estudo desatualizado", True)
    r.observer(doc)
    views = doc.get("views") or {}
    for key in ("native_1x", "light_background", "dark_background", "side_by_side"):
        r.require(views.get(key) is True, "vista por rever: " + key)
    r.require(type(views.get("integer_zoom")) is int and views["integer_zoom"] >= 2, "ampliacao inteira em falta")
    authority = manifest.get("authority") or {}
    r.require(bool(authority.get("authority_crop_sha256")), "conceito de autoridade em falta")
    rows = doc.get("frames") if isinstance(doc.get("frames"), list) else []
    r.require(len(rows) == len(manifest["frames"]), "numero de quadros da revisao diverge", True)
    for expected in manifest["frames"]:
        found = [row for row in rows if isinstance(row, dict) and row.get("index") == expected["index"]]
        label = "quadro " + str(expected["index"])
        r.require(len(found) == 1, label + ": observacao unica obrigatoria")
        if len(found) != 1:
            continue
        row = found[0]
        r.require(all(row.get(k) == v for k, v in expected.items()), label + ": pixels/tempo/pivot mudaram", True)
        pose_evidence.check(row, manifest["canvas"], r, label, authority)
    actions = doc.get("actions") if isinstance(doc.get("actions"), list) else []
    r.require(len(actions) == len(manifest["actions"]), "numero de acoes da revisao diverge", True)
    for action in manifest["actions"]:
        found = [a for a in actions if isinstance(a, dict) and a.get("name") == action["name"]]
        r.require(len(found) == 1, "revisao unica da acao " + action["name"])
        if len(found) == 1:
            checks = found[0].get("checks") or {}
            for key in ACTION_CHECKS:
                r.evidence(checks.get(key), action["name"] + ": " + key)
    try:
        windows = effect_windows.validate(doc.get("effect_windows"), len(manifest["frames"]), manifest["canvas"])
        if actor is not None and final is not None:
            outside = effect_windows.outside(actor, final, windows)
            r.require(not outside, "VFX fora da regiao/intervalo autorizado: " + str(outside), True)
        elif any(f["actor_sha256"] != f["final_sha256"] for f in manifest["frames"]):
            r.require(False, "pixels dos efeitos ainda por conferir")
    except ValueError as err:
        r.require(False, str(err), True)
    r.evidence(doc.get("effects_review"), "revisao dos efeitos (ou ausencia deles)")
    r.evidence(doc.get("replay_review"), "entrada/acao/recuperacao no mesmo ensaio")
    return r.result()
