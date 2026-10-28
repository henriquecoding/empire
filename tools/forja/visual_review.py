"""`forja.visual_review/1`: o que um observador com visao viu numa imagem exata (FORJA-10, P0).

O nucleo mede regioes anotadas; nao descobre sozinho que um segmento cinzento entre as maos nao e parte do arco,
nem que um sorriso mudou. Esta etapa regista essa observacao, antes do pedido (fase `reference`, sobre o recorte de
autoridade) e depois do retorno (fase `candidate`), e alimenta os contratos que ja existem: a observacao do
`forja equip`, os `reference_issue_reviews` e a identidade do `forja fidelity`. Nao substitui a geometria por uma
opiniao, e nao tem nota: os modelos de visao erram precisamente em relacoes finas de posicao e contacto
(Rahmanzadehgervi et al., "Vision language models are blind", arXiv 2407.06581), por isso cada achado leva caixa,
evidencia e certeza, e o que toca em geometria volta a ser medido.

Regras que o validador impoe:
- a revisao e da imagem pelo hash dos pixels (`image_sha`); outra imagem, outra revisao;
- caixas e ancoras dentro da tela; estado de cada regiao `observed`, `inferred` ou `occluded` (com quem tapa);
- uma parte tapada nao e uma parte ausente; a classe declarada pelo dono nao muda pela observacao;
- reparo so se declara sobre a imagem nova (fase `candidate`), com caixa e evidencia;
- um achado certo de defeito sem decisao do dono bloqueia; a incerteza fica visivel, nunca vira `pass`.
"""
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image

from .equipment import OBS_SCHEMA, UNCERTAINTY, image_sha

SCHEMA = "forja.visual_review/1"
PHASES = ("reference", "candidate")
STATES = ("observed", "inferred", "occluded")
CERTAINTY = ("certain", "probable", "uncertain")
CATEGORIES = ("equipment_defect", "unidentified_fragment", "missing_part", "identity_change", "pose_change",
              "anatomy", "class_mismatch", "color_material", "detail_preserved", "other")
DEFECTS = ("equipment_defect", "unidentified_fragment", "missing_part", "identity_change", "pose_change", "anatomy",
           "class_mismatch")
ACTIONS = ("repair", "keep", "ask_owner", "none")
INVARIANT = ("preserved", "changed", "uncertain", "not_visible")
CLAIMS = ("fixed", "still_present", "uncertain")


def load(path: str | Path) -> dict:
    try:
        data = json.loads(Path(path).read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise ValueError(f"revisao visual {path}: JSON invalido ({exc.msg}, linha {exc.lineno})") from exc
    if not isinstance(data, dict):
        raise ValueError(f"revisao visual {path}: esperado um objeto JSON")
    return data


def _box(b, size) -> bool:
    return (isinstance(b, list) and len(b) == 4 and all(type(v) is int for v in b)
            and 0 <= b[0] < b[2] <= size[0] and 0 <= b[1] < b[3] <= size[1])


def _meets(a, b) -> bool:
    return a[0] < b[2] and b[0] < a[2] and a[1] < b[3] and b[1] < a[3]


def validate(rev: dict, image: Image.Image, ch: dict | None = None) -> list[str]:
    errors = [] if rev.get("schema") == SCHEMA else [f"schema: esperado {SCHEMA}"]
    phase, size, sha = rev.get("phase"), image.size, image_sha(image)
    if phase not in PHASES:
        errors.append(f"fase {phase!r}: use {', '.join(PHASES)}")
    got = rev.get("image") or {}
    if got.get("sha256") != sha:
        errors.append(f"a revisao e de outra imagem (hash {str(got.get('sha256'))[:12]}..., esta {sha[:12]}...): "
                      "observe de novo depois de cada mudanca")
    if got.get("size") != list(size):
        errors.append(f"tamanho declarado {got.get('size')} e nao {list(size)}")
    who = rev.get("observer") or {}
    errors += [f"observer sem {k}" for k in ("author", "method", "date") if not who.get(k)]
    if "model" not in who:
        errors.append("observer sem model (null para uma pessoa)")
    subject = rev.get("subject") or {}
    if ch is not None:
        if subject.get("declared_role") != ch.get("role"):
            errors.append(f"class_override: a revisao diz {subject.get('declared_role')!r}, o dono declarou "
                          f"{ch.get('role')!r}; a observacao nao muda a classe")
        if subject.get("character") != ch.get("id"):
            errors.append(f"personagem {subject.get('character')!r} e nao {ch.get('id')!r}")
    regions = rev.get("regions") or {}
    for name, r in regions.items():
        if not _box(r.get("box"), size):
            errors.append(f"regiao {name}: caixa {r.get('box')} invalida ou fora da tela {list(size)}")
        if r.get("state") not in STATES:
            errors.append(f"regiao {name}: estado {r.get('state')!r} (use {', '.join(STATES)})")
        if r.get("uncertainty", "baixa") not in UNCERTAINTY:
            errors.append(f"regiao {name}: incerteza {r.get('uncertainty')!r} (use {', '.join(UNCERTAINTY)})")
        if r.get("state") == "occluded" and r.get("occluded_by") not in regions:
            errors.append(f"regiao {name}: tapada por {r.get('occluded_by')!r}, que nao foi observada")
    for name, a in (rev.get("anchors") or {}).items():
        p = a.get("point") if isinstance(a, dict) else None
        if not (isinstance(p, list) and len(p) == 2 and all(type(v) is int for v in p)
                and 0 <= p[0] < size[0] and 0 <= p[1] < size[1]):
            errors.append(f"ancora {name}: ponto {p} fora da tela {list(size)}")
        elif a.get("state") not in ("observed", "inferred"):
            errors.append(f"ancora {name}: estado {a.get('state')!r} (observed ou inferred; tapada nao e ponto)")
    hidden = [r["box"] for r in regions.values() if r.get("state") == "occluded" and _box(r.get("box"), size)]
    ids = [f.get("id") for f in rev.get("findings", [])]
    for f in rev.get("findings", []):
        name = f.get("id")
        if not name or ids.count(name) > 1:
            errors.append(f"achado {name!r}: id em falta ou repetido")
        for key, allowed in (("category", CATEGORIES), ("state", STATES), ("certainty", CERTAINTY),
                             ("action", ACTIONS)):
            if f.get(key) not in allowed:
                errors.append(f"achado {name}: {key} {f.get(key)!r} (use {', '.join(allowed)})")
        if not _box(f.get("box"), size):
            errors.append(f"achado {name}: caixa {f.get('box')} invalida ou fora da tela {list(size)}")
        elif f.get("category") == "missing_part" and (f.get("state") == "occluded" or
                                                       any(_meets(f["box"], h) for h in hidden)):
            errors.append(f"achado {name}: parte tapada nao e parte ausente; declare a oclusao e deixe inconclusivo")
        errors += [f"achado {name}: sem {k}" for k in ("evidence", "description") if not str(f.get(k, "")).strip()]
    claims = rev.get("repair_claims") or []
    if claims and phase != "candidate":
        errors.append("repair_claims so na fase candidate: um reparo prova-se na imagem nova, nao na referencia")
    known = {i["id"] for i in (ch or {}).get("reference_issues", [])}
    for c in claims:
        if c.get("status") not in CLAIMS:
            errors.append(f"reparo {c.get('issue')}: estado {c.get('status')!r} (use {', '.join(CLAIMS)})")
        if ch is not None and c.get("issue") not in known:
            errors.append(f"reparo {c.get('issue')!r}: nao e um reference_issue do contrato")
        if not _box(c.get("box"), size) or not str(c.get("evidence", "")).strip():
            errors.append(f"reparo {c.get('issue')}: sem caixa valida ou sem evidencia na imagem")
    for c in rev.get("invariant_checks", []):
        if c.get("status") not in INVARIANT or not str(c.get("evidence", "")).strip():
            errors.append(f"invariante {c.get('invariant')!r}: estado {c.get('status')!r} ou sem evidencia")
    return errors


def _covered(f: dict, ch: dict | None) -> dict | None:
    issues = (ch or {}).get("reference_issues", [])
    return next((i for i in issues if i["id"] == f.get("reference_issue")), None)


def state(rev: dict, image: Image.Image, ch: dict | None = None) -> dict:
    """pass, pending ou blocked, com o que bloqueia e o que continua incerto. Invalida: `invalid`, sem estado."""
    errors = validate(rev, image, ch)
    if errors:
        return {"status": "invalid", "errors": errors, "blocking": [], "uncertain": [], "known_issues": []}
    blocking, uncertain, known = [], [], []
    for f in rev.get("findings", []):
        line = f"{f['id']} ({f['category']}, {f['certainty']}): {f['description']}"
        if f["certainty"] != "certain" or f["category"] not in DEFECTS:
            if f["category"] in DEFECTS:
                uncertain.append(line)
            continue
        issue = _covered(f, ch)
        if issue and (rev["phase"] == "reference" or issue.get("disposition") == "preserve_intentional"):
            known.append(f"{issue['id']} ({issue.get('disposition')}): {f['description']}")
        elif rev["phase"] == "reference":
            blocking.append(f"{line} — sem decisao do dono em reference_issues")
        else:
            blocking.append(line)
    claims = {c["issue"]: c for c in rev.get("repair_claims", [])}
    if rev["phase"] == "candidate":
        for issue in (ch or {}).get("reference_issues", []):
            if issue.get("disposition") != "repair":
                continue
            c = claims.get(issue["id"])
            if c and c["status"] == "still_present":
                blocking.append(f"{issue['id']}: o defeito da referencia continua nesta imagem ({c['evidence']})")
            elif not c or c["status"] != "fixed" or c.get("certainty", "certain") != "certain":
                uncertain.append(f"{issue['id']}: reparo sem prova certa nesta imagem")
    checks = {c["invariant"]: c for c in rev.get("invariant_checks", [])}
    for inv in (ch or {}).get("required_invariants", []) if rev["phase"] == "candidate" else []:
        c = checks.get(inv)
        if c and c["status"] == "changed":
            blocking.append(f"invariante mudou: {inv} ({c['evidence']})")
        elif not c or c["status"] != "preserved":
            uncertain.append(f"invariante sem confirmacao: {inv}")
    status = "blocked" if blocking else "pending" if uncertain and rev["phase"] == "candidate" else "pass"
    return {"status": status, "phase": rev["phase"], "blocking": blocking, "uncertain": uncertain,
            "known_issues": known, "image_sha256": rev["image"]["sha256"], "observer": rev["observer"],
            "note": "observacao de quem viu, com incerteza; a geometria e o dono continuam a decidir"}


def for_reference(base: str | Path, ch: dict, crop: Image.Image) -> dict:
    """Antes do pedido: a revisao da fase reference ligada no contrato (`visual_review.reference`) sobre o recorte."""
    path = (ch.get("visual_review") or {}).get("reference")
    if not path:
        return {"errors": [], "notes": [f"{ch['id']}: observacao visual da referencia pendente (forja visual "
                                        "--phase reference): identidade e equipamento ficam por conferir"]}
    st = state(load(Path(base) / path), crop, ch)
    if st["status"] == "invalid":
        return {"errors": [f"revisao visual da referencia: {e}" for e in st["errors"]], "notes": []}
    return {"errors": [f"achado visual da referencia: {b}" for b in st["blocking"]],
            "notes": [f"referencia, problema conhecido: {k}" for k in st["known_issues"]]
            + [f"referencia, incerto: {u}" for u in st["uncertain"]]}


def observation(rev: dict) -> dict:
    """A observacao `forja.observation/1` do forja equip: o tapado fica de fora (inconclusivo), o inferido incerto."""
    regions, occluded = {}, {}
    for name, r in rev.get("regions", {}).items():
        if r["state"] == "occluded":
            occluded[name] = r.get("occluded_by")
            continue
        level = r.get("uncertainty", "baixa")
        if r["state"] == "inferred" and level == "baixa":
            level = "media"
        regions[name] = {k: v for k, v in r.items() if k in ("box", "colors", "exclude", "note")}
        regions[name]["uncertainty"] = level
    who = dict(rev["observer"], method=f"{rev['observer']['method']} ({SCHEMA})")
    return {"schema": OBS_SCHEMA, "image_sha256": rev["image"]["sha256"], "observer": who, "regions": regions,
            "anchors": {k: a["point"] for k, a in rev.get("anchors", {}).items()}, "occluded": occluded}


def issue_reviews(rev: dict) -> list[dict]:
    """Os registos `reference_issue_reviews` desta imagem, um por reparo declarado, com a evidencia da caixa."""
    out = []
    for c in rev.get("repair_claims", []):
        certain = c.get("certainty", "certain") == "certain"
        status = {"fixed": "pass" if certain else "pending", "still_present": "fail"}.get(c["status"], "pending")
        out.append({"id": c["issue"], "pixels_sha256": rev["image"]["sha256"], "status": status,
                    "reviewed_by": rev["observer"]["author"], "date": rev["observer"]["date"],
                    "method": rev["observer"]["method"], "box": c["box"],
                    "observation": c["evidence"], "source": SCHEMA})
    return out
