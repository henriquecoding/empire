"""A regua de escala: os atores reais e o mundo, lidos dos ficheiros do jogo (FORJA-09).

Um cenario adapta-se aos atores e nunca o contrario (papel `actor_ruler`: nao se encolhem os atores para a casa
caber). A altura e a largura de cada ator saem do manifesto V15 (`body_bounds`, escrito pelo export), a linha do chao
do manifesto das composicoes do dono e da `band.gd`, a janela do `project.godot`: a Forja nao escreve estes numeros
(AGENTS.md: o que a ferramenta conta nao se escreve a mao). As metricas de arquitetura — porta, beiral, peitoril,
guarda — sao fatores sobre a regua, cada uma com a sua origem; as que dizem proposta esperam pelo dono (Q-292).

A grade do cenario e de 2 px (Asset Bible §1). A linha do chao, y=517, e impar: a fase que a poe numa aresta de celula
e 1, e o nivel inferior (y=618,5) fica a meio de uma celula em qualquer fase. A regua diz a fase e o resto de cada
ancora; nao arredonda posicoes da simulacao para caber na grade da arte.
"""
from __future__ import annotations

import json
import math
import re
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
DATA = Path(__file__).with_name("scenery.json")


def data() -> dict:
    return json.loads(DATA.read_text(encoding="utf-8"))


def _read(rel: str, root: Path | None) -> str:
    return ((root or ROOT) / rel).read_text(encoding="utf-8")


def _manifest(root: Path | None) -> dict:
    return json.loads(_read(data()["actors"]["manifest"], root))


def actors(root: Path | None = None) -> list[dict]:
    """Os atores da regua, pela ordem do scenery.json: altura e largura visiveis, tela e pe."""
    d = data()["actors"]
    assets = _manifest(root)["assets"]
    out = []
    for aid in d["ruler"]:
        if aid not in assets:
            raise KeyError(f"regua: {aid} nao esta em {d['manifest']}")
        a = assets[aid]
        bx, by, bw, bh = a["body_bounds"]
        out.append({"id": aid, "height": bh, "width": bw, "canvas": list(a["size"]), "foot": list(a["foot"]),
                    "body_bounds": [bx, by, bw, bh]})
    return out


def ruler(found: list[dict] | None = None, root: Path | None = None) -> dict:
    """O mais alto (portas, beirais, luz) e o mais baixo (peitoris, guardas) dos atores que andam no mundo."""
    found = found or actors(root)
    tallest = max(found, key=lambda a: (a["height"], a["id"]))
    shortest = min(found, key=lambda a: (a["height"], a["id"]))
    return {"tallest": tallest, "shortest": shortest, "actors": found,
            "origin": data()["actors"]["origin"], "excluded": data()["actors"]["excluded"]}


def frame(actor: str, index: int | None = None,
          root: Path | None = None) -> tuple[Image.Image, tuple[int, int], str]:
    """Um quadro real do ator (por omissao o primeiro de `idle`), o pivot dos pes nesse quadro e de onde veio. Sem a
    textura (um checkout sem LFS so tem o ponteiro), a silhueta e a caixa do corpo do manifesto, e di-lo."""
    a = _manifest(root)["assets"][actor]
    i = a["tags"]["idle"]["from_frame"] if index is None else index
    path = (root or ROOT) / (a["root"].replace("res://", "") + a["texture"])
    w, h = a["size"]
    ox, oy = a["frame_origins"][i]
    px, py = a["frame_pivots"][i]
    try:
        with Image.open(path) as im:
            return im.convert("RGBA").crop((ox, oy, ox + w, oy + h)), (px, py), str(path)
    except OSError:
        bx, by, bw, bh = a["body_bounds"]
        box = Image.new("RGBA", (w, h))
        box.paste((90, 90, 90, 255), (px + bx, py + by, px + bx + bw, py + by + bh))
        return box, (px, py), "body_bounds (textura ausente: checkout sem LFS)"


def world(root: Path | None = None) -> dict:
    """A janela, a linha do chao, o nivel inferior e o horizonte, cada um com o ficheiro de onde veio."""
    w = data()["world"]
    owner = json.loads(_read(w["owner_manifest"], root))
    band = {k: int(v) for k, v in re.findall(r"const (\w+) := (\d+)\b", _read(w["band"], root))}
    project = dict(re.findall(r"window/size/(viewport_\w+)=(\d+)", _read(w["project"], root)))
    out = {"viewport": [int(project["viewport_width"]), int(project["viewport_height"])],
           "surface_y": owner["surface_y"], "under_y": owner["under_y"], "horizon_y": band.get("HORIZON"),
           "screen_bottom": band.get("SCREEN_BOTTOM"), "art_phase": art_phase(owner),
           "sources": {"viewport": w["project"], "surface_y": w["owner_manifest"], "under_y": w["owner_manifest"],
                       "horizon_y": w["band"], "art_phase": w["owner_manifest"]}, "notes": []}
    if band.get("GROUND_LINE") != owner["surface_y"]:
        out["notes"].append(f"divergencia: band.gd GROUND_LINE={band.get('GROUND_LINE')}, manifesto do dono "
                            f"surface_y={owner['surface_y']}")
    return out


def art_phase(owner: dict) -> dict:
    """A fase em que a arte do dono ja esta: o resto de cada canto dos planos exportados pela escala deles."""
    seen: dict[tuple, int] = {}
    for view in owner.get("views", {}).values():
        for layer in view.get("layers", {}).values():
            sx, sy = layer.get("scale", [1, 1])
            x, y, w, h = layer["rect"]
            key = (sx, x % sx, y % sy, (y + h) % sy)
            seen[key] = seen.get(key, 0) + 1
    if not seen:
        return {"phase": None, "layers": 0, "consistent": False}
    (step, px, py, bottom), n = max(seen.items(), key=lambda kv: kv[1])
    return {"step": step, "phase": [px, py], "layers": sum(seen.values()), "agree": n,
            "consistent": len(seen) == 1 and py == bottom}


def lattice(step: int, wld: dict) -> dict:
    """A grade do cenario no mundo, na fase da arte que ja existe: onde assenta cada ancora.

    Uma linha de pes e uma fila de pixels: o pe do ator pinta a fila y e a aresta de baixo dele e y+1. Uma ancora fica
    na grade quando essa aresta (para o horizonte e o fundo do ecra, a propria linha) cai numa aresta de celula."""
    art = wld.get("art_phase") or {}
    phase = art.get("phase") if art.get("step") == step else None
    phase, source = (phase, "medida na arte do dono") if phase else (
        [0, (math.floor(wld["surface_y"]) + 1) % step], "proposta: a aresta de baixo da linha do chao numa aresta")
    anchors = {}
    for name, feet in (("surface_y", True), ("under_y", True), ("horizon_y", False), ("screen_bottom", False)):
        v = wld.get(name)
        if v is None:
            continue
        edge = math.floor(v) + 1 if feet else v
        rest = (edge - phase[1]) % step
        anchors[name] = {"y": v, "edge": edge, "cell_edge": rest == 0, "residual_px": rest,
                         "cells_below_surface": (v - wld["surface_y"]) / step}
    loose = [n for n, a in anchors.items() if not a["cell_edge"]]
    return {"step": step, "phase": phase, "phase_source": source, "art": art, "anchors": anchors,
            "off_lattice": loose,
            "rule": "a arte do cenario assenta nesta fase; a simulacao nao arredonda posicoes para caber nela",
            "decision": None if not loose else "por decidir pelo dono como a apresentacao resolve "
                                               f"{', '.join(loose)} (Q-293)"}


def _snap(lo: float, hi: float, step: int) -> tuple[int, int]:
    a = math.ceil(lo / step) * step
    return a, max(a, math.floor(hi / step) * step)


def metrics(rul: dict, step: int = 2) -> list[dict]:
    """Cada metrica em px de ecra e em celulas, arredondada para dentro da grade (o minimo sobe, o maximo desce)."""
    bases = {"tallest": rul["tallest"]["height"], "shortest": rul["shortest"]["height"]}
    out: list[dict] = []
    for m in data()["metrics"]:
        if "px" in m:
            lo, hi = m["px"]
            base = None
        else:
            prior = next((o for o in out if o["id"] == m["base"]), None)
            base = prior["px"] if prior else [bases[m["base"]]] * 2
            lo, hi = base[0] * m["factor"][0], base[1] * m["factor"][1]
        lo, hi = _snap(lo, hi, step)
        out.append({"id": m["id"], "label": m["label"], "px": [lo, hi], "cells": [lo // step, hi // step],
                    "base": m.get("base"), "base_px": base, "factor": m.get("factor"), "origin": m["origin"],
                    "why": m["why"]})
    return out


def metric(found: list[dict], ident: str) -> dict:
    return next(m for m in found if m["id"] == ident)


def summary(step: int = 2, root: Path | None = None) -> dict:
    """Tudo o que a regua sabe, para o `forja regua` e para os pedidos de cena."""
    rul = ruler(root=root)
    wld = world(root)
    return {"world": wld, "lattice": lattice(step, wld), "ruler": rul, "metrics": metrics(rul, step), "step": step}
