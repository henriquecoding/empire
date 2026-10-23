"""Subcomandos com gerador: prompt, generate, auto (ciclo fechado), inpaint; e prova e mcp."""
from __future__ import annotations

import io
import json
from pathlib import Path

from PIL import Image

from . import contracts, guides, palette as palmod, pipeline, prompts, sheetforge
from .cli import box, command, out_path
from .imageops import open_rgba

BACKENDS = ("openai", "gemini", "pixellab")


def _palette(args, kind: str) -> palmod.Palette | None:
    if args.palette == "none" or (kind == "free" and not args.palette):
        return None
    return palmod.load(args.palette or palmod.ROOT / contracts.get(kind).palette)


def do_prompt(args) -> dict:
    tags = sheetforge.parse_tags(args.tags)
    pal = _palette(args, args.kind)
    res = prompts.build(args.subject, args.kind, tags, args.facing, args.reference, pal, args.target,
                        args.background)
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    (out / "prompt.txt").write_text(res["prompt"] + "\n", encoding="utf-8")
    (out / "expect.json").write_text(json.dumps(res["expect"], indent=1) + "\n", encoding="utf-8")
    (out / "pixellab.json").write_text(json.dumps(res["pixellab"], indent=1) + "\n", encoding="utf-8")
    c = contracts.get(args.kind)
    pivot_row = c.pivot[1] // c.cluster if c.pivot else None
    files = guides.write(out, res["expect"], pal, pivot_row)
    return {"ok": True, "prompt": res["prompt"], "size": res["size"], "expect": res["expect"], "advice": res["advice"],
            "files": {"prompt": str(out / "prompt.txt"), "expect": str(out / "expect.json"),
                      "pixellab": str(out / "pixellab.json"), **files},
            "next": f"gere a imagem ({res['size']}) com o prompt e as guias; depois: python3 -m tools.forja "
                    f"{'sheet' if res['expect']['frames'] > 1 else 'forge'} <imagem> --expect {out / 'expect.json'} -o <pasta>"}


def generate_images(backend: str, prompt: str, size: str, references: list[bytes], model: str | None,
                    n: int = 1, transport=None, background: str = "auto") -> dict:
    if backend == "openai":
        from .backends import openai_images
        if references:
            return openai_images.edit(prompt, references, None, size, model, n=n, background=background,
                                      transport=transport)
        return openai_images.generate(prompt, size, model, n=n, background=background, transport=transport)
    if backend == "gemini":
        from .backends import gemini_images
        w, _, h = size.partition("x")
        aspect = "1:1" if w == h else ("3:2" if int(w) > int(h) else "2:3")
        return gemini_images.generate(prompt, references, model, aspect, transport=transport)
    from .backends import pixellab_api
    w, _, h = size.partition("x")
    return pixellab_api.generate(prompt, int(w), int(h), model or "pixflux", transport=transport,
                                 no_background=True)


def _save(images: list[bytes], out: Path, stem: str) -> list[str]:
    out.mkdir(parents=True, exist_ok=True)
    paths = []
    for i, data in enumerate(images):
        path = out / f"{stem}_{i + 1:02d}.png"
        with Image.open(io.BytesIO(data)) as im:
            im.save(path)
        paths.append(str(path))
    return paths


def do_generate(args) -> dict:
    prompt = args.prompt or Path(args.prompt_file).read_text(encoding="utf-8")
    size = args.size
    background = "auto"
    if args.expect:
        exp = json.loads(Path(args.expect).read_text(encoding="utf-8"))
        size = size or "%dx%d" % tuple(exp["size"])
        background = "transparent" if exp.get("background") == "transparent" else "opaque"
    refs = [Path(r).read_bytes() for r in args.reference or []]
    res = generate_images(args.backend, prompt, size or "1024x1024", refs, args.model, args.n, None, background)
    out = Path(args.out)
    paths = _save(res["images"], out, args.name)
    meta = {"model": res["model"], "request": res.get("request"), "prompt": prompt, "files": paths,
            "references": args.reference or []}
    (out / f"{args.name}.generation.json").write_text(json.dumps(meta, indent=1, ensure_ascii=False) + "\n",
                                                      encoding="utf-8")
    return {"ok": bool(paths), "files": paths, "model": res["model"]}


def do_auto(args, transport=None) -> dict:
    """Ciclo fechado: prompt -> gerar -> forjar -> lint -> prompt corretivo -> ... ate passar."""
    tags = sheetforge.parse_tags(args.tags)
    pal = _palette(args, args.kind)
    built = prompts.build(args.subject, args.kind, tags, args.facing, bool(args.reference), pal,
                          "gemini" if args.backend == "gemini" else "gpt-image")
    exp, prompt, out = built["expect"], built["prompt"], Path(args.out)
    refs = [Path(r).read_bytes() for r in args.reference or []]
    history = []
    for attempt in range(1, args.attempts + 1):
        res = generate_images(args.backend, prompt, built["size"], refs, args.model, 1, transport,
                              "transparent" if exp["background"] == "transparent" else "opaque")
        [path] = _save(res["images"][:1], out / "raw", f"try{attempt}")
        opts = pipeline.Options(kind=args.kind, palette=args.palette, bg=None if exp["background"] == "transparent"
                                else exp["background"])
        if exp["frames"] > 1:
            opts.scale = float(exp["scale"])
            r = sheetforge.forge_sheet(path, out / f"try{attempt}", opts, sheetforge.SheetOptions(
                tags=[tuple(t) for t in exp["tags"]] if exp.get("tags") else None, layout=tuple(exp["layout"])),
                prompt=prompt, generator=res["model"])
            ok, feedback = r["ok"], r["prompt_feedback"]
        else:
            r = pipeline.forge(path, out / f"try{attempt}", opts, prompt=prompt, generator=res["model"])
            ok, feedback = r["lint"]["ok"], r["lint"]["prompt_feedback"]
        history.append({"attempt": attempt, "ok": ok, "image": path, "feedback": feedback})
        if ok:
            break
        prompt = prompts.corrective(built["prompt"], feedback)
    return {"ok": history[-1]["ok"], "attempts": history, "best": str(out / f"try{len(history)}")}


def do_inpaint(args) -> dict:
    from . import inpaint
    native = open_rgba(args.image)
    pal = palmod.load(args.palette) if args.palette else None
    refs = [Path(r).read_bytes() for r in args.reference or []]
    result, info = inpaint.run(native, args.box, args.change, pal, refs, model=args.model)
    out = out_path(args.out, Path(args.image).with_name(Path(args.image).stem + "_edit.png"))
    result.save(out)
    return {"ok": info["outside_identical"], "out": str(out), **info}


def do_prova(args) -> dict:
    from . import prova
    if args.bench:
        return prova.bench(args.bench)
    return prova.run(Path(args.out) if args.out else None)


def do_mcp(args) -> dict:
    from . import mcp_server
    mcp_server.serve()
    return {"_raw": ""}


def register(sub) -> None:
    p = command(sub, "prompt", "Compilar o pedido para o gerador: prompt, tamanho, guias e expect.json", do_prompt)
    p.add_argument("subject", help="o que desenhar, em poucas palavras (ingles ou portugues)")
    p.add_argument("-o", "--out", required=True)
    p.add_argument("--kind", default="character_s2", choices=contracts.kinds())
    p.add_argument("--tags", help="animacao: 'walk' ou 'idle,walk' ou 'attack:5'")
    p.add_argument("--facing", default="right", choices=("right", "left"))
    p.add_argument("--reference", action="store_true", help="vai anexar o design aprovado")
    p.add_argument("--target", default="gpt-image", choices=prompts.TARGETS)
    p.add_argument("--background", default="auto", choices=("auto", "transparent", "key"))
    p.add_argument("--palette")
    p = command(sub, "generate", "Pedir a imagem a um gerador (OPENAI_API_KEY, GEMINI_API_KEY ou PIXELLAB_API_KEY)", do_generate)
    p.add_argument("--backend", default="openai", choices=BACKENDS)
    p.add_argument("--prompt")
    p.add_argument("--prompt-file")
    p.add_argument("--expect")
    p.add_argument("--reference", nargs="*", help="imagens de referencia (design aprovado, guias)")
    p.add_argument("--model")
    p.add_argument("--size")
    p.add_argument("--n", type=int, default=1)
    p.add_argument("-o", "--out", required=True)
    p.add_argument("--name", default="gen")
    p = command(sub, "auto", "Ciclo fechado com um gerador: pedir, forjar, conferir e corrigir o prompt", do_auto)
    p.add_argument("subject")
    p.add_argument("-o", "--out", required=True)
    p.add_argument("--backend", default="openai", choices=BACKENDS)
    p.add_argument("--kind", default="character_s2", choices=contracts.kinds())
    p.add_argument("--tags")
    p.add_argument("--facing", default="right", choices=("right", "left"))
    p.add_argument("--reference", nargs="*")
    p.add_argument("--palette")
    p.add_argument("--model")
    p.add_argument("--attempts", type=int, default=3)
    p = command(sub, "inpaint", "Mudar so uma caixa do sprite com o gpt-image; fora dela, pixels identicos", do_inpaint)
    p.add_argument("image")
    p.add_argument("--box", type=box, required=True)
    p.add_argument("--change", required=True, help="o que mudar dentro da caixa")
    p.add_argument("--palette")
    p.add_argument("--reference", nargs="*")
    p.add_argument("--model")
    p.add_argument("-o", "--out")
    p = command(sub, "prova", "A prova da Forja: pixel art falsa fabricada, recuperada e conferida", do_prova)
    p.add_argument("-o", "--out", help="pasta para guardar as imagens da prova")
    p.add_argument("--bench", type=int, help="em vez da prova: bancada pesada com N casos sorteados (lenta)")
    command(sub, "mcp", "Servidor MCP (stdio) com todas as ferramentas, para Codex, Claude Code e outros", do_mcp)
