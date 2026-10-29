#!/usr/bin/env python3
"""A prova do FORJA-11: cenarios e construcoes na Forja, sobre as referencias do pacote de 28/10.

1. As cinco referencias: tamanho, modo, hash dos pixels, alfa e a grade medida (o pixel aparente de cada uma).
2. A regua: os atores, o mundo e a fase da grade lidos dos ficheiros do jogo, e as metricas de arquitetura.
3. A escala: a oficina pelo barril dela; a Enramados pelo barril da oficina e pela porta da casa (os dois marcos nao
   tem escala comum: a referencia mistura escalas); a Enramados da conversa, sem grade medida.
4. Os contratos de cena do piloto (oficina, carvalho, faixa de terreno): validos, compilados e planeados para os tres
   geradores, sem rede.
5. A adaptacao reduzida da oficina (`--reduce`, a escala da regua): o que a amostragem apaga, a revisao estrutural e
   a bancada com os atores reais. Prova o metodo e mostra a perda; nao e um mestre nativo.
6. Um conjunto Wang de 16 com os 64+64 pares conferidos e os cachos nas emendas.
Sem rede, sem geracao paga, sem aprovacao. Grava em `evidencias/` e em `prova.json`; falha se uma medida mudar.
As imagens da bancada usam os atores do LFS quando existem; sem LFS, a caixa do corpo (o JSON nao muda).

    python3 docs/art/research/2026-10-28-forja-cenarios/prova_cenarios.py
"""
from __future__ import annotations

import csv
import json
import sys
import tempfile
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
sys.path.insert(0, str(ROOT))
from tools.forja import cli, contracts, gridcheck, montagem, refs, regua, scene, scene_plan, scene_prompt  # noqa: E402
from tools.forja import palette as palmod, tiles  # noqa: E402
from tools.forja.equipment import image_sha  # noqa: E402

REFS, OUT, CENAS = HERE / "referencias", HERE / "evidencias", HERE / "cenas"
MARKS = {"oficina": [((538, 780, 628, 887), "barrel_height")],
         "enramados": [((562, 541, 611, 600), "barrel_height"), ((1389, 519, 1429, 606), "door_clear_height")],
         "enramados-conversa": [((1389, 519, 1429, 606), "door_clear_height")]}
FILES = {"oficina": "oficina-referencia.png", "enramados": "enramados-referencia.png",
         "enramados-conversa": "enramados-referencia-conversa.png"}
CROPS = {"oficina": None, "enramados": (250, 200, 1120, 606), "enramados-conversa": (0, 0, 1672, 941)}
GROUND = {"oficina": 888, "enramados": 602, "enramados-conversa": 606}
checks: list[dict] = []


def footprint(building: str = "forge") -> int:
    """A largura que a simulacao da a obra: o `width_px` do `data/source/buildings.csv` (nao se escreve a mao)."""
    with open(ROOT / "data/source/buildings.csv", encoding="utf-8") as f:
        return int(next(r for r in csv.DictReader(f) if r["id"] == building)["width_px"])


def check(label: str, ok: bool, **detail) -> None:
    assert ok, (label, detail)
    checks.append({"check": label, "status": "pass", **detail})


def references() -> dict:
    out = {}
    for path in sorted(REFS.glob("*.png")):
        with Image.open(path) as im:
            rgba = im.convert("RGBA")
            alpha = rgba.getchannel("A").histogram()
            out[path.stem] = {"size": list(im.size), "mode": im.mode, "pixels_sha256": image_sha(im),
                              "alpha": {"clear": alpha[0], "partial": sum(alpha[1:255]), "opaque": alpha[255]}}
        g, _ = gridcheck.measure(rgba, None, None, False)
        out[path.stem]["grid"] = {"period": None if g.native else round(g.period[0], 3), "origin": g.as_dict()["origin"],
                                  "cells": list(g.as_dict()["cells"])}
    check("referencias", len(out) == 5, measured=sorted(out))
    check("oficina com alfa parcial", out["oficina-referencia"]["alpha"]["partial"] > 0)
    return out


def scales(found: list[dict]) -> dict:
    rul, wld, out = regua.ruler(), regua.world(), {}
    for name, marks in MARKS.items():
        ref = Image.open(REFS / FILES[name]).convert("RGBA")
        info = montagem.scale_reference(ref, [{"box": b, "target": tuple(regua.metric(found, m)["px"]), "metric": m}
                                              for b, m in marks], 2, CROPS[name], GROUND[name],
                                        footprint() if name != "enramados-conversa" else None)
        montagem.reference_bench(ref, info, wld, [rul["tallest"]["id"], rul["shortest"]["id"]]).save(
            OUT / f"escala-{name}.png")
        out[name] = info
    check("oficina: o detalhe e mais fino do que a celula", out["oficina"]["cell_ratio"] < 0.75,
          extent=out["oficina"]["target_extent_px"])
    check("enramados: barril e porta sem escala comum", not out["enramados"]["consistent"])
    check("barris convergem para a mesma oficina", abs(out["enramados"]["target_extent_px"][0]
                                                       - out["oficina"]["target_extent_px"][0]) <= 32)
    check("enramados da conversa sem grade", out["enramados-conversa"]["reference_grid"]["period"] is None)
    check("a oficina do pacote e um marco: a forja do jogo comprime a planta",
          out["oficina"]["plan"]["compression"] < 0.5, footprint=footprint(),
          compression=out["oficina"]["plan"]["compression"])
    return out


def scenes() -> dict:
    out = {}
    pal = palmod.load(palmod.ROOT / contracts.get("building").palette)
    register = refs.load(HERE / "registo.json")
    for path in sorted(CENAS.glob("*.json")):
        res = scene.resolve(scene.load(path))
        built = scene_prompt.build(res, "gpt-image", [r["role"] for r in res["references"]] + ["ruler", "palette"],
                                   palette=pal)
        plans = {}
        for backend in ("openai", "gemini", "pixellab"):
            p = scene_plan.make(backend, path, pal, register=register)
            plans[backend] = {"ok": p.ok, "errors": p.data["errors"], "request": p.data["request"],
                              "roles": [a["prompt_role"] for a in p.data["attachments"]]}
        out[path.stem] = {"cells": res["cells"], "warnings": res["warnings"], "size": built["size"],
                          "constraints": [c["origin"] for c in built["constraints"]], "plans": plans,
                          "prompt_lines": len(built["prompt"].splitlines())}
        if path.stem == "oficina-enramados":
            (OUT / "oficina-prompt.txt").write_text(built["prompt"] + "\n", encoding="utf-8")
            scene_prompt.ruler_guide(res, built["expect"]).save(OUT / "oficina-regua.png")
        check(f"{path.stem}: plano sem rede valido no gpt-image e no Gemini", plans["openai"]["ok"] and
              plans["gemini"]["ok"])
        lost = plans["pixellab"]["errors"]  # auditoria A5: a referencia que o create-image nao recebe e recusada
        check(f"{path.stem}: o PixelLab recusa as referencias que nao pode receber, em vez de as perder",
              not plans["pixellab"]["ok"] and all("nao chega" in e or "init_image" in e for e in lost),
              refused=len(lost))
        check(f"{path.stem}: nenhuma restricao escondida do compilador",
              "compiler_default" not in out[path.stem]["constraints"])
    return out


def adaptation(tmp: Path) -> dict:
    crop = Image.open(REFS / "oficina-referencia.png").convert("RGBA").crop((17, 145, 1527, 890))
    crop.save(tmp / "oficina.png")
    sc = CENAS / "oficina-enramados.json"
    res = cli.run(["forge", str(tmp / "oficina.png"), "-o", str(tmp / "forja"), "--kind", "building",
                   "--cells", "222x110", "--reduce", "--canvas", "448x224", "--pivot", "224,223",
                   "--name", "oficina-reduzida"])
    png = tmp / "forja" / "oficina-reduzida.png"
    Image.open(png).save(OUT / "oficina-reduzida.png")
    review = cli.run(["estrutura", str(png), "--scene", str(sc)])
    bench = montagem.bench(Image.open(png).convert("RGBA"), scene.resolve(scene.load(sc)))
    bench["day"].save(OUT / "montagem-oficina-dia.png")
    bench["night"].save(OUT / "montagem-oficina-noite.png")
    shrunk = cli.run(["forge", str(tmp / "oficina.png"), "-o", str(tmp / "encolhida"), "--kind", "building",
                      "--cells", f"{footprint() // 2 - 2}x{round((footprint() // 2 - 2) * crop.height / crop.width)}",
                      "--reduce", "--canvas", "128x136", "--pivot", "64,135", "--name", "oficina-encolhida"])
    small = tmp / "encolhida" / "oficina-encolhida.png"
    Image.open(small).save(OUT / "oficina-encolhida.png")
    against = cli.run(["estrutura", str(small), "--scene", str(CENAS / "forja-jogo-enramados.json")])
    bay = next(c for c in against["checks"] if c["check"] == "opening:baia")
    check("encolher a referencia a pegada fecha a baia: redesenhar, nao reduzir", bay["status"] == "fail",
          detail=bay["detail"], erased=shrunk["loss"]["erased_cells"])
    rules = sorted({f["rule"] for f in res["findings"]})
    check("a reducao e declarada e sai como adaptacao com perda", res["grid"]["origin"] == "deliberately_reduced"
          and "grid_reduced" in rules)
    check("a amostragem apagou celulas e di-lo", res["loss"]["erased_cells"] > 0, erased=res["loss"]["erased_cells"])
    check("a oficina reduzida cumpre a estrutura do contrato", review["verdicts"]["structure"] == "pass")
    check("a aprovacao fica pendente", review["verdicts"]["artistic_approval"] == "pending")
    return {"lint": {"errors": res["lint"]["errors"], "warnings": res["lint"]["warnings"], "rules": rules},
            "loss": res["loss"], "fit": res["fit"], "verdicts": review["verdicts"],
            "checks": [{k: c[k] for k in ("check", "status", "detail")} for c in review["checks"]],
            "placement": bench["placement"], "night_tint": bench["night_tint"]["rgb"],
            "encolhida": {"loss": shrunk["loss"], "bay": bay["detail"], "verdicts": against["verdicts"]}}


def wang() -> dict:
    soil = Image.new("RGBA", (32, 32), (92, 64, 40, 255))
    grass = Image.new("RGBA", (32, 32), (110, 160, 60, 255))
    for x in range(0, 32, 8):
        soil.paste((70, 48, 30, 255), (x, 12, x + 4, 16))
    sheet, _ = tiles.wang16(32, soil, grass, rim=Image.new("RGBA", (32, 32), (60, 44, 30, 255)), rim_width=2,
                            cluster=2)
    sheet.save(OUT / "wang16-terreno.png")
    joins, cut = tiles.pairs(sheet, 32, tiles.upper_class(grass)), tiles.junctions(sheet, 32, 2)
    check("wang 16: 64+64 pares e cachos inteiros nas emendas", cut["ok"] and joins["horizontal"]["pairs"] == 64,
          pairs_bad=joins["horizontal"]["bad_count"] + joins["vertical"]["bad_count"])
    return {"pairs": {k: joins[k]["bad_count"] for k in ("horizontal", "vertical")}, "junctions": {
        k: cut[k] for k in ("pairs_checked", "seam_islands", "blocks_checked", "corner_islands")}}


def main() -> int:
    OUT.mkdir(exist_ok=True)
    summary = regua.summary(2)
    found = summary["metrics"]
    result = {"referencias": references(),
              "regua": {"tallest": summary["ruler"]["tallest"], "shortest": summary["ruler"]["shortest"],
                        "world": {k: summary["world"][k] for k in ("viewport", "surface_y", "under_y", "horizon_y")},
                        "lattice": {k: summary["lattice"][k] for k in ("phase", "phase_source", "off_lattice")},
                        "metrics": {m["id"]: m["px"] for m in found}},
              "escala": scales(found), "cenas": scenes()}
    with tempfile.TemporaryDirectory() as tmp:
        result["adaptacao"] = adaptation(Path(tmp))
    result["wang"] = wang()
    check("a regua le o rei e a fase da arte do dono", summary["lattice"]["phase_source"] == "medida na arte do dono")
    result["checks"] = checks
    (HERE / "prova.json").write_text(json.dumps(result, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps({"ok": True, "checks": len(checks)}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
