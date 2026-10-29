"""Subcomandos do Aseprite (FORJA-13): `aseprite` monta o .aseprite de um corpo (uma camada por slot, uma tag por
animacao, pivot e referencia), `ase` le um .aseprite como o Aseprite o ve e confere as convencoes do Empire, e
`exportar` escreve as folhas PNG + JSON como a CLI do Aseprite e o `tools/export_aseprite.sh`, sem o Aseprite.
"""
from __future__ import annotations

import glob
import json
from pathlib import Path

from . import aseprite, contracts, palette as palmod, scene as scene_mod, sheetforge
from .ase import cena as scene_ase
from .ase import empire
from .ase import read as read_ase
from .ase.describe import describe
from .ase.export import sheet
from .cli import command, pair
from .imageops import open_rgba

ART = Path(__file__).resolve().parents[2] / "art"
SHEET_TYPES = ("rows", "columns", "horizontal", "vertical")


def outside_art(path: str | Path) -> Path:
    out = Path(path).resolve()
    if out == ART or ART in out.parents:
        raise ValueError("nunca escrever em art/ sem pedido do dono: use build/forja/")
    return out


def _frames(spec: str) -> list:
    paths = sorted(glob.glob(spec)) if any(c in spec for c in "*?[") else [p for p in spec.split(",") if p]
    if not paths:
        raise ValueError(f"nenhum quadro em {spec!r}")
    return [open_rgba(p) for p in paths]


def do_aseprite(args) -> dict:
    frames = [open_rgba(f) for f in args.frames]
    layers = {args.layer: frames}
    for spec in args.slot or []:
        name, sep, files = spec.partition("=")
        if not sep or not name:
            raise ValueError("--slot nome=quadros (ex.: weapon_bow_l1=build/forja/arco_*.png)")
        layers[name] = _frames(files)
    if len({img.size for images in layers.values() for img in images}) != 1:
        raise ValueError("todas as camadas de um corpo partilham a tela (ASSET_BIBLE §2)")
    tl, durations = sheetforge._timeline(sheetforge.parse_tags(args.tags), len(frames))
    pal = palmod.load(args.palette).colors if args.palette else None
    pivot = args.pivot or (contracts.get(args.kind).pivot if args.kind else None)
    sprite = aseprite.assemble(frames[0].size, layers, durations, tl, pal, pivot,
                               open_rgba(args.reference) if args.reference else None, args.kind)
    path = aseprite.save(sprite, outside_art(args.out))
    check = aseprite.verify(path, frames if len(layers) == 1 else None, layers if len(layers) > 1 else None)
    exact = check["pixel_equal"] if len(layers) == 1 else all(check["layer_equal"].values())
    lint = empire.check(sprite, args.kind)
    return {"ok": exact and lint["ok"], "out": str(path), "verify": check, "check": lint}


def do_ase(args) -> dict:
    sprite = read_ase(args.file)
    seen = describe(sprite, full=True)
    if not args.cels:
        for layer in seen["layers"]:
            layer["cels"] = len(layer["cels"])
    lint = empire.check(sprite, args.kind)
    out = {"ok": lint["ok"], "file": args.file, "aseprite": seen, "check": lint}
    if args.scene:  # o contrato de cena contra o que o ficheiro diz agora (o ficheiro nunca o reescreve)
        found = scene_ase.read(sprite)
        out["scene"] = {"seen": found, "drift": scene_ase.drift(scene_mod.resolve(scene_mod.load(args.scene)), found)}
        out["ok"] = out["ok"] and not out["scene"]["drift"]
    return out


def do_exportar(args) -> dict:
    sprite = read_ase(args.file)
    title = args.title or Path(args.file).stem
    out = outside_art(args.out or f"build/forja/exportar/{title}")
    if args.composite or args.layer:
        stem = f"{title}_{empire.export_name(args.layer)}" if args.layer else title
        jobs = [(stem, *sheet(sprite, title, f"{stem}.png", layer=args.layer, kind=args.sheet_type,
                              columns=args.columns, layers=True, slices=True))]
    else:
        if args.sheet_type != "rows" or args.columns:
            raise ValueError("a exportacao por camada e a do script (em linha): --sheet-type/--columns pedem "
                             "--composite ou --layer")
        jobs = empire.export_layers(sprite, title, args.slices)
    out.mkdir(parents=True, exist_ok=True)
    files = []
    for stem, img, data in jobs:
        img.save(out / f"{stem}.png")
        (out / f"{stem}.json").write_text(json.dumps(data, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
        files.append({"png": str(out / f"{stem}.png"), "json": str(out / f"{stem}.json"),
                      "frames": len(data["frames"]), "tags": [t["name"] for t in data["meta"].get("frameTags", [])]})
    lint = empire.check(sprite)
    return {"ok": True, "files": files, "findings": [f for f in lint["findings"] if f["severity"] != "info"]}


def register(sub) -> None:
    p = command(sub, "aseprite", "Quadros PNG -> .aseprite de um corpo: uma camada por slot (--slot, pela ordem Z "
                "da §58), uma tag por animacao, duracoes, paleta, pivot em slice e referencia; conferido pixel a "
                "pixel e contra as convencoes do Empire", do_aseprite)
    p.add_argument("frames", nargs="+", help="os quadros da camada principal (--layer)")
    p.add_argument("-o", "--out", required=True)
    p.add_argument("--tags")
    p.add_argument("--layer", default="body")
    p.add_argument("--slot", action="append", help="outra camada: nome=quadros (lista com virgulas ou glob); um so "
                   "quadro repete-se em todos (repetivel)")
    p.add_argument("--reference", help="imagem de trabalho: a camada References, que o Aseprite nao compoe nem exporta")
    p.add_argument("--kind", help="contrato (troop_64, royal_80...): confere a tela e da o pivot por omissao")
    p.add_argument("--palette")
    p.add_argument("--pivot", type=pair)
    p = command(sub, "ase", "Um .aseprite como o Aseprite 1.3 o ve (camadas e pais, mistura, cels, tags, slices, "
                "dados) e conferido contra as convencoes do Empire (slots, nomes, tags, pivot); so le", do_ase)
    p.add_argument("file")
    p.add_argument("--kind", help="contrato a conferir (tela e pivot)")
    p.add_argument("--cels", action="store_true", help="listar as cels de cada camada (por omissao, so a contagem)")
    p.add_argument("--scene", help="contrato forja.scene/1: conferir os vaos, sinais, zonas e pivot das slices")
    p = command(sub, "exportar", "Um .aseprite -> folha PNG + JSON por camada, igual ao tools/export_aseprite.sh e a "
                "CLI do Aseprite 1.3.18.6, sem o Aseprite; --composite ou --layer para uma folha so", do_exportar)
    p.add_argument("file")
    p.add_argument("-o", "--out", help="pasta (por omissao build/forja/exportar/<nome>; nunca art/)")
    p.add_argument("--title", help="o nome dos quadros no JSON (por omissao o do ficheiro, como a CLI)")
    p.add_argument("--composite", action="store_true", help="uma folha com as camadas visiveis (ASEPRITE_WORKFLOW §7)")
    p.add_argument("--layer", help="uma folha so desta camada (--layer da CLI)")
    p.add_argument("--slices", action="store_true", help="na exportacao por camada, levar as slices (o pivot) ao JSON")
    p.add_argument("--sheet-type", default="rows", choices=SHEET_TYPES)
    p.add_argument("--columns", type=int, help="quadros por linha (--sheet-columns)")
