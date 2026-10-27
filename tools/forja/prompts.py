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
import re

from . import constraints, contracts, matte
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


ROLES = {
    "identity": "the APPROVED design of this character: preserve proportions, head, face, clothing, materials "
                "and colors exactly; change only the pose",
    "identity_review": "an adaptation of this character that is still IN REVIEW and NOT approved: use it for scale "
                       "and placement on the grid only; where it differs from the concept art, follow the concept",
    "identity_unrecorded": "a reference design of this character whose approval is NOT recorded: keep its "
                           "proportions, head, face, clothing, materials and colors, as a reference, not a master",
    "concept": "the authority CONCEPT ART of this character (not on the pixel grid): match its face (eyes, brows, "
               "nose, mouth, facial hair), proportions, materials and equipment, redrawn on the logical grid; do "
               "not copy its brushwork, gradients or resolution",
    "style": "a style reference: copy its pixel-art language (outline, shading, cluster size), not its subject",
    "palette": "the palette swatch (big squares, no text)",
    "layout": "the layout template at the exact output proportions: one figure per cell, feet on the faint "
              "baseline, centered on the dotted axis; do NOT copy its lines",
}


VIEWS = (("tres quartos", r"three[- ]quarters?|\b3/4\b|tr[eê]s quartos"),
         ("de frente", r"front(al)?[- ]view|\bfrontal\b|facing (the )?(viewer|camera)|de frente"),
         ("de costas", r"back[- ]view|rear[- ]view|from behind|de costas"),
         ("de cima", r"top[- ]down|bird'?s[- ]eye|vista de cima|isometric|isom[eé]tric"))
OPPOSITE = {"right": r"facing left|looking left|virad[oa] para a esquerda|olhando para a esquerda",
            "left": r"facing right|looking right|virad[oa] para a direita|olhando para a direita"}


def camera_conflicts(text: str, facing: str) -> list[str]:
    """O que um texto (o assunto, ou o prompt expandido por um gerador) contradiz na camara do Empire:
    perfil estrito, virado para `facing`. A camara resolve-se num campo so, antes de escrever o prompt."""
    low = text.lower()
    out = [f"pede vista {name}, mas a camara e de perfil estrito" for name, rx in VIEWS if re.search(rx, low)]
    if re.search(OPPOSITE[facing], low):
        out.append(f"vira a figura ao contrario de --facing {facing}")
    return out


def default_attached(reference: bool | str, palette: Palette | None, listed: int = 24) -> list[str]:
    """O que o `forja prompt` manda anexar: a referencia, no papel do seu estado (FORJA-06: sem registo nao e
    'APPROVED'), e, se a paleta nao cabe no texto, a amostra."""
    role = reference if isinstance(reference, str) else "identity_unrecorded"
    return ([role] if reference else []) + (["palette"] if palette is not None and len(palette) > listed else [])


def geometry(kind: str, tags: list[tuple[str, int]] | None, target: str,
             cells: tuple[int, int] | None = None) -> dict:
    """Grelha logica, escala e tamanho de imagem para um gerador de lados livres (gpt-image) ou generico."""
    c = contracts.get(kind)
    canvas = cells or (tuple(v // c.cluster for v in c.canvas) if c.canvas else (64, 64))
    frames = sum(n for _, n in tags) if tags else 1
    cols, rows = layout_for(frames)
    logical = (canvas[0] * cols, canvas[1] * rows)
    k = pick_scale(logical[0], logical[1], target)
    return {"canvas": list(canvas), "layout": [cols, rows], "frames": frames, "logical": list(logical),
            "content": [0, 0, logical[0], logical[1]], "scale": k, "size": [logical[0] * k, logical[1] * k],
            "exact": target == "gpt-image"}


def build(subject: str, kind: str = "character_s2", tags: list[tuple[str, int]] | None = None,
          facing: str = "right", reference: bool | str = False, palette: Palette | None = None,
          target: str = "gpt-image", background: str = "auto", listed: int = 24,
          cells: tuple[int, int] | None = None, attached: list[str] | None = None,
          geo: dict | None = None, mode: str = "stylized", fidelity: dict | None = None) -> dict:
    """O prompt e o `expect`. `attached` sao os papeis das imagens que VAO anexadas, por ordem:
    o texto so promete essas. `geo` (do plano por backend) substitui a geometria calculada aqui. `mode` e
    `fidelity` ({invariants, where, max_colors, tones}) decidem as restricoes e a origem de cada uma (FORJA-07)."""
    if target not in TARGETS:
        raise ValueError(f"alvo desconhecido: {target}")
    c = contracts.get(kind)
    geo = geo or geometry(kind, tags, target, cells)
    attached = default_attached(reference, palette, listed) if attached is None else attached
    unknown = [r for r in attached if r not in ROLES]
    if unknown:
        raise ValueError(f"papel de imagem desconhecido: {unknown}")
    number = {r: attached.index(r) + 1 for r in attached}
    canvas, (cols, rows), frames, k = geo["canvas"], geo["layout"], geo["frames"], geo["scale"]
    (lw, lh), (x0, y0, x1, y1) = geo["logical"], geo["content"]
    key = matte.best_key(palette.colors if palette else [])
    transparent = background == "transparent" or (background == "auto" and target == "gpt-image")
    pivot = c.pivot
    base = (canvas[1] - 1 - pivot[1] // c.cluster) if pivot else 2
    block = f"ONE crisp solid {k}x{k} square block" if geo["exact"] else (
        f"ONE crisp solid square block of one fixed size (about {round(k)}x{round(k)} image pixels)")
    fid = fidelity or {}
    rules = constraints.rules(c, palette, facing, mode, listed, number.get("palette"), fid.get("invariants"),
                              fid.get("where"), fid.get("max_colors"), fid.get("tones"))
    lines = [
        'Create a pixel-art game asset for "Empire", a 2D side-view kingdom builder.',
        f"Subject: {subject}.",
        f"Asset type: {c.en}.",
        f"Pixel grid: the image is an exact grid of {lw}x{lh} logical pixels; every logical pixel is {block} "
        "aligned to the image edges. No sub-pixel detail, no anti-aliasing, no blur, no gradients, no soft "
        "brushes, no texture noise.",
    ] + [r["text"] for r in rules]
    if attached:
        lines.append("Attached images, in order: " + "; ".join(f"image {i}: {ROLES[r]}"
                                                                for i, r in enumerate(attached, 1)) + ".")
    if c.useful_height and c.useful_height[0] > 1:
        lines.append(f"Scale: the figure is {c.useful_height[0]}-{c.useful_height[1]} logical pixels tall, "
                     f"feet resting on a ground baseline {base} logical pixels above the bottom edge of its cell, "
                     "centered horizontally.")
    if transparent:
        lines.append("Background: fully transparent; no backdrop, no scenery, no floor, no checkerboard.")
    else:
        lines.append(f"Background: one perfectly flat solid {key} color (chroma key) everywhere around the figure; "
                     f"never use {key} inside the figure; no shadow, floor, gradient or vignette.")
    if (x0, y0, x1, y1) != (0, 0, lw, lh):
        lines.append(f"Margins: draw only inside logical pixels x {x0}-{x1 - 1}, y {y0}-{y1 - 1}; everything "
                     "outside that box is empty background.")
    if frames > 1:
        lines.append(f"Layout: a {cols}x{rows} sprite sheet of equal {canvas[0]}x{canvas[1]}-logical-pixel cells, "
                     "read left-to-right then top-to-bottom; one pose per cell; the SAME character, scale, palette and "
                     "baseline in every cell; generous empty space between figures; no text, labels, numbers, "
                     "borders, frame lines or grid lines.")
        lines += _timeline(tags or [])
    if reference and not set(attached) & {"identity", "identity_review", "identity_unrecorded", "concept"}:
        raise ValueError("reference sem a imagem de identidade anexada")
    lines.append("Avoid: photorealism, 3D render, painterly or vector style, glow, lens effects, drop shadows, "
                 "extra characters, watermarks, signatures, UI.")
    expect = {"kind": kind, "cells": geo["logical"], "content": geo["content"], "scale": k,
              "scale_exact": geo["exact"], "grid": "requested", "layout": [cols, rows], "frames": frames,
              "tags": [list(t) for t in tags] if tags else None,
              "background": "transparent" if transparent else key, "size": geo["size"], "cluster": c.cluster,
              "attached": attached, "mode": mode}
    advice = None
    if k < 8:
        advice = (f"cada pixel logico tera so {k:g} px na imagem: o gerador perde precisao. Peca menos quadros por "
                  "prancha (ex.: --tags walk:4 duas vezes) ou uma figura por imagem.")
    return {"prompt": "\n".join(lines), "size": f"{geo['size'][0]}x{geo['size'][1]}", "expect": expect,
            "advice": advice, "pixellab": pixellab_params(subject, c, tuple(canvas), facing), "target": target,
            "conflicts": camera_conflicts(subject, facing), "mode": mode,
            "constraints": [{"id": "pixel_grid", "origin": "request"}] + [{k: r[k] for k in ("id", "origin")}
                                                                       for r in rules],
            "implicit": constraints.implicit(rules)}


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
