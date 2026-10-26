"""Subcomandos do equipamento (FORJA-03): `equip` julga uma imagem contra o manifesto e a observacao;
`line` refaz uma linha fina (a corda) so dentro da mascara e julga o antes e o depois."""
from __future__ import annotations

import json
from pathlib import Path

from . import annotate, compose, contracts, equipment, geometry, lint, palette as palmod, repair
from .cli import command
from .imageops import open_rgba, upscale


def _load(args):
    image = open_rgba(args.image)
    manifest = equipment.load(args.manifest)
    errors = equipment.validate(manifest)
    if errors:
        raise ValueError("manifesto invalido: " + "; ".join(errors))
    raw = equipment.load(args.observation)
    base = Path(args.observation).parent
    return image, manifest, raw, equipment.observe(image, raw, base), base


def _raster(image, args) -> dict | None:
    if not args.kind:
        return None
    c = contracts.get(args.kind)
    pal = None if args.palette == "none" else palmod.load(args.palette or palmod.ROOT / c.palette)
    return lint.check(image, c, pal, frame=bool(c.canvas))


def _lint_summary(report: dict | None) -> dict | None:
    if report is None:
        return None
    return {"ok": report["ok"], "errors": report["errors"], "warnings": report["warnings"],
            "rules": sorted({f["rule"] for f in report["findings"]})}


def _write(path: Path, data: dict) -> str:
    path.write_text(json.dumps(data, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    return str(path)


def _failed(result: dict) -> list[str]:
    return [c["detail"] for c in result["checks"] if c["status"] in ("fail", "inconclusive")]


def do_equip(args) -> dict:
    image, manifest, _, obs, _ = _load(args)
    report = _raster(image, args)
    result = geometry.review(manifest, obs, report["ok"] if report else None,
                             coherence=report["coherence"] if report else None)
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    stem = Path(args.image).stem
    annotate.overlay(image, obs["regions"], obs["anchors"], args.zoom).save(out / f"{stem}_equip.png")
    files = {"preview": str(out / f"{stem}_equip.png")}
    files["json"] = _write(out / f"{stem}_equip.json", {
        "image": args.image, "image_sha256": obs["image_sha256"], "manifest": args.manifest,
        "observation": args.observation, "observer": obs["observer"], "lint": _lint_summary(report), **result})
    return {"ok": not result["blocking"], "summary": result["summary"], "blocking": result["blocking"],
            "problems": _failed(result), "files": files,
            "note": "ok so diz que nada falhou; o que esta not_evaluated continua por avaliar e a aprovacao e do autor"}


def do_line(args) -> dict:
    image, manifest, raw, obs, base = _load(args)
    item = next((i for i in equipment.items(manifest) if i["id"] == args.item), None)
    if item is None or not item["line"]:
        raise ValueError(f"{args.item}: nao ha esse objeto no manifesto, ou a familia dele nao tem linha fina")
    name = f"{item['id']}.{item['line']}"
    a, b = (obs["anchors"].get(f"{item['id']}.{k}") for k in item["anchors"])
    if name not in obs["regions"] or a is None or b is None:
        raise ValueError(f"a observacao precisa da regiao {name} e das ancoras {', '.join(item['anchors'])}")
    line = obs["regions"][name]
    keep = frozenset().union(*[obs["regions"].get(n, frozenset())
                               for n in item["parts"][item["line"]]["occluders"]])
    candidate, zone, info = repair.straighten(image, line, a, b, keep)
    others = frozenset().union(*[r for n, r in obs["regions"].items() if n != name])
    fixed, proof = compose.compose(image, candidate, zone, "replace", others - zone, old=line, joints=[a, b])
    proof["protected_overlap"] = len(others & zone)
    who = raw["observer"]
    again = equipment.observation(fixed, raw["regions"], obs["anchors"], f"{who['author']} (seletores reaplicados)",
                                  f"{who['method']}; os mesmos seletores, reaplicados a imagem reparada pela forja line",
                                  who["date"], source_observation=args.observation)
    before = geometry.review(manifest, obs, (_raster(image, args) or {}).get("ok"))
    report = _raster(fixed, args)
    after = geometry.review(manifest, equipment.observe(fixed, again, base), report["ok"] if report else None)
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    stem = Path(args.image).stem
    fixed.save(out / f"{stem}_line.png")
    upscale(fixed, args.zoom).save(out / f"{stem}_line@{args.zoom}x.png")
    annotate.strip([image, fixed], ["antes", "depois"], args.zoom).save(out / f"{stem}_line_compare.png")
    annotate.overlay(fixed, {f"zona do reparo ({name})": zone}, dict(zip(item["anchors"], (a, b))), args.zoom).save(
        out / f"{stem}_line_mask.png")
    files = {"png": str(out / f"{stem}_line.png"), "preview": str(out / f"{stem}_line_compare.png"),
             "mask": str(out / f"{stem}_line_mask.png"),
             "observation": _write(out / f"{stem}_line.observation.json", again)}
    files["json"] = _write(out / f"{stem}_line.json", {
        "image": args.image, "item": item["id"], "repair": info, "compose": proof, "lint_after": _lint_summary(report),
        "before": before, "after": after, "artistic_approval": "pending"})
    return {"ok": proof["ok"] and not after["blocking"], "repair": {k: v for k, v in info.items() if k != "note"},
            "compose": {k: proof[k] for k in ("ok", "outside_identical", "protected_identical", "changed_pixels")},
            "before": before["summary"], "after": after["summary"], "problems_after": _failed(after), "files": files}


def _common(p) -> None:
    p.add_argument("image")
    p.add_argument("--manifest", required=True, help="o manifesto de equipamento (intencao), forja.equipment/1")
    p.add_argument("--observation", required=True, help="regioes e ancoras marcadas NESTA imagem, forja.observation/1")
    p.add_argument("--kind", choices=contracts.kinds(), help="tambem conferir o contrato raster deste tipo")
    p.add_argument("--palette", help="paleta do lint (por omissao a do contrato)")
    p.add_argument("--zoom", type=int, default=8, help="ampliacao inteira das imagens de revisao")
    p.add_argument("-o", "--out", required=True, help="pasta de saida")


def register(sub) -> None:
    p = command(sub, "equip", "Vereditos de equipamento: partes, lamina, corda e contactos contra o manifesto, "
                "sobre regioes observadas; o que falta observar fica por avaliar", do_equip)
    _common(p)
    p = command(sub, "line", "Refazer uma linha fina (a corda) a 1 px entre as ancoras, so dentro da mascara; "
                "fora dela e nas regioes protegidas, pixels identicos", do_line)
    _common(p)
    p.add_argument("--item", required=True, help="o id do objeto no manifesto (ex.: bow_main)")
