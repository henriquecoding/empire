#!/usr/bin/env python3
"""A prova do FORJA-06: a solucao de 27/10 nas funcoes da Forja, ja integradas, sobre as fixtures REJEITADAS.

Repete os ensaios do pacote (`SOLUCAO.md`, §8) com a Forja deste ramo, e nao com o prototipo externo dele:
1. a composicao local no Rei, no Arqueiro e no Escudeiro com uma resposta adversa simulada (rosto pintado), o eco,
   o tamanho errado (que agora para a tentativa com o job, sem redesenhar) e a mascara sobre a zona protegida;
2. o mestre registado: uma versao rejeitada e recusada antes do pedido; o prompt so diz APPROVED pelo registo;
3. a rampa so na lamina do Rei (26 mudancas, 826 presos) e o material `pending` pelos 9 conflitos;
4. a corda com o miolo x=56 e a cor declarados (30 claros conservados, 10 interrupcoes preenchidas, o contorno
   x=57 intacto) e a corda sem cor declarada, que fica inconclusiva;
5. o `forge` manual com `--expect` e um tamanho que nao e o pedido;
6. o `verify` so a ler: preservado, contrato valido e mesmo assim nao entregavel — falta a aprovacao do dono;
7. o banding (Pixel Fixer, TU Delft 2025) nas tres figuras, como suspeita.
Sem rede, sem geracao paga, sem aprovacao. Grava em `evidencias/` e em `prova.json`; falha se uma medida mudar.

    python3 docs/art/research/2026-10-27-forja-fidelidade/prova_fidelidade.py
"""
from __future__ import annotations

import io
import json
import os
import sys
import tempfile
from pathlib import Path
from unittest import mock

from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
sys.path.insert(0, str(ROOT))
from tools.forja import banding, cli, compose, equipment, inpaint, masks, plan, refs  # noqa: E402
from tools.forja import palette as palmod  # noqa: E402

FIX, OUT = HERE / "fixtures", HERE / "evidencias"
MANIFEST = ROOT / "docs/art/research/2026-10-24-forja-armas/arqueiro/manifesto.json"
CASES = {"rei": ((35, 21, 50, 35), (24, 63, 39, 78), "royal_80"),
         "arqueiro": ((38, 23, 49, 38), (54, 17, 68, 76), "royal_80"),
         "escudeiro": ((35, 29, 43, 40), (6, 49, 24, 61), "royal_64")}
ORANGE, LIGHT = (217, 124, 43, 255), (251, 236, 195, 255)
KING_PLAN = {"schema": "forja.cores/1", "lock": ["face", "hand_back", "hand_front", "sword_hilt"],
             "regions": {"blade": {"ramp": ["#A19D9E", "#F0F0F0"], "group": False}}}
checks: list[dict] = []


def rel(path) -> str:
    return str(Path(path).resolve().relative_to(ROOT))


def check(label: str, ok: bool, **detail) -> None:
    assert ok, (label, detail)
    checks.append({"check": label, "status": "pass", **detail})


def fixture(name: str) -> Image.Image:
    return Image.open(FIX / f"{name}.png").convert("RGBA")


def local() -> dict:
    master, out = palmod.load("empire"), {}
    for name, (face, zone, kind) in CASES.items():
        native, protected = fixture(name), masks.box(face)
        source, _, k, size, key = inpaint.prepare(native, zone, palette=master)
        sent = Image.open(io.BytesIO(source)).convert("RGBA")
        echo, _ = inpaint.merge(native, sent, k, zone, master, key, protect=protected)
        check(f"{name}: o eco devolve o RGBA exato", echo.tobytes() == native.tobytes())
        adverse = sent.copy()
        draw = ImageDraw.Draw(adverse)
        facial = [p for p in sorted(protected) if native.getpixel(p)[3]][:5]
        allowed = (zone[0], zone[3] - 1)
        for x, y in facial + [allowed]:
            draw.rectangle((x * k, y * k, (x + 1) * k - 1, (y + 1) * k - 1), fill=ORANGE)
        result, info = inpaint.merge(native, adverse, k, zone, master, key, protect=protected)
        result.save(OUT / f"{name}-local.png")
        check(f"{name}: o rosto e o exterior ficam iguais", info["outside_identical"] and info["protected_identical"])
        check(f"{name}: o pixel autorizado entra", result.getpixel(allowed) == ORANGE)
        try:
            inpaint.merge(native, sent.resize((sent.width + k, sent.height)), k, zone, master, key)
            stopped = False
        except inpaint.SizeMismatch:
            stopped = True
        check(f"{name}: o tamanho errado para a tentativa", stopped)
        try:
            compose.refuse_protected(masks.box(zone), masks.box(zone))
            refused = False
        except ValueError:
            refused = True
        check(f"{name}: a mascara sobre o protegido e recusada", refused)
        lint = cli.run(["lint", rel(FIX / f"{name}.png"), "--kind", kind])
        out[name] = {"scale": k, "sent": size, "changed_pixels": info["changed_pixels"],
                     "lint_ok": lint["ok"], "banding": banding.find(native)["pairs"]}
    check("as tres fixtures rejeitadas passam no lint: contrato valido nao e aprovacao",
          all(v["lint_ok"] for v in out.values()))
    return out


def stopped_edit() -> dict:
    def wrong(_prompt, images, *_a, **_kw):
        with Image.open(io.BytesIO(images[0])) as im:
            buf = io.BytesIO()
            im.convert("RGBA").resize((im.width + 16, im.height)).save(buf, "PNG")
        return {"images": [buf.getvalue()], "model": "synthetic/wrong", "job": {"id": "simulado"}}

    with mock.patch("tools.forja.backends.openai_images.edit", side_effect=wrong) as sent:
        out, info = inpaint.run(fixture("rei"), (24, 63, 39, 78), "repair the blade",
                                protect=masks.box((35, 21, 50, 35)))
    check("tamanho errado: um pedido, nenhuma imagem, o job guardado", out is None and sent.call_count == 1
          and info["stopped"] == "size_mismatch")
    return {k: info[k] for k in ("stopped", "sent", "job", "next")}


def authority() -> dict:
    entries = []
    for ident, name, state, extra in (("rei-v2", "rei", "rejected", {"decided_by": "Henrique", "date": "2026-10-27",
                                                                     "reason": "fixture rejeitada (SOLUCAO.md)"}),
                                      ("arqueiro-v2", "arqueiro", "adaptation_in_review", {})):
        entries.append({"id": ident, "file": f"../fixtures/{name}.png", "state": state,
                        "pixels_sha256": equipment.image_sha(fixture(name)), **extra})
    (OUT / "refs.json").write_text(json.dumps({"schema": refs.SCHEMA, "entries": entries}, indent=1) + "\n")
    reg = refs.load(OUT / "refs.json")
    with mock.patch("tools.forja.backends.openai_images.edit") as sent:
        try:
            cli.run(["inpaint", rel(FIX / "rei.png"), "--box", "24,63,39,78", "--change", "x", "--refs",
                     rel(OUT / "refs.json"), "-o", rel(OUT / "nao-sai.png")])
            refused = False
        except ValueError:
            refused = True
    check("a versao rejeitada nao e editada por zonas, e nada sai para o gerador", refused and sent.call_count == 0)
    words = {}
    for name in ("rei", "arqueiro"):
        p = plan.make("openai", "comic king", "royal_80", references=[("identity", rel(FIX / f"{name}.png"))],
                      register=reg)
        words[name] = {"ok": p.ok, "stage": p.data["authority"]["stage"],
                       "approved_word": "APPROVED" in p.data["prompt"]}
    check("nenhuma das duas e chamada APPROVED; a rejeitada nao entra no plano",
          not words["rei"]["ok"] and not any(w["approved_word"] for w in words.values()))
    return {"register": rel(OUT / "refs.json"), "plans": words}


def king() -> dict:
    (OUT / "rei-plano-cores.json").write_text(json.dumps(KING_PLAN, indent=1) + "\n")
    res = cli.run(["cores", rel(FIX / "rei-before-colors.png"), "--observation",
                   rel(FIX / "rei-colors-observation.json"),
                   "--plan", rel(OUT / "rei-plano-cores.json"), "--kind", "royal_80", "-o", rel(OUT / "rei-cores")])
    check("lamina: 26 mudancas, nada preso muda, o ok tecnico passa", res["changed_pixels"] == 26
          and res["locked"] == {"pixels": 826, "changed": 0} and res["outside_zone_changed"] == 0)
    check("lamina: 9 pixels presos fora da rampa deixam o material pendente", res["material"]["status"] == "pending"
          and res["material"]["conflicts"] == 9, conflicts=res["material"]["conflicts"])
    verify = cli.run(["verify", res["files"]["png"], "--master", rel(FIX / "rei-before-colors.png"), "--kind",
                      "royal_80", "--cores", res["files"]["json"]])
    check("verify: contrato valido, e nao entregavel (material e aprovacao)", verify["ok"] and not verify["deliverable"]
          and {"material", "artistic_approval"} <= set(verify["closure"]["missing"]))
    return {"material": res["material"], "banding": res["banding"], "closure_missing": verify["closure"]["missing"]}


def string() -> dict:
    base = ["line", rel(FIX / "arqueiro-before-string.png"), "--manifest", rel(MANIFEST), "--observation",
            rel(FIX / "arqueiro-equipment-observation.json"), "--item", "bow_main", "--kind", "royal_80"]
    vague = cli.run([*base, "-o", rel(OUT / "corda-sem-cor")])
    check("corda sem cor declarada: inconclusiva, nada escrito", vague["status"] == "inconclusive"
          and not list((OUT / "corda-sem-cor").glob("*.png")))
    res = cli.run([*base, "-o", rel(OUT / "corda"), "--mode", "fill", "--core-box", "56,22,57,70",
                   "--color", "#FBECC3"])
    before, after = fixture("arqueiro-before-string"), Image.open(res["files"]["png"]).convert("RGBA")
    raw = json.loads((FIX / "arqueiro-equipment-observation.json").read_text(encoding="utf-8"))
    arm = equipment.observe(before, raw, FIX)["regions"]["forearm_front"]
    core = [(56, y) for y in range(22, 70) if (56, y) not in arm]
    kept = sum(before.getpixel(p) == LIGHT for p in core)
    check("corda: 30 claros conservados e 10 interrupcoes preenchidas", (kept, len(core)) == (30, 40)
          and all(after.getpixel(p) == LIGHT for p in core) and res["compose"]["changed_pixels"] == 10)
    check("corda: o contorno x=57 e o antebraco ficam iguais", res["compose"]["protected_identical"]
          and all(after.getpixel((57, y)) == before.getpixel((57, y)) for y in range(80)))
    for label, extra in (("corda: cor fora da paleta recusada", ["--color", "#FF00FF"]),
                         ("corda: miolo sobre a mao recusado", ["--core-box", "56,40,63,56"])):
        try:
            cli.run([*base, "-o", rel(OUT / "corda-recusada"), "--mode", "fill", "--core-box", "56,22,57,70",
                     "--color", "#FBECC3", *extra])
            refused = False
        except ValueError:
            refused = True
        check(label, refused)
    return {"inconclusive": {k: vague[k] for k in ("core_pixels", "colors_in_core")}, "paint": res["paint"],
            "compose": res["compose"], "geometry_after": res["after"]["equipment_geometry"],
            "files": {k: rel(v) for k, v in res["files"].items()}}


def manual_forge() -> dict:
    tmp = Path(tempfile.mkdtemp(prefix="forja-fidelidade-"))  # intermedios, nao evidencia
    cli.run(["prompt", "comic knight", "-o", str(tmp / "pedido"), "--kind", "royal_64"])
    fixture("escudeiro").resize((512, 512), Image.Resampling.NEAREST).save(tmp / "escudeiro-512.png")
    res = cli.run(["forge", str(tmp / "escudeiro-512.png"), "--expect", str(tmp / "pedido" / "expect.json"),
                   "-o", str(tmp / "forge")])
    check("forge manual: o tamanho que nao e o pedido fica escrito e invalida", not res["ok"]
          and res["expectation"]["hard"] == ["size_mismatch"])
    return {"raster": res["expectation"]["raster"], "hard": res["expectation"]["hard"]}


def main() -> int:
    os.chdir(ROOT)  # os caminhos que ficam gravados sao relativos a raiz, iguais em qualquer checkout
    OUT.mkdir(exist_ok=True)
    result = {"schema": "forja.prova_fidelidade/1", "date": "2026-10-27", "network": False, "paid_calls": 0,
              "generator_response": "simulada", "source_state": "fixtures rejeitadas pelo dono (fixtures/STATE.json)",
              "artistic_approval": "pending", "local": local(), "stopped_edit": stopped_edit(),
              "authority": authority(), "king_blade": king(), "string": string(), "manual_forge": manual_forge()}
    result["checks"] = checks
    (HERE / "prova.json").write_text(json.dumps(result, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps({"ok": True, "checks": len(checks)}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
