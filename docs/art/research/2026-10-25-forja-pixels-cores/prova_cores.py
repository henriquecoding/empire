#!/usr/bin/env python3
"""A prova do FORJA-04: a cor no espaco, a protecao ate ao fim e o tempo com intencao, sobre o codigo atual.

1. As provas do pacote (`pacote/provas-pixels-cores.py`, sem alteracao) correm contra `tools/forja` de agora, lado a
   lado com o que o pacote mediu no snapshot 4471cde: o que mudou, e o que ficou igual de proposito.
2. O elenco recuperado da figura de 24/10 (rei, arqueiro, escudeiro), conferido com as nove medidas do pacote; o
   diagnostico de cor de cada um, sem mexer em nada.
3. O arqueiro: a observacao de cores e o plano (rampas por material; rosto, bracos, arco e corda presos), o
   candidato, as diferencas, as zonas, as metricas por regiao e o que ficou por resolver; os vereditos de
   equipamento antes e depois (iguais: a corda larga e de outro reparo, o do FORJA-03).
4. O mesmo plano sobre a corda refeita do FORJA-03: as duas propostas juntas, e as mesmas mudancas de cor.
Grava tudo nesta pasta e falha se um resultado mudar. Sem rede, sem geracao, sem aprovacao.

    python3 docs/art/research/2026-10-25-forja-pixels-cores/prova_cores.py
"""
from __future__ import annotations

import json
import subprocess
import sys
import tempfile
from collections import Counter
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
sys.path.insert(0, str(ROOT))
from tools.forja import annotate, cleanup, cli, clusters, equipment  # noqa: E402
from tools.forja.imageops import open_rgba  # noqa: E402

ARMAS = ROOT / "docs/art/research/2026-10-24-forja-armas"
FIGURE, K, CARD = ARMAS / "entrega-examinada.png", 6, (35, 46, 60)
CAST = {"rei": ("royal_80", 80, (45, 193), 5), "arqueiro": ("royal_80", 80, (580, 193), 5),
        "escudeiro": ("royal_64", 64, (1163, 289), 0)}
ARCHER = HERE / "arqueiro"


def rel(path) -> str:
    return str(Path(path).resolve().relative_to(ROOT))


def package_proofs() -> dict:
    """O script do pacote, intacto, contra o codigo de agora; e a mesma tabela do pacote ao lado."""
    then = json.loads((HERE / "pacote/evidencias/resultados.json").read_text(encoding="utf-8"))["cases"]
    with tempfile.TemporaryDirectory() as tmp:
        subprocess.run([sys.executable, str(HERE / "pacote/provas-pixels-cores.py"), "--forja-dir",
                        str(ROOT / "tools/forja"), "--out", tmp], check=True, capture_output=True)
        now = json.loads((Path(tmp) / "resultados.json").read_text(encoding="utf-8"))["cases"]
    pick = {
        "scatter_vs_cluster_raster": lambda c: [[c[n]["lint"]["errors"], c[n]["lint"]["warnings"]]
                                                for n in ("scatter", "cluster")],
        "scatter_vs_cluster_coherence": lambda c: [c[n]["lint"].get("coherence", {}).get("status", "nao medido")
                                                   for n in ("scatter", "cluster")],
        "equal_histogram": lambda c: c["equal_histogram"],
        "budget_output_colors": lambda c: c["palette_and_color_budget"]["output_colors"],
        "protected_pixel_after_finish": lambda c: c["protection_scope"]["protected_pixel_after_finish"],
        "diagonal_helper_changed": lambda c: c["diagonal_helper"]["changed"],
        "area_1x4_and_2x2_islands": lambda c: [c["area_vs_footprint"]["1x4_islands_reported"],
                                               c["area_vs_footprint"]["2x2_islands_reported"]],
        "eye_blink_middle_frame_changes": lambda c: c["intentional_eye_blink"]["middle_frame_changes"],
        "moving_stripe_changed_pixels": lambda c: c["moving_near_color"]["changed_pixels"],
        "dither_zero_white_pixels": lambda c: c["dither_zero_helper"]["white_pixels"]}
    rows = {name: {"4471cde": f(then), "agora": f(now)} for name, f in pick.items()}
    expected = {"scatter_vs_cluster_raster": [[0, 0], [0, 0]], "scatter_vs_cluster_coherence": ["needs_review", "pass"],
                "equal_histogram": True, "budget_output_colors": 2,
                "protected_pixel_after_finish": [105, 105, 105, 255],
                "diagonal_helper_changed": 0, "area_1x4_and_2x2_islands": [[], []],
                "eye_blink_middle_frame_changes": 0, "moving_stripe_changed_pixels": 0, "dither_zero_white_pixels": 0}
    for name, want in expected.items():
        assert rows[name]["agora"] == want, (name, rows[name])
    strip, square = Image.new("RGBA", (10, 10)), Image.new("RGBA", (10, 10))
    for x in range(3, 7):
        strip.putpixel((x, 3), (240, 220, 60, 255))
    for x, y in ((3, 3), (4, 3), (3, 4), (4, 4)):
        square.putpixel((x, y), (240, 220, 60, 255))
    rows["footprint_without_block_1x4_and_2x2"] = {"4471cde": "nao medido", "agora": [
        cleanup.footprint(strip, 2)["without_block"], cleanup.footprint(square, 2)["without_block"]]}
    assert rows["footprint_without_block_1x4_and_2x2"]["agora"] == [1, 0]
    return rows


def recover(name: str) -> tuple[Path, dict]:
    kind, n, origin, title = CAST[name]
    px = Image.open(FIGURE).convert("RGB").load()
    out = Image.new("RGBA", (n, n))
    mixed = 0
    for gy in range(n):
        for gx in range(n):
            cell = Counter(px[origin[0] + gx * K + i, origin[1] + gy * K + j] for j in range(K) for i in range(K))
            rgb, count = cell.most_common(1)[0]
            if gy < title or rgb == CARD:
                continue
            mixed += count < K * K
            out.putpixel((gx, gy), (*rgb, 255))
    path = HERE / "elenco" / name / f"{name}.png"
    path.parent.mkdir(parents=True, exist_ok=True)
    out.save(path)
    want = json.loads((HERE / "pacote/evidencias/resultados.json").read_text(encoding="utf-8"))["assets"][name]
    stats = clusters.stats(out)
    assert mixed == 0 and stats == want["stats"], (name, mixed, stats)
    return path, {"kind": kind, "origin": list(origin), "mixed_cells": mixed, "pixels_sha256": equipment.image_sha(out),
                  "stats": stats, "matches_package": True}


def cast() -> dict:
    out = {}
    for name in CAST:
        path, info = recover(name)
        res = cli.run(["cores", rel(path), "--kind", info["kind"], "-o", rel(path.parent)])
        info.update(status=res["status"], counts=res["counts"], figure=res["metrics"]["figure"],
                    files={k: rel(v) for k, v in res["files"].items()})
        out[name] = info
    same = open_rgba(HERE / "elenco/arqueiro/arqueiro.png").tobytes() == \
        open_rgba(ARMAS / "arqueiro/arqueiro-recuperado.png").tobytes()
    assert same, "o arqueiro recuperado tem de ser o mesmo do FORJA-03"
    return out


def equip(image: Path, observation: Path, out: Path) -> dict:
    res = cli.run(["equip", rel(image), "--manifest", rel(ARMAS / "arqueiro/manifesto.json"), "--observation",
                   rel(observation), "--kind", "royal_80", "-o", rel(out)])
    return {"summary": res["summary"], "problems": res["problems"]}


def rebind(raw_path: Path, image: Path, out: Path, why: str) -> Path:
    """Os mesmos seletores de uma observacao, sobre outra imagem (o hash e o da imagem nova)."""
    raw = json.loads(raw_path.read_text(encoding="utf-8"))
    who = raw["observer"]
    again = equipment.observation(open_rgba(image), raw["regions"], {k: tuple(v) for k, v in raw["anchors"].items()},
                                  f"{who['author']} (seletores reaplicados)", f"{who['method']}; {why}", who["date"],
                                  source_observation=rel(raw_path))
    out.write_text(json.dumps(again, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    return out


def apply(image: Path, observation: Path, out: Path) -> dict:
    res = cli.run(["cores", rel(image), "--observation", rel(observation), "--plan", rel(ARCHER / "plano-cores.json"),
                   "--kind", "royal_80", "--name", "arqueiro", "-o", rel(out)])
    assert res["ok"] and res["locked"]["changed"] == 0 and res["outside_zone_changed"] == 0, res
    assert res["alpha_identical"] and not res["separation_lost"], res
    return res


def changed(a: Path, b: Path) -> set:
    pa, pb = open_rgba(a).load(), open_rgba(b).load()
    return {(x, y) for y in range(80) for x in range(80) if pa[x, y] != pb[x, y]}


def archer() -> dict:
    src = HERE / "elenco/arqueiro/arqueiro.png"
    res = apply(src, ARCHER / "observacao-cores.json", ARCHER / "cores")
    fixed = Path(res["files"]["png"])
    before = equip(src, ARMAS / "arqueiro/observacao.json", ARCHER / "equip/antes")
    after = equip(fixed, rebind(ARMAS / "arqueiro/observacao.json", fixed, ARCHER / "equip/observacao-depois.json",
                                "reaplicados ao candidato das cores"), ARCHER / "equip/depois")
    for axis in ("raster_contract", "equipment_geometry", "functional_pose"):
        assert before["summary"][axis] == after["summary"][axis], (axis, before, after)
    line = ARMAS / "arqueiro/depois/arqueiro-recuperado_line.png"
    both_dir = ARCHER / "corda-e-cores"
    both_dir.mkdir(parents=True, exist_ok=True)
    both = apply(line, rebind(ARCHER / "observacao-cores.json", line, both_dir / "observacao-cores.json",
                              "reaplicados a corda refeita do FORJA-03"), both_dir)
    both_png = Path(both["files"]["png"])
    final = equip(both_png, rebind(ARMAS / "arqueiro/depois/arqueiro-recuperado_line.observation.json", both_png,
                                   both_dir / "equip-observacao.json", "reaplicados a corda refeita e as cores"),
                  both_dir / "equip")
    assert final["summary"]["equipment_geometry"] == "pass", final
    assert changed(src, fixed) == changed(line, both_png), "as mudancas de cor tem de ser as mesmas"
    assert not changed(src, line) & changed(src, fixed), "a corda e as cores nao se tocam"
    annotate.strip([open_rgba(src), open_rgba(line), open_rgba(both_png)],
                   ["entrega", "corda refeita (FORJA-03)", "corda + cores (FORJA-04)"], 8).save(
        ARCHER / "comparacao.png")
    keep = ("changed_pixels", "locked", "outside_zone_changed", "alpha_identical", "merged", "kept", "remap",
            "status", "counts", "metrics", "separation_lost", "lint")
    return {"cores": {k: res[k] for k in keep}, "files": {k: rel(v) for k, v in res["files"].items()},
            "equip_before": before, "equip_after": after, "with_string_repair": {
                "changed_pixels": both["changed_pixels"], "equip": final,
                "files": {k: rel(v) for k, v in both["files"].items()}},
            "comparison": rel(ARCHER / "comparacao.png")}


def main() -> int:
    result = {"schema": "forja.prova_cores/1", "date": "2026-10-26", "network": False, "generation": False,
              "artistic_approval": "pending", "package_proofs": package_proofs(), "cast": cast(), "archer": archer()}
    (HERE / "prova.json").write_text(json.dumps(result, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    m = result["archer"]["cores"]["metrics"]["figure"]
    print(json.dumps({"ok": True, "archer_changed": result["archer"]["cores"]["changed_pixels"],
                      "S8": m["S8"], "components8": m["components8"], "U": m["U"]}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
