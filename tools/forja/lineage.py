"""`forja.lineage/1`: as etapas de um candidato e as perdas que ele herda, ate cada uma ser resolvida (FORJA-15, P0-01).

Auditoria de fidelidade de 29/10, caso D: os 15 relatorios finais diziam `erased_cells=0` porque a ultima etapa
comecava numa base ja nativa (uma celula por pixel) e a recuperacao anterior, que apagara os dentes da mercenaria,
ficava noutro ficheiro, sem ligacao. Aqui cada etapa grava o hash dos pixels a entrada e a saida, a transformacao das
coordenadas (grade, recorte, contorno, cluster, tela), as caixas que reescreveu e as perdas novas (`loss.py`), e leva
as ocorrencias da etapa anterior pelas coordenadas desta. Uma etapa so se liga a anterior quando a entrada dela e a
saida da outra (pelo hash): um ficheiro intermedio novo nao encerra nada.

Cada ocorrencia fica `open` ate uma resolucao (`forja.loss_resolutions/1`): `repaired` com prova nesta imagem exata
(os pixels e as cores declarados, no sitio da ocorrencia), `excepted` por decisao com autor e data, ou `inconclusive`
(continua aberta). E `critical` quando cai numa regiao obrigatoria ou num marco da ficha facial; as outras ficam
escritas e nao seguram a entrega. Uma cadeia que comeca numa base ja nativa, sem a etapa anterior nem a declaracao de
que essa base e a origem, nao fecha: as perdas de antes nao foram trazidas.
"""
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image

from . import color
from .equipment import image_sha
from .guard import final_xy
from .signals import _cell

SCHEMA, RESOLUTIONS = "forja.lineage/1", "forja.loss_resolutions/1"
OUTCOMES = ("repaired", "excepted", "inconclusive")
GRID_DOUBT = 0.75  # abaixo disto a fase da grade e duvidosa: pede-se redesenho ou marcacao, nao um voto


def load(path: str | Path) -> dict:
    """A cadeia de um JSON do forge (o campo `lineage`) ou de um `forja.lineage/1` solto."""
    data = json.loads(Path(path).read_text(encoding="utf-8"))
    lin = data.get("lineage") if data.get("schema") != SCHEMA else data
    if not lin or lin.get("schema") != SCHEMA:
        raise ValueError(f"{path}: sem cadeia {SCHEMA} (um JSON do forge feito antes do FORJA-15 nao a tem)")
    return lin


def _to_final(cell, crop, info, inside: bool) -> list[int] | None:
    if info is None or not inside:
        return None
    return list(final_xy([cell[0] - crop[0], cell[1] - crop[1]], info))


def cli_args(p) -> None:
    p.add_argument("--lineage", help="o JSON do forge (ou forja.lineage/1) que produziu esta imagem: as perdas dele "
                   "vem para esta etapa e so fecham com resolucao (FORJA-15)")
    p.add_argument("--native-root", action="store_true", help="esta base ja nativa e a origem da cadeia (desenho "
                   "nativo), nao a saida de uma recuperacao anterior")


def apply(opts, args) -> None:
    opts.lineage = load(args.lineage) if getattr(args, "lineage", None) else None
    opts.native_root = bool(getattr(args, "native_root", False))


def summary(lin: dict) -> dict:
    occ = lin["occurrences"]
    return {"stages": len(lin["stages"]), "root": lin["root"]["kind"], "occurrences": len(occ),
            "critical": sum(1 for o in occ if o.get("critical")), "inherited": lin["stages"][-1]["carried"]}


def _meets(a, b) -> bool:
    return a[0] < b[2] and b[0] < a[2] and a[1] < b[3] and b[1] < a[3]


def _inside(xy, box) -> bool:
    return bool(xy) and box[0] <= xy[0] < box[2] and box[1] <= xy[1] < box[3]


def forge(image: Image.Image, final: Image.Image, g, snapinfo: dict, info: dict | None, opts) -> dict:
    """A etapa do forge acrescentada a cadeia de `opts.lineage` (ou a primeira), com as perdas novas e as herdadas."""
    parent, sha_in = opts.lineage, image_sha(image)
    if parent and parent.get("output_sha256") != sha_in:
        raise ValueError(f"a cadeia nao liga: a etapa anterior deu {str(parent.get('output_sha256'))[:12]}..., esta "
                         f"entrada e {sha_in[:12]}...; passe o JSON do forge que produziu esta imagem")
    stages = list((parent or {}).get("stages", []))
    n, crop = len(stages) + 1, snapinfo.get("crop_origin") or [0, 0]
    cols, rows = snapinfo.get("grid_cells") or [0, 0]
    native_in = [cols, rows] == list(image.size)
    required = [r for r in ((opts.signals or {}).get("regions") or []) if r.get("required")]
    occ = []
    for o in (parent or {}).get("occurrences", []):
        cell = _cell(g, o["target_pixel"]) if o.get("target_pixel") else None
        inside = bool(cell) and 0 <= cell[0] - crop[0] < snapinfo["native_size"][0] and \
            0 <= cell[1] - crop[1] < snapinfo["native_size"][1]
        occ.append({**o, "target_pixel": _to_final(cell, crop, info, inside) if cell else None,
                    "carried_through": o.get("carried_through", []) + [n]})
    for e in (snapinfo.get("loss") or {}).get("erased", []):
        target = _to_final(e["cell"], crop, info, e.get("inside_crop", True))
        hit = [r["id"] for r in required if (r.get("source_box") and _meets(e["source_box"], r["source_box"]))
               or (r.get("target_box") and _inside(target, r["target_box"]))]
        occ.append({"id": f"{n}:{e['cell'][0]},{e['cell'][1]}", "stage": n, "cell": e["cell"], "kind": e["kind"],
                    "color": e["color"], "kept": e.get("kept"), "cell_share": e.get("cell_share"),
                    "votes": e.get("votes"), "margin": e.get("margin"), "source_box": e.get("source_box"),
                    "grid_confidence": (snapinfo.get("grid") or {}).get("confidence"), "target_pixel": target,
                    "regions": hit, "critical": bool(hit), "status": "open"})
    root = (parent or {}).get("root") or {"input_sha256": sha_in, "kind": "native_root_declared" if opts.native_root
                                          else "native_input" if native_in else "generated"}
    new = sum(1 for o in occ if o.get("stage") == n)
    stage = {"n": n, "stage": "forge", "input_sha256": sha_in, "output_sha256": image_sha(final),
             "transform": {"grid_cells": [cols, rows], "native_input": native_in, "crop_origin": list(crop),
                           "grid": {k: (snapinfo.get("grid") or {}).get(k) for k in ("period", "confidence", "origin")},
                           "shift": (info or {}).get("shift"), "cluster": (info or {}).get("cluster_upscale", 1),
                           "fit": (info or {}).get("fit")},
             "new_losses": new, "carried": len(occ) - new, "edited": []}
    return {"schema": SCHEMA, "root": root, "stages": stages + [stage], "occurrences": occ,
            "output_sha256": stage["output_sha256"]}


def patch(parent: dict, report: dict, boxes: list) -> dict:
    """Uma edicao ao pixel (forja patch): as coordenadas nao mudam; o que caiu na mascara fica marcado, nao resolvido."""
    if parent.get("output_sha256") != report["base_pixels_sha256"]:
        raise ValueError("a cadeia nao liga: o patch partiu de outra imagem que nao a saida da ultima etapa")
    n = len(parent["stages"]) + 1
    occ = [{**o, "touched_by": o.get("touched_by", []) + [n]} if any(_inside(o.get("target_pixel"), b) for b in boxes)
           else o for o in parent["occurrences"]]
    stage = {"n": n, "stage": "patch", "input_sha256": report["base_pixels_sha256"],
             "output_sha256": report["result_pixels_sha256"], "transform": {"identity": True},
             "edited": [list(b) for b in boxes], "new_losses": 0, "carried": len(occ)}
    return {**parent, "stages": parent["stages"] + [stage], "occurrences": occ, "output_sha256": stage["output_sha256"]}


def delivery(raster_ok: bool, lin: dict | None) -> dict:
    """O estado do forge: o raster valido nao e a entrega. So o fecho (`forja fidelity`) diz `release_ready`."""
    critical = sum(1 for o in (lin or {}).get("occurrences", []) if o.get("critical"))
    return {"raster_valid": raster_ok, "release_ready": False, "label": "study" if raster_ok else "blocked",
            "state": "candidate_in_review" if raster_ok else "blocked", "artistic_approval": "pending",
            "critical_losses": critical,
            "closure": "forja fidelity --candidate --forge-json: runtime, sinais, identidade, mestre e perdas herdadas"}


def load_resolutions(path: str | Path | None) -> list[dict]:
    if not path:
        return []
    data = json.loads(Path(path).read_text(encoding="utf-8"))
    if data.get("schema") != RESOLUTIONS:
        raise ValueError(f"resolucoes: schema esperado {RESOLUTIONS}")
    return data.get("resolutions", [])


def _proof(res: dict, o: dict, candidate: Image.Image, sha: str) -> str | None:
    """Porque um reparo nao prova: outra imagem, pixel fora da ocorrencia, ou outra cor no pixel."""
    if res.get("pixels_sha256") != sha:
        return "o reparo foi provado noutra imagem (pixels_sha256)"
    if not o.get("target_pixel"):
        return "a ocorrencia saiu da tela: nao ha pixel onde provar o reparo"
    px, (tx, ty) = candidate.load(), o["target_pixel"]
    near = [p for p in res.get("pixels", []) if max(abs(p[0] - tx), abs(p[1] - ty)) <= 1]
    if not near:
        return f"nenhum pixel do reparo no sitio da ocorrencia {o['target_pixel']}"
    for x, y, hexa in res["pixels"]:
        if not (0 <= x < candidate.width and 0 <= y < candidate.height) or \
                px[x, y] != (*color.parse_hex(hexa), 255):
            return f"o pixel {[x, y]} nao tem {hexa} nesta imagem"
    return None


def closure(lin: dict | None, candidate: Image.Image, boxes: dict[str, list], resolutions: list[dict],
            unboxed: list[str] | None = None) -> dict:
    """O fecho das perdas herdadas: `pass`, `pending` ou `blocked`, com cada ocorrencia critica e o proximo passo.

    `boxes`: as caixas obrigatorias no PNG final (regioes criticas e marcos da ficha facial); `unboxed`: as regioes
    obrigatorias que ainda nao tem caixa no destino (as perdas nao se conseguem classificar contra elas)."""
    if lin is None:
        return {"status": "pending", "reasons": ["cadeia de etapas desconhecida: sem o JSON do forge (FORJA-15)"],
                "open_critical": [], "resolved": [], "minor": 0}
    sha, reasons, open_, resolved, errors = image_sha(candidate), [], [], [], []
    if lin.get("output_sha256") != sha:
        reasons.append("o candidato nao e a saida da cadeia (outra imagem): registe a etapa que o produziu")
    if lin["root"]["kind"] == "native_input":
        reasons.append("a cadeia comeca numa base ja nativa sem a etapa anterior (--lineage) nem a declaracao de que "
                       "e a origem (--native-root): as perdas de antes nao foram trazidas")
    by_id = {}
    for r in resolutions:
        by_id.setdefault(r.get("occurrence"), []).append(r)
    minor = 0
    for o in lin["occurrences"]:
        hit = sorted(set(o.get("regions", [])) | {k for k, b in boxes.items() if _inside(o.get("target_pixel"), b)})
        if not hit:
            minor += 1
            continue
        rec = {k: o.get(k) for k in ("id", "stage", "cell", "kind", "color", "kept", "target_pixel", "votes",
                                     "grid_confidence")} | {"regions": hit}
        outcome, why = "open", None
        for r in by_id.get(o["id"], []):
            if r.get("status") not in OUTCOMES or not (r.get("by") and r.get("date") and r.get("evidence")):
                errors.append(f"resolucao de {o['id']}: estado, autor, data ou evidencia em falta")
            elif r["status"] == "repaired":
                why = _proof(r, o, candidate, sha)
                outcome = "repaired" if why is None else outcome
            elif r["status"] == "excepted" and r.get("authorized_by"):
                outcome = "excepted"
            elif r["status"] == "inconclusive":
                outcome = "inconclusive"
        if outcome in ("repaired", "excepted"):
            resolved.append({**rec, "outcome": outcome})
            continue
        doubt = (o.get("grid_confidence") or 1) < GRID_DOUBT or o.get("kind") == "outside_core"
        open_.append({**rec, "outcome": outcome, "proof_refused": why,
                      "next_step": "redesenho nativo da regiao ou marcacao explicita (grade duvidosa ou traco mais "
                      "fino que a celula); corpo e equipamento fora da edicao" if doubt else
                      "reparo na mascara (forja patch) e resolucao repaired com os pixels desta imagem"})
    if unboxed and minor:
        reasons.append(f"{minor} perdas herdadas sem classificar: as regioes {unboxed} nao tem caixa no destino")
    blocked = [o for o in open_ if o["outcome"] == "open"]
    status = "blocked" if blocked or errors else "pending" if open_ or reasons else "pass"
    return {"status": status, "reasons": reasons + errors, "open_critical": open_, "resolved": resolved,
            "minor": minor, "stages": len(lin["stages"]), "root": lin["root"],
            "note": "zero perdas na ultima etapa nao encerra uma perda de antes; um reparo libera so a sua ocorrencia"}
