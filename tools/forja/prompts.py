"""O compilador de prompts: do contrato do Empire a um pedido que o gerador cumpre.

Sai um prompt em ingles (os geradores seguem-no melhor), o tamanho de imagem e a
grelha que tornam a grade conhecida (cada pixel logico = k x k pixels), a cor de
chave mais longe da paleta, os parametros equivalentes do PixelLab e um bloco
`expect` que o `forja forge --expect` le para recortar sem adivinhar.

O estilo segue os prompts V15 do projeto (evidencias/v15/prompts.json): caso de
uso, identidade, camera fixa, linha de chao comum, pixels grossos, paleta curta,
contorno, luz de cima a esquerda, nada de gradiente, texto ou molduras.
"""
from __future__ import annotations

import math

from . import contracts, matte
from .palette import Palette

TARGETS = ("gpt-image", "gemini", "pixellab", "generic")


def layout_for(frames: int) -> tuple[int, int]:
    """Colunas x linhas com poucas celulas vazias e perto de 3:2 (a forma que os geradores preferem)."""
    return min(((c, -(-frames // c)) for c in range(1, frames + 1)),
               key=lambda cr: cr[0] * cr[1] - frames + 3 * abs(math.log(cr[0] / cr[1] / 1.5)))


def pick_scale(width: int, height: int, target: str) -> int:
    """O maior k (pixels por pixel logico) que o gerador aceita.

    gpt-image 2.x: lados multiplos de 16, 655360 a 8294400 pixels, e acima de
    2560x1440 e experimental — fica-se abaixo. Os outros: ate 2048 por lado.
    """
    if target == "pixellab":
        return 1
    for k in range(256, 1, -1):
        w, h = width * k, height * k
        if target == "gpt-image":
            if w % 16 or h % 16 or max(w, h) > 2560 or w * h > 2560 * 1440 or w * h < 655360:
                continue
            if max(w / h, h / w) > 3:
                continue
        elif max(w, h) > 2048:
            continue
        return k
    return 2


def _outline(c: contracts.Contract) -> str:
    if c.outline_px is None:
        return "outline only where it helps readability"
    if c.outline_px == 0:
        return "NO outline at all; shapes are separated by value only"
    return f"a {max(1, c.outline_px // c.cluster)}-logical-pixel pure black (#000000) outline around the whole silhouette and on key internal details"


def _colors(pal: Palette | None, c: contracts.Contract, listed: int) -> str:
    if c.max_colors:
        limit = f"at most {c.max_colors} colors in total"
    else:
        limit = "a short palette (about 12-24 colors)"
    if pal is None or not len(pal):
        return f"flat colors only, {limit}"
    if len(pal) <= listed:
        return f"use ONLY these colors: {', '.join(pal.hexes())}; {limit}"
    return f"use ONLY colors from the attached palette swatch ({len(pal)} colors); {limit}"


def build(subject: str, kind: str = "character_s2", tags: list[tuple[str, int]] | None = None,
          facing: str = "right", reference: bool = False, palette: Palette | None = None,
          target: str = "gpt-image", background: str = "auto", listed: int = 24,
          cells: tuple[int, int] | None = None) -> dict:
    if target not in TARGETS:
        raise ValueError(f"alvo desconhecido: {target}")
    c = contracts.get(kind)
    canvas = cells or (tuple(v // c.cluster for v in c.canvas) if c.canvas else (64, 64))
    frames = sum(n for _, n in tags) if tags else 1
    cols, rows = layout_for(frames)
    k = pick_scale(canvas[0] * cols, canvas[1] * rows, target)
    size = (canvas[0] * cols * k, canvas[1] * rows * k)
    content_box = None
    if target == "gemini":
        x, y = (2048 - size[0]) // 2, (2048 - size[1]) // 2
        content_box = [x, y, x + size[0], y + size[1]]
    key = matte.best_key(palette.colors if palette else [])
    transparent = background == "transparent" or (background == "auto" and target in ("gpt-image", "pixellab"))
    pivot = c.pivot
    base = (canvas[1] - 1 - pivot[1] // c.cluster) if pivot else 2
    lines = [
        'Create a pixel-art game asset for "Empire", a 2D side-view kingdom builder.',
        f"Subject: {subject}.",
        f"Asset type: {c.en}.",
        f"Pixel grid: the image is an exact grid of {canvas[0] * cols}x{canvas[1] * rows} logical pixels; "
        f"every logical pixel is ONE crisp solid {k}x{k} square block aligned to the image edges. "
        "No sub-pixel detail, no anti-aliasing, no blur, no gradients, no soft brushes, no texture noise.",
        f"Camera: strict side view (profile), facing {facing.upper()}, like a 2D platformer sprite.",
        f"Outline: {_outline(c)}.",
        "Shading: two tones per material (light and shadow), light from the top-left, big readable flat clusters"
        + ("" if c.dither else ", no dithering") + ".",
        f"Colors: {_colors(palette, c, listed)}.",
    ]
    if c.useful_height and c.useful_height[0] > 1:
        lines.append(f"Scale: the figure is {c.useful_height[0] // c.cluster}-{c.useful_height[1] // c.cluster} logical pixels tall, "
                     f"feet resting on a ground baseline {base} logical pixels above the bottom edge of its cell, "
                     "centered horizontally.")
    if transparent:
        lines.append("Background: fully transparent; no backdrop, no scenery, no floor, no checkerboard.")
    else:
        lines.append(f"Background: one perfectly flat solid {key} color (chroma key) everywhere around the figure; "
                     f"never use {key} inside the figure; no shadow, floor, gradient or vignette.")
    if frames > 1:
        lines.append(f"Layout: a {cols}x{rows} sprite sheet of equal {canvas[0]}x{canvas[1]}-logical-pixel cells, "
                     "read left-to-right then top-to-bottom; one pose per cell; the SAME character, scale, palette and "
                     "baseline in every cell; generous empty space between figures; no text, labels, numbers, "
                     "borders, frame lines or grid lines.")
        lines += _timeline(tags or [])
    if reference:
        lines.append("Identity: the attached image is the APPROVED design. Preserve proportions, head, face, clothing, "
                     "materials and colors exactly; change only the pose.")
    if content_box:
        lines.append(f"Output canvas: 2048x2048 pixels. Put the entire pixel grid ONLY inside the exact "
                     f"rectangle {content_box} (left, top, right, bottom). All margins must be blank background; "
                     "do not stretch the grid to fill the canvas. Follow the attached layout guide.")
    if cols * rows > frames:
        lines.append(f"Leave cells {frames + 1}-{cols * rows} empty, with background only.")
    lines.append("Avoid: photorealism, 3D render, painterly or vector style, glow, lens effects, drop shadows, "
                 "extra characters, watermarks, signatures, UI.")
    expect = {"kind": kind, "cells": [canvas[0] * cols, canvas[1] * rows], "scale": k, "layout": [cols, rows],
              "frames": frames, "tags": [list(t) for t in tags] if tags else None,
              "background": "transparent" if transparent else key, "size": list(size), "cluster": c.cluster}
    if content_box:
        expect.update(content_box=content_box, generator_size=[2048, 2048])
    advice = None
    if k < 8 and target != "pixellab":
        advice = (f"cada pixel logico tera so {k} px na imagem: o gerador perde precisao. Peca menos quadros por "
                  "prancha (ex.: --tags walk:4 duas vezes) ou uma figura por imagem.")
    return {"prompt": "\n".join(lines), "size": "2048x2048" if content_box else f"{size[0]}x{size[1]}",
            "expect": expect, "advice": advice,
            "pixellab": pixellab_params(subject, c, canvas, facing), "target": target}


def _timeline(tags: list[tuple[str, int]]) -> list[str]:
    out, start = [], 1
    for name, n in tags:
        note = (contracts.tag(name) or {}).get("note", "")
        out.append(f"Cells {start}-{start + n - 1}: '{name}' animation, {n} frames, in place"
                   + (f" ({note})" if note else "") + ".")
        start += n
    return out


def pixellab_params(subject: str, c: contracts.Contract, canvas: tuple[int, int], facing: str) -> dict:
    """O mesmo pedido nos termos da API do PixelLab (create-image-pixflux)."""
    outline = {None: None, 0: "lineless"}.get(c.outline_px, "single color black outline")
    return {"description": subject, "image_size": {"width": canvas[0], "height": canvas[1]},
            "outline": outline, "shading": "basic shading", "detail": "medium detail", "view": "side",
            "direction": "east" if facing == "right" else "west", "no_background": True}


def corrective(original: str, feedback: str) -> str:
    """O prompt seguinte: o original mais as correcoes que o lint pediu."""
    if not feedback:
        return original
    return original + "\nCorrections from the previous attempt (follow strictly): " + feedback


def edit_prompt(change: str, keep: str = "everything outside the masked area") -> str:
    return (f"Edit this pixel-art sprite: {change}. Keep {keep} exactly the same, preserving the pixel grid, "
            "palette, outline and lighting. Same crisp square pixels, no anti-aliasing, no new colors.")


def texture_prompt(material: str, size: int, k: int) -> str:
    return (f"A seamless tileable pixel-art texture of {material} for a 2D side-view game, {size}x{size} logical "
            f"pixels, each logical pixel a crisp {k}x{k} block. Two or three tones, flat clusters of at least 2x2 "
            "pixels, no outline, no lighting gradient, no border; the left edge must continue into the right edge "
            "and the top into the bottom.")
