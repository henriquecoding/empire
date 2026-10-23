"""Subcomandos de imagem: snap, forge, lint, clean, quantize, outline, fit, scale."""
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image

from . import cleanup, contracts, grid as gridmod, lint, outline, palette as palmod, pipeline
from . import quantize, resample, scale
from .cli import box, command, out_path, pair
from .imageops import binarize, open_rgba, upscale


def _options(args) -> pipeline.Options:
    opts = pipeline.Options(kind=args.kind, palette=args.palette, colors=args.colors, scale=args.scale,
                            cells=args.cells, bg=args.bg, tolerance=args.tolerance, method=args.method,
                            outline=getattr(args, "outline_mode", "auto"), dither=args.dither,
                            noise=args.noise, cleanup=args.cleanup, protect=args.protect,
                            fit=not getattr(args, "no_fit", False),
                            pivot=getattr(args, "pivot", None), canvas=getattr(args, "canvas", None))
    if getattr(args, "expect", None):
        exp = json.loads(Path(args.expect).read_text(encoding="utf-8"))
        opts.kind = args.kind if args.kind != "free" else exp.get("kind", opts.kind)
        if exp.get("grid") == "native" and not (opts.scale or opts.cells):
            opts.scale = 1.0
        # grade so pedida por palavras (F03): deteta-se; a escala pedida fica para comparar, nao se assume
        if exp.get("background", "transparent") != "transparent" and not opts.bg:
            opts.bg = exp["background"]
    return opts


def common(p) -> None:
    p.add_argument("--kind", default="free", choices=contracts.kinds(), help="contrato do Empire (ver `kinds`)")
    p.add_argument("--palette", help="'empire', caminho .gpl/.hex/.json/.png, hex separados por virgula, ou 'none'")
    p.add_argument("--colors", type=int, help="sem paleta: extrair N cores (k-means OKLab)")
    p.add_argument("--scale", type=float, help="tamanho do pixel logico, se conhecido")
    p.add_argument("--cells", type=pair, help="grelha logica conhecida, LxA (ex.: 64x64)")
    p.add_argument("--bg", help="cor de fundo a remover (#RRGGBB); por omissao deteta pela borda")
    p.add_argument("--tolerance", type=float, default=0.09, help="tolerancia do fundo em OKLab")
    p.add_argument("--method", default="dominant", choices=resample.METHODS, help="voto de cada celula")
    p.add_argument("--dither", default="none", choices=quantize.DITHERS, help="so em contratos que o permitem")
    p.add_argument("--noise", type=float, default=0.08, help="ruido de cor a alisar (OKLab); 0 desliga")
    p.add_argument("--cleanup", default="auto", choices=("auto",) + tuple(cleanup.POLICIES),
                   help="auto: cenario tira pixels soltos e tapa furos; personagem e efeito so os apontam")
    p.add_argument("--protect", type=box, action="append", help="caixa x0,y0,x1,y1 do recorte nativo que a limpeza "
                   "nao toca (repetivel)")
    p.add_argument("--expect", help="o expect.json do `forja prompt`")
    p.add_argument("--generator", help="quem gerou a imagem (proveniencia)")
    p.add_argument("--prompt-file", help="o prompt usado (proveniencia)")
    p.add_argument("--name", help="nome dos ficheiros de saida")


def do_snap(args) -> dict:
    image = open_rgba(args.image)
    g = gridmod.detect(image, scale=args.scale, cells=args.cells)
    sampled = resample.resample(image, g, args.method)
    out = out_path(args.out, Path(args.image).with_name(Path(args.image).stem + "_native.png"))
    sampled.image.save(out)
    return {"ok": True, "out": str(out), "grid": g.as_dict(), "sample": sampled.as_dict()}


def do_forge(args) -> dict:
    prompt = Path(args.prompt_file).read_text(encoding="utf-8") if args.prompt_file else None
    res = pipeline.forge(args.image, args.out, _options(args), args.name, prompt, args.generator, args.aseprite)
    return {"ok": res["lint"]["ok"], "files": res["files"], "lint": {k: res["lint"][k] for k in
            ("errors", "warnings", "prompt_feedback")}, "findings": res["lint"]["findings"],
            "grid": res["snap"]["grid"], "native_size": res["snap"]["native_size"], "fit": res["finish"].get("fit")}


def do_lint(args) -> dict:
    c = contracts.get(args.kind)
    pal = palmod.load(args.palette) if args.palette and args.palette != "none" else (
        palmod.load(palmod.ROOT / c.palette) if args.kind != "free" and args.palette != "none" else None)
    return lint.check(open_rgba(args.image), c, pal, frame=not args.loose)


def do_clean(args) -> dict:
    img = binarize(open_rgba(args.image))
    img, stats = cleanup.despeckle(img, args.noise, not args.no_holes)
    if args.cluster > 1:
        img, stats["merged"] = cleanup.min_cluster(img, args.cluster)
    if args.pixel_perfect:
        img, stats["pixel_perfect"] = cleanup.pixel_perfect(img)
    out = out_path(args.out, Path(args.image))
    img.save(out)
    return {"ok": True, "out": str(out), **stats}


def do_quantize(args) -> dict:
    img = binarize(open_rgba(args.image))
    if args.palette:
        pal = palmod.load(args.palette)
        img = quantize.to_palette(img, pal, args.dither, args.strength)
    elif args.colors:
        img, pal = quantize.reduce(img, args.colors, args.dither)
    else:
        raise ValueError("diga --palette ou --colors")
    out = out_path(args.out, Path(args.image))
    img.save(out)
    return {"ok": True, "out": str(out), "palette": pal.hexes()[:64], "palette_size": len(pal)}


def do_outline(args) -> dict:
    from . import color
    img = open_rgba(args.image)
    rgb = color.parse_hex(args.color)
    if args.strip:
        img, found = outline.strip(img, None)
        result = {"stripped": color.to_hex(found) if found else None}
    else:
        pal = palmod.load(args.palette) if args.palette else None
        padded = Image.new("RGBA", (img.width + 2 * args.width, img.height + 2 * args.width))
        padded.alpha_composite(img, (args.width, args.width))
        img = outline.add(padded if args.grow else img, rgb, args.width, args.mode, not args.no_corners, pal)
        result = {"mode": args.mode, "width": args.width}
    out = out_path(args.out, Path(args.image))
    img.save(out)
    return {"ok": True, "out": str(out), **result, "measure": outline.measure(img, rgb)}


def do_fit(args) -> dict:
    c = contracts.get(args.kind, canvas=list(args.canvas) if args.canvas else None,
                      pivot=list(args.pivot) if args.pivot else None)
    if not c.canvas:
        raise ValueError(f"o contrato {args.kind} nao tem tela; diga --canvas")
    img = open_rgba(args.image)
    bbox = img.getchannel("A").getbbox()
    img = img.crop(bbox) if bbox else img
    from .imageops import place
    anchor = pipeline._anchor(img, args.anchor or c.anchor)
    target = c.pivot or (c.canvas[0] // 2, c.canvas[1] - 1)
    framed, clipped = place(img, c.canvas, anchor, target)
    out = out_path(args.out, Path(args.image))
    framed.save(out)
    return {"ok": clipped == 0, "out": str(out), "canvas": list(c.canvas), "pivot": list(target),
            "clipped_pixels": clipped}


def do_scale(args) -> dict:
    img = open_rgba(args.image)
    if args.rotate is not None:
        img = scale.rotsprite(img, args.rotate)
    if args.scale2x:
        img = scale.scale2x(img)
    if args.down:
        img = scale.downscale(img, args.down)
    if args.factor:
        img = upscale(img, args.factor)
    out = out_path(args.out, Path(args.image).with_name(Path(args.image).stem + "_scaled.png"))
    img.save(out)
    return {"ok": True, "out": str(out), "size": list(img.size)}


def register(sub) -> None:
    p = command(sub, "snap", "So a grade: imagem ampliada/gerada -> resolucao nativa (como o 'unzoom')", do_snap)
    p.add_argument("image")
    p.add_argument("-o", "--out")
    p.add_argument("--scale", type=float)
    p.add_argument("--cells", type=pair)
    p.add_argument("--method", default="dominant", choices=resample.METHODS)
    p = command(sub, "forge", "Imagem gerada -> sprite do contrato: grade, fundo, paleta, contorno, tela, lint e relatorio", do_forge)
    p.add_argument("image")
    p.add_argument("-o", "--out", required=True, help="pasta de saida")
    common(p)
    p.add_argument("--outline", dest="outline_mode", default="auto", choices=("auto", "keep", "force"))
    p.add_argument("--no-fit", action="store_true", help="nao pousar na tela do contrato")
    p.add_argument("--canvas", type=pair, help="tela LxA (sobrepoe o contrato)")
    p.add_argument("--pivot", type=pair, help="pivot X,Y (sobrepoe o contrato)")
    p.add_argument("--aseprite", action="store_true", help="tambem escrever .aseprite")
    p = command(sub, "lint", "Conferir um PNG contra o contrato (achados, correcoes e prompt corretivo)", do_lint)
    p.add_argument("image")
    p.add_argument("--kind", default="free", choices=contracts.kinds())
    p.add_argument("--palette")
    p.add_argument("--loose", action="store_true", help="peca solta: sem tela nem pivot")
    p = command(sub, "clean", "Alfa binario, pixels soltos, furos, ruido de cor, cluster minimo, pixel perfect", do_clean)
    p.add_argument("image")
    p.add_argument("-o", "--out")
    p.add_argument("--noise", type=float, default=0.08)
    p.add_argument("--cluster", type=int, default=1)
    p.add_argument("--pixel-perfect", action="store_true")
    p.add_argument("--no-holes", action="store_true")
    p = command(sub, "quantize", "Levar a uma paleta (OKLab) ou reduzir a N cores, com dither ordenado opcional", do_quantize)
    p.add_argument("image")
    p.add_argument("-o", "--out")
    p.add_argument("--palette")
    p.add_argument("--colors", type=int)
    p.add_argument("--dither", default="none", choices=quantize.DITHERS)
    p.add_argument("--strength", type=float, default=1.0)
    p = command(sub, "outline", "Por (exterior, interior, seletivo) ou tirar o contorno", do_outline)
    p.add_argument("image")
    p.add_argument("-o", "--out")
    p.add_argument("--width", type=int, default=1)
    p.add_argument("--mode", default="outer", choices=outline.MODES)
    p.add_argument("--color", default="#000000")
    p.add_argument("--palette", help="paleta para o modo seletivo")
    p.add_argument("--strip", action="store_true")
    p.add_argument("--grow", action="store_true", help="aumentar a tela para o contorno caber")
    p.add_argument("--no-corners", action="store_true", help="contorno so em cruz (sem diagonais)")
    p = command(sub, "fit", "Pousar o sprite na tela e no pivot do contrato", do_fit)
    p.add_argument("image")
    p.add_argument("-o", "--out")
    p.add_argument("--kind", default="character_s2", choices=contracts.kinds())
    p.add_argument("--canvas", type=pair)
    p.add_argument("--pivot", type=pair)
    p.add_argument("--anchor", choices=("feet", "bottom", "center"))
    p = command(sub, "scale", "Ampliar inteiro, Scale2x, rodar com RotSprite ou reduzir por voto", do_scale)
    p.add_argument("image")
    p.add_argument("-o", "--out")
    p.add_argument("--factor", type=int)
    p.add_argument("--scale2x", action="store_true")
    p.add_argument("--rotate", type=float, help="graus, sentido anti-horario (RotSprite)")
    p.add_argument("--down", type=int, help="reduzir por um fator inteiro (voto)")
