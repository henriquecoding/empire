"""Sinais declarados: pixels presos e regioes criticas, do voto ate ao PNG final (FORJA-07; auditoria de 27/10, §16.3).

Um voto por celula nao sabe que um branco pequeno e um dente nem que uma linha escura e a palpebra que da arrogancia ao
rei. Quem sabe declara-o, num ficheiro `forja.signals/1` preso a uma imagem (o hash dos pixels):

- `pins`: um pixel e a cor que ele tem de ter, com a funcao (`role`), a origem (`source_annotation`) e o estado. So
  `authorized` se aplica: a cor vai para a celula depois do voto e fica protegida ate ao fim (o mesmo `guard` do
  `--protect`). Sem cor, sem coordenada, ou com outro estado, o pino fica `pending`. Dois pinos com cores diferentes
  na mesma celula sao `layout_conflict`, com as duas origens, e nenhum se aplica: a ordem nao decide quem ganha.
- `regions`: uma caixa com funcao e `required`. Uma celula apagada pela amostragem (`loss.py`) dentro dela deixa a
  regiao `lost`; sem caixa, `pending`; sem perda medida, `no_loss_detected` — que nao e `pass`: o desenho continua a
  olho.

Coordenadas `source_*` sao da imagem que se forja (`source_xy`, `source_box`) ou da grade dela (`cell`); `target_*`
sao do PNG final (`target_pixel`, `target_box`). O estado do conjunto: `blocked` (um pino perdido, um conflito, uma
regiao obrigatoria perdida), `pending` (falta declarar ou anotar) ou `pass` (os sinais declarados chegaram). Aplicar
uma cor prova que a restricao se cumpriu, nao que o olho ficou bem desenhado.
"""
from __future__ import annotations

import json
from bisect import bisect_right
from pathlib import Path

from PIL import Image

from . import color
from .equipment import image_sha
from .guard import final_xy

SCHEMA = "forja.signals/1"
APPLY = "authorized"


def load(path: str | Path, image: Image.Image | None = None) -> dict:
    data = json.loads(Path(path).read_text(encoding="utf-8"))
    errors = validate(data, image)
    if errors:
        raise ValueError("sinais invalidos: " + "; ".join(errors))
    return data


def validate(data: dict, image: Image.Image | None = None) -> list[str]:
    errors = [] if data.get("schema") == SCHEMA else [f"schema: esperado {SCHEMA}"]
    if image is not None and data.get("image_sha256") and data["image_sha256"] != image_sha(image):
        errors.append("os sinais foram anotados noutra imagem (image_sha256 nao bate com os pixels)")
    ids = [p.get("id") for p in data.get("pins", [])] + [r.get("id") for r in data.get("regions", [])]
    errors += [f"id em falta ou repetido: {i!r}" for i in dict.fromkeys(ids) if not i or ids.count(i) > 1]
    for p in data.get("pins", []):
        if p.get("color"):
            try:
                color.parse_hex(p["color"])
            except ValueError as err:
                errors.append(f"{p.get('id')}: {err}")
    return errors


def _cell(g, xy) -> list[int]:
    cols, rows = g.size
    return [min(cols - 1, max(0, bisect_right(g.xs, xy[0]) - 1)), min(rows - 1, max(0, bisect_right(g.ys, xy[1]) - 1))]


def resolve(pins: list[dict], g) -> list[dict]:
    """Cada pino com a celula da grade e o estado antes de aplicar: authorized, pending ou layout_conflict."""
    out = []
    for p in pins:
        rec = {"id": p["id"], "role": p.get("role"), "color": p.get("color"), "origin": p.get("source_annotation"),
               "declared_status": p.get("status")}
        where = p.get("cell") or (_cell(g, p["source_xy"]) if p.get("source_xy") else None)
        reason = ("estado " + repr(p.get("status")) + ": so 'authorized' se aplica" if p.get("status") != APPLY
                  else "sem cor declarada (material por resolver)" if not p.get("color")
                  else "sem coordenada na imagem (cell ou source_xy)" if where is None else None)
        rec.update(cell=list(where) if where else None, state="pending" if reason else APPLY, reason=reason)
        out.append(rec)
    by_cell: dict[tuple, list[dict]] = {}
    for rec in out:
        if rec["state"] == APPLY:
            by_cell.setdefault(tuple(rec["cell"]), []).append(rec)
    for recs in by_cell.values():
        if len({color.parse_hex(r["color"]) for r in recs}) > 1:
            for r in recs:
                r.update(state="layout_conflict", reason="outra cor exigida na mesma celula",
                         conflicts_with=[(o["id"], o["origin"]) for o in recs if o is not r])
    return out


def apply(native: Image.Image, resolved: list[dict]) -> tuple[Image.Image, int]:
    """Pinta os pinos autorizados na saida da amostragem (a grade inteira, antes do fundo e do recorte)."""
    out, n = native.copy(), 0
    px = out.load()
    for r in resolved:
        if r["state"] == APPLY:
            want = (*color.parse_hex(r["color"]), 255)
            x, y = r["cell"]
            n += px[x, y] != want
            px[x, y] = want
    return out, n


def crop(resolved: list[dict], box: tuple[int, int, int, int]) -> list[dict]:
    return [{**r, "native": [r["cell"][0] - box[0], r["cell"][1] - box[1]] if r["cell"] else None} for r in resolved]


def protect_boxes(resolved: list[dict]) -> list[tuple[int, int, int, int]]:
    """Os pinos aplicados como caixas de 1 px do recorte nativo, para o `guard` os levar ate ao PNG final."""
    return [(x, y, x + 1, y + 1) for r in resolved if r["state"] == APPLY and r.get("native")
            for x, y in [r["native"]]]


def _final_ok(final: Image.Image, xy, want, k: int = 1) -> bool:
    w, h = final.size
    fp = final.load()
    return all(0 <= xy[0] + i < w and 0 <= xy[1] + j < h and fp[xy[0] + i, xy[1] + j] == want
               for j in range(k) for i in range(k))


def verify_pins(final: Image.Image, resolved: list[dict], info: dict | None) -> list[dict]:
    """Depois do ultimo passo que muda pixels: cada pino aplicado tem a sua cor onde o mapeamento o leva."""
    out = []
    for r in resolved:
        r = dict(r)
        if r["state"] == APPLY and r.get("native") and info is not None:
            xy = list(final_xy(r["native"], info))
            ok = _final_ok(final, xy, (*color.parse_hex(r["color"]), 255), info.get("cluster_upscale", 1))
            r.update(target_pixel=xy, state="verified" if ok else "lost",
                     reason=None if ok else "a cor nao chegou ao PNG final (paleta, limpeza, contorno ou tela)")
        out.append(r)
    return out


def target_pins(final: Image.Image, pins: list[dict]) -> list[dict]:
    """Pinos em coordenadas do PNG final (`target_pixel`), conferidos num PNG ja feito (verify, fidelity)."""
    out = []
    for p in pins:
        rec = {"id": p["id"], "role": p.get("role"), "color": p.get("color"), "origin": p.get("source_annotation"),
               "target_pixel": p.get("target_pixel")}
        if p.get("status") != APPLY or not p.get("color") or not p.get("target_pixel"):
            rec.update(state="pending", reason="sem estado authorized, cor ou target_pixel")
        else:
            ok = _final_ok(final, p["target_pixel"], (*color.parse_hex(p["color"]), 255))
            rec.update(state="verified" if ok else "lost", reason=None if ok else "outra cor nesse pixel")
        out.append(rec)
    seen: dict[tuple, list[dict]] = {}
    for rec in out:
        if rec["target_pixel"] and rec["color"]:
            seen.setdefault(tuple(rec["target_pixel"]), []).append(rec)
    for recs in seen.values():
        if len({color.parse_hex(r["color"]) for r in recs}) > 1:
            for r in recs:
                r.update(state="layout_conflict", reason="outra cor exigida no mesmo pixel",
                         conflicts_with=[(o["id"], o["origin"]) for o in recs if o is not r])
    return out


def _inside(xy, box) -> bool:
    return box[0] <= xy[0] < box[2] and box[1] <= xy[1] < box[3]


def _meets(a, b) -> bool:
    return a[0] < b[2] and b[0] < a[2] and a[1] < b[3] and b[1] < a[3]


def regions(declared: list[dict], erased: list[dict] | None, info: dict | None) -> list[dict]:
    """Cada regiao contra as celulas apagadas: `lost`, `pending` ou `no_loss_detected` (nunca `pass`). Sem a perda
    medida (`erased` None: um PNG sem o JSON do forge), a regiao anotada fica pendente."""
    out = []
    for r in declared:
        rec = {"id": r["id"], "required": bool(r.get("required")), "purpose": r.get("purpose"),
               "source_box": r.get("source_box"), "target_box": r.get("target_box")}
        if not (r.get("source_box") or r.get("target_box")):
            out.append({**rec, "state": "pending", "reason": "sem caixa anotada"})
            continue
        if erased is None:
            out.append({**rec, "state": "pending", "reason": "perda nao medida (falta o JSON do forge)"})
            continue
        hits = []
        for e in erased:
            final = list(final_xy(e["native"], info)) if info is not None and e.get("native") else None
            if (r.get("source_box") and _meets(e["source_box"], r["source_box"])) or (
                    r.get("target_box") and final and _inside(final, r["target_box"])):
                hits.append({"cell": e["cell"], "kind": e["kind"], "color": e["color"], "target_pixel": final})
        out.append({**rec, "state": "lost" if hits else "no_loss_detected", "erased": hits[:12],
                    "erased_cells": len(hits)})
    return out


def final_state(final: Image.Image, snapinfo: dict, finishinfo: dict | None, declared: dict | None) -> dict:
    """Os sinais declarados depois do ultimo passo que muda pixels (FORJA-07), so desta etapa (`scope`)."""
    declared = declared or {}
    pins = verify_pins(final, snapinfo.get("pins", []), finishinfo)
    pins += target_pins(final, [p for p in declared.get("pins", []) if p.get("target_pixel")])
    erased = (snapinfo.get("loss") or {}).get("erased", [])
    return {**state(pins, regions(declared.get("regions", []), erased, finishinfo)), "scope": "this_stage"}


def state(pins: list[dict], regs: list[dict]) -> dict:
    """O estado dos sinais declarados: blocked, pending ou pass, com as razoes."""
    blocked = ([f"pino {p['id']}: {p['state']}" for p in pins if p["state"] in ("lost", "layout_conflict")]
               + [f"regiao {r['id']}: perdida ({r['erased_cells']} celulas apagadas)" for r in regs
                  if r["state"] == "lost" and r["required"]])
    pending = ([f"pino {p['id']}: {p['reason']}" for p in pins if p["state"] == "pending"]
               + [f"regiao {r['id']}: {r['reason']}" for r in regs if r["state"] == "pending"])
    if not pins and not regs:
        pending.append("nenhum sinal declarado: a preservacao nao foi avaliada")
    status = "blocked" if blocked else ("pending" if pending else "pass")
    return {"status": status, "blocked": blocked, "pending": pending, "pins": pins, "regions": regs,
            "note": "um sinal que chegou cumpre a restricao; nao prova que o desenho esteja fiel"}
