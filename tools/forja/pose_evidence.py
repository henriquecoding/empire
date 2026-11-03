"""Maos/objeto, identidade por estado e apoio: a geometria sozinha nao aprova nenhum deles."""
from __future__ import annotations

from .review_evidence import box, pending, text


def template() -> dict:
    return {"hands": [{"hand": side, **pending(), "contact": None, "arm": None, "object": None,
                       "visibility": None, "orientation": "", "occluder": None, "box": None,
                       "trajectory": "", "shared_dimensions": None} for side in ("left", "right")],
            "face": {**pending(), "state": "", "orientation": "", "box": None,
                     "invariants_preserved": []},
            "support": {**pending(), "phase": "", "contact": "", "point": None,
                        "leading_parts": [], "secondary_parts": [], "occlusion": ""},
            "body_without_vfx": pending(), "final_composition": pending()}


def hands(rows, size, r, label, shared_props) -> None:
    rows = rows if isinstance(rows, list) else []
    r.require(len(rows) == 2 and {h.get("hand") for h in rows if isinstance(h, dict)} == {"left", "right"},
              label + ": observar ambas as maos")
    for h in rows:
        if not r.evidence(h, label + ": mao"):
            continue
        r.require(h.get("arm") in ("connected", "occluded"), label + ": braco ausente/desligado", True)
        r.require(h.get("contact") in ("valid_grip", "empty_hand", "occluded"), label + ": pega invalida", True)
        r.require(h.get("visibility") in ("visible", "partial", "occluded"), label + ": visibilidade em falta")
        r.require(box(h.get("box"), size), label + ": caixa da mao/objeto invalida", True)
        r.require(text(h.get("orientation")) and text(h.get("trajectory")), label + ": orientacao/trajetoria em falta")
        if h.get("contact") == "empty_hand":
            r.require(h.get("object") is None, label + ": objeto declarado numa mao vazia", True)
        else:
            r.require(text(h.get("object")), label + ": identificar o objeto")
        if h.get("visibility") != "visible" or h.get("arm") == "occluded":
            r.require(text(h.get("occluder")), label + ": identificar o oclusor")
        for prop in shared_props:
            if h.get("object") == prop["id"]:
                dims = prop.get("native_shared_dimensions")
                r.require(dims is not None, label + ": medida partilhada ainda sem autoridade")
                if dims is not None:
                    r.require(h.get("shared_dimensions") == dims, label + ": tamanho absoluto do objeto diverge", True)


def check(row, size, r, label, authority) -> None:
    hands(row.get("hands"), size, r, label, authority.get("shared_props", []))
    for prop in authority.get("shared_props", []):
        observations = row.get("shared_props") or []
        found = [p for p in observations if isinstance(p, dict) and p.get("id") == prop["id"]]
        r.require(len(found) == 1, label + ": observar objeto partilhado " + prop["id"])
        dims = prop.get("native_shared_dimensions")
        r.require(dims is not None, label + ": medida do objeto partilhado sem autoridade")
        if len(found) == 1 and r.evidence(found[0], label + ": objeto partilhado"):
            r.require(found[0].get("visibility") in ("visible", "occluded", "absent"), label + ": visibilidade do objeto")
            if found[0].get("visibility") == "visible" and dims is not None:
                r.require(found[0].get("dimensions") == dims, label + ": dimensoes partilhadas divergentes", True)
    face = row.get("face")
    if r.evidence(face, label + ": rosto"):
        state = next((s for s in authority.get("face_states", []) if s.get("id") == face.get("state") and
                      s.get("orientation") == face.get("orientation")), None)
        r.require(state is not None, label + ": estado/orientacao facial sem referencia autorizada")
        r.require(box(face.get("box"), size), label + ": regiao do rosto invalida", True)
        if state:
            r.require(all(text(state.get(k)) for k in ("authorized_by", "date", "reference_sha256", "instruction")),
                      label + ": autorizacao facial incompleta")
            required = state.get("invariants") or []
            r.require(bool(required) and set(required) <= set(face.get("invariants_preserved") or []),
                      label + ": nariz, pelos e feicoes da autoridade por conferir")
    support = row.get("support")
    if r.evidence(support, label + ": apoio"):
        r.require(text(support.get("phase")) and text(support.get("occlusion")), label + ": fase/oclusao em falta")
        r.require(support.get("contact") in ("left_foot", "right_foot", "both", "airborne", "seated", "grounded"),
                  label + ": tipo de apoio invalido", True)
        r.require(isinstance(support.get("leading_parts"), list) and any(text(p) for p in support["leading_parts"]),
                  label + ": partes condutoras em falta")
        r.require(isinstance(support.get("secondary_parts"), list), label + ": partes secundarias em falta")
        if support.get("contact") != "airborne":
            p = support.get("point")
            r.require(isinstance(p, list) and len(p) == 2 and all(type(v) is int for v in p) and
                      all(0 <= p[i] < size[i] for i in (0, 1)), label + ": ponto de apoio invalido", True)
    for key in ("body_without_vfx", "final_composition"):
        r.evidence(row.get(key), label + ": " + key)
