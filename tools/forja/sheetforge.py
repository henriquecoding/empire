"""A forja de uma prancha: figuras -> quadros nativos alinhados -> animacao exportada.

Conta as figuras reais contra as pedidas e nunca inventa um quadro; usa uma
escala e uma paleta comuns a todos os quadros; alinha pelo apoio; mede a
cintilacao e a deriva do pivot; escreve tira + JSON do Aseprite + .aseprite +
GIF/APNG (+ SpriteFrames do Godot, se pedido) e um relatorio com leitor.
"""
from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path

from PIL import Image

from . import anim, color, contracts, godot, lint, matte, motion, provenance, quantize, sheet
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
    lock: tuple[int, int, int, int] | None = None
    mirror: bool = False
    godot_texture: str | None = None


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
    bg = _bg(image, opts.bg)
    if sopts.layout:
        cells, stray, masks = sheet.find_cells(image, bg, sopts.layout)
        boxes = [b for b in cells if b]
    else:
        boxes, stray, masks = sheet.find_masks(image, bg)
    expected = sum(n for _, n in sopts.tags) if sopts.tags else None
    figures = sheet.extract(image, boxes, bg, scale=opts.scale, same_height=sopts.same_height, masks=masks)
    contract = contract_for(opts)
    pal = palette_for(opts, contract)
    natives = [f.native for f in figures]
    if pal is None and opts.colors:
        pal = quantize.shared_palette(natives, opts.colors)
    frames, details = [], []
    for fig in figures:
        done, info = finish(fig.native, Options(**{**opts.__dict__, "fit": False}), contract, pal)
        fig.native = done
        details.append(info)
    anchor = sopts.anchor if sopts.anchor in sheet.ANCHORS else "feet"
    canvas, pivot = contract.canvas, contract.pivot
    if not canvas:
        canvas, pivot = _common_canvas([f.native for f in figures], anchor)
    pivot = pivot or (canvas[0] // 2, canvas[1] - 1)
    frames, placed = sheet.frames(figures, canvas, pivot, anchor)
    fixes = {}
    if sopts.deflicker:
        frames, fixes["deflicker_pixels"] = quantize.deflicker(frames, sopts.deflicker)
    if sopts.lock:
        frames, fixes["lock"] = motion.lock(frames, sopts.lock)
    tags, durations = _timeline(sopts.tags, len(frames))
    files = anim.export(frames, out, name, durations, tags, pivot)
    files["aseprite"] = str(ase.from_frames(out / f"{name}.aseprite", frames, durations=durations, tags=tags,
                                            palette=pal.colors if pal and len(pal) <= 256 else None, pivot=pivot))
    if sopts.mirror:
        left, left_pivot = anim.mirror(frames, pivot)
        files.update({f"left_{k}": v for k, v in anim.export(left, out, f"{name}_left", durations,
                                                               tags, left_pivot, previews=False).items()})
    if sopts.godot_texture:
        _, rects = anim.strip(frames)
        loops = {t: (contracts.tag(t) or {}).get("loop", True) for t, *_ in tags}
        files["godot"] = str(godot.write(out / f"{name}.tres", godot.sprite_frames(
            sopts.godot_texture, rects, durations, tags, 1000 / durations[0], loops)))
    verdicts = [lint.check(f, contract, pal) for f in frames]
    for verdict, place_info, fig in zip(verdicts, placed, figures):
        if place_info["clipped_pixels"]:
            lint.add(verdict, lint.too_big(contract, place_info["clipped_pixels"], fig.native.size))
    metrics = anim.metrics(frames, pivot)
    found = len(frames)
    summary = f"{found} quadros achados" + (f" de {expected} pedidos" if expected else "")
    result = {"name": name, "ok": (expected in (None, found)) and all(v["ok"] for v in verdicts),
              "summary": summary, "requested": expected, "found": found, "stray_blobs": [list(b) for b in stray],
              "contract": contract.as_dict(), "tags": [list(t) for t in tags], "durations": durations,
              "pivot": list(pivot), "canvas": list(canvas), "frames": [
                  {**p, "finish": d, "lint_errors": v["errors"], "lint_warnings": v["warnings"]}
                  for p, d, v in zip(placed, details, verdicts)],
              "metrics": metrics, "fixes": fixes, "files": files,
              "prompt_feedback": " ".join(dict.fromkeys(f["prompt_hint"] for v in verdicts for f in v["findings"]
                                                        if f["prompt_hint"])),
              "provenance": provenance.record(source, generator, prompt, {**opts.__dict__, **sopts.__dict__})}
    if expected and expected != found:
        result["prompt_feedback"] = (f"Draw exactly {expected} separate poses with clear empty space between them. "
                                     + result["prompt_feedback"]).strip()
    from . import report
    files["report"] = str(report.animation(out / "report.html", frames, durations, result))
    (out / f"{name}.forja.json").write_text(json.dumps(result, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    files["forja_json"] = str(out / f"{name}.forja.json")
    return result


def _common_canvas(images: list[Image.Image], anchor: str, margin: int = 2) -> tuple[tuple[int, int], tuple[int, int]]:
    """Sem tela no contrato: a menor tela onde todas cabem com o apoio no mesmo pivot."""
    points = [sheet.anchor_point(i, anchor) for i in images]
    left = max(p[0] for p in points)
    right = max(i.width - p[0] for i, p in zip(images, points))
    up = max(p[1] for p in points)
    down = max(i.height - 1 - p[1] for i, p in zip(images, points))
    return (margin + left + right + margin, margin + up + down + 1 + margin), (margin + left, margin + up)


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

