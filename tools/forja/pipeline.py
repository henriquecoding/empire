"""A forja: de uma imagem gerada a um sprite que cumpre o contrato, com relatorio.

grade -> amostragem -> fundo -> limpeza -> paleta -> contorno -> cluster ->
tela e pivot -> lint -> ficheiros. Cada passo deixa o que decidiu no relatorio,
para que o agente (ou o autor) saiba o que aconteceu sem abrir as imagens.
"""
from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path

from PIL import Image

from . import cleanup, contracts, grid as gridmod, gridcheck, lint, masks, matte, outline, palette as palmod
from . import provenance, quantize, resample, verdicts
from .imageops import flat as imageops_flat, foot_point, opaque_bbox, open_rgba, place, upscale


@dataclass
class Options:
    kind: str = "free"
    palette: str | None = None
    colors: int | None = None
    scale: float | None = None
    cells: tuple[int, int] | None = None
    bg: str | None = None
    tolerance: float = 0.09
    method: str = "dominant"
    outline: str = "auto"
    dither: str = "none"
    noise: float = 0.08
    cleanup: str = "auto"
    protect: list[tuple[int, int, int, int]] | None = None
    bare: list[tuple[int, int, int, int]] | None = None
    fit: bool = True
    pivot: tuple[int, int] | None = None
    canvas: tuple[int, int] | None = None
    notes: list[str] = field(default_factory=list)


def contract_for(opts: Options) -> contracts.Contract:
    return contracts.get(opts.kind, canvas=list(opts.canvas) if opts.canvas else None,
                         pivot=list(opts.pivot) if opts.pivot else None)


def palette_for(opts: Options, contract: contracts.Contract) -> palmod.Palette | None:
    if opts.palette == "none":
        return None
    if opts.palette:
        return palmod.load(opts.palette)
    if opts.kind != "free":
        return palmod.load(palmod.ROOT / contract.palette)
    return None


def snap(image: Image.Image, opts: Options, g: gridmod.Grid | None = None) -> tuple[Image.Image, dict]:
    """Imagem gerada -> nativa recortada, com fundo transparente."""
    g = g or gridcheck.detect(image, scale=opts.scale, cells=opts.cells)
    sampled = resample.resample(image, g, opts.method)
    native, bginfo = matte.remove(sampled.image, opts.bg, opts.tolerance)
    box = opaque_bbox(native) or (0, 0, native.width, native.height)
    native = native.crop(box)
    return native, {"grid": g.as_dict(), "sample": sampled.as_dict(), "background": bginfo,
                    "native_size": list(native.size), "subgrid": subgrid(native, sampled.impure, box)}


def subgrid(native: Image.Image, impure: list[tuple[int, int]], box: tuple[int, int, int, int]) -> dict:
    """A maior zona de celulas misturadas: o gerador desenhou ali mais fino do que a propria grade.

    Costuma ser o rosto. O voto nao recupera um traco mais fino que a celula; diz-se onde e,
    para o gerador, como desenhar (ou corrige-se essa caixa com `forja inpaint`).
    """
    alpha = native.getchannel("A")
    cells = {(x - box[0], y - box[1]) for x, y in impure
             if 0 <= x - box[0] < native.width and 0 <= y - box[1] < native.height
             and alpha.getpixel((x - box[0], y - box[1])) >= 128}
    solid = sum(1 for v in imageops_flat(alpha) if v >= 128) or 1
    best: list[tuple[int, int]] = []
    seen: set = set()
    for start in cells:
        if start in seen:
            continue
        group, stack = [], [start]
        seen.add(start)
        while stack:
            x, y = stack.pop()
            group.append((x, y))
            for nx in range(x - 1, x + 2):
                for ny in range(y - 1, y + 2):
                    if (nx, ny) in cells and (nx, ny) not in seen:
                        seen.add((nx, ny))
                        stack.append((nx, ny))
        best = max(best, group, key=len)
    region = ([min(x for x, _ in best), min(y for _, y in best), max(x for x, _ in best) + 1,
               max(y for _, y in best) + 1] if best else None)
    return {"cells": len(cells), "share": round(len(cells) / solid, 3), "largest": len(best), "box": region,
            "_coords": sorted(cells)}


def finish(native: Image.Image, opts: Options, contract: contracts.Contract,
           pal: palmod.Palette | None) -> tuple[Image.Image, dict]:
    """Limpeza, paleta, contorno, cluster e tela — o que torna o recorte um asset."""
    info: dict = {}
    img, info["cleanup"] = cleanup.clean(native, cleanup.policy_for(opts.kind, opts.cleanup), opts.noise,
                                         opts.protect)
    if contract.outline_px:
        img, info["outline_normalized"] = outline.normalize(img, contract.outline_color)
    if pal is not None:
        img = quantize.to_palette(img, pal, opts.dither if contract.dither else "none")
        info["palette"] = {"name": pal.name, "size": len(pal)}
    elif opts.colors:
        img, extracted = quantize.reduce(img, opts.colors, opts.dither if contract.dither else "none")
        info["palette"] = {"name": "extraida", "colors": extracted.hexes()}
    shift = (0, 0)
    if contract.outline_px and opts.outline != "keep":
        measured = outline.measure(img, contract.outline_color)
        if opts.outline == "force" or measured["outline_share"] < 0.85:
            if opts.outline == "force":
                img, _ = outline.strip(img)
            keep = frozenset().union(*[masks.box((x0 + 1, y0 + 1, x1 + 1, y1 + 1))
                                       for x0, y0, x1, y1 in opts.bare or []])
            img = outline.add(_pad(img, 1), contract.outline_color, 1, keep=keep)
            box = opaque_bbox(img)
            img = img.crop(box) if box else img
            shift = (box[0] - 1, box[1] - 1) if box else (-1, -1)
            info["outline_added"] = True
    if opts.bare:
        info["outline_bare"] = [list(b) for b in opts.bare]
    if contract.cluster > 1:
        img = upscale(img, contract.cluster)
        info["cluster_upscale"] = contract.cluster
    info["shift"] = [shift[0] * contract.cluster, shift[1] * contract.cluster]
    if opts.fit and contract.canvas:
        anchor = _anchor(img, contract.anchor)
        target = contract.pivot or (contract.canvas[0] // 2, contract.canvas[1] - 1)
        img, clipped = place(img, contract.canvas, anchor, target)
        info["fit"] = {"canvas": list(contract.canvas), "pivot": list(target), "anchor": list(anchor),
                       "clipped_pixels": clipped}
    return img, info


def _to_final(box: list[int], info: dict, contract: contracts.Contract) -> list[int]:
    """Uma caixa do recorte nativo nas coordenadas do PNG final (cluster e tela)."""
    k = info.get("cluster_upscale", 1)
    fit = info.get("fit")
    dx, dy = ((fit["pivot"][0] - fit["anchor"][0], fit["pivot"][1] - fit["anchor"][1]) if fit else (0, 0))
    pad = 1 if info.get("outline_added") else 0
    return [box[0] * k + pad + dx, box[1] * k + pad + dy, box[2] * k + pad + dx, box[3] * k + pad + dy]


def _pad(img: Image.Image, n: int) -> Image.Image:
    out = Image.new("RGBA", (img.width + 2 * n, img.height + 2 * n))
    out.alpha_composite(img, (n, n))
    return out


def _anchor(img: Image.Image, mode: str) -> tuple[int, int]:
    if mode == "feet":
        return foot_point(img) or (img.width // 2, img.height - 1)
    if mode == "center":
        return img.width // 2, img.height // 2
    return img.width // 2, img.height - 1


def forge(source: str | Path, out_dir: str | Path, opts: Options, name: str | None = None,
          prompt: str | None = None, generator: str | None = None, aseprite: bool = False,
          report_html: bool = True) -> dict:
    """Um ficheiro de entrada, uma figura. Escreve <nome>.png, @4x, .json e report.html."""
    source = Path(source)
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    name = name or source.stem
    image = open_rgba(source)
    contract = contract_for(opts)
    pal = palette_for(opts, contract)
    g = gridcheck.detect(image, scale=opts.scale, cells=opts.cells)
    native, snapinfo = snap(image, opts, g)
    final, finishinfo = finish(native, opts, contract, pal)
    exempt = frozenset().union(*[masks.box(_to_final(list(b), finishinfo, contract)) for b in opts.bare or []])
    verdict = lint.check(final, contract, pal, frame=bool(contract.canvas), exempt=exempt)
    clipped = (finishinfo.get("fit") or {}).get("clipped_pixels", 0)
    if clipped:
        lint.add(verdict, lint.too_big(contract, clipped, native.size))
    sub = snapinfo["subgrid"]
    if sub["box"] and (sub["share"] >= 0.05 or sub["largest"] >= 12):
        lint.add(verdict, lint.below_grid(sub, _to_final(sub["box"], finishinfo, contract)))
    final.save(out / f"{name}.png")
    upscale(final, 4).save(out / f"{name}@4x.png")
    files = {"png": str(out / f"{name}.png"), "preview": str(out / f"{name}@4x.png")}
    if aseprite:
        from . import aseprite as ase
        pivot = (finishinfo.get("fit") or {}).get("pivot")
        files["aseprite"] = str(ase.from_frames(out / f"{name}.aseprite", [final],
                                                palette=pal.colors if pal and len(pal) <= 256 else None,
                                                pivot=tuple(pivot) if pivot else None))
    result = {"name": name, "contract": contract.as_dict(), "snap": snapinfo, "finish": finishinfo,
              "lint": verdict, "files": files, "verdicts": verdicts.summary(verdicts.for_review(verdict["ok"], None)),
              "provenance": provenance.record(source, generator, prompt, opts.__dict__)}
    impure = [_to_final([x, y, x + 1, y + 1], finishinfo, contract)[:2] for x, y in sub.pop("_coords")]
    if report_html:
        from . import report
        files["report"] = str(report.single(out / "report.html", image, g, final, result, impure))
    (out / f"{name}.json").write_text(json.dumps(result, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    files["json"] = str(out / f"{name}.json")
    return result
