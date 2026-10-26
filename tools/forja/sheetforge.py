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
from statistics import median

from PIL import Image

from . import anim, color, contracts, godot, guard, lint, matte, motion, provenance, quantize, review, sheet
from . import temporal
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
    if sopts.region:
        image = image.crop(sopts.region)
    bg = _bg(image, opts.bg)
    if sopts.layout:
        cells, stray, masks = sheet.find_cells(image, bg, sopts.layout)
        rects = [r for r, b in zip(sheet.cell_rects(image.size, sopts.layout), cells) if b]
        boxes = [b for b in cells if b]
    else:
        boxes, stray, masks = sheet.find_masks(image, bg)
        rects = None
    expected = sum(n for _, n in sopts.tags) if sopts.tags else None
    figures = sheet.extract(image, boxes, bg, scale=opts.scale, same_height=sopts.same_height, masks=masks)
    contract = contract_for(opts)
    pal = palette_for(opts, contract)
    natives = [f.native for f in figures]
    if pal is None and opts.colors:
        pal = quantize.shared_palette(natives, opts.colors)
    details = []
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
        canvas, pivot = _common_canvas(figures, anchor, align if rects else "feet")
    pivot = pivot or (canvas[0] // 2, canvas[1] - 1)
    frames, placed = sheet.frames(figures, canvas, pivot, anchor, align)
    fixes = {}
    if sopts.deflicker:
        frames, flicker = temporal.stabilize(frames, sopts.deflicker, sopts.static, sopts.actions)
        fixes["deflicker"] = {"changed": len(flicker["changed"]), "counts": flicker["counts"],
                              "static": flicker["static"], "actions": flicker["actions"], "note": flicker["note"]}
    if sopts.lock:
        frames, fixes["lock"] = motion.lock(frames, sopts.lock)
    tags, durations = _timeline(sopts.tags, len(frames))
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
    for verdict, info in zip(verdicts, details):
        for item in guard.findings(info):
            lint.add(verdict, item)
    for verdict, place_info, fig in zip(verdicts, placed, figures):
        if place_info["clipped_pixels"]:
            fits = fig.native.width <= canvas[0] and fig.native.height <= canvas[1]
            lint.add(verdict, lint.too_big(contract, place_info["clipped_pixels"], fig.native.size) if not fits else
                     lint.finding("placement", "error", f"{place_info['clipped_pixels']} pixels fora da tela pelo "
                                  "lugar da figura na celula", fix="gerar de novo, ou --align contact/feet",
                                  hint="Keep every pose inside its cell, on the same ground line as the others."))
    metrics = anim.metrics(frames, pivot)
    found = len(frames)
    summary = f"{found} quadros achados" + (f" de {expected} pedidos" if expected else "")
    clipped = sum(p["clipped_pixels"] for p in placed)
    contract_valid = (expected in (None, found)) and all(v["ok"] for v in verdicts) and not clipped
    loops = {t: (contracts.tag(t) or {}).get("loop", True) for t, *_ in tags}
    moved = review.motion(frames, tags, sopts.holds, align, loops)
    rv = review.verdict(contract_valid, moved, [v["coherence"] for v in verdicts])
    metrics["alignment"] = {"mode": align, "offsets_preserved": align != "feet",
                            "drift_imposed_by_alignment": align == "feet"}
    result = {"name": name, "ok": not rv["needs_regeneration"], "review": rv,
              "summary": summary, "requested": expected, "found": found, "stray_blobs": [list(b) for b in stray],
              "region": list(sopts.region) if sopts.region else None,
              "contract": contract.as_dict(), "tags": [list(t) for t in tags], "durations": durations,
              "holds": sopts.holds or [], "pivot": list(pivot), "canvas": list(canvas), "frames": [
                  {**p, "finish": d, "lint_errors": v["errors"], "lint_warnings": v["warnings"]}
                  for p, d, v in zip(placed, details, verdicts)],
              "metrics": metrics, "fixes": fixes, "files": files,
              "prompt_feedback": " ".join(dict.fromkeys(f["prompt_hint"] for v in verdicts for f in v["findings"]
                                                        if f["prompt_hint"])),
              "provenance": provenance.record(source, generator, prompt, {**opts.__dict__, **sopts.__dict__})}
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


def _origins(figures: list, rects: list, details: list[dict], cluster: int) -> None:
    """A posicao de cada figura dentro da sua celula, em pixels finais (para manter saltos e passadas)."""
    for f, cell, info in zip(figures, rects, details):
        px, py = f.periods if f.periods[0] > 0 else (1.0, 1.0)
        ox = round((f.origin_raw[0] - cell[0]) / px) * cluster + info.get("shift", [0, 0])[0]
        oy = round((f.origin_raw[1] - cell[1]) / py) * cluster + info.get("shift", [0, 0])[1]
        f.origin = (ox, oy)


def _common_canvas(figures: list, anchor: str, align: str, margin: int = 2) -> tuple[tuple[int, int],
                                                                                  tuple[int, int]]:
    """Sem tela no contrato: a menor tela onde todas cabem, alinhadas como vao ficar."""
    images = [f.native for f in figures]
    points = [sheet.anchor_point(i, anchor) for i in images]
    if align == "feet":
        tops = [(-p[0], -p[1]) for p in points]
        ref = (0, 0)
    else:
        feet = [(f.origin[0] + p[0], f.origin[1] + p[1]) for f, p in zip(figures, points)]
        tops = [f.origin for f in figures]
        ref = (round(median(x for x, _ in feet)), max(y for _, y in feet))
    x0 = min(t[0] for t in tops)
    y0 = min(t[1] for t in tops)
    x1 = max(t[0] + i.width for t, i in zip(tops, images))
    y1 = max(t[1] + i.height for t, i in zip(tops, images))
    x1, y1 = max(x1, ref[0] + 1), max(y1, ref[1] + 1)
    return (x1 - x0 + 2 * margin, y1 - y0 + 2 * margin), (ref[0] - x0 + margin, ref[1] - y0 + margin)


def _timeline(tags: list[tuple[str, int]] | None, count: int) -> tuple[list[tuple[str, int, int, str]], list[int]]:
    if not tags:
        return [("anim", 0, count - 1, "forward")], [1000 // contracts.load_data()["fps"]] * count
    out, durations, start = [], [], 0
    for name, n in tags:
        if start >= count:
            break
        last = min(count, start + n) - 1
        info = contracts.tag(name) or {}
        out.append((name, start, last, "forward"))
        durations += [round(1000 / info.get("fps", 10))] * (last - start + 1)
        start = last + 1
    durations += [durations[-1] if durations else 100] * (count - len(durations))
    return out, durations

