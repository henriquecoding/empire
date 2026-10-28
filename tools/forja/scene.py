"""O contrato de uma cena ou construcao: `forja.scene/1` (FORJA-09).

O personagem tinha o rosto e a pose; uma construcao tem o seu equivalente: a inclinacao do telhado, a espessura do
beiral, a porta que um ator usa, a chamine ligada, os apoios, a base no chao. O contrato diz isso antes de qualquer
pedido, em campos separados (relatorio de 28/10, §9, §10, §17 e §18):

- o asset (`building`, `tree`, `terrain_strip`, `plane_mid`...) e o contrato raster que lhe corresponde;
- a extensao explicita, em px de ecra (multipla da grade): nao ha tela por omissao de 64x64 para uma casa;
- a projecao do mundo (elevacao lateral), separada da orientacao dos atores;
- os vaos, conferidos contra a regua dos atores reais (`regua.py`), e os sinais de identidade com nome;
- materiais, estados de construcao e condicoes (noite, neve), e o que nunca muda entre eles;
- as referencias, cada uma num papel que diz o que transporta e o que nao autoriza copiar.

As caixas sao em px de ecra no referencial da extensao: (0, 0) e o canto de cima a esquerda e a base assenta em
y = altura. Um contrato valido nao e arte: e o que se pede e o que se confere depois (`estrutura.py`).
"""
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image

from . import contracts, regua
from .equipment import image_sha

SCHEMA = "forja.scene/1"
OPENINGS = ("door", "window", "arch", "bay", "gate")
TREATMENTS = ("interior", "lit", "transparent")  # escuro, aceso (janela, forja) ou vazado


def _box(box, size: tuple[int, int]) -> str | None:
    if not (isinstance(box, list) and len(box) == 4 and all(isinstance(v, int) for v in box)):
        return "caixa x0,y0,x1,y1 em px inteiros"
    x0, y0, x1, y1 = box
    if not (0 <= x0 < x1 <= size[0] and 0 <= y0 < y1 <= size[1]):
        return f"caixa {box} fora da extensao {size[0]}x{size[1]}"
    return None


def _extent(scene: dict, step: int) -> tuple[list[str], tuple[int, int] | None]:
    ext = scene.get("extent_px")
    if not (isinstance(ext, list) and len(ext) == 2 and all(isinstance(v, int) and v > 0 for v in ext)):
        return ["extent_px: obrigatoria, [largura, altura] em px de ecra (nao ha tamanho por omissao)"], None
    if any(v % step for v in ext):
        return [f"extent_px {ext}: multipla da grade de {step} px"], None
    return [], (ext[0], ext[1])


def _openings(scene: dict, size: tuple[int, int], step: int, found: list[dict]) -> tuple[list[str], list[str]]:
    errors, warns = [], []
    door, public = regua.metric(found, "door_clear_height"), regua.metric(found, "public_door_height")
    sill = regua.metric(found, "window_sill")
    for o in scene.get("openings", []):
        name = o.get("id", "?")
        if o.get("kind") not in OPENINGS:
            errors.append(f"vao {name}: tipo {o.get('kind')!r} (use {', '.join(OPENINGS)})")
            continue
        if o.get("treatment", "interior") not in TREATMENTS:
            errors.append(f"vao {name}: tratamento {o.get('treatment')!r} (use {', '.join(TREATMENTS)})")
        bad = _box(o.get("box_px"), size)
        if bad:
            errors.append(f"vao {name}: {bad}")
            continue
        x0, y0, x1, y1 = o["box_px"]
        if any(v % step for v in o["box_px"]):
            warns.append(f"vao {name}: caixa {o['box_px']} fora da grade de {step} px")
        h, lift = y1 - y0, size[1] - y1
        need = public if o["kind"] in ("gate", "arch") else door
        if o["kind"] in ("door", "gate", "arch", "bay"):
            if h < need["px"][0]:
                errors.append(f"vao {name}: {h} px de altura; pede pelo menos {need['px'][0]} ({need['label']}, "
                              f"{need['origin']})")
            elif o["kind"] == "door" and h > door["px"][1]:
                warns.append(f"vao {name}: {h} px acima de {door['px'][1]}: le-se como porta publica (88-104) ou "
                             "portao; confirme o papel")
            if lift > step and not o.get("raised"):
                errors.append(f"vao {name}: a soleira esta {lift} px acima da base; uma porta assenta no chao "
                              "(declare raised: true se houver degraus)")
        elif o["kind"] == "window" and lift < sill["px"][0]:
            warns.append(f"vao {name}: peitoril a {lift} px do chao, abaixo de {sill['px'][0]}: as cabecas tapam-na")
    return errors, warns


def _references(scene: dict, base: Path) -> list[str]:
    errors, roles = [], regua.data()["roles"]
    for r in scene.get("references", []):
        name = r.get("file", "?")
        if r.get("role") not in roles:
            errors.append(f"referencia {name}: papel {r.get('role')!r} (use {', '.join(roles)})")
        path = base / str(r.get("file", ""))
        if not r.get("file") or not path.is_file():
            errors.append(f"referencia {name}: ficheiro nao existe")
            continue
        with Image.open(path) as im:
            if r.get("pixels_sha256") and image_sha(im) != r["pixels_sha256"]:
                errors.append(f"referencia {name}: os pixels mudaram depois do contrato")
            if r.get("crop") and _box(r["crop"], im.size):
                errors.append(f"referencia {name}: recorte {r['crop']} fora da imagem {im.size}")
    return errors


def validate(scene: dict, base: Path | None = None, found: list[dict] | None = None) -> dict:
    """{'errors': [...], 'warnings': [...]} — os erros param o pedido; os avisos ficam no relatorio."""
    d = regua.data()
    errors = [] if scene.get("schema") == SCHEMA else [f"schema: esperado {SCHEMA}"]
    warns: list[str] = []
    spec = d["assets"].get(scene.get("asset"))
    if spec is None:
        return {"errors": errors + [f"asset {scene.get('asset')!r} (use {', '.join(d['assets'])})"], "warnings": []}
    c = contracts.get(spec["contract"])
    if not str(scene.get("id", "")).strip() or not str(scene.get("subject", "")).strip():
        errors.append("id e subject sao obrigatorios (o subject e o pedido, em ingles)")
    bad, size = _extent(scene, c.cluster)
    errors += bad
    if size and c.width_multiple and size[0] % c.width_multiple:
        warns.append(f"largura {size[0]} px nao e multipla de {c.width_multiple} (Asset Bible: sempre que possivel)")
    found = found or regua.metrics(regua.ruler(), c.cluster)
    if size:
        e, w = _openings(scene, size, c.cluster, found)
        errors, warns = errors + e, warns + w
        for sid, box in (scene.get("signal_regions") or {}).items():
            if _box(box, size):
                errors.append(f"sinal {sid}: {_box(box, size)}")
    if spec.get("openings") and not any(o.get("kind") in ("door", "gate", "bay", "arch")
                                        for o in scene.get("openings", [])):
        warns.append("sem porta declarada: um edificio de oficio precisa de um vao que um ator use")
    for field, known in (("signals", d["signals"]), ("materials", d["materials"])):
        unknown = [s for s in scene.get(field, []) if s not in known]
        if unknown:
            errors.append(f"{field} desconhecidos: {unknown} (ha: {', '.join(known)})")
    unknown = [s for s in scene.get("signal_regions") or {} if s not in scene.get("signals", [])]
    if unknown:
        errors.append(f"signal_regions sem sinal declarado: {unknown}")
    states = d["states"]
    for field, known in (("states", states["construction"]), ("conditions", states["conditions"])):
        unknown = [s for s in scene.get(field, []) if s not in known]
        if unknown:
            errors.append(f"{field} desconhecidos: {unknown} (use {', '.join(known)})")
    for name, boxes in (scene.get("state_changes") or {}).items():
        if name not in states["construction"] + states["conditions"]:
            errors.append(f"state_changes: estado {name!r} desconhecido")
        errors += [f"state_changes {name}: {_box(b, size)}" for b in boxes if size and _box(b, size)]
    bad_axes = [a for a in scene.get("repeat", spec["repeat"]) if a not in ("x", "y")]
    if bad_axes:
        errors.append(f"repeat: eixos {bad_axes} (use x e/ou y)")
    if scene.get("people") and scene["people"] not in d["families"]:
        warns.append(f"povo {scene['people']!r} sem familia no scenery.json ({', '.join(d['families'])})")
    errors += _references(scene, base or Path("."))
    return {"errors": errors, "warnings": warns}


def load(path: str | Path) -> dict:
    path = Path(path)
    scene = json.loads(path.read_text(encoding="utf-8"))
    return {**scene, "_base": str(path.parent)}


def resolve(scene: dict, root: Path | None = None) -> dict:
    """O contrato resolvido: o raster, as celulas, a ancora, os vaos em celulas, a regua e os argumentos do forge."""
    spec = regua.data()["assets"][scene["asset"]]
    c = contracts.get(spec["contract"])
    step = c.cluster
    rul = regua.ruler(root=root)
    found = regua.metrics(rul, step)
    check = validate(scene, Path(scene.get("_base", ".")), found)
    if check["errors"]:
        raise ValueError("contrato de cena invalido: " + "; ".join(check["errors"]))
    w, h = scene["extent_px"]
    wld = regua.world(root)
    repeat = scene.get("repeat", spec["repeat"])
    pivot = [w // 2, h - 1]  # o forge pousa o centro da base do recorte aqui (ancora `bottom` dos contratos)
    return {"id": scene["id"], "asset": scene["asset"], "kind": c.kind, "contract": c.as_dict(), "step": step,
            "extent_px": [w, h], "cells": [w // step, h // step], "background": spec["background"],
            "projection": spec["projection"], "anchor": {"mode": spec["anchor"],
                                                         "local_px": [w // 2 if spec["anchor"] == "base_center" else 0, h],
                                                         "ground": spec["ground"]},
            "repeat": repeat, "connectors": bool(spec.get("connectors")),
            "openings": [{**o, "cells": [v // step for v in o["box_px"]]} for o in scene.get("openings", [])],
            "signals": scene.get("signals", []), "signal_regions": scene.get("signal_regions") or {},
            "materials": scene.get("materials", []), "states": scene.get("states", ["done"]),
            "conditions": scene.get("conditions", []), "state_changes": scene.get("state_changes") or {},
            "references": scene.get("references", []), "ruler": {"tallest": rul["tallest"],
                                                                 "shortest": rul["shortest"]},
            "metrics": found, "lattice": regua.lattice(step, wld), "world": wld, "warnings": check["warnings"],
            "forge_args": ["--kind", c.kind, "--canvas", f"{w}x{h}", "--pivot", f"{pivot[0]},{pivot[1]}"]
            + (["--bg", "keep"] if spec["background"] == "opaque" else []), "spec": spec, "scene": scene}
