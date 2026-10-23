"""Subcomandos de producao: sheet, anim, aseprite, tileset, seams, palette, motion, kinds."""
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image

from . import anim, aseprite, contracts, godot, motion, palette as palmod, sheetforge, tiles
from .cli import box, command, out_path, pair
from .cmd_image import _options, common
from .imageops import open_rgba


def do_sheet(args) -> dict:
    opts = _options(args)
    layout = args.layout
    tags = sheetforge.parse_tags(args.tags)
    if args.expect:
        exp = json.loads(Path(args.expect).read_text(encoding="utf-8"))
        layout = layout or tuple(exp["layout"])
        tags = tags or ([tuple(t) for t in exp["tags"]] if exp.get("tags") else None)
        opts.scale = opts.scale or float(exp["scale"])
    sopts = sheetforge.SheetOptions(tags=tags, layout=layout, anchor=args.anchor, same_height=args.same_height,
                                    deflicker=args.deflicker, lock=args.lock, mirror=args.mirror,
                                    godot_texture=args.godot_texture)
    prompt = Path(args.prompt_file).read_text(encoding="utf-8") if args.prompt_file else None
    res = sheetforge.forge_sheet(args.image, args.out, opts, sopts, args.name, prompt, args.generator)
    return {k: res[k] for k in ("ok", "summary", "requested", "found", "files", "metrics", "prompt_feedback",
                                "pivot", "canvas", "tags", "stray_blobs")}


def do_anim(args) -> dict:
    frames = [open_rgba(f) for f in args.frames]
    if len({f.size for f in frames}) != 1:
        raise ValueError("todos os quadros precisam da mesma tela")
    tags = sheetforge.parse_tags(args.tags)
    tl, durations = sheetforge._timeline(tags, len(frames))
    if args.ms:
        durations = [args.ms] * len(frames)
    pivot = args.pivot
    files = anim.export(frames, args.out, args.name, durations, tl, pivot, args.columns)
    files["aseprite"] = str(aseprite.from_frames(Path(args.out) / f"{args.name}.aseprite", frames,
                                                 durations=durations, tags=tl, pivot=pivot))
    if args.mirror and pivot:
        left, lp = anim.mirror(frames, pivot)
        files.update({f"left_{k}": v for k, v in anim.export(left, args.out, f"{args.name}_left", durations,
                                                               tl, lp, args.columns, False).items()})
    if args.godot_texture:
        _, rects = anim.strip(frames, args.columns)
        loops = {t: (contracts.tag(t) or {}).get("loop", True) for t, *_ in tl}
        files["godot"] = str(godot.write(Path(args.out) / f"{args.name}.tres", godot.sprite_frames(
            args.godot_texture, rects, durations, tl, 1000 / durations[0], loops)))
    return {"ok": True, "files": files, "tags": [list(t) for t in tl], "metrics": anim.metrics(frames, pivot)}


def do_aseprite(args) -> dict:
    frames = [open_rgba(f) for f in args.frames]
    tags = sheetforge.parse_tags(args.tags)
    tl, durations = sheetforge._timeline(tags, len(frames))
    pal = palmod.load(args.palette).colors if args.palette else None
    path = aseprite.from_frames(args.out, frames, args.layer, durations, tl, pal, args.pivot)
    return {"ok": True, "out": str(path), "verify": aseprite.verify(path, frames)}


def _texture(spec: str | None, size: int) -> Image.Image | None:
    if not spec or spec == "none":
        return None
    if spec.startswith("#"):
        return Image.new("RGBA", (size, size), spec)
    return open_rgba(spec)


def do_tileset(args) -> dict:
    lower, upper = _texture(args.lower, args.size), _texture(args.upper, args.size)
    rim = _texture(args.rim, args.size)
    sheet, meta = tiles.wang16(args.size, lower, upper, rim=rim, rim_width=args.rim_width if rim else 0,
                               rim_side=args.rim_side, rag=args.rag, seed=args.seed, cluster=args.cluster)
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    sheet.save(out / f"{args.name}.png")
    tiles.demo_map(sheet, args.size, seed=args.seed).save(out / f"{args.name}_demo.png")
    (out / f"{args.name}.json").write_text(json.dumps({"tile_size": args.size, "encoding": "NW<<3|NE<<2|SW<<1|SE",
                                                       "tiles": meta}, indent=1) + "\n", encoding="utf-8")
    files = {"sheet": str(out / f"{args.name}.png"), "demo": str(out / f"{args.name}_demo.png"),
             "json": str(out / f"{args.name}.json")}
    if args.godot_texture:
        files["godot"] = str(godot.write(out / f"{args.name}.tres", godot.tileset(args.godot_texture, args.size)))
    return {"ok": True, "files": files, "tiles": 16}


def do_seams(args) -> dict:
    img = open_rgba(args.image)
    res = tiles.seams(img)
    if args.out:
        tiles.repeat(img).save(out_path(args.out, Path(args.out)))
    return {"ok": res["seamless"], **res}


def do_palette(args) -> dict:
    if args.action == "ramp":
        from . import color
        pal = palmod.ramp(color.parse_hex(args.source), args.steps, args.hue_shift)
    elif args.action == "extract":
        pal = palmod.extract(open_rgba(args.source), args.colors)
    else:
        pal = palmod.load(args.source)
    if args.merge:
        pal = palmod.merge_close(pal, args.merge)
    if args.out:
        palmod.save(pal, args.out)
    return {"ok": True, "name": pal.name, "size": len(pal), "colors": pal.hexes(), "out": args.out}


def do_motion(args) -> dict:
    frame = open_rgba(args.image)
    if args.effect == "breathe":
        frames = motion.breathe(frame, args.split_y)
    elif args.effect == "flash":
        frames = [frame, motion.flash(frame)]
    elif args.effect == "dissolve":
        frames = motion.dissolve(frame, args.steps)
    else:
        frames = [frame, motion.knockback(frame)]
    files = anim.export(frames, args.out, args.name or args.effect, pivot=args.pivot)
    return {"ok": True, "files": files, "frames": len(frames),
            "note": "ajuda procedural: nao substitui desenhar a pose (Animation Bible, fluxo do Aseprite)"}


def do_lock(args) -> dict:
    frames = [open_rgba(f) for f in args.frames]
    locked, report = motion.lock(frames, args.box, args.ref, args.search)
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    paths = []
    for i, f in enumerate(locked):
        f.save(out / f"{Path(args.frames[i]).stem}.png")
        paths.append(str(out / f"{Path(args.frames[i]).stem}.png"))
    return {"ok": True, "frames": paths, "report": report}


def do_kinds(args) -> dict:
    data = contracts.load_data()
    return {"ok": True, "palette": data["palette"], "fps": data["fps"],
            "kinds": {k: contracts.get(k).as_dict() for k in data["kinds"]}, "tags": contracts.tags()}


def register(sub) -> None:
    p = command(sub, "sheet", "Prancha gerada -> quadros nativos alinhados, tira, JSON, .aseprite, GIF, relatorio", do_sheet)
    p.add_argument("image")
    p.add_argument("-o", "--out", required=True)
    common(p)
    p.add_argument("--tags", help="ex.: 'idle' ou 'idle,walk' (contagens da Animation Bible) ou 'idle:4'")
    p.add_argument("--layout", type=pair, help="colunas x linhas da prancha (junta pedacos por celula)")
    p.add_argument("--anchor", default="feet", choices=("feet", "mass", "bottom", "center"))
    p.add_argument("--same-height", action="store_true", help="igualar a altura das figuras antes da grade")
    p.add_argument("--deflicker", type=float, default=0.0, help="prender cores que mudam menos que isto (OKLab)")
    p.add_argument("--lock", type=box, help="caixa x0,y0,x1,y1 do rosto a travar em todos os quadros")
    p.add_argument("--mirror", action="store_true", help="exportar tambem a direcao espelhada")
    p.add_argument("--godot-texture", help="caminho res:// da tira, para escrever o SpriteFrames .tres")
    p = command(sub, "anim", "Quadros PNG -> tira/atlas, JSON do Aseprite, .aseprite, GIF/APNG (e SpriteFrames)", do_anim)
    p.add_argument("frames", nargs="+")
    p.add_argument("-o", "--out", required=True)
    p.add_argument("--name", default="anim")
    p.add_argument("--tags")
    p.add_argument("--ms", type=int, help="duracao fixa por quadro")
    p.add_argument("--pivot", type=pair)
    p.add_argument("--columns", type=int)
    p.add_argument("--mirror", action="store_true")
    p.add_argument("--godot-texture")
    p = command(sub, "aseprite", "Quadros PNG -> .aseprite (camada, tags, duracoes, paleta, pivot) e verificacao", do_aseprite)
    p.add_argument("frames", nargs="+")
    p.add_argument("-o", "--out", required=True)
    p.add_argument("--tags")
    p.add_argument("--layer", default="body")
    p.add_argument("--palette")
    p.add_argument("--pivot", type=pair)
    p = command(sub, "tileset", "Conjunto Wang de 16 por cantos (topo ou plataforma lateral) + TileSet do Godot", do_tileset)
    p.add_argument("--lower", required=True, help="textura PNG, #cor, ou 'none' (transparente: plataforma)")
    p.add_argument("--upper", required=True, help="textura PNG ou #cor")
    p.add_argument("-o", "--out", required=True)
    p.add_argument("--name", default="wang")
    p.add_argument("--size", type=int, default=32)
    p.add_argument("--rim", help="textura ou #cor do rebordo do terreno de cima")
    p.add_argument("--rim-width", type=int, default=2)
    p.add_argument("--rim-side", default="top", choices=("top", "all"))
    p.add_argument("--rag", type=float, default=0.35, help="irregularidade da fronteira")
    p.add_argument("--seed", type=int, default=0)
    p.add_argument("--cluster", type=int, default=2, help="2 = lei dos 2 px do cenario")
    p.add_argument("--godot-texture")
    p = command(sub, "seams", "A textura repete sem emenda? (e uma previa 3x3)", do_seams)
    p.add_argument("image")
    p.add_argument("-o", "--out")
    p = command(sub, "palette", "Paletas: show/convert, extract de imagem, ramp com desvio de matiz", do_palette)
    p.add_argument("action", choices=("show", "extract", "ramp"))
    p.add_argument("source", help="paleta, imagem ou #cor base")
    p.add_argument("-o", "--out")
    p.add_argument("--colors", type=int, default=16)
    p.add_argument("--steps", type=int, default=5)
    p.add_argument("--hue-shift", type=float, default=18.0)
    p.add_argument("--merge", type=float, help="fundir cores a menos disto (OKLab, ex.: 0.04)")
    p = command(sub, "motion", "Ajudas procedurais: breathe (idle de 6), flash, dissolve, knockback", do_motion)
    p.add_argument("effect", choices=("breathe", "flash", "dissolve", "knockback"))
    p.add_argument("image")
    p.add_argument("-o", "--out", required=True)
    p.add_argument("--name")
    p.add_argument("--split-y", type=int, default=0, help="breathe: linha acima da qual o corpo sobe")
    p.add_argument("--steps", type=int, default=6)
    p.add_argument("--pivot", type=pair)
    p = command(sub, "lock", "Travar o rosto/cabeca do quadro de referencia em todos os quadros", do_lock)
    p.add_argument("frames", nargs="+")
    p.add_argument("-o", "--out", required=True)
    p.add_argument("--box", type=box, required=True)
    p.add_argument("--ref", type=int, default=0)
    p.add_argument("--search", type=int, default=3)
    command(sub, "kinds", "Os contratos do Empire (telas, pivots, contornos) e as tags de animacao", do_kinds)
