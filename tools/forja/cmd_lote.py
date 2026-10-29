"""`forja par` e `forja lote`: o objeto partilhado de uma dupla e o estado de cada personagem do elenco (FORJA-15).

- `par`: as duas imagens de uma dupla com a mesma restricao (`shared_prop_constraints`), cada uma com o manifesto
  (o item com o id da restricao, partes, oclusores, contactos e o `model`) e a observacao marcada nessa imagem. Mede o
  envelope nas duas, compara a forma com o modelo nativo e confere a pega (contactos); sem observacao, `pending`.
- `lote`: uma entrada por personagem do elenco, com ou sem candidato, e os estados separados (runtime, sinais,
  identidade, mestre, perdas herdadas, rotulo). Um personagem sem candidato aparece como tal; com `--previous`, diz os
  que ficaram iguais a entrega anterior. Nunca junta os estados numa nota.
Os dois so leem e escrevem o relatorio onde lhes dizem.
"""
from __future__ import annotations

import json
from pathlib import Path

from . import cast, contracts, equipment, fidelity, geometry, lineage, lint, palette as palmod, prop_shape, props
from . import review_state, visual_review
from .cli import command, out_path
from .imageops import open_rgba


def _side(data: dict, ident: str, png: str, manifest: str, observation: str, cid: str) -> tuple[dict, dict, dict]:
    entry = cast.character(data, ident)
    ch = fidelity.character(cast.authority(data, entry), entry["id"], entry.get("pose"))
    constraint = next((c for c in ch.get("shared_prop_constraints") or [] if c["id"] == cid), None)
    if constraint is None:
        raise ValueError(f"{entry['id']} nao declara a restricao partilhada {cid!r}")
    image, man = open_rgba(png), equipment.load(manifest)
    errors = equipment.validate(man)
    if errors:
        raise ValueError(f"manifesto de {entry['id']} invalido: " + "; ".join(errors))
    item = next((i for i in equipment.items(man) if i["id"] == cid), None)
    if item is None:
        raise ValueError(f"o manifesto de {entry['id']} nao tem o item {cid!r} (o id da restricao)")
    obs = equipment.observe(image, equipment.load(observation), Path(observation).parent)
    spec = item.get("model") or constraint.get("model")
    base = man["_base"] if item.get("model") else str(Path(cast.authority(data, entry)["base"]))
    shape = prop_shape.compare(props.load_model(spec, Path(base)), item, obs, constraint.get("allowed_variations")) \
        if spec else None
    grip = [c for c in geometry.evaluate(man, obs) if c["item"] == cid and c["check"] == "contact"]
    return constraint, {"character": entry["id"], "measure": prop_shape.measure(item, obs), "shape": shape}, \
        {"character": entry["id"], "contacts": grip}


def do_pair(args) -> dict:
    data = cast.load(args.catalog)
    if len(args.side or []) != 2:
        raise ValueError("par pede --side duas vezes: personagem png manifesto observacao")
    (ca, a, ga), (cb, b, gb) = (_side(data, *s, args.constraint) for s in args.side)
    if ca.get("paired_with") != b["character"]:
        raise ValueError(f"{a['character']} declara o par {ca.get('paired_with')!r}, nao {b['character']}")
    res = props.pair(ca, a, b)
    grip = [c for g in (ga, gb) for c in g["contacts"]]
    if any(c["status"] == "fail" for c in grip):
        res["status"] = "blocked"
    elif res["status"] == "pass" and any(c["status"] != "pass" for c in grip):
        res["status"] = "pending"
    res["contacts"] = [{k: c[k] for k in ("item", "part", "status", "detail")} for c in grip]
    if args.out:
        out_path(args.out, Path(args.out)).write_text(json.dumps(res, indent=1, ensure_ascii=False) + "\n",
                                                      encoding="utf-8")
    return {"ok": res["status"] != "blocked", **res, "read_only": True,
            "note": "o mesmo envelope nao e o mesmo molde; a cor do liquido e a oclusao declaradas nao reprovam"}


def _entry(data: dict, e: dict, folder: Path, previous: Path | None) -> dict:
    row = {"character": e["id"], "label_pt": e.get("label"), "kind": e["kind"]}
    png = folder / f"{e['id']}.png"
    if not png.is_file():
        return {**row, "candidate": None, "label": "no_candidate", "deliverable": False,
                "summary": None, "note": "sem candidato nesta pasta: continua no relatorio"}
    ch = fidelity.character(cast.authority(data, e), e["id"], e.get("pose"))
    image = open_rgba(png)
    c = contracts.get(ch["kind"])
    raster = lint.check(image, c, palmod.load(palmod.ROOT / c.palette), frame=bool(c.canvas))
    side = {k: folder / f"{e['id']}{suffix}" for k, suffix in
            (("forge", ".json"), ("visual", ".visual.json"), ("resolutions", ".resolutions.json"))}
    forge = json.loads(side["forge"].read_text(encoding="utf-8")) if side["forge"].is_file() else None
    visual = visual_review.load(side["visual"]) if side["visual"].is_file() else None
    res = lineage.load_resolutions(side["resolutions"] if side["resolutions"].is_file() else None)
    rev = review_state.review(ch, image, None, raster, forge, visual, res)
    old = previous / f"{e['id']}.png" if previous else None
    prev = open_rgba(old) if old and old.is_file() else None
    same = None if prev is None else prev.size == image.size and prev.tobytes() == image.tobytes()
    return {**row, "candidate": str(png), "pixels_sha256": rev["candidate_pixels_sha256"], "canvas": list(image.size),
            "summary": rev["summary"], "release": rev["release"]["status"],
            "open_critical_losses": len(rev["release"]["open_critical"]), "label": rev["label"],
            "deliverable": rev["deliverable"], "unchanged_from_previous": same,
            "face": rev["states"]["declared_feature_preservation"]["face"]["status"]}


def do_batch(args) -> dict:
    data = cast.load(args.catalog)
    folder, previous = Path(args.folder), Path(args.previous) if args.previous else None
    rows = [_entry(data, e, folder, previous) for e in data["characters"]]
    labels = {k: sum(1 for r in rows if r["label"] == k) for k in ("release", "study", "blocked", "no_candidate")}
    report = {"schema": "forja.batch_report/1", "cast": data["path"], "folder": str(folder), "entries": rows,
              "count": len(rows), "labels": labels, "deliverable": sum(1 for r in rows if r["deliverable"]),
              "unchanged_from_previous": sum(1 for r in rows if r.get("unchanged_from_previous")),
              "note": "uma entrada por personagem, estados separados; nenhum lote e finalizado sem a revisao do dono"}
    if args.out:
        out_path(args.out, Path(args.out)).write_text(json.dumps(report, indent=1, ensure_ascii=False) + "\n",
                                                      encoding="utf-8")
    return {"ok": True, **report}


def register(sub) -> None:
    p = command(sub, "par", "O objeto partilhado de uma dupla (o frasco dos alquimistas): envelope nas duas imagens, "
                "forma contra o modelo nativo e pega; so le", do_pair)
    p.add_argument("--constraint", required=True, help="o id da restricao (e do item nos manifestos)")
    p.add_argument("--side", nargs=4, action="append", metavar=("PERSONAGEM", "PNG", "MANIFESTO", "OBSERVACAO"),
                   help="uma imagem da dupla (duas vezes)")
    p.add_argument("--catalog", default=str(cast.DEFAULT), help="catalogo forja.cast/1")
    p.add_argument("-o", "--out", help="gravar o relatorio JSON")
    p = command(sub, "lote", "O relatorio do elenco: uma entrada por personagem (com ou sem candidato) e os estados "
                "separados, sem omitir os que nao mudaram; so le", do_batch)
    p.add_argument("folder", help="pasta com <id>.png e, se houver, <id>.json (forge), <id>.visual.json, "
                   "<id>.resolutions.json")
    p.add_argument("--previous", help="pasta da entrega anterior: diz quem ficou igual")
    p.add_argument("--catalog", default=str(cast.DEFAULT), help="catalogo forja.cast/1")
    p.add_argument("-o", "--out", help="gravar o relatorio JSON")
