"""Intencao temporal localizada, em indices zero-based inclusivos; nao aprova o desenho."""
from __future__ import annotations

from . import masks


def validate(windows, count: int, size) -> list[dict]:
    if windows is None:
        return []
    if not isinstance(windows, list):
        raise ValueError("effect windows: lista esperada")
    for w in windows:
        if not isinstance(w, dict) or any(type(w.get(k)) is not int for k in ("from", "to")) or not (
                0 <= w["from"] <= w["to"] < count):
            raise ValueError("effect window: intervalo fora da timeline")
        box = w.get("box")
        if not isinstance(box, list) or len(box) != 4 or any(type(v) is not int for v in box) or not (
                0 <= box[0] < box[2] <= size[0] and 0 <= box[1] < box[3] <= size[1]):
            raise ValueError("effect window: regiao fora do canvas")
        if not isinstance(w.get("reason"), str) or not w["reason"].strip():
            raise ValueError("effect window: explicar a intencao")
    return windows


def at(windows: list[dict], frame: int) -> frozenset:
    return frozenset().union(*(masks.box(w["box"]) for w in windows if w["from"] <= frame <= w["to"]))


def outside(actor, final, windows) -> list[dict]:
    validate(windows, len(actor), actor[0].size)
    changes = [(i, set(masks.changed(a, b)) - at(windows, i)) for i, (a, b) in enumerate(zip(actor, final))]
    return [{"frame": i, "outside_pixels": len(pixels)} for i, pixels in changes if pixels]
