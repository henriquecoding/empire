"""Subcomando `cores` (FORJA-04): a cor no espaco, diagnosticada e, com um plano, agrupada por regiao.

Sem plano so diagnostica: componentes de cor com 4 e 8 vizinhos, fragmentos de 1-3 pixels e o estado de cada um
(clusters.py), e a imagem dos candidatos. Com `--plan` (forja.cores/1) aplica as rampas por material e o
agrupamento com prova local (materials.py) e escreve o candidato a 1x e ampliado, o antes/depois/diferencas, as
zonas presas e editaveis, as metricas por regiao e o que ficou por resolver. E uma proposta: a leitura a 1x, no
jogo, e a aprovacao artistica sao do autor.

FORJA-06: o resultado diz o estado do material (`pending` com um pixel preso fora da rampa, mesmo com `ok`) e, antes e
depois, os pares em banding (banding.py) — suspeita, como os fragmentos.
"""
from __future__ import annotations

import json
from pathlib import Path

from . import annotate, banding, clusters, contracts, equipment, guard, lint, materials, palette as palmod
from .cli import box, command
from .imageops import open_rgba, upscale


def _raster(image, kind: str | None) -> dict | None:
    if not kind:
        return None
    c = contracts.get(kind)
    report = lint.check(image, c, palmod.load(palmod.ROOT / c.palette), frame=bool(c.canvas))
    return {"ok": report["ok"], "errors": report["errors"], "warnings": report["warnings"],
            "rules": sorted({f["rule"] for f in report["findings"]})}


def _dump(obj, depth: int = 0) -> str:
    """JSON legivel por cima e compacto por baixo: um candidato, uma linha."""
    if depth >= 3 or not isinstance(obj, (dict, list)) or not obj:
        return json.dumps(obj, ensure_ascii=False, separators=(", ", ": "))
    pad = " " * (depth + 1)
    items = ([f"{pad}{json.dumps(k, ensure_ascii=False)}: {_dump(v, depth + 1)}" for k, v in obj.items()]
             if isinstance(obj, dict) else [pad + _dump(v, depth + 1) for v in obj])
    open_, close = "{}" if isinstance(obj, dict) else "[]"
    return open_ + "\n" + ",\n".join(items) + "\n" + " " * depth + close


def _write(path: Path, data: dict) -> str:
    path.write_text(_dump(data) + "\n", encoding="utf-8")
    return str(path)


def _regions(image, args) -> tuple[dict, dict | None]:
    if not args.observation:
        return {}, None
    raw = equipment.load(args.observation)
    obs = equipment.observe(image, raw, Path(args.observation).parent)
    return materials.regions_from(raw, obs), obs["observer"]


def _metrics(diag: dict) -> dict:
    return {"figure": diag["figure"], **diag["regions"]}


def do_cores(args) -> dict:
    image = open_rgba(args.image)
    regions, observer = _regions(image, args)
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    stem, k = args.name or Path(args.image).stem, args.zoom
    head = {"image": args.image, "observation": args.observation, "observer": observer,
            "artistic_approval": "pending", "lint": _raster(image, args.kind)}
    if not args.plan:
        diag = clusters.diagnose(image, regions, guard.pixels(args.protect, image.size))
        annotate.candidates(image, diag, k).save(out / f"{stem}_cores_candidatos.png")
        files = {"candidates": str(out / f"{stem}_cores_candidatos.png")}
        bands = banding.find(image, regions)
        files["json"] = _write(out / f"{stem}_cores.json", {**head, "diagnosis": diag, "banding": bands})
        return {"ok": True, "status": diag["status"], "counts": diag["counts"], "metrics": _metrics(diag),
                "banding": {k: bands[k] for k in ("pairs", "horizontal", "vertical", "by_region", "status")},
                "files": files, "note": "diagnostico: nada mudou; review e suspeita, nao defeito confirmado"}
    plan = json.loads(Path(args.plan).read_text(encoding="utf-8"))
    master = palmod.load(args.palette or plan.get("palette") or "empire")
    result, rep = materials.apply(image, plan, regions, master)
    result.save(out / f"{stem}_cores.png")
    upscale(result, k).save(out / f"{stem}_cores@{k}x.png")
    annotate.strip([image, result, annotate.diff(image, result)], ["antes", "depois", "diferencas"], k).save(
        out / f"{stem}_cores_compare.png")
    locked = frozenset().union(*[regions[n]["pixels"] for n in plan.get("lock", [])])
    zone = frozenset().union(*[regions[n]["pixels"] for n in plan.get("regions", {})]) - locked
    annotate.overlay(image, {"preso": locked, "editavel": zone}, {}, k,
                     {"preso": (72, 168, 255), "editavel": (90, 230, 130)}).save(out / f"{stem}_cores_zonas.png")
    annotate.candidates(image, rep["before"], k).save(out / f"{stem}_cores_candidatos_antes.png")
    annotate.candidates(result, rep["after"], k).save(out / f"{stem}_cores_candidatos_depois.png")
    files = {"png": str(out / f"{stem}_cores.png"), "preview": str(out / f"{stem}_cores@{k}x.png"),
             "compare": str(out / f"{stem}_cores_compare.png"), "regions": str(out / f"{stem}_cores_zonas.png"),
             "candidates_before": str(out / f"{stem}_cores_candidatos_antes.png"),
             "candidates_after": str(out / f"{stem}_cores_candidatos_depois.png")}
    after_lint = _raster(result, args.kind)
    remaining = [c for c in rep["after"]["candidates"] if c["status"] in ("review", "inconclusive")]
    written = {k: v for k, v in rep.items() if k not in ("before", "after")}
    bands = {"before": banding.find(image, regions), "after": banding.find(result, regions)}
    files["json"] = _write(out / f"{stem}_cores.json", {**head, "plan": plan, "lint_after": after_lint, **written,
                                                        "remaining": remaining, "banding": bands,
                                                        "not_measured": rep["after"]["not_measured"]})
    lost = [s["pair"] for s in rep["separation"] if s["lost"]]
    return {"ok": rep["ok"] and (after_lint is None or after_lint["ok"]), "changed_pixels": rep["changed_pixels"],
            "locked": rep["locked"], "outside_zone_changed": rep["outside_zone_changed"],
            "alpha_identical": rep["alpha_identical"], "merged": len(rep["regroup"]["merged"]),
            "kept": len(rep["regroup"]["kept"]), "remap": {n: r["changed"] for n, r in rep["remap"].items()},
            "status": rep["status"], "counts": rep["counts"], "metrics": rep["metrics"], "separation_lost": lost,
            "lint": {"before": head["lint"], "after": after_lint}, "files": files, "material": rep["material"],
            "banding": {k: v["pairs"] for k, v in bands.items()},
            "note": "ok so prova o que nao mudou; um material pending impede a aprovacao do material; a leitura a 1x "
                    "e a aprovacao sao do autor"}


def register(sub) -> None:
    p = command(sub, "cores", "A cor no espaco: fragmentos de cor N4/N8 e o estado de cada um; com --plan, rampas "
                "por material e agrupamento so nas regioes editaveis, com o resto provado igual", do_cores)
    p.add_argument("image")
    p.add_argument("-o", "--out", required=True, help="pasta de saida")
    p.add_argument("--observation", help="regioes marcadas NESTA imagem (forja.observation/1), com role e material")
    p.add_argument("--plan", help="plano de cores (forja.cores/1): lock, rampas por regiao, onde agrupar")
    p.add_argument("--palette", help="paleta mestra das rampas (por omissao a do plano, ou empire)")
    p.add_argument("--kind", choices=contracts.kinds(), help="tambem conferir o contrato raster antes e depois")
    p.add_argument("--protect", type=box, action="append", help="caixa x0,y0,x1,y1 protegida no diagnostico")
    p.add_argument("--name", help="nome dos ficheiros de saida")
    p.add_argument("--zoom", type=int, default=8, help="ampliacao inteira das imagens de revisao")
