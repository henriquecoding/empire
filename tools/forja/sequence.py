"""Leitura exata da sequência: PNG + JSON + cadeia. O hash inclui pixels, ordem, tempos, tags e pivô."""
from __future__ import annotations

import hashlib
import json
from dataclasses import dataclass
from pathlib import Path

from PIL import Image

from . import aseprite, timeline
from .ase import read as read_ase
from .equipment import image_sha
from .imageops import open_rgba
from .sheet_audit import SCHEMA


def digest(value: object) -> str:
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(",", ":"),
                                    ensure_ascii=False, allow_nan=False).encode()).hexdigest()


@dataclass
class Clip:
    data: dict
    frames: list[Image.Image]
    metadata: dict
    path: Path
    source: Image.Image | None = None
    last: Image.Image | None = None

    @property
    def sha(self) -> str:
        d = self.data
        return digest({"frames": [image_sha(f) for f in self.frames], "durations": d["durations"],
                       "tags": d["tags"], "pivot": d["pivot"], "canvas": d["canvas"],
                       "lineage": d["lineage"], "source": d.get("source"), "holds": d.get("holds"),
                       "character": d.get("character"), "kind": d["contract"]["kind"]})


def resolve(path: Path, filename: str) -> Path:
    p = Path(filename)
    if p.is_absolute():
        return p
    candidate = path.parent / p
    return candidate if candidate.exists() else p


def load(path: str | Path) -> Clip:
    path = Path(path)
    d = json.loads(path.read_text(encoding="utf-8"))
    chain = d.get("lineage") or {}
    if chain.get("schema") != SCHEMA:
        raise ValueError("sequencia sem cadeia forja.animation_lineage/1")
    files = d["files"]
    atlas = open_rgba(resolve(path, files["sheet"]))
    if image_sha(atlas) != chain.get("output_sha256"):
        raise ValueError("os pixels do atlas nao correspondem a cadeia da sequencia")
    meta = json.loads(resolve(path, files["json"]).read_text(encoding="utf-8"))
    slices = [s for s in meta["meta"].get("slices", []) if s.get("name") == "pivot"]
    expected_pivot = {"x": d["pivot"][0], "y": d["pivot"][1]}
    if len(slices) != 1 or not slices[0].get("keys") or any(
            k.get("pivot") != expected_pivot for k in slices[0]["keys"]):
        raise ValueError("pivot do JSON difere da sequencia registada")
    if meta["meta"]["size"] != {"w": atlas.width, "h": atlas.height}:
        raise ValueError("tela do atlas difere do JSON")
    rows = meta["frames"]
    if not isinstance(rows, list):
        raise ValueError("JSON da sequencia precisa de frames em lista ordenada")
    frames, durations = [], []
    for row in rows:
        r = row["frame"]
        x, y, w, h = (r[k] for k in ("x", "y", "w", "h"))
        if any(type(v) is not int for v in (x, y, w, h)) or not (
                0 <= x < x + w <= atlas.width and 0 <= y < y + h <= atlas.height):
            raise ValueError("retangulo de quadro fora do atlas")
        if row.get("rotated") or row.get("trimmed") or [w, h] != d["canvas"]:
            raise ValueError("a revisao nativa requer quadros inteiros, sem trim nem rotacao")
        frames.append(atlas.crop((x, y, x + w, y + h)))
        durations.append(row["duration"])
    tags = [[t["name"], t["from"], t["to"], t["direction"]] for t in meta["meta"]["frameTags"]]
    if durations != d["durations"] or tags != d["tags"]:
        raise ValueError("timeline do export difere da sequencia registada")
    timeline.validate(frames, durations, tags)
    if not isinstance(d.get("holds", []), list) or any(not isinstance(h, dict) for h in d.get("holds", [])):
        raise ValueError("holds da sequencia: lista de registos esperada")
    timeline.holds(d.get("holds"), len(frames))
    records = chain.get("frames") or []
    if len(records) != len(frames):
        raise ValueError("cadeia incompleta: falta um registo por quadro")
    for i, (frame, record) in enumerate(zip(frames, records)):
        if record.get("frame") != i or record.get("output_sha256") != image_sha(frame):
            raise ValueError(f"pixels ou ordem do quadro {i} nao correspondem a cadeia")
        if d.get("schema") == "forja.animation/1":
            native = open_rgba(path.parent / f"frame_{i:03d}.png")
            if image_sha(native) != image_sha(frame):
                raise ValueError(f"PNG nativo do quadro {i} difere do atlas")
    source = open_rgba(resolve(path, files["source"])) if files.get("source") else None
    if source is not None and image_sha(source) != chain.get("input_sha256"):
        raise ValueError("a referencia da sequencia mudou")
    last = open_rgba(resolve(path, files["source_last"])) if files.get("source_last") else None
    end = (d.get("source") or {}).get("last")
    if end and (last is None or image_sha(last) != end.get("pixels_sha256")):
        raise ValueError("a pose final de referencia da sequencia mudou")
    if files.get("aseprite") or d.get("schema") == "forja.animation/1":
        ase_path = resolve(path, files["aseprite"])
        check = aseprite.verify(ase_path, frames)
        if not check["pixel_equal"] or check["durations"] != durations:
            raise ValueError("fonte Aseprite difere dos pixels ou tempos do atlas")
        src = read_ase(ase_path)
        wanted = [aseprite.tag(*t) for t in tags]
        pivots = [s for s in src.slices if s.name == "pivot"]
        if src.tags != wanted or len(pivots) != 1 or not pivots[0].keys or any(
                k.pivot != tuple(d["pivot"]) for k in pivots[0].keys):
            raise ValueError("tags ou pivot Aseprite diferem da sequencia")
    return Clip(d, frames, meta, path, source, last)
