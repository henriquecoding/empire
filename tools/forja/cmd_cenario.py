"""Subcomandos de cenario e construcao (FORJA-09): regua, cena, estrutura, montagem e escala.

O ciclo de uma peca de cenario: `escala` mede uma referencia contra a regua dos atores; `cena` valida o contrato
forja.scene/1 e compila o pedido (ou o plano por gerador, sem rede); o gerador desenha; `forge --expect` pousa a peca
na tela e no pivot da cena; `estrutura` confere-a contra o contrato; `montagem` poe-na no mundo com os atores reais.
A aprovacao e do dono, para a imagem exata (`refs`, `verify`).
"""
from __future__ import annotations

import json
from pathlib import Path

from . import estrutura, guides, montagem, palette as palmod, regua, scene as scene_mod, scene_plan, scene_prompt
from . import refs as refs_mod
from .cli import box, command, pair
from .imageops import open_rgba, upscale


def _palette(name: str | None, res: dict) -> palmod.Palette | None:
    if name == "none":
        return None
    return palmod.load(name or palmod.ROOT / res["contract"]["palette"])


def _write(path: Path, data) -> str:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    return str(path)


def _brief(res: dict) -> dict:
    return {k: res[k] for k in ("id", "asset", "kind", "step", "extent_px", "cells", "anchor", "repeat", "openings",
                                "signals", "materials", "states", "conditions", "lattice", "forge_args", "warnings")}


def do_regua(args) -> dict:
    """A regua dos atores e o mundo, lidos dos ficheiros do jogo; so le."""
    s = regua.summary(args.step)
    rul = s["ruler"]
    return {"ok": True, "world": s["world"], "lattice": s["lattice"], "metrics": s["metrics"],
            "tallest": rul["tallest"], "shortest": rul["shortest"], "actors": rul["actors"], "origin": rul["origin"],
            "excluded": rul["excluded"]}


def do_cena(args) -> dict:
    sc = scene_mod.load(args.scene)
    check = scene_mod.validate(sc, Path(sc["_base"]))
    if check["errors"]:
        return {"ok": False, "errors": check["errors"], "warnings": check["warnings"]}
    res = scene_mod.resolve(sc)
    out = Path(args.out)
    pal = _palette(args.palette, res)
    files = {"resolved": _write(out / "cena.json", _brief(res))}
    register = refs_mod.load(args.refs) if args.refs else None
    if args.backend:
        p = scene_plan.make(args.backend, args.scene, pal, args.model, args.guides, args.image_size, args.seed,
                            register)
        files["plan"] = str(p.write(out / "plan"))
        return {"ok": p.ok, "errors": p.data["errors"], "notes": p.data["notes"], "request": p.data["request"],
                "attachments": p.data["attachments"], "expect": p.data["expect"], "advice": p.data["advice"],
                "files": files, "network": False, "warnings": res["warnings"]}
    seen: dict = {"errors": [], "references": []}  # o mesmo registo do plano: a rejeitada nao se anexa
    scene_plan.references(sc, Path(sc["_base"]), register, seen)
    kept = [(i, r) for i, (r, e) in enumerate(zip(res["references"], seen["references"]), 1)
            if e["state"] != "rejected"]
    probe = scene_prompt.build(res, args.target, [], palette=pal)
    roles = [r["role"] for _, r in kept] + ["ruler"] + (["palette"] if pal is not None else [])
    built = scene_prompt.build(res, args.target, roles, palette=pal)
    scene_prompt.ruler_guide(res, probe["expect"]).save(out / "guide_ruler.png")
    files["ruler"] = str(out / "guide_ruler.png")
    if pal is not None:
        guides.palette_swatch(pal).save(out / "guide_palette.png")
        files["palette"] = str(out / "guide_palette.png")
    (out / "prompt.txt").write_text(built["prompt"] + "\n", encoding="utf-8")
    files.update(prompt=str(out / "prompt.txt"), expect=_write(out / "expect.json", {
        **built["expect"], "canvas_px": res["extent_px"], "pivot_px": [res["extent_px"][0] // 2,
                                                                       res["extent_px"][1] - 1]}))
    attach = [_reference(sc, r, i, out) for i, r in kept] + [files["ruler"]] + (
        [files["palette"]] if pal is not None else [])
    return {"ok": not built["conflicts"] and not seen["errors"], "errors": seen["errors"],
            "references": seen["references"], "conflicts": built["conflicts"], "warnings": res["warnings"],
            "size": built["size"], "cells": res["cells"], "prompt": built["prompt"], "constraints":
            built["constraints"], "attach": attach, "advice": built["advice"], "files": files,
            "next": f"gere a imagem ({built['size']}) com o prompt, anexando por esta ordem: {attach}; depois "
                    f"python3 -m tools.forja forge <imagem> --expect {files['expect']} -o <pasta> e "
                    f"python3 -m tools.forja estrutura <pasta>/<nome>.png --scene {args.scene}"}


def _reference(sc: dict, ref: dict, index: int, out: Path) -> str:
    """O ficheiro a anexar: a referencia, ou o recorte dela que o contrato diz (escrito na pasta do pedido)."""
    path = Path(sc["_base"]) / ref["file"]
    if not ref.get("crop"):
        return str(path)
    target = out / f"attach_{index:02d}_{ref['role']}.png"
    open_rgba(path).crop(tuple(ref["crop"])).save(target)
    return str(target)


def _states(items: list[str] | None) -> dict:
    out = {}
    for item in items or []:
        name, _, path = item.partition("=")
        if not path:
            raise ValueError(f"--state nome=caminho.png (veio {item!r})")
        out[name] = open_rgba(path)
    return out


def do_estrutura(args) -> dict:
    res = scene_mod.resolve(scene_mod.load(args.scene))
    neighbors = {k: open_rgba(v) for k, v in (("left", args.left), ("right", args.right)) if v}
    pal = _palette(args.palette, res)
    rep = estrutura.review(open_rgba(args.image), res, open_rgba(args.master) if args.master else None, neighbors,
                           _states(args.state), pal)
    if args.out:
        rep["file"] = _write(Path(args.out), rep)
    return {"ok": not rep["blocking"], **rep}


def do_montagem(args) -> dict:
    res = scene_mod.resolve(scene_mod.load(args.scene))
    b = montagem.bench(open_rgba(args.image), res, args.x)
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    files = {}
    for name in ("day", "night"):
        b[name].save(out / f"montagem_{name}.png")
        upscale(b[name], 2).save(out / f"montagem_{name}@2x.png")
        files[name] = str(out / f"montagem_{name}.png")
    report = {"placement": b["placement"], "actors": b["actors"], "night_tint": b["night_tint"], "files": files}
    files["json"] = _write(out / "montagem.json", report)
    return {"ok": True, **report,
            "next": "rever a 1x e a 2x: a porta deixa passar o rei? as silhuetas separam-se de noite? a densidade de "
                    "detalhe e a dos vizinhos? (a aprovacao e do dono)"}


def mark(text: str) -> tuple:
    """`x0,y0,x1,y1=metrica` ou `x0,y0,x1,y1=MINxMAX` (px de ecra)."""
    area, _, what = text.partition("=")
    if not what:
        raise ValueError(f"marco: caixa=metrica ou caixa=MINxMAX (veio {text!r})")
    return box(area), what


def do_escala(args) -> dict:
    ref = open_rgba(args.reference)
    step = args.step
    found = regua.metrics(regua.ruler(), step)
    marks = []
    for area, what in args.mark:
        known = [m for m in found if m["id"] == what]
        marks.append({"box": area, "metric": what if known else None,
                      "target": tuple(known[0]["px"]) if known else pair(what)})
    info = montagem.scale_reference(ref, marks, step, args.crop, args.ground_y, args.footprint)
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    rul = regua.ruler()
    stage = montagem.reference_bench(ref, info, regua.world(), [rul["tallest"]["id"], rul["shortest"]["id"]])
    stage.save(out / "escala.png")
    upscale(stage, 2).save(out / "escala@2x.png")
    info["files"] = {"bench": str(out / "escala.png"), "bench_2x": str(out / "escala@2x.png")}
    info["files"]["json"] = _write(out / "escala.json", info)
    return {"ok": True, **info}


def register(sub) -> None:
    p = command(sub, "regua", "A regua de escala: os atores reais, a linha do chao, a fase da grade e as metricas de "
                "arquitetura (porta, beiral, peitoril), lidas dos ficheiros do jogo", do_regua)
    p.add_argument("--step", type=int, default=2, help="a grade do cenario em px de ecra")
    p = command(sub, "cena", "Validar um contrato forja.scene/1 e compilar o pedido: prompt de elevacao lateral, "
                "regua em imagem, expect.json; com --backend, o plano sem rede", do_cena)
    p.add_argument("scene", help="o contrato forja.scene/1 (JSON)")
    p.add_argument("-o", "--out", required=True)
    p.add_argument("--target", default="gpt-image", choices=("gpt-image", "gemini", "pixellab", "generic"))
    p.add_argument("--backend", choices=("openai", "gemini", "pixellab"), help="planear para um gerador (sem rede)")
    p.add_argument("--palette", help="por omissao a do contrato; 'none' sem paleta")
    p.add_argument("--model")
    p.add_argument("--guides", default="auto", choices=("auto", "none", "palette", "layout", "all"))
    p.add_argument("--image-size", help="Gemini: 1K, 2K ou 4K")
    p.add_argument("--seed", type=int, help="PixelLab: seed")
    p.add_argument("--refs", help="registo forja.refs/1: o estado de cada referencia da cena")
    p = command(sub, "estrutura", "Rever uma peca de cenario forjada contra o contrato: extensao, grade, base no chao, "
                "vaos, sinais de identidade, repeticao, conectores e estados", do_estrutura)
    p.add_argument("image")
    p.add_argument("--scene", required=True)
    p.add_argument("--master", help="o mestre aprovado: os sinais tem de ficar iguais a ele")
    p.add_argument("--left", help="o modulo vizinho a esquerda")
    p.add_argument("--right", help="o modulo vizinho a direita")
    p.add_argument("--state", action="append", help="nome=caminho.png de um estado (igual a base fora das zonas)")
    p.add_argument("--palette")
    p.add_argument("-o", "--out", help="escrever o relatorio JSON aqui")
    p = command(sub, "montagem", "Pousar a peca no mundo 1280x720 com os atores reais: dia e noite aproximada, 1x e "
                "2x", do_montagem)
    p.add_argument("image")
    p.add_argument("--scene", required=True)
    p.add_argument("--x", type=int, help="o centro da base no mundo (por omissao o meio da janela)")
    p.add_argument("-o", "--out", required=True)
    p = command(sub, "escala", "Adequar uma referencia aos atores: um marco medido (porta, barril, figura) da a escala; "
                "o pixel aparente contra a celula de 2 px diz se o redesenho simplifica ou acrescenta", do_escala)
    p.add_argument("reference")
    p.add_argument("--mark", type=mark, action="append", required=True, help="um marco: x0,y0,x1,y1=metrica (ex.: "
                   "door_clear_height, barrel_height) ou =MINxMAX em px; repetivel: o primeiro e o do proprio objeto, "
                   "os outros conferem se a referencia tem uma so escala")
    p.add_argument("--crop", type=box, help="o objeto a adaptar (por omissao o opaco inteiro)")
    p.add_argument("--ground-y", type=int, help="a linha do chao na referencia (por omissao a base do marco)")
    p.add_argument("--footprint", type=int, help="a largura da obra na simulacao (data/source/buildings.csv, width_px)")
    p.add_argument("--step", type=int, default=2)
    p.add_argument("-o", "--out", required=True)
