"""A forja: de uma imagem gerada a um sprite que cumpre o contrato, com relatorio.

grade -> amostragem -> fundo -> limpeza -> paleta -> contorno -> cluster ->
tela e pivot -> lint -> ficheiros. Cada passo deixa o que decidiu no relatorio,
para que o agente (ou o autor) saiba o que aconteceu sem abrir as imagens.
"""
from __future__ import annotations

import json
from dataclasses import dataclass, field, replace
from pathlib import Path

from PIL import Image

from . import cleanup, contracts, grid as gridmod, gridcheck, guard, lint, masks, matte, outline, palette as palmod
from . import limits, lineage, loss, occupancy, provenance, quantize, resample, signals, verdicts
from .imageops import count_colors, foot_point, inside, opaque_bbox, open_rgba, place, upscale
from .loss import subgrid  # mudou-se para loss.py; pipeline.subgrid continua (os ensaios de 27/10)


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
    reduce: bool = False  # FORJA-07: a grade dada e uma reducao deliberada (adaptacao, nao recuperacao)
    signals: dict | None = None  # forja.signals/1: pinos e regioes declarados para esta imagem
    origin: tuple[int, int] | None = None  # cena (FORJA-11): a celula da grade pedida que e o canto da tela
    origin_grid: tuple[int, int] | None = None  # e a grade pedida; so com ela medida a figura fica onde a grade a pos
    lineage: dict | None = None  # FORJA-15: a cadeia da etapa que produziu esta entrada (o JSON do forge anterior)
    native_root: bool = False  # e a entrada ja nativa e a origem da cadeia (desenho nativo), nao uma recuperacao
    owner_rules: dict | None = None  # regras consultadas pelo pedido; conservadas na cadeia
    crop_at: tuple[int, int] | None = None  # interno: onde o recorte do snap comecava na grade recebida
    useful_box: tuple[int, int, int, int] | None = None


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


def snap(image: Image.Image, opts: Options, g: gridmod.Grid | None = None,
         sampled: resample.Sampled | None = None) -> tuple[Image.Image, dict]:
    """Imagem gerada -> nativa recortada, com fundo transparente. `sampled`: a amostragem que a conferencia da grade
    ja fez pelo voto dominante (O6), que so serve se o metodo pedido e esse."""
    g = g or gridcheck.detect(image, scale=opts.scale, cells=opts.cells, reduce=opts.reduce)
    if sampled is None or opts.method != "dominant":
        sampled = resample.resample(image, g, opts.method)
    lost = loss.observe(image, g, sampled.image)
    pins = signals.resolve([p for p in (opts.signals or {}).get("pins", []) if not p.get("target_pixel")], g)
    native, bginfo = matte.remove(signals.apply(sampled.image, pins)[0], opts.bg, opts.tolerance)
    occupied = occupancy.measure(native, contract_for(opts).canvas)
    box = opaque_bbox(native) or (0, 0, min(1, native.width), min(1, native.height))  # vazia: nada a limpar
    native = native.crop(box)
    return native, {"grid": g.as_dict(), "sample": sampled.as_dict(), "background": bginfo,
                    "grid_cells": list(sampled.image.size), "crop_origin": [box[0], box[1]],
                    "native_size": list(native.size), "subgrid": subgrid(native, sampled.impure, box),
                    "loss": loss.crop(lost, box), "pins": signals.crop(pins, box), "occupancy": occupied}


def finish(native: Image.Image, opts: Options, contract: contracts.Contract,
           pal: palmod.Palette | None) -> tuple[Image.Image, dict]:
    """Limpeza, paleta, contorno, cluster e tela — o que torna o recorte um asset."""
    info: dict = {}
    guarded = guard.pixels(opts.protect, native.size)
    img, info["cleanup"] = cleanup.clean(native, cleanup.policy_for(opts.kind, opts.cleanup), opts.noise,
                                         opts.protect)
    if contract.outline_px:
        img, info["outline_normalized"] = outline.normalize(img, contract.outline_color)
    required = guard.colors(native, guarded) + ([contract.outline_color] if contract.outline_px else [])
    img, palinfo = quantize.apply(img, pal, opts.colors, opts.dither if contract.dither else "none", required)
    if palinfo:
        info["palette"] = palinfo
    if guarded:
        img, restored = guard.restore(img, native, guarded)
        info["protect"] = {"boxes": [list(b) for b in opts.protect], "restored": restored,
                           "conflicts": guard.conflicts(native, guarded, pal)}
    shift = (0, 0)
    if contract.outline_px and opts.outline != "keep":
        measured = outline.measure(img, contract.outline_color)
        if opts.outline == "force" or measured["outline_share"] < 0.85:
            if opts.outline == "force":
                img, _ = outline.strip(img)
                if guarded:
                    img, n = guard.restore(img, native, guarded)
                    info["protect"]["restored"] += n
            keep = frozenset().union(*[masks.box((x0 + 1, y0 + 1, x1 + 1, y1 + 1))
                                       for x0, y0, x1, y1 in opts.bare or []], {(x + 1, y + 1) for x, y in guarded})
            img = outline.add(_pad(img, 1), contract.outline_color, 1, keep=keep, gaps=opts.outline != "force")
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
        if opts.origin is not None and opts.crop_at is not None:  # cena: fica onde a grade a pos, sem recentrar
            anchor, c = (0, 0), contract.cluster if info.get("outline_added") else 0
            target = tuple(inside((opts.crop_at[i] - opts.origin[i]) * contract.cluster + info["shift"][i],
                                   img.size[i], contract.canvas[i], c) for i in (0, 1))
        else:
            anchor = _anchor(img, contract.anchor)
            target = contract.pivot or (contract.canvas[0] // 2, contract.canvas[1] - 1)
        img, clipped = place(img, contract.canvas, anchor, target)
        info["fit"] = {"canvas": list(contract.canvas), "pivot": list(target), "anchor": list(anchor),
                       "clipped_pixels": clipped, "mode": "origin" if anchor == (0, 0) else "anchor"}
    if guarded:
        info["protect"].update(guard.verify(img, native, guarded, info))
    budget = info.get("palette", {}).get("budget")
    if budget:
        budget["output_colors"] = count_colors(img)
        budget["within"] = budget["output_colors"] <= budget["requested"]
    return img, info


def _to_final(box: list[int], info: dict) -> list[int]:
    """Uma caixa do recorte nativo nas coordenadas do PNG final (contorno, cluster e tela)."""
    return [*guard.final_xy(box[:2], info), *guard.final_xy(box[2:], info)]


def _gridless(image: Image.Image, g: gridmod.Grid, opts: Options, contract: contracts.Contract) -> bool:
    """Sem grade nenhuma e com mais do dobro da tela nos dois lados: nao e pixel art nesta escala (O4). Antes, uma
    pintura de 1920x1920 passava 225 s pela limpeza e pelo lint para acabar a pedir "Draw the figure smaller"."""
    return (g.native and not (opts.scale or opts.cells) and bool(contract.canvas)
            and all(s > 2 * c for s, c in zip(image.size, contract.canvas)))


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
    g, sampled = gridcheck.measure(image, opts.scale, opts.cells, opts.reduce)
    if _gridless(image, g, opts, contract):
        final, finishinfo = Image.new("RGBA", contract.canvas), {}
        snapinfo = {"grid": g.as_dict(), "sample": {"size": list(image.size), "purity": None}, "background": None,
                    "native_size": list(image.size), "subgrid": {"box": None, "_coords": []}}
        verdict = limits.no_grid(final, contract, image.size)
    else:
        native, snapinfo = snap(image, opts, g, sampled)
        pinned = signals.protect_boxes(snapinfo["pins"])
        held = opts.origin is not None and snapinfo["grid_cells"] == list(opts.origin_grid or [])
        snapinfo["placement"] = "origin" if held else "anchor" if opts.origin is None else \
            "anchor: a grade recebida nao e a pedida, a figura foi centrada pela base (rever os vaos)"
        fopts = replace(opts, crop_at=tuple(snapinfo["crop_origin"]) if held else None)
        final, finishinfo = finish(native, replace(fopts, protect=(opts.protect or []) + pinned) if pinned else fopts,
                                   contract, pal)
        exempt = frozenset().union(*[masks.box(_to_final(list(b), finishinfo)) for b in opts.bare or []])
        verdict = lint.check(final, contract, pal, frame=bool(contract.canvas), exempt=exempt)
        clipped = (finishinfo.get("fit") or {}).get("clipped_pixels", 0)
        if clipped:
            limits.clipped(verdict, limits.too_big(contract, clipped, native.size))
        sub = snapinfo["subgrid"]
        if sub["box"] and (sub["share"] >= 0.05 or sub["largest"] >= 12):
            lint.add(verdict, limits.below_grid(sub, _to_final(sub["box"], finishinfo)))
        for item in guard.findings(finishinfo) + limits.losses(snapinfo, lambda b: _to_final(b, finishinfo)):
            lint.add(verdict, item)
    with Image.open(source) as im:
        snapinfo["grid_report"] = gridcheck.report(image, g, snapinfo["native_size"], contract.canvas, im.format)
    for item in limits.grid_origin(snapinfo["grid_report"]) if "loss" in snapinfo else []:  # sem grade: o no_grid
        lint.add(verdict, item)
    sig = signals.final_state(final, snapinfo, finishinfo if "loss" in snapinfo else None, opts.signals)
    for reason in sig["blocked"]:
        lint.add(verdict, lint.finding("required_signal", "error", reason))
    if opts.useful_box and "loss" in snapinfo:
        for item in limits.useful_budget(final, opts.useful_box):
            lint.add(verdict, item)
    lin = lineage.forge(image, final, g, snapinfo, finishinfo if "loss" in snapinfo else None, opts)
    for item in limits.inherited(lin):
        lint.add(verdict, item)
    sub = snapinfo["subgrid"]
    final.save(out / f"{name}.png")
    upscale(final, 4).save(out / f"{name}@4x.png")
    files = {"png": str(out / f"{name}.png"), "preview": str(out / f"{name}@4x.png")}
    if (finishinfo.get("fit") or {}).get("clipped_pixels"):
        uncut, _ = finish(native, replace(opts, fit=False), contract, pal)
        files["uncut_png"] = str(out / f"{name}_uncut.png")
        uncut.save(files["uncut_png"])
    if aseprite:
        from . import aseprite as ase
        pivot = (finishinfo.get("fit") or {}).get("pivot")
        files["aseprite"] = str(ase.from_frames(out / f"{name}.aseprite", [final],
                                                palette=pal.colors if pal and len(pal) <= 256 else None,
                                                pivot=tuple(pivot) if pivot else None))
    summary = verdicts.summary(verdicts.for_review(verdict["ok"], None, coherence=verdict["coherence"]))
    result = {"name": name, "contract": contract.as_dict(), "snap": snapinfo, "finish": finishinfo,
              "lint": verdict, "files": files, "verdicts": summary,
              "signals": sig, "delivery": lineage.delivery(verdict["ok"], lin), "lineage": lin,
              "provenance": provenance.record(source, generator, prompt, opts.__dict__,
                                              image.info.get("forja_source"), lin)}
    impure = [_to_final([x, y, x + 1, y + 1], finishinfo)[:2] for x, y in sub.pop("_coords")]
    if report_html:
        from . import report
        files["report"] = str(report.single(out / "report.html", image, g, final, result, impure))
    (out / f"{name}.json").write_text(json.dumps(result, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    files["json"] = str(out / f"{name}.json")
    return result
