"""O contrato de fidelidade: a autoridade de cada personagem e pose, e o que nao pode mudar (FORJA-07).

Auditoria de 27/10, §3.1, §3.4 e §16. O arqueiro rejeitado veio de outra referencia (tunica verde comprida, sorriso,
mao na cintura) e o rei e o escudeiro de um guia reduzido que substituiu o conceito na ultima chamada. O registo de
referencias (`refs.py`) diz o estado de uma imagem; nao diz se ela e o personagem certo. O contrato
`forja.fidelity/1` prende cada personagem e pose a um recorte da prancha de autoridade (o ficheiro com o sha256 dos
bytes e a caixa), com as invariantes visuais, as regioes criticas, os pinos e os candidatos ja rejeitados (pelo
hash dos pixels). E dados escritos por quem decide; a Forja le-os e confere-os, nunca os preenche:

- num pedido `adapt_concept`, o recorte vai anexado como conceito e um conceito que nao seja ele e
  `reference_conflict` (resolve-se o alvo antes de gerar); uma referencia que e um candidato rejeitado nao entra;
- as invariantes vao para o prompt como do dono, e as restricoes implicitas do compilador ficam de fora;
- a revisao (`review.py`, `forja fidelity`) le daqui as regioes, os pinos e os rejeitados.
Recortar uma prancha nao faz do recorte um mestre nativo: e a autoridade de identidade, fora da grade.
"""
from __future__ import annotations

import hashlib
import io
import json
from pathlib import Path

from PIL import Image

from . import constraints, contracts, face, production, signals, visual_review
from .equipment import image_sha

SCHEMA = "forja.fidelity/1"


def load(path: str | Path) -> dict:
    path = Path(path)
    data = json.loads(path.read_text(encoding="utf-8"))
    errors = validate(data, path.parent)
    if errors:
        raise ValueError("contrato de fidelidade invalido: " + "; ".join(errors))
    return {**data, "path": str(path), "base": str(path.parent)}


def validate(data: dict, base: Path) -> list[str]:
    errors = [] if data.get("schema") == SCHEMA else [f"schema: esperado {SCHEMA}"]
    auth = data.get("authority") or {}
    path = base / str(auth.get("file", ""))
    if not auth.get("file") or not path.is_file():
        return errors + [f"autoridade: ficheiro {auth.get('file')!r} nao existe"]
    if hashlib.sha256(path.read_bytes()).hexdigest() != auth.get("sha256"):
        errors.append("autoridade: o ficheiro mudou (sha256 dos bytes nao bate)")
    with Image.open(path) as im:
        size = im.size
    if list(size) != list(auth.get("size") or []):
        errors.append(f"autoridade: tamanho {list(size)}, declarado {auth.get('size')}")
    keys = [(c.get("id"), c.get("pose")) for c in data.get("characters", [])]
    for ch in data.get("characters", []):
        name = f"{ch.get('id')}/{ch.get('pose')}"
        errors += [f"{name}: {e}" for e in production.validate(ch)]
        if not ch.get("id") or not ch.get("pose") or keys.count((ch["id"], ch["pose"])) > 1:
            errors.append(f"{name}: id e pose em falta ou repetidos")
        x0, y0, x1, y1 = ch.get("authority_crop_xyxy") or (0, 0, 0, 0)
        if not (0 <= x0 < x1 <= size[0] and 0 <= y0 < y1 <= size[1]):
            errors.append(f"{name}: recorte {ch.get('authority_crop_xyxy')} fora da autoridade {list(size)}")
        if ch.get("kind") not in contracts.kinds():
            errors.append(f"{name}: kind {ch.get('kind')!r} nao e um contrato")
        elif list(contracts.get(ch["kind"]).canvas or []) != list(ch.get("target_canvas") or []):
            errors.append(f"{name}: target_canvas {ch.get('target_canvas')} nao e a tela de {ch['kind']}")
        errors += [f"{name}: {e}" for e in signals.validate({"schema": signals.SCHEMA, "pins": ch.get("pixel_pins", []),
                                                              "regions": ch.get("critical_regions", [])})]
        errors += [f"{name}: {e}" for e in face.validate(ch.get("face_sheet"), ch.get("target_canvas"),
                                                          ch.get("authority_crop_xyxy"))]
        errors += [f"{name}: pino {p.get('id')}: source_kind authority sem authority_xy dentro do recorte"
                   for p in ch.get("pixel_pins", []) if p.get("source_kind") == "authority" and not _within(
                       p.get("authority_xy"), ch.get("authority_crop_xyxy"))]
        for r in ch.get("rejected_candidates", []):
            file = base / str(r.get("file", ""))
            if not file.is_file() or not (r.get("decided_by") and r.get("date")):
                errors.append(f"{name}: candidato rejeitado sem ficheiro, decided_by ou date ({r.get('file')!r})")
                continue
            with Image.open(file) as im:
                if image_sha(im) != r.get("pixels_sha256"):
                    errors.append(f"{name}: o candidato rejeitado {r['file']} mudou depois do registo")
    return errors


def _within(xy, crop) -> bool:
    return isinstance(xy, list) and len(xy) == 2 and bool(crop) and crop[0] <= xy[0] < crop[2] and \
        crop[1] <= xy[1] < crop[3]


def character(data: dict, ident: str, pose: str | None = None) -> dict:
    found = [c for c in data.get("characters", []) if c["id"] == ident and (pose is None or c["pose"] == pose)]
    if len(found) != 1:
        poses = [c["pose"] for c in data.get("characters", []) if c["id"] == ident]
        why = "diga --pose: " + ", ".join(poses) if poses else "nao esta no contrato"
        raise ValueError(f"personagem {ident!r} pose {pose!r}: {why}")
    return found[0]


def where(ch: dict) -> str:
    return f"{ch['id']}/{ch['pose']}"


def authority_crop(data: dict, ch: dict) -> Image.Image:
    with Image.open(Path(data["base"]) / data["authority"]["file"]) as im:
        return im.convert("RGBA").crop(tuple(ch["authority_crop_xyxy"]))


def crop_png(data: dict, ch: dict) -> bytes:
    buf = io.BytesIO()
    authority_crop(data, ch).save(buf, format="PNG")
    return buf.getvalue()


def rejected(ch: dict, image: Image.Image) -> dict | None:
    sha = image_sha(image)
    return next((r for r in ch.get("rejected_candidates", []) if r["pixels_sha256"] == sha), None)


def _pixels(data: bytes) -> Image.Image:
    with Image.open(io.BytesIO(data)) as im:
        return im.convert("RGBA")


def prepare(contract: dict | None, ident: str | None, pose: str | None, mode: str | None,
            given: list[tuple[str, str, bytes]]) -> dict:
    """O modo do pedido e o que a autoridade acrescenta ou recusa. `given`: (papel, nome, bytes) das referencias.

    Devolve {mode, attach (papel, nome, bytes) a juntar, errors, notes, prompt (para prompts.build), record}."""
    out = {"mode": mode, "attach": [], "errors": [], "notes": [], "prompt": None, "record": None}
    if mode == "recover_grid":
        out["errors"].append("recover_grid nao gera: recupera-se a ampliacao que existe com forja forge/snap")
        return out
    if mode and mode not in constraints.MODES:
        raise ValueError(f"modo desconhecido: {mode} (use {', '.join(constraints.MODES)})")
    if contract is None:
        if mode == "adapt_concept":
            out["errors"].append("adapt_concept pede --fidelity e --character: o recorte de autoridade e as "
                                 "invariantes saem do contrato de fidelidade")
        out["mode"] = mode or ("adapt_concept" if any(r == "concept" for r, _, _ in given) else "stylized")
        if out["mode"] == "adapt_concept" and not mode:
            out["notes"].append("modo adapt_concept pelo conceito anexado, sem contrato de fidelidade: o recorte e as "
                                "invariantes nao foram conferidos")
        return out
    if not ident:
        raise ValueError("--fidelity pede --character")
    ch = character(contract, ident, pose)
    decisions = production.prepare(ch)
    out["errors"] += decisions["errors"]
    crop = crop_png(contract, ch)
    sha = image_sha(_pixels(crop))
    seen = visual_review.for_reference(contract["base"], ch, _pixels(crop))
    out["errors"] += seen["errors"]
    out["notes"] += seen["notes"]
    out["mode"] = mode or "adapt_concept"
    for role, name, data in given:
        pixels = _pixels(data)
        if role == "concept" and image_sha(pixels) != sha:
            out["errors"].append(f"reference_conflict: o conceito {name} nao e o recorte de autoridade de {where(ch)} "
                                 f"(pixels {image_sha(pixels)[:12]}, autoridade {sha[:12]}): resolva o alvo antes de "
                                 "gerar")
        bad = rejected(ch, pixels)
        if bad:
            out["errors"].append(f"{name} e um candidato rejeitado de {where(ch)} ({bad['date']}, {bad['decided_by']}):"
                                 f" {'; '.join(bad.get('reasons', []))}")
    if not any(r == "concept" for r, _, _ in given) and out["mode"] in constraints.FAITHFUL:
        out["attach"].append(("concept", f"autoridade:{where(ch)}", crop))
    out["prompt"] = {"invariants": ch.get("prompt_invariants") or ch.get("required_invariants"), "where": where(ch),
                     **decisions["prompt"]}
    out["record"] = {"contract": contract["path"], "character": ch["id"], "pose": ch["pose"],
                     "authority_sha256": contract["authority"]["sha256"], "crop": ch["authority_crop_xyxy"],
                     "crop_pixels_sha256": sha, "kind": ch["kind"], "target_canvas": ch["target_canvas"],
                     "role": ch.get("role"), "target_useful_bbox": ch.get("target_useful_bbox")}
    return out


def guide_alone(mode: str, seen, states: list[str]) -> list[str]:
    """Um guia em revisao sem o conceito ao lado (auditoria de 27/10, §3.4): a reducao virava a autoridade."""
    roles = {r for _, _, r, _, err in seen if not err}
    if "identity_review" in roles and "concept" not in roles and "approved" not in states:
        return ["a adaptacao em revisao so serve de guia de grade ao lado do conceito: anexe --concept ou --fidelity"]
    if mode == "edit_approved_master" and "approved" not in states:
        return ["edit_approved_master pede o mestre aprovado pelo dono no registo (--refs)"]
    return []
