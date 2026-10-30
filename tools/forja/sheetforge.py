"""A forja de uma prancha: figuras -> quadros nativos na tela -> animacao exportada.

Conta as figuras reais contra as pedidas e nunca inventa um quadro; usa uma
escala e uma paleta comuns a todos os quadros; com a grelha pedida, mantem cada
figura onde estava na sua celula e so leva o chao comum ao pivot (um salto fica
no ar); separa a validade do contrato, os indicios de movimento e a aprovacao do
autor (`review.py`); escreve tira + JSON do Aseprite + .aseprite + GIF/APNG
(+ SpriteFrames do Godot, se pedido) e um relatorio com leitor.
"""
from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path

from PIL import Image

from . import anim, cells, color, contracts, godot, guard, limits, lint, matte, placement, provenance
from . import quantize, review, sheet, sheet_audit, timeline
from . import aseprite as ase
from .imageops import open_rgba
from .pipeline import Options, contract_for, finish, palette_for


@dataclass
class SheetOptions:
    tags: list[tuple[str, int]] | None = None
    layout: tuple[int, int] | None = None
    anchor: str = "feet"
    same_height: bool = False
    deflicker: float = 0.0
    static: list[tuple[int, int, int, int]] | None = None
    actions: list[tuple[int, int, int, int]] | None = None
    lock: tuple[int, int, int, int] | None = None
    mirror: bool = False
    godot_texture: str | None = None
    region: tuple[int, int, int, int] | None = None
    align: str = "auto"
    holds: list[dict] | None = None


def parse_tags(text: str | None, default: str = "anim") -> list[tuple[str, int]] | None:
    """'idle,walk' usa as contagens da Animation Bible; 'idle:4' fixa uma contagem."""
    if not text:
        return None
    out = []
    for part in text.split(","):
        name, _, count = part.strip().partition(":")
        frames = int(count) if count else (contracts.tag(name) or {}).get("frames")
        if not frames:
            raise ValueError(f"tag sem contagem conhecida: {name} (use {name}:N)")
        out.append((name or default, frames))
    timeline.declarations(out)
    return out


def _bg(image: Image.Image, given: str | None) -> tuple[int, int, int] | None:
    if given:
        return color.parse_hex(given)
    thumb = image.resize((max(1, image.width // 8), max(1, image.height // 8)), Image.Resampling.NEAREST)
    info = matte.detect(thumb)
    return color.parse_hex(info["color"]) if info.get("color") else None


def forge_sheet(source: str | Path, out_dir: str | Path, opts: Options, sopts: SheetOptions,
                name: str | None = None, prompt: str | None = None, generator: str | None = None) -> dict:
    source = Path(source)
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    name = name or source.stem
    image = open_rgba(source)
    seen = image.info.get("forja_source")
    source_image = image
    scale = sheet_audit.validate(opts, sopts, image.size)
    if opts.lineage and opts.lineage.get("output_sha256") != sheet_audit.image_sha(source_image):
        raise ValueError("a cadeia nao liga: esta prancha nao e a saida da etapa anterior")
    if sopts.region:
        image = image.crop(sopts.region)
    bg = _bg(image, opts.bg)
    crossing = {}
    if sopts.layout:
        found_cells, masks, crossed = cells.split(image, bg, sopts.layout)
        rects = [r for r, b in zip(cells.cell_rects(image.size, sopts.layout), found_cells) if b]
        boxes, stray, crossing = [b for b in found_cells if b], [], cells.by_frame(found_cells, crossed)
    else:
        boxes, stray, masks = sheet.find_masks(image, bg)
        rects = None
    expected = sum(n for _, n in sopts.tags) if sopts.tags else None
    figures = sheet.extract(image, boxes, bg, scale=scale, same_height=sopts.same_height, masks=masks,
                            exact=bool(sopts.layout), reduce=opts.reduce, method=opts.method, audit=True)
    contract = contract_for(opts)
    if not figures:
        return _empty(out, name, contract, expected, stray, provenance.record(
            source, generator, prompt, {**opts.__dict__, **sopts.__dict__}))
    pal = palette_for(opts, contract)
    natives = [f.native for f in figures]
    if pal is None and opts.colors:
        pal = quantize.shared_palette(natives, opts.colors)
    details, sources = [], [f.native for f in figures]
    for fig in figures:
        done, info = finish(fig.native, Options(**{**opts.__dict__, "fit": False}), contract, pal)
        fig.native = done
        details.append(info)
    if rects:
        _origins(figures, rects, details, contract.cluster)
    align = sopts.align if sopts.align != "auto" else ("preserve" if rects else "feet")
    anchor = sopts.anchor if sopts.anchor in sheet.ANCHORS else "feet"
    canvas, pivot = contract.canvas, contract.pivot
    if not canvas:
        canvas, pivot = placement.common_canvas(figures, anchor, align if rects else "feet")
    pivot = pivot or (canvas[0] // 2, canvas[1] - 1)
    frames, placed = sheet.frames(figures, canvas, pivot, anchor, align)
    tags, durations = _timeline(sopts.tags, len(frames))
    timeline.holds(sopts.holds, len(frames))
    guarded = [guard.pixels(opts.protect, s.size) for s in sources]
    keep = frozenset().union(*[guard.frame_pixels(g, guard.placed(d, p["offset"]))
                               for g, d, p in zip(guarded, details, placed)])
    frames, fixes = sheet_audit.correct(frames, tags, sopts, keep)
    for frame, src, g, info, place_info in zip(frames, sources, guarded, details, placed):
        if g:
            info["protect"].update(guard.verify(frame, src, g, guard.placed(info, place_info["offset"])))
    for h in sopts.holds or []:
        if h.get("ms") and 0 <= h["frame"] < len(durations):
            durations[h["frame"]] = h["ms"]
    files = anim.export(frames, out, name, durations, tags, pivot)
    files["aseprite"] = str(ase.from_frames(out / f"{name}.aseprite", frames, durations=durations, tags=tags,
                                            palette=pal.colors if pal and len(pal) <= 256 else None, pivot=pivot))
    if sopts.mirror:
        left, left_pivot = anim.mirror(frames, pivot)
        files.update({f"left_{k}": v for k, v in anim.export(left, out, f"{name}_left", durations,
                                                               tags, left_pivot, previews=False).items()})
    if sopts.godot_texture:
        _, rects_out = anim.strip(frames)
        loops = {t: (contracts.tag(t) or {}).get("loop", True) for t, *_ in tags}
        files["godot"] = str(godot.write(out / f"{name}.tres", godot.sprite_frames(
            sopts.godot_texture, rects_out, durations, tags, 1000 / durations[0], loops)))
    verdicts = [lint.check(f, contract, pal) for f in frames]
    for i, (verdict, info) in enumerate(zip(verdicts, details)):
        snap = figures[i].snap
        transform = guard.placed(info, placed[i]["offset"])
        for item in limits.grid_origin(snap["grid_report"]) + limits.losses(
                snap, lambda b, t=transform: [*guard.final_xy(b[:2], t), *guard.final_xy(b[2:], t)]):
            lint.add(verdict, item)
        for item in guard.findings(info) + ([cells.finding(crossing[i])] if i in crossing else []):
            lint.add(verdict, item)
        for item in limits.useful_budget(frames[i], opts.useful_box) if opts.useful_box else []:
            lint.add(verdict, item)
        if i in crossing:
            placed[i]["cell_crossing"] = crossing[i]
    for verdict, place_info, fig in zip(verdicts, placed, figures):
        if not place_info["clipped_pixels"]:
            continue
        if fig.native.width > canvas[0] or fig.native.height > canvas[1]:
            limits.clipped(verdict, limits.too_big(contract, place_info["clipped_pixels"], fig.native.size))
        else:
            lint.add(verdict, lint.finding("placement", "error", f"{place_info['clipped_pixels']} pixels fora da tela "
                                           "pelo lugar da figura na celula", fix="gerar de novo, ou --align contact/feet",
                                           hint="Keep every pose inside its cell, on the same ground line as the "
                                                "others."))
    metrics = sheet_audit.metrics(frames, pivot, tags)
    found = len(frames)
    summary = f"{found} quadros achados" + (f" de {expected} pedidos" if expected else "")
    clipped = sum(p["clipped_pixels"] for p in placed)
    contract_valid = (expected in (None, found)) and all(v["ok"] for v in verdicts) and not clipped
    loops = {t: (contracts.tag(t) or {}).get("loop", True) for t, *_ in tags}
    moved = review.motion(frames, tags, sopts.holds, align, loops)
    rv = review.verdict(contract_valid, moved, [v["coherence"] for v in verdicts])
    metrics["alignment"] = {"mode": align, "offsets_preserved": align != "feet",
                            "drift_imposed_by_alignment": align == "feet"}
    chain = sheet_audit.chain(source_image, frames, figures, details, placed, opts, sopts.region)
    result = {"name": name, "ok": not rv["needs_regeneration"], "review": rv,
              "lineage": chain, "delivery": sheet_audit.delivery(contract_valid, chain),
              "summary": summary, "requested": expected, "found": found, "stray_blobs": [list(b) for b in stray],
              "region": list(sopts.region) if sopts.region else None,
              "contract": contract.as_dict(), "tags": [list(t) for t in tags], "durations": durations,
              "holds": sopts.holds or [], "pivot": list(pivot), "canvas": list(canvas), "frames": [
                  {**p, "finish": d, "snap": f.snap, "lint_errors": v["errors"], "lint_warnings": v["warnings"]}
                  for p, d, v, f in zip(placed, details, verdicts, figures)],
              "metrics": metrics, "fixes": fixes, "files": files,
              "prompt_feedback": " ".join(dict.fromkeys(f["prompt_hint"] for v in verdicts for f in v["findings"]
                                                        if f["prompt_hint"])),
              "provenance": provenance.record(source, generator, prompt, {**opts.__dict__, **sopts.__dict__},
                                              seen)}
    if moved["blocking"]:
        result["prompt_feedback"] = ("Every frame must show a different pose of the action (no copies). "
                                     + result["prompt_feedback"]).strip()
    if expected and expected != found:
        result["prompt_feedback"] = (f"Draw exactly {expected} separate poses with clear empty space between them. "
                                     + result["prompt_feedback"]).strip()
    from . import report
    files["report"] = str(report.animation(out / "report.html", frames, durations, result))
    (out / f"{name}.forja.json").write_text(json.dumps(result, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    files["forja_json"] = str(out / f"{name}.forja.json")
    return result


def _empty(out: Path, name: str, contract, expected: int | None, stray: list, record: dict) -> dict:
    """Nenhuma figura na imagem (A02): nada a exportar, e o gerador tem de desenhar outra vez."""
    rv = {**review.verdict(False, None), "review_reasons": ["nenhuma figura na imagem"]}
    poses = f"exactly {expected} separate poses" if expected else "the requested poses"
    result = {"name": name, "ok": False, "review": rv, "summary": "0 quadros achados"
              + (f" de {expected} pedidos" if expected else ""), "requested": expected, "found": 0,
              "stray_blobs": [list(b) for b in stray], "contract": contract.as_dict(), "tags": [], "durations": [],
              "holds": [], "pivot": list(contract.pivot) if contract.pivot else None,
              "canvas": list(contract.canvas) if contract.canvas else None, "frames": [], "metrics": {"frames": 0},
              "fixes": {}, "files": {}, "provenance": record,
              "prompt_feedback": f"The image came back with no figure at all: draw {poses} of the subject, one per "
                                 "cell, on the flat background."}
    (out / f"{name}.forja.json").write_text(json.dumps(result, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    result["files"]["forja_json"] = str(out / f"{name}.forja.json")
    return result


def _origins(figures: list, rects: list, details: list[dict], cluster: int) -> None:
    """A posicao de cada figura dentro da sua celula, em pixels finais (para manter saltos e passadas)."""
    for f, cell, info in zip(figures, rects, details):
        px, py = f.periods if f.periods[0] > 0 else (1.0, 1.0)
        ox = round((f.origin_raw[0] - cell[0]) / px) * cluster + info.get("shift", [0, 0])[0]
        oy = round((f.origin_raw[1] - cell[1]) / py) * cluster + info.get("shift", [0, 0])[1]
        f.origin = (ox, oy)


def _timeline(tags: list[tuple[str, int]] | None, count: int, strict: bool = False):
    return timeline.build(tags, count, strict)

