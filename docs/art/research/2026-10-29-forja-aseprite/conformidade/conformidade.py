#!/usr/bin/env python3
"""A prova de conformidade da Forja com o Aseprite 1.3.18.6 (FORJA-13). Precisa do Aseprite (a CLI basta).

    ASEPRITE=/caminho/aseprite python3 conformidade.py [--fixtures]

1. O Aseprite gera, pelo `gerar.lua`, sprites que cobrem a especificacao; a Forja escreve os casos de
   `tools/forja/tests/ase_cases.py`; e copiam-se tres fontes pequenas do dono (`EMPIRE`).
2. Para cada .aseprite, o Aseprite exporta os quadros (`--save-as`), descreve o que ve (`ler.lua`) e, nos da Forja,
   regrava-o; exporta as folhas + JSON dos casos de `SHEETS` (o comando do ASEPRITE_WORKFLOW §7 e variantes); e o
   proprio `tools/export_aseprite.sh` corre sobre `SCRIPT`, numa copia fora de `art/`.
3. A Forja confere: le cada ficheiro e ve o mesmo que o Aseprite; renderiza cada quadro igual; o que escreveu o
   Aseprite abre e regrava sem perder nada; a folha e o JSON saem iguais aos da CLI (menos `app` e `version`); a
   exportacao por camada sai igual a do script.
4. Todas as fontes `.aseprite` de `art/source/` passam pela leitura e pela folha completa (so ficam na evidencia,
   com o SHA-256 de cada uma).
Escreve `conformidade.json` ao lado; com `--fixtures`, copia os ficheiros para `tools/forja/tests/ase_fixtures/`,
onde o CI repete as conferencias sem o Aseprite.
"""
from __future__ import annotations

import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
sys.path.insert(0, str(ROOT))

from tools.forja import ase  # noqa: E402
from tools.forja.ase import empire  # noqa: E402
from tools.forja.ase.describe import describe, diff  # noqa: E402
from tools.forja.ase.export import sheet  # noqa: E402
from tools.forja.tests.ase_cases import CASES  # noqa: E402

FIXTURES = ROOT / "tools/forja/tests/ase_fixtures"
MADE = ["blends_rgba", "blends_gray", "structure", "indexed", "tilemap"]
EMPIRE = ["art/source/originals/troop.aseprite", "art/source/originals/archer.aseprite",
          "art/source/royals_v15/plants/rose-7.aseprite"]
SCRIPT = ["troop", "archer", "forja_rgba", "structure"]
SHEETS = [("structure", "structure_sheet", [], dict(layers=True, slices=True)),
          ("structure", "structure_weapon", ["--layer", "weapon_bow_l1"], dict(layer="weapon_bow_l1")),
          ("forja_rgba", "forja_rgba_sheet", ["--sheet-columns", "2"], dict(columns=2, layers=True, slices=True)),
          ("forja_rgba", "forja_rgba_hidden", ["--layer", "hidden"], dict(layer="hidden", layers=True)),
          ("indexed", "indexed_sheet", [], dict(layers=True, slices=True)),
          ("blends_gray", "blends_gray_sheet", ["--sheet-type", "columns"], dict(kind="columns")),
          ("troop", "troop_sheet", [], dict(layers=True, slices=True))]


def run(ase_bin: str, *args: str) -> None:
    r = subprocess.run([ase_bin, "-b", *args], capture_output=True, text=True, timeout=300)
    if r.returncode or r.stderr.strip():
        raise RuntimeError(f"aseprite {' '.join(args)}: {r.returncode} {r.stderr.strip()}")


def same(ref: Path, img: Image.Image, mode: bool = True) -> bool:
    """Os mesmos pixels (e, numa folha, o mesmo modo: um quadro com fundo opaco o Aseprite grava-o em RGB)."""
    theirs = Image.open(ref)
    return (theirs.mode == img.mode or not mode) and theirs.convert("RGBA").tobytes() == img.convert("RGBA").tobytes()


def cli_sheet(ase_bin: str, src: Path, png: Path, args: list[str], kw: dict) -> None:
    run(ase_bin, *args, str(src), "--sheet", str(png), "--data", str(png.with_suffix(".json")), "--format",
        "json-array", "--list-tags", *(["--list-layers"] if kw.get("layers") else []),
        *(["--list-slices"] if kw.get("slices") else []), *([] if "--sheet-type" in args else ["--sheet-type", "rows"]))


def same_json(data: dict, path: Path) -> list[str]:
    theirs = json.loads(path.read_text(encoding="utf-8"))
    for doc in (data, theirs):
        doc["meta"].pop("app")
        doc["meta"].pop("version")
    return diff(data, theirs)


def same_sheet(sprite, title: str, png: Path, kw: dict) -> list[str]:
    img, data = sheet(sprite, title, png.name, **kw)
    return same_json(data, png.with_suffix(".json")) + ([] if same(png, img) else ["pixels da folha"])


def one(ase_bin: str, out: Path, name: str, origin: str, checks: list) -> dict:
    f = out / f"{name}.aseprite"
    sprite = ase.read(f)
    run(ase_bin, str(f), "--save-as", str(out / f"{name}-{{frame}}.png"))
    run(ase_bin, str(f), "--script-param", f"out={out / (name + '.json')}", "--script", str(HERE / "ler.lua"))
    seen = describe(sprite)
    seen.pop("bytes_per_pixel")
    d = diff(seen, json.loads((out / f"{name}.json").read_text(encoding="utf-8")))
    checks.append({"check": f"{name}: a Forja le o que o Aseprite ve", "ok": not d, "diff": d[:8]})
    frames = [f"{name}-{i}.png" for i in range(sprite.frames)]  # o Aseprite numera mesmo um quadro so
    bad = [i for i, png in enumerate(frames) if not same(out / png, ase.render(sprite, i, native=True), False)]
    checks.append({"check": f"{name}: os {len(frames)} quadros renderizados iguais ao export", "ok": not bad,
                   "diff": bad[:8]})
    case = {"origin": origin, "frames": frames, "dump": f"{name}.json"}
    if origin == "forja":
        run(ase_bin, str(f), "--save-as", str(out / f"{name}_resaved.aseprite"))
        again = ase.read(out / f"{name}_resaved.aseprite")
        back = diff(describe(again, full=True), describe(sprite, full=True))
        back += [f"quadro {i}" for i in range(sprite.frames)
                 if ase.render(again, i, native=True).tobytes() != ase.render(sprite, i, native=True).tobytes()]
        checks.append({"check": f"{name}: o Aseprite regrava sem perder nada", "ok": not back, "diff": back[:8]})
        case["resaved"] = f"{name}_resaved.aseprite"
    return case


def script(ase_bin: str, out: Path, checks: list) -> dict:
    """O `tools/export_aseprite.sh` verdadeiro, numa raiz de trabalho que imita a do repositorio."""
    root = out.parent / "raiz"
    (root / "tools").mkdir(parents=True)
    (root / "art/source/t").mkdir(parents=True)
    shutil.copy(ROOT / "tools/export_aseprite.sh", root / "tools")
    (out / "export").mkdir()
    made = {}
    for name in SCRIPT:
        shutil.copy(out / f"{name}.aseprite", root / "art/source/t")
        r = subprocess.run(["bash", "tools/export_aseprite.sh", f"art/source/t/{name}.aseprite"], cwd=root,
                           env={**os.environ, "ASEPRITE": ase_bin}, capture_output=True, text=True, timeout=300)
        if r.returncode:
            raise RuntimeError(f"export_aseprite.sh {name}: {r.stderr.strip()}")
        theirs = sorted(p.stem for p in (root / "art/export/t").glob(f"{name}_*.json"))
        for stem in theirs:
            for ext in (".png", ".json"):
                shutil.copy(root / "art/export/t" / f"{stem}{ext}", out / "export" / f"{stem}{ext}")
        mine = empire.export_layers(ase.read(out / f"{name}.aseprite"), name)
        d = [] if sorted(s for s, _, _ in mine) == theirs else [f"camadas {theirs}"]
        for stem, img, data in mine:
            d += [f"{stem}{x}" for x in same_json(data, out / "export" / f"{stem}.json")]
            d += [] if same(out / "export" / f"{stem}.png", img) else [f"{stem}: pixels"]
        checks.append({"check": f"{name}: a exportacao por camada igual a do tools/export_aseprite.sh",
                       "ok": not d, "diff": d[:8]})
        made[f"{name}.aseprite"] = theirs
    return made


def survey(ase_bin: str, tmp: Path) -> list[dict]:
    """Todas as fontes do dono: a leitura e a folha completa, com o SHA-256 de cada uma."""
    out = []
    for src in sorted((ROOT / "art/source").rglob("*.aseprite")):
        png = tmp / f"{len(out)}.png"
        run(ase_bin, str(src), "--script-param", f"out={tmp / 'dump.json'}", "--script", str(HERE / "ler.lua"))
        sprite = ase.read(src)
        seen = describe(sprite)
        seen.pop("bytes_per_pixel")
        d = diff(seen, json.loads((tmp / "dump.json").read_text(encoding="utf-8")))
        kw = dict(layers=True, slices=True)
        cli_sheet(ase_bin, src, png, [], kw)
        d += same_sheet(sprite, src.stem, png, kw)
        out.append({"source": str(src.relative_to(ROOT)), "sha256": hashlib.sha256(src.read_bytes()).hexdigest(),
                    "ok": not d, "size": [sprite.width, sprite.height], "frames": sprite.frames,
                    "layers": len(sprite.layers), "tags": len(sprite.tags), "diff": d[:8]})
    return out


def conform(ase_bin: str, out: Path) -> dict:
    run(ase_bin, "--script-param", f"out={out}", "--script", str(HERE / "gerar.lua"))
    for name, make in CASES.items():
        ase.write(make(), out / f"{name}.aseprite")
    for src in EMPIRE:
        shutil.copy(ROOT / src, out / Path(src).name)
    origin = {**{n: "aseprite" for n in MADE}, **{n: "forja" for n in CASES},
              **{Path(s).stem: "empire" for s in EMPIRE}}
    checks: list[dict] = []
    cases = {f"{n}.aseprite": one(ase_bin, out, n, o, checks) for n, o in origin.items()}
    for src in EMPIRE:
        cases[Path(src).name]["source"] = src
    sheets = []
    for src, label, args, kw in SHEETS:
        cli_sheet(ase_bin, out / f"{src}.aseprite", out / f"{label}.png", args, kw)
        d = same_sheet(ase.read(out / f"{src}.aseprite"), src, out / f"{label}.png", kw)
        checks.append({"check": f"folha {label}: JSON e PNG iguais aos da CLI", "ok": not d, "diff": d[:8]})
        sheets.append({"source": f"{src}.aseprite", "label": label, "options": kw})
    return {"checks": checks, "cases": cases, "sheets": sheets, "script": script(ase_bin, out, checks)}


def main() -> int:
    ase_bin = os.environ.get("ASEPRITE", "aseprite")
    version = subprocess.run([ase_bin, "--version"], capture_output=True, text=True).stdout.strip()
    with tempfile.TemporaryDirectory() as tmp:
        out = Path(tmp) / "out"
        out.mkdir()
        result = conform(ase_bin, out)
        (Path(tmp) / "survey").mkdir()
        result["art_source"] = survey(ase_bin, Path(tmp) / "survey")
        files = sorted([p.name for p in out.iterdir() if p.suffix in (".aseprite", ".png", ".json")]
                       + [f"export/{p.name}" for p in (out / "export").iterdir()])
        result["aseprite"] = version
        result["files"] = {n: hashlib.sha256((out / n).read_bytes()).hexdigest() for n in files}
        if "--fixtures" in sys.argv:
            shutil.rmtree(FIXTURES, ignore_errors=True)
            (FIXTURES / "export").mkdir(parents=True)
            for n in files:
                shutil.copy(out / n, FIXTURES / n)
            keep = ("aseprite", "cases", "sheets", "script")
            (FIXTURES / "casos.json").write_text(json.dumps({k: result[k] for k in keep}, indent=1,
                                                            ensure_ascii=False) + "\n", encoding="utf-8")
    ok = all(c["ok"] for c in result["checks"]) and all(s["ok"] for s in result["art_source"])
    (HERE / "conformidade.json").write_text(json.dumps({"ok": ok, **result}, indent=1, ensure_ascii=False) + "\n",
                                            encoding="utf-8")
    print(json.dumps({"ok": ok, "checks": len(result["checks"]), "art_source": len(result["art_source"]),
                      "falhas": [c["check"] for c in result["checks"] if not c["ok"]]
                      + [s["source"] for s in result["art_source"] if not s["ok"]]}, ensure_ascii=False))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
