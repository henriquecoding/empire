#!/usr/bin/env python3
"""A prova pequena do FORJA-03: o arqueiro, uma pose estatica, arco, corda e empunhadura.

1. Recupera o arqueiro 80x80 da figura do relatorio (`entrega-examinada.png`, ampliacao 6x sem suavizacao):
   cada celula 6x6 tem uma so cor dentro do sprite; o fundo do cartao e o titulo ficam de fora. Os PNG
   originais da entrega nao estao no repositorio; esta copia confere com as medidas do relatorio (37 cores,
   altura util 74 px).
2. `forja equip` com o manifesto e a observacao marcada a mao: vereditos da entrega.
3. `forja line`: a corda refeita a 1 px entre as pontas, so dentro da mascara; vereditos depois.
4. As fixtures do relatorio (espada) e as do arco, com o lint raster e a geometria lado a lado.
5. As duas sondas do contorno global (corda engrossada, vazio fechado), sem e com a protecao.
Grava tudo nesta pasta e falha se um resultado mudar. Sem rede, sem geracao, sem aprovacao.

    python3 docs/art/research/2026-10-24-forja-armas/prova_arqueiro.py
"""
from __future__ import annotations

import hashlib
import json
import sys
from collections import Counter
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
sys.path.insert(0, str(ROOT))
from tools.forja import cli, contracts, equipment, geometry, lint, masks, outline  # noqa: E402
from tools.forja import palette as palmod  # noqa: E402
from tools.forja.imageops import flat, opaque_bbox, upscale  # noqa: E402
from tools.forja.tests import equip_fixtures as F  # noqa: E402

FIGURE, ARCHER = HERE / "entrega-examinada.png", HERE / "arqueiro"
ORIGIN, K, CARD, TITLE_ROWS = (580, 193), 6, (35, 46, 60), 5


def rel(path) -> str:
    return str(Path(path).resolve().relative_to(ROOT))


def recover() -> dict:
    fig = Image.open(FIGURE).convert("RGB")
    px = fig.load()
    out = Image.new("RGBA", (80, 80))
    mixed_inside = 0
    for gy in range(80):
        for gx in range(80):
            cell = Counter(px[ORIGIN[0] + gx * K + i, ORIGIN[1] + gy * K + j] for j in range(K) for i in range(K))
            rgb, n = cell.most_common(1)[0]
            if gy < TITLE_ROWS or rgb == CARD:
                continue
            mixed_inside += n < K * K
            out.putpixel((gx, gy), (*rgb, 255))
    path = ARCHER / "arqueiro-recuperado.png"
    out.save(path)
    box = opaque_bbox(out)
    colors = len({p[:3] for p in flat(out) if p[3]})
    info = {"source": rel(FIGURE), "source_sha256": hashlib.sha256(FIGURE.read_bytes()).hexdigest(),
            "origin": list(ORIGIN), "scale": K, "card_background": "#%02X%02X%02X" % CARD,
            "ignored_title_rows": TITLE_ROWS, "mixed_cells_inside_sprite": mixed_inside, "png": rel(path),
            "pixels_sha256": equipment.image_sha(out), "opaque_colors": colors, "useful_height": box[3] - box[1],
            "matches_report": colors == 37 and box[3] - box[1] == 74}
    assert info["matches_report"] and mixed_inside == 0, info
    return info


def archer() -> dict:
    common = ["--manifest", rel(ARCHER / "manifesto.json"), "--observation", rel(ARCHER / "observacao.json"),
              "--kind", "royal_80"]
    before = cli.run(["equip", rel(ARCHER / "arqueiro-recuperado.png"), *common, "-o", rel(ARCHER / "antes")])
    fixed = cli.run(["line", rel(ARCHER / "arqueiro-recuperado.png"), *common, "--item", "bow_main",
                     "-o", rel(ARCHER / "depois")])
    after = cli.run(["equip", rel(fixed["files"]["png"]), "--manifest", rel(ARCHER / "manifesto.json"),
                     "--observation", rel(fixed["files"]["observation"]), "--kind", "royal_80",
                     "-o", rel(ARCHER / "depois")])
    assert before["blocking"] == ["equipment_geometry"] and len(before["problems"]) == 1, before
    assert fixed["ok"] and fixed["compose"]["outside_identical"] and fixed["compose"]["protected_identical"], fixed
    assert after["ok"] and after["summary"]["equipment_geometry"] == "pass", after
    return {"before": {k: before[k] for k in ("summary", "problems")}, "repair": fixed["repair"],
            "compose": fixed["compose"], "after": {k: after[k] for k in ("summary", "problems")},
            "files": {k: rel(v) for k, v in {**before["files"], **{f"line_{a}": b for a, b in fixed["files"].items()},
                                              "after_overlay": after["files"]["preview"]}.items()}}


def fixtures() -> dict:
    c = contracts.get("royal_80")
    pal = palmod.load(palmod.ROOT / c.palette)
    cases = [("sword", n, F.sword(n)) for n in ("reference", "forked", "two_guards", "none", "grip_hidden")]
    cases += [("bow", n, F.bow(n)) for n in ("valid", "wide", "double", "short", "wavy")]
    rows, tiles = {}, []
    for kind, name, img in cases:
        obs = (F.sword_observation if kind == "sword" else F.bow_observation)(img)
        manifest = F.sword_manifest() if kind == "sword" else F.bow_manifest()
        raster = lint.check(img, c, pal)
        r = geometry.review(manifest, equipment.observe(img, obs), raster["ok"])
        rows[f"{kind}/{name}"] = {"lint_errors": raster["errors"], **{k: r["summary"][k] for k in
                                  ("raster_contract", "equipment_geometry", "functional_pose")},
                                  "problems": [x["detail"] for x in r["checks"] if x["status"] == "fail"]}
        tiles.append((f"{kind}/{name}", img, r["summary"]["equipment_geometry"], raster["errors"]))
    expected = {"sword/reference": "pass", "sword/grip_hidden": "pass", "bow/valid": "pass"}
    for key, row in rows.items():
        assert row["lint_errors"] == 0, key
        assert row["equipment_geometry"] == expected.get(key, "fail"), (key, row)
    font = ImageFont.load_default()
    sheet = Image.new("RGBA", (5 * 250, 2 * 300), (26, 32, 44, 255))
    draw = ImageDraw.Draw(sheet)
    for i, (label, img, geo, errors) in enumerate(tiles):
        x, y = i % 5 * 250 + 10, i // 5 * 300 + 8
        draw.text((x, y), label, fill=(240, 228, 190, 255), font=font)
        sheet.alpha_composite(upscale(img, 3), (x, y + 14))
        draw.text((x, y + 258), f"lint: {errors} erros", fill=(235, 235, 235, 255), font=font)
        draw.text((x, y + 272), f"geometria: {geo}", fill=(120, 230, 140, 255) if geo == "pass" else
                  (255, 120, 120, 255), font=font)
    sheet.save(HERE / "fixtures.png")
    return rows


def probes() -> dict:
    img = Image.new("RGBA", (16, 16))
    for y in range(2, 14):
        for x in (4, 8, 11):
            img.putpixel((x, y), (229, 211, 149, 255))
    width = lambda im: sum(im.getpixel((x, 7))[3] > 0 for x in range(2, 7))  # noqa: E731
    gap = lambda im: [im.getpixel((x, 7))[3] > 0 for x in (9, 10)]  # noqa: E731
    plain, kept = outline.add(img), outline.add(img, keep=masks.box((0, 0, 16, 16)))
    out = {"string_width": {"before": width(img), "global_outline": width(plain), "protected": width(kept)},
           "gap_of_2_closed": {"global_outline": all(gap(plain)), "protected": all(gap(kept))}}
    assert out["string_width"] == {"before": 1, "global_outline": 3, "protected": 1}, out
    return out


def main() -> int:
    result = {"schema": "forja.prova_arqueiro/1", "date": "2026-10-25", "network": False, "generation": False,
              "artistic_approval": "pending", "recovery": recover(), "archer": archer(), "fixtures": fixtures(),
              "outline_probes": probes()}
    (HERE / "prova.json").write_text(json.dumps(result, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps({"ok": True, "before": result["archer"]["before"]["summary"]["equipment_geometry"],
                      "after": result["archer"]["after"]["summary"]["equipment_geometry"]}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
