#!/usr/bin/env python3
"""A prova do FORJA-07: os ensaios da auditoria de 27/10 (revisao 2) refeitos com a Forja deste ramo.

A auditoria caracterizou o comportamento antigo (`AUDITORIA.md`, §12-§14): 60 configuracoes do amostrador, 12 passagens
pelo pipeline e 21 perturbacoes de grade. Aqui os mesmos casos viram regressao, com os criterios do
`PLANO-DE-IMPLEMENTACAO.md`:
1. amostrador: nenhuma marca declarada some sem ficar nos dados de perda; o controlo de celula inteira nunca e perda;
   a pureza e medida em todos os metodos;
2. pipeline: o traco de borda e a linha sobre o vazio dao o achado `erased`; a grade de periodo 2 que nao cabe na tela
   de 16x16 da `grid_budget` com as zonas finas; uma grade dada mais grossa e `deliberately_reduced`; uma regiao
   declarada com a celula apagada bloqueia;
3. grade: os 12 controlos PNG inteiros continuam exatos; nos 6 JPEG a silhueta volta e a cor original nao se afirma;
   nas 3 bilineares a medida diz que nao mediu;
4. autoridade e revisao, no contrato real (`fidelidade.json`): o arqueiro de tunica verde e `reference_conflict`; o
   pedido fiel leva o recorte e nenhuma preferencia do compilador; os rejeitados ficam `blocked` na identidade.
Sem rede, sem geracao, sem aprovacao. Grava `prova.json` e `evidencias/`; falha se um criterio nao se cumprir.

    python3 docs/art/research/2026-10-27-forja-auditoria-fidelidade/prova_auditoria.py
"""
from __future__ import annotations

import io
import json
import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageFilter

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
sys.path.insert(0, str(ROOT))
from tools.forja import fidelity, gridcheck, loss, pipeline, plan, review_state, signals  # noqa: E402
from tools.forja.imageops import flat, opaque_bbox, upscale  # noqa: E402
from tools.forja.resample import METHODS, resample  # noqa: E402
from tools.forja.tests import audit_fixtures as fx  # noqa: E402

OUT = HERE / "evidencias"
CONTRACT = HERE / "fidelidade.json"
TARGETS = {**{name: [fx.CELL] for name in fx.MARKS}, "fio_alfa": fx.LINE_CELLS}
checks: list[dict] = []


def check(label: str, ok: bool, **detail) -> None:
    assert ok, (label, detail)
    checks.append({"check": label, "status": "pass", **detail})


def sampler() -> list[dict]:
    g = gridcheck.phased((fx.K * fx.N, fx.K * fx.N), fx.K, (0, 0), "fixture")
    cases, control, rows = fx.cases(), {}, []
    for name, image in cases.items():
        reference = fx.base() if name != "fio_alfa" else _line_base()
        for inset in (0.18, 0.0):
            for method in METHODS:
                out = resample(image, g, method, inset=inset)
                ctrl = control.setdefault((name, inset, method), resample(reference, g, method, inset=inset))
                lost = loss.observe(image, g, out.image, inset)
                cells = {tuple(e["cell"]) for e in lost["erased"]}
                gone = [c for c in TARGETS[name] if out.image.getpixel(c) == ctrl.image.getpixel(c)]
                rows.append({"case": name, "method": method, "inset": inset, "purity": round(out.purity, 4),
                             "feature_cells": len(TARGETS[name]), "erased_by_vote": len(gone),
                             "reported": len([c for c in gone if c in cells]), "erased_cells": lost["erased_cells"],
                             "by_kind": lost["by_kind"]})
    silent = [r for r in rows if r["reported"] < r["erased_by_vote"]]
    check("amostrador: nenhuma marca apagada fica fora dos dados de perda", not silent, configurations=len(rows),
          erased_marks=sum(r["erased_by_vote"] > 0 for r in rows))
    check("amostrador: o controlo de celula inteira nunca e perda",
          all(r["erased_cells"] == 0 for r in rows if r["case"] == "pixel_inteiro"))
    edge = [r for r in rows if r["case"] == "borda" and r["method"] == "dominant" and r["inset"] == 0.18][0]
    check("amostrador: o traco de borda tem pureza 1,0 e fica escrito como fora do miolo",
          edge["purity"] == 1.0 and edge["by_kind"]["outside_core"] == 1)
    return rows


def _line_base() -> Image.Image:
    image = fx.line()
    image.paste((0, 0, 0, 0), (10 * fx.K, 2 * fx.K, 11 * fx.K, 14 * fx.K))
    return image


def _forge(image: Image.Image, name: str, **kw) -> dict:
    with tempfile.TemporaryDirectory() as tmp:
        image.save(Path(tmp) / f"{name}.png")
        opts = pipeline.Options(kind="free", palette="none", noise=0, cleanup="conservative", outline="keep",
                                fit=False, bg="#FF00FF", canvas=(16, 16), **kw)
        return pipeline.forge(Path(tmp) / f"{name}.png", Path(tmp) / "o", opts, name=name, report_html=False)


def through_pipeline() -> list[dict]:
    rows = []
    for name, image in fx.cases().items():
        for mode in ("known", "auto"):
            res = _forge(image, name, scale=16 if mode == "known" else None)
            rep = res["snap"]["grid_report"]
            rows.append({"case": name, "mode": mode, "origin": rep["origin"], "period": rep["period"],
                         "native_size": rep["native_size"], "fits_target": rep["fits_target"],
                         "erased_cells": res["snap"]["loss"]["erased_cells"],
                         "rules": sorted({f["rule"] for f in res["lint"]["findings"]}),
                         "mixed_scale": rep["mixed_scale"] and {k: rep["mixed_scale"][k] for k in
                                                                ("coarse_period", "fine_period", "zones")}})
    find = {(r["case"], r["mode"]): r for r in rows}
    check("pipeline: o traco de borda e a linha sobre o vazio dao o achado erased com a escala conhecida",
          all("erased" in find[(c, "known")]["rules"] for c in ("borda", "fio_alfa")))
    check("pipeline: a grade de periodo 2 que nao cabe em 16x16 diz o orcamento e as zonas finas",
          all("grid_budget" in find[(c, "auto")]["rules"] and find[(c, "auto")]["mixed_scale"]["coarse_period"] == 16
              for c in ("centro_4", "dente")))
    check("pipeline: a escala 16 sobre uma ampliacao exata 2x e reducao deliberada",
          find[("centro_4", "known")]["origin"] == "deliberately_reduced")
    region = {"id": "boca", "required": True, "source_box": [120, 120, 152, 152]}
    sig = _forge(fx.marked("dente"), "dente", scale=16, signals={"schema": signals.SCHEMA, "regions": [region]})
    check("pipeline: a regiao declarada com a marca apagada bloqueia, sem limiar global",
          sig["signals"]["status"] == "blocked" and "subgrid" not in {f["rule"] for f in sig["lint"]["findings"]})
    return rows


def _perturb(native: Image.Image) -> list[tuple[str, Image.Image, str]]:
    nn8 = upscale(native, 8)
    solid = Image.new("RGBA", nn8.size, (255, 0, 255, 255))
    solid.alpha_composite(nn8)
    out = [("png-8x", nn8, "PNG"), ("png-13x", upscale(native, 13), "PNG"),
           ("png-8x-fase-3-5", nn8.crop((3, 5, *nn8.size)), "PNG"),
           ("png-8x-blur035", nn8.filter(ImageFilter.GaussianBlur(0.35)), "PNG"),
           ("png-fracionario-1254", native.resize((1254, 1254), Image.Resampling.BILINEAR), "PNG")]
    for q in (95, 75):
        buf = io.BytesIO()
        solid.convert("RGB").save(buf, format="JPEG", quality=q, subsampling=0)
        out.append((f"jpeg-8x-q{q}", Image.open(io.BytesIO(buf.getvalue())).convert("RGBA"), "JPEG"))
    return out


def grid_robustness() -> list[dict]:
    rows = []
    for who in ("rei", "escudeiro", "arqueiro"):
        native = fx.rejected(who)
        target = native.crop(opaque_bbox(native))
        for case, image, fmt in _perturb(native):
            opts = pipeline.Options(kind="free", palette="none", noise=0, cleanup="conservative", outline="keep",
                                    fit=False, bg="#FF00FF" if fmt == "JPEG" else None)
            g, s = gridcheck.measure(image)
            got, info = pipeline.snap(image, opts, g, s)
            rep = gridcheck.report(image, g, got.size, None, fmt)
            same = got.size == target.size
            rows.append({"character": who, "case": case, "origin": rep["origin"], "period": rep["period"],
                         "recovered_size": list(got.size), "raw_identical": same and got.tobytes() == target.tobytes(),
                         "silhouette_identical": same and [p[3] >= 128 for p in flat(got)] ==
                         [p[3] >= 128 for p in flat(target)], "pixel_values": rep["pixel_values"],
                         "original_colors": rep["original_colors"], "erased_cells": info["loss"]["erased_cells"],
                         "note": g.notes[0] if g.origin == "unmeasured" else None})
    png = [r for r in rows if r["case"].startswith("png") and "fracionario" not in r["case"]]
    jpeg = [r for r in rows if r["case"].startswith("jpeg")]
    frac = [r for r in rows if "fracionario" in r["case"]]
    check("grade: os 12 controlos PNG inteiros recuperam os pixels conhecidos",
          len(png) == 12 and all(r["raw_identical"] for r in png))
    check("grade: nos 6 JPEG a silhueta volta e a cor original nao se afirma",
          len(jpeg) == 6 and all(r["silhouette_identical"] and r["original_colors"] == "not_provable_lossy_input"
                                 and not r["raw_identical"] for r in jpeg))
    check("grade: nas 3 bilineares a medida diz que nao mediu e o que fazer",
          len(frac) == 3 and all(r["origin"] == "unmeasured" and "--reduce" in r["note"] for r in frac))
    return rows


def authority() -> dict:
    data = fidelity.load(CONTRACT)
    out = {"plans": {}, "reviews": {}}
    conflict = plan.make("openai", "imperial archer", "royal_80", references=[("concept", str(HERE / "fixtures/arqueiro.png"))],
                         fidelity=data, character="arqueiro")
    check("autoridade: o arqueiro de tunica verde como conceito e reference_conflict, antes de gerar",
          not conflict.ok and any(e.startswith("reference_conflict") for e in conflict.data["errors"]))
    for ch in data["characters"]:
        p = plan.make("openai", ch["id"], ch["kind"], fidelity=data, character=ch["id"])
        out["plans"][ch["id"]] = {"ok": p.ok, "mode": p.data["mode"], "implicit": p.data["implicit"],
                                  "first_attachment": p.data["attachments"][0]["prompt_role"],
                                  "crop_pixels_sha256": p.data["fidelity"]["crop_pixels_sha256"],
                                  "origins": {c["id"]: c["origin"] for c in p.data["constraints"]}}
        candidate = fx.rejected(ch["id"])
        rev = review_state.review(ch, candidate)
        out["reviews"][ch["id"]] = rev["summary"]
        review_state.sheet(data, ch, candidate).save(OUT / f"{ch['id']}-conceito-e-rejeitado.png")
    check("autoridade: o pedido fiel leva o recorte primeiro e nenhuma preferencia do compilador",
          all(v["ok"] and v["mode"] == "adapt_concept" and not v["implicit"] and v["first_attachment"] == "concept"
              for v in out["plans"].values()))
    check("revisao: os tres rejeitados ficam blocked na identidade e nada fica aprovado",
          all(v["identity_and_pose"] == "blocked" and v["native_master_approval"] == "pending"
              for v in out["reviews"].values()))
    return out


def main() -> None:
    OUT.mkdir(exist_ok=True)
    result = {"schema": "forja.prova-auditoria/1", "task": "FORJA-07", "sampler": sampler(),
              "pipeline": through_pipeline(), "grid": grid_robustness(), "authority": authority()}
    result["observations"] = {k: len(result[k]) for k in ("sampler", "pipeline", "grid")}
    result["checks"] = checks
    (HERE / "prova.json").write_text(json.dumps(result, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps({"ok": True, "checks": len(checks), "observations": result["observations"]}))


if __name__ == "__main__":
    main()
