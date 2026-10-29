"""Objetos partilhados entre personagens e o modelo nativo de onde saem (FORJA-15, P0-02).

Auditoria de fidelidade de 29/10, caso A: o contrato dos alquimistas dizia `shared_prop_constraints` (o frasco do
escudeiro e o do imperador com o mesmo molde e o mesmo tamanho absoluto) e nada na Forja o lia: trocar a medida
declarada por 99x3 devolvia a mesma lista vazia de erros, e os dois frascos 13x20 passavam por terem o mesmo envelope
com bojos diferentes. Aqui:

- `validate` confere o esquema de cada restricao (par, escala, medida nativa dentro da tela, variacoes permitidas);
- `pairs` confere o elenco: o par existe e declara a mesma restricao com a mesma medida;
- `load_model` le o `forja.prop_model/1`: o objeto desenhado na grade a partir do conceito (`authored_from`), por
  partes (linhas de caracteres e legenda), com estado `proposed` ou `approved` (quem e quando). Um modelo proposto
  compara, mas nunca da `pass`: os 13x20 de uma entrega nao viram padrao por conveniencia;
- `pair` junta as duas medidas observadas e as duas comparacoes de forma num veredito por restricao.
"""
from __future__ import annotations

import json
from pathlib import Path

SCALES = ("same_absolute_world_pixel_dimensions",)
VARIATIONS = ("liquid_color", "orientation", "occlusion", "highlight")
MODEL = "forja.prop_model/1"
MODEL_STATES = ("proposed", "approved")


def validate(items, ch: dict) -> list[str]:
    """Os erros das `shared_prop_constraints` de um personagem (lista vazia: valida)."""
    if items is None:
        return []
    if not isinstance(items, list):
        return ["shared_prop_constraints: esperado uma lista"]
    errors, ids, canvas = [], [], ch.get("target_canvas") or [0, 0]
    for c in items:
        name = c.get("id") if isinstance(c, dict) else None
        if not name or name in ids:
            errors.append(f"shared_prop {name!r}: id em falta ou repetido")
            continue
        ids.append(name)
        if not isinstance(c.get("paired_with"), str) or c["paired_with"] in ("", ch.get("id")):
            errors.append(f"shared_prop {name}: paired_with tem de nomear outro personagem")
        if c.get("scale") not in SCALES:
            errors.append(f"shared_prop {name}: scale {c.get('scale')!r} (use {', '.join(SCALES)})")
        if c.get("scale_with_character_canvas") is not False:
            errors.append(f"shared_prop {name}: o objeto partilhado nao escala com a tela do personagem")
        dims = c.get("native_shared_dimensions")
        if dims is not None and not (isinstance(dims, list) and len(dims) == 2 and all(type(v) is int and v > 0
                                                                                       for v in dims)):
            errors.append(f"shared_prop {name}: native_shared_dimensions {dims} nao e [largura, altura] em pixels")
        elif dims is not None and (dims[0] > canvas[0] or dims[1] > canvas[1]):
            errors.append(f"shared_prop {name}: {dims[0]}x{dims[1]} nao cabe na tela {canvas[0]}x{canvas[1]}")
        bad = [v for v in c.get("allowed_variations", []) if v not in VARIATIONS]
        if bad:
            errors.append(f"shared_prop {name}: variacoes {bad} (use {', '.join(VARIATIONS)})")
        if c.get("model") is not None and not isinstance(c["model"], str):
            errors.append(f"shared_prop {name}: model e o caminho de um {MODEL}")
    return errors


def pairs(chars: dict[str, dict]) -> list[str]:
    """No elenco: cada restricao tem par existente, recíproco e com a mesma medida declarada."""
    errors = []
    for ident, ch in chars.items():
        for c in ch.get("shared_prop_constraints") or []:
            other = chars.get(c.get("paired_with"))
            if other is None:
                errors.append(f"{ident}: shared_prop {c.get('id')}: par {c.get('paired_with')!r} fora do elenco")
                continue
            mate = next((m for m in other.get("shared_prop_constraints") or [] if m.get("id") == c.get("id")), None)
            if mate is None or mate.get("paired_with") != ident:
                errors.append(f"{ident}: shared_prop {c['id']}: {c['paired_with']} nao declara a mesma restricao")
            elif mate.get("native_shared_dimensions") != c.get("native_shared_dimensions"):
                errors.append(f"{ident}: shared_prop {c['id']}: medida {c.get('native_shared_dimensions')} e a do par "
                              f"{mate.get('native_shared_dimensions')} divergem")
    return errors


def load_model(spec, base: Path | None = None) -> dict:
    """O modelo nativo (dict ou caminho): partes como conjuntos de pixels no referencial do modelo."""
    data = spec if isinstance(spec, dict) else json.loads(Path(base or ".", spec).read_text(encoding="utf-8"))
    errors = [] if data.get("schema") == MODEL else [f"schema esperado {MODEL}"]
    rows, legend = data.get("rows") or [], data.get("legend") or {}
    size = [max((len(r) for r in rows), default=0), len(rows)]
    if not rows or size != list(data.get("size") or []):
        errors.append(f"linhas {size} e size {data.get('size')} divergem")
    src = data.get("authored_from") or {}
    if not (src.get("authority_sha256") and src.get("box")):
        errors.append("modelo sem authored_from (o conceito e a caixa de onde foi desenhado)")
    if data.get("status") not in MODEL_STATES or (data.get("status") == "approved" and
                                                  not (data.get("approved_by") and data.get("date"))):
        errors.append(f"estado {data.get('status')!r}: proposed, ou approved com approved_by e date")
    parts: dict[str, set] = {}
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch in (".", " "):
                continue
            if ch not in legend:
                errors.append(f"caractere {ch!r} sem legenda (linha {y})")
                continue
            parts.setdefault(legend[ch], set()).add((x, y))
    if errors:
        raise ValueError("modelo de objeto invalido: " + "; ".join(errors))
    return {**data, "parts": {k: frozenset(v) for k, v in parts.items()}, "approved": data["status"] == "approved"}


def pair(constraint: dict, a: dict, b: dict) -> dict:
    """Um veredito por restricao: `a`/`b` = {character, measure (prop_shape.measure), shape (prop_shape.compare)}."""
    checks, dims = [], constraint.get("native_shared_dimensions")
    for side in (a, b):
        m = side.get("measure")
        if not m or not m.get("envelope"):
            checks.append(("pending", f"{side['character']}: sem observacao do objeto nesta imagem"))
        elif m.get("cut_by_occluder"):
            checks.append(("inconclusive", f"{side['character']}: o envelope toca um oclusor ({m['envelope']})"))
        elif dims and m["envelope"] != dims:
            checks.append(("fail", f"{side['character']}: {m['envelope']} e nao a medida declarada {dims}"))
        shape = side.get("shape")
        if shape is not None:
            checks.append((shape["status"], f"{side['character']}: forma {shape['detail']}"))
    ea, eb = ((a.get("measure") or {}).get("envelope"), (b.get("measure") or {}).get("envelope"))
    if ea and eb and ea != eb:
        checks.append(("fail", f"tamanho absoluto diverge: {a['character']} {ea}, {b['character']} {eb}"))
    if dims is None:
        checks.append(("pending", "native_shared_dimensions por fechar no mestre: o envelope igual nao e o molde"))
    if a.get("shape") is None or b.get("shape") is None:
        checks.append(("pending", "sem modelo nativo do objeto: o mesmo envelope nao prova o mesmo molde"))
    states = {c[0] for c in checks}
    status = "blocked" if "fail" in states else "pending" if states - {"pass"} else "pass"
    return {"id": constraint["id"], "status": status, "checks": [{"status": s, "detail": d} for s, d in checks],
            "envelopes": {a["character"]: ea, b["character"]: eb}, "declared": dims,
            "allowed_variations": constraint.get("allowed_variations", [])}
