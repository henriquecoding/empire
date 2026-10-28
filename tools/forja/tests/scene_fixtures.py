"""Fixtures das cenas (FORJA-11): uma casa sintetica na grade de 2 px, o contrato dela e uma faixa de terreno."""
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw

WALL, ROOF, DARK, SOIL, GRASS = (186, 170, 140, 255), (60, 90, 100, 255), (40, 30, 24, 255), (92, 64, 40, 255), \
    (110, 160, 60, 255)
DOOR = [52, 44, 76, 128]


def house(size: tuple[int, int] = (128, 128), door: list[int] | None = DOOR, lift: int = 0) -> Image.Image:
    """Parede, telhado e uma porta escura ate a soleira, em blocos de 2 px; `lift` levanta tudo (a casa a flutuar)."""
    w, h = size
    img = Image.new("RGBA", (w, h))
    d = ImageDraw.Draw(img)
    d.rectangle([8, 36, w - 9, h - 1 - lift], fill=WALL)
    d.rectangle([0, 8, w - 1, 37], fill=ROOF)
    d.rectangle([96, 0, 105, 9], fill=WALL)
    if door:
        d.rectangle([door[0], door[1], door[2] - 1, door[3] - 1 - lift], fill=DARK)
    return img


def strip(size: tuple[int, int] = (64, 32), rise: int = 0) -> Image.Image:
    """Uma faixa de terreno: relva por cima, terra por baixo; `rise` sobe a superficie da esquerda para a direita em
    degraus de 2 px (dentro da faixa nunca ha um degrau maior do que 2; na emenda da repeticao ha um de `rise`)."""
    w, h = size
    img = Image.new("RGBA", (w, h))
    d = ImageDraw.Draw(img)
    for x in range(0, w, 2):
        top = 8 + rise - (x * rise // w) // 2 * 2
        d.rectangle([x, top, x + 1, h - 1], fill=SOIL)
        d.rectangle([x, top, x + 1, top + 3], fill=GRASS)
    return img


def contract(**over) -> dict:
    base = {"schema": "forja.scene/1", "id": "casa_teste", "asset": "building", "people": "enramados",
            "subject": "a small Enramados timber house", "extent_px": [128, 128],
            "openings": [{"id": "porta", "kind": "door", "box_px": list(DOOR), "treatment": "interior"}],
            "signals": ["roof_pitch", "door_opening", "chimney_join"],
            "signal_regions": {"chimney_join": [94, 0, 108, 12]},
            "materials": ["timber", "stone", "roof_tile"], "states": ["done", "damaged"],
            "state_changes": {"damaged": [[0, 0, 128, 40]]},
            "brief": {"story": "built by woodfolk", "light": "one lantern by the door"}}
    base.update(over)
    return base


def write(folder: Path, data: dict, name: str = "cena.json") -> Path:
    folder.mkdir(parents=True, exist_ok=True)
    path = folder / name
    path.write_text(json.dumps(data), encoding="utf-8")
    return path
