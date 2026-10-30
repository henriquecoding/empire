"""Revisão da sequência exata por quadro/ação e aprovação separada do dono."""
from __future__ import annotations

from . import delivery_review, owner_rules, sequence, sequence_checks, timeline
from .equipment import image_sha

SCHEMA = "forja.animation_review/1"
APPROVALS = "forja.animation_approvals/1"
EXTRA = ("limbs", "support", "volume")
ACTION_CHECKS = ("key_poses", "articulation", "timing", "entry_transition", "exit_transition")


def _findings(clip, ch: dict) -> list[dict]:
    motion = sequence_checks.automatic(clip, ch)["motion"]
    return [{"id": sequence.digest(c), "check": c, "status": "pending", "evidence": ""}
            for c in motion["motion_checks"] if c["status"] in ("fail", "flag")]


def template(clip, ch: dict) -> dict:
    frames = []
    for i, frame in enumerate(clip.frames):
        checks = delivery_review.template(ch, frame)["checks"]
        checks += [{"id": k, "status": "pending", "evidence": "", "candidate_box": None, "authority_box": None}
                   for k in EXTRA]
        frames.append({"frame": i, "pixels_sha256": image_sha(frame), "checks": checks})
    return {"schema": SCHEMA, "sequence_sha256": clip.sha, "character": ch["id"],
            "character_contract_sha256": sequence.digest(ch),
            "authority_crop_sha256": ch.get("_authority_crop_sha256"),
            "owner_rules_revision": owner_rules.context()["revision"],
            "observer": {"author": "", "method": "", "date": ""},
            "views": {"native_1x": False, "integer_zoom": None, "light_background": False,
                      "dark_background": False, "side_by_side": False, "real_speed": False,
                      "frame_step": False, "onion_skin": False},
            "frames": frames, "tags": [{"name": t["name"], "checks": [
                {"id": k, "status": "pending", "evidence": ""}
                for k in ACTION_CHECKS + (("loop_seam",) if t["loop"] else ())]}
                for t in timeline.playback(clip.data["tags"])], "findings": _findings(clip, ch),
            "note": "preencher so apos observar a sequencia e conceito exatos; isto nao aprova arte pelo dono"}


def _items(rows: object, expected: list, key: str, blocked: list, pending: list, prefix: str) -> dict:
    if not isinstance(rows, list) or any(not isinstance(r, dict) for r in rows):
        blocked.append(prefix + ": lista invalida")
        return {}
    result = {}
    for ident in expected:
        found = [r for r in rows if r.get(key) == ident]
        if len(found) != 1:
            pending.append(prefix + f": falta registo unico de {ident}")
        else:
            result[ident] = found[0]
    if any(r.get(key) not in expected for r in rows):
        blocked.append(prefix + ": registo inesperado")
    return result


def _status(row: dict, blocked: list, pending: list, label: str) -> bool:
    if row.get("status") == "fail":
        blocked.append(label + ": defeito observado")
    elif row.get("status") != "pass" or not isinstance(row.get("evidence"), str) or not row["evidence"].strip():
        pending.append(label + ": falta evidencia revista")
    else:
        return True
    return False


def check(clip, ch: dict, visual: dict | None = None, approvals: dict | None = None,
          resolutions: dict | None = None) -> dict:
    auto = sequence_checks.automatic(clip, ch, resolutions)
    blocked, pending = list(auto["blocked"]), list(auto["pending"])
    expected = template(clip, ch)
    if visual is None:
        pending.append("revisao completa da sequencia em falta")
    elif not isinstance(visual, dict):
        blocked.append("revisao de sequencia invalida: esperado um objeto")
    else:
        for key in ("schema", "sequence_sha256", "character", "character_contract_sha256",
                    "authority_crop_sha256", "owner_rules_revision"):
            if visual.get(key) != expected[key]:
                blocked.append(key + ": revisao de outros pixels, timeline, regras ou autoridade")
        who = visual.get("observer") or {}
        if not isinstance(who, dict) or any(not isinstance(who.get(k), str) or not who[k].strip()
                                         for k in ("author", "method", "date")):
            pending.append("observador, metodo ou data em falta")
        views = visual.get("views") or {}
        if not isinstance(views, dict) or any(views.get(k) is not True for k in expected["views"] if k != "integer_zoom"):
            pending.append("faltam vistas da sequencia a 1x, fundos, conceito, velocidade real e quadro a quadro")
        if not isinstance(views, dict) or type(views.get("integer_zoom")) is not int or views["integer_zoom"] < 2:
            pending.append("ampliacao inteira em falta")
        rows = _items(visual.get("frames"), list(range(len(clip.frames))), "frame", blocked, pending, "quadros")
        for i, row in rows.items():
            if row.get("pixels_sha256") != image_sha(clip.frames[i]):
                blocked.append(f"quadro {i}: outros pixels")
            ids = owner_rules.load()["review_checks"] + list(EXTRA)
            items = _items(row.get("checks"), ids, "id", blocked, pending, f"quadro {i}")
            for key, item in items.items():
                if _status(item, blocked, pending, f"quadro {i}/{key}"):
                    if not delivery_review._box(item.get("candidate_box"), [0, 0, *clip.frames[i].size]) or \
                            not delivery_review._box(item.get("authority_box"), ch["authority_crop_xyxy"]):
                        blocked.append(f"quadro {i}/{key}: caixas invalidas")
        tags = _items(visual.get("tags"), [t["name"] for t in expected["tags"]], "name", blocked, pending, "acoes")
        for name, row in tags.items():
            source = next(t for t in expected["tags"] if t["name"] == name)
            items = _items(row.get("checks"), [c["id"] for c in source["checks"]], "id", blocked, pending, name)
            for key, item in items.items():
                _status(item, blocked, pending, name + "/" + key)
        found = _items(visual.get("findings"), [r["id"] for r in expected["findings"]], "id", blocked, pending, "achados")
        for key, row in found.items():
            _status(row, blocked, pending, "achado " + key[:8])
    approval = "pending"
    if approvals is not None:
        if not isinstance(approvals, dict) or approvals.get("schema") != APPROVALS or \
                not isinstance(approvals.get("entries"), list) or any(
                    not isinstance(r, dict) for r in approvals["entries"]):
            blocked.append("registo de aprovacao de sequencias invalido")
        else:
            entries = [r for r in approvals.get("entries", []) if r.get("sequence_sha256") == clip.sha]
            if len(entries) > 1:
                blocked.append("decisao do dono ambigua para a sequencia")
            elif entries:
                e = entries[0]
                if e.get("decided_by") != owner_rules.load()["owner"] or any(
                        not isinstance(e.get(k), str) or not e[k].strip() for k in ("date", "evidence")):
                    blocked.append("decisao sem dono, data ou evidencia")
                elif e.get("state") == "rejected":
                    blocked.append("sequencia rejeitada pelo dono")
                elif e.get("state") == "approved":
                    approval = "approved"
                else:
                    blocked.append("estado de aprovacao invalido")
    ready = not blocked and not pending
    return {"sequence_sha256": clip.sha, "character": ch["id"], "ready_for_review": ready,
            "release_ready": ready and approval == "approved", "owner_approval": approval,
            "status": "blocked" if blocked else "pending" if pending else "pass", "blocking": blocked,
            "pending": pending, "label": "release" if ready and approval == "approved" else "study",
            "note": "o programa valida os registos; a observacao e aprovacao artistica pertencem a quem as declara"}
