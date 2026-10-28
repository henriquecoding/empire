"""A bancada de montagem e a escala de uma referencia (FORJA-11).

Uma peca isolada engana: a casa que parece rica sozinha pode tapar o rei, a porta pode nao o deixar passar, o
detalhe pode ser mais grosso ou mais fino do que o dos vizinhos. A bancada poe a peca no mundo de 1280x720, com a
base na linha do chao, na fase da grade da arte do dono, e os atores reais a frente da porta e ao lado; a 1x e a 2x
(inteiro), de dia e numa noite aproximada.

A noite da bancada e so a modulacao da fase (`data/source/clock.csv`: matiz, saturacao e valor da noite, com o piso
do `night_vision`), sem as luzes da §80 nem o shader `world_light`: serve para ver se as silhuetas se separam, nao
substitui a captura no motor.

`scale_reference` responde a pergunta do dono: como adequar uma referencia aos atores de 64x64 e 80x80. Um marco
funcional medido na referencia (a porta, um barril, uma figura) diz a escala; o pixel aparente da referencia nessa
escala, comparado com a celula de 2 px, diz se o redesenho simplifica ou acrescenta detalhe.
"""
from __future__ import annotations

import colorsys
import csv

from PIL import Image

from . import gridcheck, regua, scene
from .imageops import opaque_bbox, upscale

SKY, GROUND = (143, 160, 170, 255), (74, 59, 42, 255)


def night_tint(root=None) -> dict:
    with open((root or regua.ROOT) / "data/source/clock.csv", encoding="utf-8") as f:
        row = next(csv.DictReader(f))
    hue, sat, val = (float(row[f"phase_tint_{k}"].split("|")[5]) for k in ("hue", "sat", "val"))
    value = max(val, float(row["night_vision"]))
    rgb = tuple(round(c * 255) for c in colorsys.hsv_to_rgb(hue / 360, sat, value))
    return {"rgb": rgb, "hue": hue, "sat": sat, "value": value, "source": "data/source/clock.csv (noite; piso "
            "night_vision)", "approximation": "so a modulacao da fase; sem luzes nem o shader world_light"}


def _modulate(img: Image.Image, rgb: tuple[int, int, int]) -> Image.Image:
    r, g, b, a = img.split()
    out = Image.merge("RGB", [ch.point(lambda v, m=m: v * m // 255) for ch, m in zip((r, g, b), rgb)])
    return Image.merge("RGBA", (*out.split(), a))


def _stage(wld: dict) -> Image.Image:
    w, h = wld["viewport"]
    img = Image.new("RGBA", (w, h), SKY)
    img.paste(GROUND, (0, wld["surface_y"] + 1, w, h))
    return img


def _put(stage: Image.Image, img: Image.Image, xy: tuple[int, int]) -> None:
    """Compor por cima, mesmo com a origem fora do palco (o alpha_composite recusa coordenadas negativas)."""
    layer = Image.new("RGBA", stage.size)
    layer.paste(img, xy)
    stage.alpha_composite(layer)


def _actor(img: Image.Image, actor: str, foot_x: int, foot_y: int, root=None) -> dict:
    sprite, (px, py), source = regua.frame(actor, root=root)
    _put(img, sprite, (foot_x - px, foot_y - py))
    return {"actor": actor, "foot": [foot_x, foot_y], "source": source}


def bench(asset: Image.Image, res: dict, x: int | None = None, root=None) -> dict:
    """A peca pousada pela sua ancora (o chao, o horizonte ou o fundo do ecra; repetida em x se o contrato o pede) e
    os atores a volta, na linha do chao. Devolve as imagens (dia, noite) e onde ficou cada coisa."""
    wld = res["world"]
    vw = wld["viewport"][0]
    w = asset.width
    where = scene.place(res, asset.size, x)
    stage = _stage(wld)
    piece = asset.convert("RGBA")
    for xy in where["copies"]:
        _put(stage, piece, tuple(xy))
    left = where["asset_top_left"][0]
    doors = [o for o in res["openings"] if o["kind"] in ("door", "gate", "arch", "bay")]
    foot_y = int(wld["surface_y"])
    tall, short = res["ruler"]["tallest"]["id"], res["ruler"]["shortest"]["id"]
    door_x = left + (doors[0]["box_px"][0] + doors[0]["box_px"][2]) // 2 if doors else left - 48
    spots = [(tall, door_x), (short, left + w + 40), (tall, left - 56)]
    actors = [_actor(stage, a, min(max(fx, 40), vw - 40), foot_y, root) for a, fx in spots]
    tint = night_tint(root)
    return {"day": stage, "night": _modulate(stage, tint["rgb"]), "placement": where, "actors": actors,
            "night_tint": tint}


def _marks(marks: list[dict]) -> dict:
    """A escala admissivel de cada marco ([min, max] da metrica sobre a altura medida) e se elas se cruzam: dois marcos
    sem escala comum querem dizer que a referencia desenhou partes em escalas diferentes."""
    rows = []
    for m in marks:
        h = m["box"][3] - m["box"][1]
        lo, hi = m["target"]
        rows.append({"metric": m.get("metric"), "box": list(m["box"]), "measured_px": h, "target_px": [lo, hi],
                     "scale_range": [round(lo / h, 4), round(hi / h, 4)]})
    low, high = max(r["scale_range"][0] for r in rows), min(r["scale_range"][1] for r in rows)
    return {"landmarks": rows, "common_range": [low, high] if low <= high else None, "consistent": low <= high}


def scale_reference(ref: Image.Image, marks: list[dict], step: int, crop: tuple[int, int, int, int] | None = None,
                    ground_y: int | None = None, footprint: int | None = None) -> dict:
    """A escala que leva os marcos funcionais da referencia a medida dos atores, e o que isso faz ao detalhe.

    `marks`: [{box, target: (min, max) em px de ecra, metric}]; o primeiro e o marco do proprio objeto e decide a
    escala (o meio do intervalo comum, se os marcos concordam; senao o meio do intervalo dele). `crop`: o objeto a
    adaptar (por omissao o opaco inteiro). `ground_y`: a linha do chao na referencia (por omissao a base do marco).
    `footprint`: a largura que a simulacao da a obra (`buildings.csv`); abaixo de 1, a planta comprime-se (menos vaos e
    pisos) e a porta fica do tamanho da regua — nunca se encolhe a imagem (pesquisa A, §4.2 e §5.3)."""
    ref = ref.convert("RGBA")
    agree = _marks(marks)
    lo, hi = agree["common_range"] or agree["landmarks"][0]["scale_range"]
    scale = (lo + hi) / 2
    g, _ = gridcheck.measure(ref, None, None, False)
    period = None if g.native else round(g.period[0], 3)
    cell = round(period * scale, 2) if period else None
    ratio = round(cell / step, 2) if cell else None
    if ratio is None:
        verdict = ("sem grade medida: a referencia e pictorica (ou tem pixels de tamanhos misturados); o redesenho "
                   "decide o detalhe todo na grade de 2 px")
    elif ratio > 1.5:
        verdict = (f"mais grossa: cada pixel da referencia vale {cell} px de ecra, {ratio}x a celula de {step} px; "
                   "o redesenho acrescenta detalhe na grade do jogo, ou a peca le-se mais grossa do que os vizinhos")
    elif ratio < 0.75:
        verdict = (f"mais fina: cada pixel da referencia vale {cell} px de ecra, {ratio}x a celula; o redesenho "
                   "simplifica (funde, tira, exagera os sinais de identidade); reduzir apaga-os")
    else:
        verdict = f"compativel: cada pixel da referencia vale {cell} px de ecra ({ratio}x a celula)"
    box = crop or opaque_bbox(ref) or (0, 0, ref.width, ref.height)
    size = [round((box[2] - box[0]) * scale / step) * step, round((box[3] - box[1]) * scale / step) * step]
    ground = ground_y if ground_y is not None else marks[0]["box"][3]
    return {"scale": round(scale, 4), **agree,
            "scale_note": None if agree["consistent"] else "os marcos nao tem escala comum: a referencia mistura "
            "escalas; vale o primeiro (o marco do proprio objeto) e a excecao regista-se no contrato",
            "reference_grid": {"period": period, "origin": g.as_dict().get("origin"), "cells": g.as_dict()["cells"]},
            "apparent_cell_px": cell, "cell_ratio": ratio, "detail": verdict, "crop": list(box),
            "target_extent_px": size, "target_cells": [v // step for v in size],
            "segment_share": round(size[0] / 640, 2), "ground_y": ground,
            "plan": None if not footprint else {
                "footprint_px": footprint, "compression": round(footprint / size[0], 3),
                "rule": "comprimir a arquitetura (vaos, pisos, janelas) e manter a porta e os sinais na regua"
                if footprint < size[0] else "cabe: a planta da referencia serve a pegada"}}


def reference_bench(ref: Image.Image, info: dict, res_world: dict, actors: list[str], root=None) -> Image.Image:
    """A referencia na escala da regua, com o chao dela na linha do jogo e os atores reais ao lado. A amostragem e
    suave (e uma previa de composicao e escala, nao pixel art)."""
    x0, y0, x1, y1 = info["crop"]
    s = info["scale"]
    part = ref.convert("RGBA").crop((x0, y0, x1, max(y1, info["ground_y"])))
    size = (max(1, round(part.width * s)), max(1, round(part.height * s)))
    part = part.resize(size, Image.Resampling.LANCZOS)
    stage = _stage(res_world)
    w = res_world["viewport"][0]
    edge = int(res_world["surface_y"]) + 1
    left = (w - part.width) // 2
    _put(stage, part, (left, edge - round((info["ground_y"] - y0) * s)))
    for i, actor in enumerate(actors):
        _actor(stage, actor, left - 40 - 70 * i, int(res_world["surface_y"]), root)
    return stage


def zoom(img: Image.Image, k: int = 2) -> Image.Image:
    return upscale(img, k)
