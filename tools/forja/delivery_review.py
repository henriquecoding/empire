"""Portao de producao: evidencia visual ligada aos pixels e as regras, sem aprovar o mestre."""
from __future__ import annotations

from PIL import Image

from . import owner_rules
from .equipment import image_sha

SCHEMA = "forja.owner_review/1"


def template(ch: dict, image: Image.Image) -> dict:
    return {"schema": SCHEMA, "revision": owner_rules.context()["revision"],
            "image_sha256": image_sha(image), "character": ch.get("id"),
            "authority_crop_sha256": ch.get("_authority_crop_sha256"),
            "views": {"native_1x": False, "integer_zoom": None, "light_background": False,
                      "dark_background": False, "side_by_side": False},
            "checks": [{"id": key, "status": "pending", "evidence": "",
                        "candidate_box": None, "authority_box": None}
                       for key in owner_rules.load()["review_checks"]],
            "note": "Preencher olhando a imagem exata; contacto e contagens nao provam pega nem personalidade."}


def _box(box, bounds) -> bool:
    return isinstance(box, list) and len(box) == 4 and all(type(v) is int for v in box) and bool(bounds) and \
        bounds[0] <= box[0] < box[2] <= bounds[2] and bounds[1] <= box[1] < box[3] <= bounds[3]


def measurements(image: Image.Image) -> dict:
    rgba = image.convert("RGBA")
    box = rgba.getchannel("A").getbbox()
    return {"canvas": list(rgba.size), "occupied_bbox": list(box) if box else None,
            "occupied_size": [box[2] - box[0], box[3] - box[1]] if box else [0, 0],
            "pixels_changed_by_review": 0,
            "note": "medidas, nao uma nota de qualidade nem um limiar de preenchimento"}


def check(ch: dict, image: Image.Image, forge: dict | None, visual: dict | None) -> dict:
    measured = measurements(image)
    if ch.get("kind") not in owner_rules.CHARACTERS:
        return {"status": "not_applicable", "ready_for_review": True, "blocking": [], "pending": [],
                "measurements": measured}
    blocking, pending = [], []
    sha, current = image_sha(image), owner_rules.context()["revision"]
    bad = owner_rules.rejected(sha)
    if bad:
        blocking.append("candidato de entrega rejeitada: " + bad["reason"])
    if list(image.size) != ch.get("target_canvas"):
        blocking.append("tela nao corresponde ao contrato do personagem")
    chain = (forge or {}).get("lineage") or {}
    consulted = chain.get("owner_rules") or (forge or {}).get("owner_rules") or {}
    if not isinstance(consulted, dict):
        blocking.append("consulta das regras invalida")
        consulted = {}
    if not consulted:
        pending.append("consulta das regras ausente na origem: compilar e conservar --expect e --lineage")
    elif consulted.get("revision") != current:
        blocking.append("consulta das regras desatualizada: consultar e planear de novo")
    elif consulted.get("character") != ch.get("id") or not consulted.get("authority_crop_sha256"):
        blocking.append("consulta nao esta presa a autoridade deste personagem")
    expected_authority = ch.get("_authority_crop_sha256")
    if expected_authority and consulted and consulted.get("authority_crop_sha256") != expected_authority:
        blocking.append("a autoridade consultada nao e o conceito atual do personagem")
    if not chain:
        pending.append("sem cadeia da fonte ate aos pixels entregues")
    elif chain.get("output_sha256") != sha:
        blocking.append("a cadeia e de outra imagem")
    for stage in chain.get("stages", []):
        if not isinstance(stage, dict):
            blocking.append("etapa invalida na cadeia")
            continue
        grid = stage.get("grid") or stage.get("transform", {}).get("grid") or {}
        if grid.get("origin") == "deliberately_reduced":
            blocking.append("reducao com perda na cadeia: diagnostico; redesenhar na grade nativa antes da entrega")
            break
    doc = (visual or {}).get("owner_rules")
    if doc and not isinstance(doc, dict):
        blocking.append("revisao das regras invalida")
        doc = None
    if not doc:
        pending.append("revisao das regras do dono ausente")
    else:
        if doc.get("schema") != SCHEMA:
            blocking.append("schema da revisao das regras invalido")
        if doc.get("revision") != current:
            blocking.append("revisao usa regras desatualizadas")
        if doc.get("image_sha256") != sha or doc.get("character") != ch.get("id"):
            blocking.append("revisao e de outra imagem ou personagem")
        authority = expected_authority or consulted.get("authority_crop_sha256")
        if not authority or doc.get("authority_crop_sha256") != authority:
            blocking.append("revisao nao compara o conceito de autoridade exato")
        observer = (visual or {}).get("observer") or {}
        if not isinstance(observer, dict):
            observer = {}
        if any(not isinstance(observer.get(k), str) or not observer[k].strip() for k in ("author", "method", "date")):
            pending.append("revisao sem observador, metodo ou data")
        views = doc.get("views") or {}
        if not isinstance(views, dict):
            views = {}
        if any(views.get(k) is not True for k in ("native_1x", "light_background", "dark_background", "side_by_side")):
            pending.append("ver a 1x, em fundo claro/escuro e lado a lado com o conceito")
        zoom = views.get("integer_zoom")
        if type(zoom) is not int or zoom < 2:
            pending.append("revisao sem ampliacao inteira")
        checks = doc.get("checks") or []
        if not isinstance(checks, list) or any(not isinstance(c, dict) for c in checks):
            blocking.append("lista de verificacoes invalida")
            checks = []
        for key in owner_rules.load()["review_checks"]:
            found = [c for c in checks if c.get("id") == key]
            if len(found) != 1:
                pending.append(key + ": falta verificacao unica")
                continue
            item = found[0]
            if item.get("status") == "fail":
                blocking.append(key + ": defeito apontado pelo observador")
            elif item.get("status") != "pass" or not isinstance(item.get("evidence"), str) or not item["evidence"].strip():
                pending.append(key + ": falta evidencia revista")
            else:
                if not _box(item.get("candidate_box"), [0, 0, image.width, image.height]):
                    blocking.append(key + ": caixa do candidato invalida")
                if not _box(item.get("authority_box"), ch.get("authority_crop_xyxy")):
                    blocking.append(key + ": caixa na autoridade invalida")
    return {"status": "blocked" if blocking else "pending" if pending else "pass",
            "ready_for_review": not blocking and not pending, "blocking": blocking, "pending": pending,
            "measurements": measured, "owner_approval": "not_granted",
            "note": "evidencia declarada por quem olha; o programa nao determina sozinho qualidade artistica"}
