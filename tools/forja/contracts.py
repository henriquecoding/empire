"""Os contratos de arte do Empire (contracts.json), resolvidos por tipo de asset."""
from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path

from . import color

DATA = Path(__file__).with_name("contracts.json")


@dataclass
class Contract:
    kind: str
    label: str
    en: str
    source: str
    status: str
    canvas: tuple[int, int] | None
    pivot: tuple[int, int] | None
    useful_height: tuple[int, int] | None
    outline_px: int | None
    outline_color: tuple[int, int, int]
    cluster: int
    max_colors: int | None
    dither: bool
    anchor: str
    width_multiple: int | None
    palette: str

    def as_dict(self) -> dict:
        out = dict(self.__dict__)
        out["outline_color"] = color.to_hex(self.outline_color)
        return out


def load_data() -> dict:
    return json.loads(DATA.read_text(encoding="utf-8"))


def kinds() -> list[str]:
    return list(load_data()["kinds"])


def get(kind: str = "free", **overrides) -> Contract:
    data = load_data()
    if kind not in data["kinds"]:
        raise KeyError(f"tipo desconhecido: {kind} (ha: {', '.join(data['kinds'])})")
    k = dict(data["kinds"][kind])
    for key, value in overrides.items():
        if value is not None:
            k[key] = value
    return Contract(
        kind=kind, label=k["label"], en=k.get("en", k["label"]), source=k["source"], status=k["status"],
        canvas=tuple(k["canvas"]) if k.get("canvas") else None,
        pivot=tuple(k["pivot"]) if k.get("pivot") else None,
        useful_height=tuple(k["useful_height"]) if k.get("useful_height") else None,
        outline_px=k.get("outline_px"), outline_color=color.parse_hex(data["outline_color"]),
        cluster=int(k.get("cluster") or 1), max_colors=k.get("max_colors"),
        dither=bool(k.get("dither")), anchor=k.get("anchor", "feet"),
        width_multiple=k.get("width_multiple"), palette=k.get("palette", data["palette"]))


def tag(name: str) -> dict | None:
    return load_data()["tags"].get(name)


def tags() -> dict:
    return {k: v for k, v in load_data()["tags"].items() if not k.startswith("_")}
