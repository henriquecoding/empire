"""Diagramas de teste de equipamento, 80x80 na paleta do Empire (FORJA-03). Nao sao arte proposta.

As quatro da espada repetem a prova do relatorio de 24-25/10 (referencia, lamina bifurcada, duas guardas,
sem arma: todas passam no lint raster); as do arco acrescentam a corda e os controlos positivos (arco
curvo, corda tapada pelo braco). Cada fixture traz o manifesto e a observacao que um revisor marcaria.
"""
from __future__ import annotations

import math

from PIL import Image

from tools.forja import equipment, outline

SKIN, TUNIC, LEGS = "#E3BC88", "#416E4E", "#4F3206"
STEEL, GOLD, HILT, POMMEL = "#C9C5C6", "#FFB416", "#6C3206", "#A19D9E"
WOOD, STRING = "#915F46", "#E5D395"
DATE = "2026-10-25"


def _rgb(h: str) -> tuple[int, int, int, int]:
    return (int(h[1:3], 16), int(h[3:5], 16), int(h[5:7], 16), 255)


def _fill(img: Image.Image, color: str, *boxes) -> None:
    for x0, y0, x1, y1 in boxes:
        img.paste(_rgb(color), (x0, y0, x1, y1))


def _body(arm: tuple[int, int, int, int]) -> Image.Image:
    img = Image.new("RGBA", (80, 80))
    _fill(img, SKIN, (30, 20, 42, 32), arm)
    _fill(img, TUNIC, (30, 32, 42, 58))
    _fill(img, LEGS, (31, 58, 35, 78), (37, 58, 41, 78))
    return img


def sword(case: str = "reference") -> Image.Image:
    """A espada curta do estudo: lamina, guarda, punho e pomo, a mao no punho."""
    img = _body((42, 51, 49, 55))
    if case == "none":
        return outline.add(img)
    _fill(img, HILT, (49, 50, 51, 58))
    _fill(img, POMMEL, (49, 58, 51, 60))
    _fill(img, GOLD, (46, 48, 54, 50))
    if case == "forked":
        _fill(img, STEEL, (49, 36, 51, 48), (48, 35, 53, 36), (48, 26, 49, 35), (52, 26, 53, 35))
    else:
        _fill(img, STEEL, (49, 26, 51, 48))
    if case == "two_guards":
        _fill(img, GOLD, (46, 40, 54, 42))
    if case == "grip_hidden":
        _fill(img, SKIN, (42, 52, 51, 55))
    return outline.add(img)


def bow(case: str = "valid") -> Image.Image:
    """Um arco simples em repouso: madeira curva, corda reta entre as pontas, a mao na empunhadura."""
    img = _body((42, 39, 64, 42))
    for y in range(20, 61):
        x = 58 + round(8 * math.sin(math.pi * (y - 20) / 40))
        _fill(img, WOOD, (x, y, x + 2, y + 1))
    _fill(img, SKIN, (62, 37, 69, 44))
    end = 52 if case == "short" else 60
    for y in range(21, end):
        if 39 <= y < 42:
            continue
        x = 57
        if case == "wavy" and 28 <= y < 34:
            x = 55
        _fill(img, STRING, (x, y, x + (2 if case == "wide" and y < 30 else 1), y + 1))
        if case == "double":
            _fill(img, STRING, (54, y, 55, y + 1))
    return outline.add(img)


def sword_manifest() -> dict:
    return {"schema": equipment.SCHEMA, "subject": "fixture: espada curta reta", "status": "fixture",
            "items": [{"id": "sword", "family": "sword_straight", "slot": "weapon", "state": "held",
                       "parts": {"grip": {"occluders": ["hand"]}},
                       "contacts": [{"part": "grip", "body": "hand", "kind": "holds"}]}]}


def bow_manifest() -> dict:
    return {"schema": equipment.SCHEMA, "subject": "fixture: arco simples em repouso", "status": "fixture",
            "items": [{"id": "bow", "family": "bow_simple", "slot": "weapon", "state": "rest",
                       "parts": {"string": {"occluders": ["arm"]}, "grip": {"occluders": ["hand"]},
                                 "limb": {"occluders": ["hand"]}},
                       "contacts": [{"part": "grip", "body": "hand", "kind": "holds"}]}]}


def sword_observation(img: Image.Image) -> dict:
    regions = {"sword.blade": {"box": [44, 20, 56, 48], "colors": [STEEL]},
               "sword.guard": {"box": [44, 20, 56, 50], "colors": [GOLD]},
               "sword.grip": {"box": [44, 50, 56, 58], "colors": [HILT]},
               "sword.pommel": {"box": [44, 58, 56, 61], "colors": [POMMEL]},
               "hand": {"box": [42, 50, 52, 56], "colors": [SKIN]}}
    return equipment.observation(img, regions, {"sword.base": (50, 47), "sword.tip": (50, 26)},
                                 "fixture (testes)", "caixa e cores marcadas a mao", DATE)


def bow_observation(img: Image.Image) -> dict:
    regions = {"bow.limb": {"box": [56, 18, 70, 62], "colors": [WOOD]},
               "bow.string": {"box": [52, 18, 60, 62], "colors": [STRING]},
               "bow.grip": {"box": [60, 34, 70, 47], "colors": [WOOD]},
               "hand": {"box": [62, 37, 69, 44], "colors": [SKIN]},
               "arm": {"box": [42, 38, 62, 43], "colors": [SKIN, "#000000"]}}
    return equipment.observation(img, regions, {"bow.nock_top": (57, 21), "bow.nock_bottom": (57, 59)},
                                 "fixture (testes)", "caixa e cores marcadas a mao", DATE)
