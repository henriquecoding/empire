"""Subcomandos do equipamento (FORJA-03): `equip` julga uma imagem contra o manifesto e a observacao;
`line` refaz uma linha fina (a corda) so dentro da mascara e julga o antes e o depois.

FORJA-06: o miolo e o contorno separam-se (`--core`, `--core-box`; o resto da regiao da linha fica protegido), a cor e
declarada (`--color`, ou as cores do seletor) e vai para todo o miolo; sem ela o reparo e inconclusivo."""
from __future__ import annotations

import json
from pathlib import Path

from . import annotate, color, compose, contracts, equipment, geometry, lint, masks, palette as palmod, repair
from .cli import box, command
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


def _intent(args, raw: dict, core_name: str | None) -> tuple[list | None, str | None]:
    """A cor do miolo: a de --color, ou as cores do seletor da regiao do miolo na observacao. Nunca a maioria."""
    hexes = args.color.split(",") if args.color else (raw["regions"].get(core_name) or {}).get("colors")
    if not hexes:
        return None, None
    pal = palmod.load(args.palette or (palmod.ROOT / contracts.get(args.kind).palette if args.kind else "empire"))
    rgb = [color.parse_hex(h.strip()) for h in hexes]
    off = [color.to_hex(c) for c in rgb if c not in pal]
    if off:
        raise ValueError(f"cor do traco fora da paleta {pal.name or ''}: {', '.join(off)}")
    return rgb, "declared" if args.color else "observation"


def do_line(args) -> dict:
    image, manifest, raw, obs, base = _load(args)
    item = next((i for i in equipment.items(manifest) if i["id"] == args.item), None)
    if item is None or not item["line"]:
        raise ValueError(f"{args.item}: nao ha esse objeto no manifesto, ou a familia dele nao tem linha fina")
    name = f"{item['id']}.{item['line']}"
    a, b = (obs["anchors"].get(f"{item['id']}.{k}") for k in item["anchors"])
    if name not in obs["regions"] or (args.mode == "reroute" and (a is None or b is None)):
        raise ValueError(f"a observacao precisa da regiao {name} e das ancoras {', '.join(item['anchors'])}")
    keep = frozenset().union(*[obs["regions"].get(n, frozenset())
                               for n in item["parts"][item["line"]]["occluders"]])
    core_name = args.core or (None if args.core_box else name)
    if core_name and core_name not in obs["regions"]:
        raise ValueError(f"o miolo {core_name} nao esta na observacao")
    line = obs["regions"][core_name] if core_name else masks.box(args.core_box, image.size) - keep
    colors, source = _intent(args, raw, core_name)
    if colors is None:
        found = sorted({color.to_hex(image.getpixel(p)[:3]) for p in line if image.getpixel(p)[3] >= 128})
        return {"ok": False, "status": "inconclusive", "item": item["id"], "core_pixels": len(line),
                "colors_in_core": found, "why": "a cor do miolo nao esta declarada (--color, ou colors no seletor "
                "da regiao): com varias cores na selecao, a maioria nao decide o material"}
    outline = obs["regions"][name] - line
    others = frozenset().union(*[r for n, r in obs["regions"].items() if n != name]) | outline
    if args.mode == "fill":
        candidate, zone, info = repair.fill(image, line, colors)
    else:
        candidate, zone, info = repair.straighten(image, line, a, b, keep, colors)
    compose.refuse_protected(zone, others)
    fixed, proof = compose.compose(image, candidate, zone, "replace", others,
                                   old=line if args.mode == "reroute" else frozenset(),
                                   joints=[a, b] if args.mode == "reroute" else ())
    proof["protected_overlap"] = len(others & zone)
    moved = ("core_pixels", "kept", "filled") if args.mode == "fill" else ("repainted",)
    paint = {"mode": args.mode, "source": source, "colors": [color.to_hex(c) for c in colors],
             "core": core_name or list(args.core_box), "core_pixels": len(line), "outline_protected": len(outline),
             **{k: info.pop(k) for k in moved}}
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
    ends = {k: v for k, v in zip(item["anchors"], (a, b)) if v}
    annotate.overlay(fixed, {f"zona do reparo ({name})": zone}, ends, args.zoom).save(out / f"{stem}_line_mask.png")
    files = {"png": str(out / f"{stem}_line.png"), "preview": str(out / f"{stem}_line_compare.png"),
             "mask": str(out / f"{stem}_line_mask.png"),
             "observation": _write(out / f"{stem}_line.observation.json", again)}
    files["json"] = _write(out / f"{stem}_line.json", {
        "image": args.image, "item": item["id"], "repair": info, "paint": paint, "compose": proof,
        "lint_after": _lint_summary(report), "before": before, "after": after, "artistic_approval": "pending"})
    return {"ok": proof["ok"] and not after["blocking"], "status": "candidate", "paint": paint,
            "repair": {k: v for k, v in info.items() if k != "note"},
            "compose": {k: proof[k] for k in ("ok", "outside_identical", "protected_identical", "changed_pixels")},
            "before": before["summary"], "after": after["summary"], "problems_after": _failed(after), "files": files,
            "artistic_approval": "pending"}


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
    p = command(sub, "line", "Refazer uma linha fina (a corda) a 1 px entre as ancoras, so dentro da mascara e na cor "
                "declarada; fora dela, no contorno e nas regioes protegidas, pixels identicos", do_line)
    _common(p)
    p.add_argument("--item", required=True, help="o id do objeto no manifesto (ex.: bow_main)")
    p.add_argument("--color", help="a cor do miolo e da familia dele, hex separados por virgula (a primeira e a base); "
                   "sem ela, as colors do seletor da regiao; sem nenhuma, inconclusivo")
    p.add_argument("--core", help="a regiao da observacao que e o miolo (por omissao a da linha)")
    p.add_argument("--core-box", type=box, help="o miolo como caixa x0,y0,x1,y1, sem os oclusores; o resto da "
                   "regiao da linha (o contorno) fica protegido")
    p.add_argument("--mode", default="reroute", choices=("reroute", "fill"),
                   help="reroute: a linha nova entre as ancoras; fill: pintar o miolo declarado tal como esta")
