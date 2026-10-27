"""A autoridade de cada referencia: conceito, adaptacao em revisao, mestre aprovado ou rejeitada (FORJA-06).

Solucao de 27/10, §1 e §7.1: o desenho recupera-se antes de se proteger, e proteger o ultimo resultado rejeitado so
congelava a descaracterizacao. Por isso cada imagem que entra num pedido ou numa edicao local tem um estado
registado, com o hash dos pixels (o mesmo da observacao), e a ultima saida nao substitui a referencia so por ser mais
recente. O registo (`forja.refs/1`) e escrito por quem decide; a Forja le-o e acrescenta estados, nunca uma
aprovacao: `approved` e `rejected` dizem quem decidiu e quando, e so o dono escreve `approved`. Uma referencia fora do
registo fica `unrecorded`, e o prompt nao a chama aprovada.
"""
from __future__ import annotations

import io
import json
from pathlib import Path

from PIL import Image

from .equipment import image_sha

SCHEMA = "forja.refs/1"
STATES = ("concept", "adaptation_in_review", "approved", "rejected")
UNRECORDED = "unrecorded"
DECIDED = ("approved", "rejected")
PROMPT_ROLE = {"approved": "identity", "adaptation_in_review": "identity_review", "concept": "concept",
               UNRECORDED: "identity_unrecorded"}
FAMILY = {"identity_review": "identity", "identity_unrecorded": "identity", "concept": "identity"}


def family(role: str) -> str:
    """O papel que o gerador conhece (identity, style, palette, layout), qualquer que seja o estado."""
    return FAMILY.get(role, role)


def validate(reg: dict, base: Path) -> list[str]:
    """Os erros do registo (lista vazia: valido), com cada ficheiro conferido pelo hash dos pixels."""
    errors = [] if reg.get("schema") == SCHEMA else [f"schema: esperado {SCHEMA}"]
    seen: dict[str, str] = {}
    ids = [e.get("id") for e in reg.get("entries", [])]
    for e in reg.get("entries", []):
        name = e.get("id") or "?"
        if not e.get("id") or ids.count(e["id"]) > 1:
            errors.append(f"{name}: id em falta ou repetido")
        if e.get("state") not in STATES:
            errors.append(f"{name}: estado {e.get('state')!r} (use {', '.join(STATES)})")
        if e.get("state") in DECIDED and not (e.get("decided_by") and e.get("date")):
            errors.append(f"{name}: {e.get('state')} pede decided_by e date (quem decidiu e quando)")
        if e.get("derived_from") and e["derived_from"] not in ids:
            errors.append(f"{name}: derived_from {e['derived_from']!r} nao esta no registo")
        path = base / str(e.get("file", ""))
        if not e.get("file") or not path.is_file():
            errors.append(f"{name}: ficheiro {e.get('file')!r} nao existe")
            continue
        with Image.open(path) as im:
            got = image_sha(im)
        if got != e.get("pixels_sha256"):
            errors.append(f"{name}: a imagem mudou depois do registo (pixels {got[:12]}, registados "
                          f"{str(e.get('pixels_sha256'))[:12]}): registe-a de novo")
        if got in seen:
            errors.append(f"{name}: os mesmos pixels que {seen[got]}")
        seen[got] = name
    return errors


def load(path: str | Path) -> dict:
    path = Path(path)
    reg = json.loads(path.read_text(encoding="utf-8"))
    errors = validate(reg, path.parent)
    if errors:
        raise ValueError("registo de referencias invalido: " + "; ".join(errors))
    return {**reg, "path": str(path)}


def lookup(reg: dict | None, image: Image.Image) -> dict | None:
    """A entrada do registo com estes pixels, ou nada."""
    if not reg:
        return None
    sha = image_sha(image)
    return next((e for e in reg.get("entries", []) if e.get("pixels_sha256") == sha), None)


def record(reg: dict | None, image: Image.Image) -> dict:
    """O que se sabe desta imagem: hash, estado e, se registada, a entrada."""
    entry = lookup(reg, image)
    return {"pixels_sha256": image_sha(image), "state": entry["state"] if entry else UNRECORDED,
            "id": entry["id"] if entry else None, "register": (reg or {}).get("path")}


def resolve(role: str, data: bytes, reg: dict | None) -> tuple[str | None, dict, str | None]:
    """(papel no prompt, registo, erro) de uma referencia anexada. Com registo, quem nao esta nele e erro."""
    with Image.open(io.BytesIO(data)) as im:
        rec = record(reg, im)
    if role == "style":
        return "style", rec, None
    if role == "concept":
        if rec["state"] not in (UNRECORDED, "concept"):
            return None, rec, f"o conceito {rec['id']} esta registado como {rec['state']}"
        return "concept", {**rec, "state": "concept"}, None
    if reg and rec["state"] == UNRECORDED:
        return None, rec, "referencia nao esta no registo (forja refs --add): sem estado, nao entra"
    if rec["state"] == "rejected":
        return None, rec, (f"referencia {rec['id']} rejeitada: nao entra como identidade (proteger o rejeitado "
                           "congela a descaracterizacao; recupere a partir do conceito)")
    return PROMPT_ROLE[rec["state"]], rec, None


def stage(states: list[str]) -> str:
    """from_master: ha um mestre aprovado anexado; recovery: o resultado sera uma adaptacao em revisao."""
    return "from_master" if "approved" in states else "recovery"


def approval(reg: dict | None, image: Image.Image) -> dict:
    """A aprovacao artistica desta imagem exata, como o dono a registou; senao, pendente."""
    entry = lookup(reg, image)
    if entry and entry["state"] == "approved":
        return {"status": "approved", "by": entry["decided_by"], "date": entry["date"], "id": entry["id"],
                "source": "registo do dono"}
    return {"status": "pending", "state": entry["state"] if entry else UNRECORDED}


def add(path: str | Path, image_path: str | Path, state: str, ident: str, by: str | None = None,
        origin: str | None = None, derived_from: str | None = None, date: str | None = None) -> dict:
    """Acrescenta uma entrada ao registo (cria-o se falta). `approved` nao: essa linha e do dono."""
    if state == "approved":
        raise ValueError("approved e escrito pelo dono no registo, a mao: a Forja nao aprova arte")
    if state not in STATES:
        raise ValueError(f"estado {state!r} (use {', '.join(STATES)})")
    path = Path(path)
    reg = json.loads(path.read_text(encoding="utf-8")) if path.exists() else {"schema": SCHEMA, "entries": []}
    image_path = Path(image_path)
    with Image.open(image_path) as im:
        sha = image_sha(im)
    try:
        rel = str(image_path.resolve().relative_to(path.resolve().parent))
    except ValueError:
        rel = str(image_path.resolve())
    entry = {"id": ident, "file": rel, "pixels_sha256": sha, "state": state}
    entry.update({k: v for k, v in (("recorded_by", by), ("origin", origin), ("derived_from", derived_from),
                                    ("date", date)) if v})
    if state == "rejected":
        entry["decided_by"] = by
    reg["entries"].append(entry)
    errors = validate(reg, path.parent)
    if errors:
        raise ValueError("; ".join(errors))
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(reg, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    return {**reg, "path": str(path)}
