"""Quadros em animacao: tira, atlas, JSON no formato do Aseprite, GIF/APNG e medidas.

O JSON segue o `--format json-array` do CLI do Aseprite, o mesmo que o
tools/export_aseprite.sh produz, para que o resto do pipeline do projeto o leia
como leria um export do aplicativo. As medidas sao as da checklist de revisao:
pivot estavel, quadros distintos, paleta comum e cintilacao.
"""
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image

from .imageops import CLEAR, flat, foot_point, on_background, opaque_bbox, upscale


def strip(frames: list[Image.Image], columns: int | None = None) -> tuple[Image.Image, list[tuple[int, int, int, int]]]:
    """As imagens lado a lado (ou num atlas de `columns` colunas) e o retangulo de cada uma."""
    w, h = frames[0].size
    cols = columns or len(frames)
    rows = -(-len(frames) // cols)
    sheet = Image.new("RGBA", (w * cols, h * rows), CLEAR)
    rects = []
    for i, f in enumerate(frames):
        x, y = (i % cols) * w, (i // cols) * h
        sheet.paste(f, (x, y))
        rects.append((x, y, w, h))
    return sheet, rects


def aseprite_json(image_name: str, size: tuple[int, int], rects: list, durations: list[int],
                  tags: list[tuple[str, int, int, str]], name: str = "sprite",
                  pivot: tuple[int, int] | None = None) -> dict:
    frames = [{"filename": f"{name} {i}.aseprite", "frame": {"x": x, "y": y, "w": w, "h": h},
               "rotated": False, "trimmed": False,
               "spriteSourceSize": {"x": 0, "y": 0, "w": w, "h": h},
               "sourceSize": {"w": w, "h": h}, "duration": d}
              for i, ((x, y, w, h), d) in enumerate(zip(rects, durations))]
    meta = {"app": "forja (Empire)", "version": "1", "image": image_name, "format": "RGBA8888",
            "size": {"w": size[0], "h": size[1]}, "scale": "1",
            "frameTags": [{"name": t, "from": a, "to": b, "direction": d} for t, a, b, d in tags],
            "layers": [{"name": "body", "opacity": 255, "blendMode": "normal"}], "slices": []}
    if pivot:
        w, h = rects[0][2], rects[0][3]
        meta["slices"].append({"name": "pivot", "color": "#0000ffff", "keys": [
            {"frame": 0, "bounds": {"x": 0, "y": 0, "w": w, "h": h},
             "pivot": {"x": pivot[0], "y": pivot[1]}}]})
    return {"frames": frames, "meta": meta}


def mirror(frames: list[Image.Image], pivot: tuple[int, int]) -> tuple[list[Image.Image], tuple[int, int]]:
    """A direcao oposta por espelho; o pivot espelha com ela (V15: [40,78] -> [39,78] em 80 px).

    Um espelho nao e uma segunda direcao desenhada (guia de personagens §6): o
    relatorio conta-o como espelho.
    """
    w = frames[0].width
    flipped = [f.transpose(Image.Transpose.FLIP_LEFT_RIGHT) for f in frames]
    return flipped, (w - 1 - pivot[0], pivot[1])


def save_gif(frames: list[Image.Image], durations: list[int], path: str | Path, scale: int = 4,
             bg: tuple[int, int, int] | None = (40, 34, 30), loop: bool = True) -> Path:
    """GIF para ver em qualquer lado (fundo solido) — o GIF nao tem alfa parcial."""
    shown = [upscale(on_background(f, bg) if bg else f, scale).convert("RGB") for f in frames]
    path = Path(path)
    shown[0].save(path, save_all=True, append_images=shown[1:], duration=durations,
                  loop=0 if loop else 1, disposal=2, optimize=False)
    return path


def save_apng(frames: list[Image.Image], durations: list[int], path: str | Path, scale: int = 4) -> Path:
    shown = [upscale(f, scale) for f in frames]
    path = Path(path)
    shown[0].save(path, save_all=True, append_images=shown[1:], duration=durations, loop=0,
                  disposal=1, default_image=False)
    return path


def export(frames: list[Image.Image], out_dir: str | Path, name: str, durations: list[int] | None = None,
           tags: list[tuple[str, int, int, str]] | None = None, pivot: tuple[int, int] | None = None,
           columns: int | None = None, previews: bool = True) -> dict:
    """Escreve <name>.png (tira/atlas), <name>.json (Aseprite), e previas GIF/APNG."""
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    durations = durations or [100] * len(frames)
    tags = tags or [(name, 0, len(frames) - 1, "forward")]
    sheet, rects = strip(frames, columns)
    sheet.save(out / f"{name}.png")
    data = aseprite_json(f"{name}.png", sheet.size, rects, durations, tags, name, pivot)
    (out / f"{name}.json").write_text(json.dumps(data, indent=1) + "\n", encoding="utf-8")
    files = {"sheet": str(out / f"{name}.png"), "json": str(out / f"{name}.json")}
    if previews:
        files["gif"] = str(save_gif(frames, durations, out / f"{name}@4x.gif"))
        files["apng"] = str(save_apng(frames, durations, out / f"{name}@4x.png"))
    return files


def metrics(frames: list[Image.Image], pivot: tuple[int, int] | None = None, loop: bool = True) -> dict:
    """O que a revisao de uma animacao quer saber antes de olhar."""
    feet = [foot_point(f) for f in frames]
    boxes = [opaque_bbox(f) for f in frames]
    rasters = [f.tobytes() for f in frames]
    unique = set(rasters)
    flips = {f.tobytes(): f.transpose(Image.Transpose.FLIP_LEFT_RIGHT).tobytes() for f in frames}
    colors = set()
    for f in frames:
        colors |= {p[:3] for p in flat(f) if p[3] >= 128}
    drift = [None if p is None or pivot is None else [p[0] - pivot[0], p[1] - pivot[1]] for p in feet]
    return {"frames": len(frames), "distinct_rasters": len(unique),
            "duplicates": len(rasters) - len(unique),
            "mirror_pairs": sum(1 for r in unique if flips[r] != r and flips[r] in unique) // 2,
            "palette_size": len(colors), "feet": [list(p) if p else None for p in feet],
            "pivot_drift": drift, "max_drift": max((abs(d[0]) + abs(d[1]) for d in drift if d), default=0),
            "heights": [b[3] - b[1] if b else 0 for b in boxes], "flicker": flicker(frames, loop)}


def flicker(frames: list[Image.Image], loop: bool = True) -> int:
    """Pixels que piscam A -> B -> A em tres quadros seguidos (ciclicos): ruido, nao movimento."""
    if len(frames) < 3:
        return 0
    data = [flat(f) for f in frames]
    n = len(data)
    count = 0
    for i in range(n if loop else n - 2):
        a, b, c = data[i], data[(i + 1) % n], data[(i + 2) % n]
        count += sum(1 for p, q, r in zip(a, b, c) if p == r and q != p and p[3] >= 128 and q[3] >= 128)
    return count


def onion(frames: list[Image.Image], index: int, alpha: int = 90) -> Image.Image:
    """O quadro `index` com o anterior e o seguinte em transparencia, para comparar volumes."""
    w, h = frames[0].size
    out = Image.new("RGBA", (w, h), CLEAR)
    for j, tint in ((index - 1, (255, 80, 80)), (index + 1, (80, 160, 255))):
        if 0 <= j < len(frames):
            ghost = Image.new("RGBA", (w, h), (*tint, alpha))
            out.alpha_composite(Image.composite(ghost, Image.new("RGBA", (w, h)), frames[j].getchannel("A")))
    out.alpha_composite(frames[index])
    return out
