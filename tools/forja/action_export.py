"""Folhas por acao e duas composicoes, com reconstrucao exata do canvas antes de rever."""
from __future__ import annotations

import copy
import json
from pathlib import Path

from PIL import Image

from . import ase, contracts, proof_io, study, timeline
from .ase.empire import LEGACY, PIVOTS, WORK, slot
from .ase.model import DIRECTIONS
from .equipment import image_sha
from .imageops import foot_point

SCHEMA = "forja.action_export/1"


def prepare(sprite, kind: str, effect_layers: list[str]) -> tuple:
    c = contracts.get(kind)
    if not c.canvas or [sprite.width, sprite.height] != list(c.canvas) or not c.pivot:
        raise ValueError("exportacao por acao: canvas nativo e pivot do contrato obrigatorios")
    names = [layer.name for layer in sprite.layers]
    if len(set(names)) != len(names) or any(n not in names for n in effect_layers):
        raise ValueError("camadas repetidas ou efeito desconhecido")
    parents = sprite.parents()
    for i, layer in enumerate(sprite.layers):
        chain, parent = [i], parents[i]
        while parent is not None:
            chain.append(parent)
            parent = parents[parent]
        if (slot(layer.name) or LEGACY.get(layer.name)) in ("body", "head", "face", "weapon", "shield", "storage"):
            if any(sprite.layers[j].name in effect_layers for j in chain):
                raise ValueError("VFX nao pode esconder anatomia ou equipamento: " + layer.name)
    pivot = list(c.pivot)
    for sl in (s for s in sprite.slices if s.name in PIVOTS):
        for key in sl.keys:
            if not key.pivot or [key.x + key.pivot[0], key.y + key.pivot[1]] != pivot:
                raise ValueError("pivot mudou entre acoes ou diverge do contrato")
    if not any(s.name in PIVOTS and any(k.frame == 0 for k in s.keys) for s in sprite.slices):
        raise ValueError("pivot explicito desde o quadro zero necessario")
    final_sprite = copy.deepcopy(sprite)
    for layer in final_sprite.layers:
        if layer.name in WORK or layer.has("reference"):
            layer.flags &= ~1
    actor_sprite = copy.deepcopy(final_sprite)
    for layer in actor_sprite.layers:
        if layer.name in effect_layers:
            layer.flags &= ~1
    actor = [ase.render(actor_sprite, i) for i in range(sprite.frames)]
    final = [ase.render(final_sprite, i) for i in range(sprite.frames)]
    tags = [(t.name, t.first, t.last, DIRECTIONS[t.direction]) for t in sprite.tags]
    timeline.validate(final, sprite.durations, tags)
    return actor, final, tags, pivot


def pack(frames, indices, durations, tag, pivot, trim: bool) -> tuple:
    boxes = [(f.getchannel("A").getbbox() or (0, 0, 1, 1)) if trim else (0, 0, *f.size) for f in frames]
    width, height = sum(b[2] - b[0] for b in boxes), max(b[3] - b[1] for b in boxes)
    sheet, rows, x = Image.new("RGBA", (width, height)), [], 0
    for f, i, d, b in zip(frames, indices, durations, boxes):
        w, h = b[2] - b[0], b[3] - b[1]
        sheet.paste(f.crop(b), (x, 0))
        support = foot_point(f)
        rows.append({"filename": f"frame-{i}", "frame": dict(x=x, y=0, w=w, h=h),
                     "rotated": False, "trimmed": trim, "sourceSize": dict(w=f.width, h=f.height),
                     "spriteSourceSize": dict(x=b[0], y=b[1], w=w, h=h), "duration": d,
                     "forja": {"source_frame": i, "pivot": pivot, "ground_y": pivot[1],
                               "support": list(support) if support else None, "pixels_sha256": image_sha(f)}})
        x += w
    return sheet, {"frames": rows, "meta": {"app": "forja", "scale": "1", "size": dict(w=width, h=height),
        "frameTags": [{"name": tag[0], "from": 0, "to": len(rows) - 1, "direction": tag[3]}]}}


def reconstruct(sheet: Image.Image, row: dict) -> Image.Image:
    size, src, rect = row["sourceSize"], row["spriteSourceSize"], row["frame"]
    values = [size[k] for k in ("w", "h")] + [v[k] for v in (src, rect) for k in ("x", "y", "w", "h")]
    if any(type(v) is not int for v in values) or row.get("rotated") is not False:
        raise ValueError("quadro: geometria invalida ou rotacao nao suportada")
    if not (0 < size["w"] <= 4096 and 0 < size["h"] <= 4096 and
            0 <= src["x"] < src["x"] + src["w"] <= size["w"] and
            0 <= src["y"] < src["y"] + src["h"] <= size["h"] and
            0 <= rect["x"] < rect["x"] + rect["w"] <= sheet.width and
            0 <= rect["y"] < rect["y"] + rect["h"] <= sheet.height and
            (src["w"], src["h"]) == (rect["w"], rect["h"])):
        raise ValueError("quadro: recorte fora do canvas ou da folha")
    out = Image.new("RGBA", (size["w"], size["h"]))
    out.paste(sheet.crop((rect["x"], rect["y"], rect["x"] + rect["w"], rect["y"] + rect["h"])),
              (src["x"], src["y"]))
    return out


def export(source: str | Path, out: str | Path, kind: str, effect_layers=(), trim: bool = False) -> dict:
    source, out = Path(source).resolve(), Path(out).resolve()
    if out == source.parent or out in source.parents:
        raise ValueError("a prova usa uma pasta separada do mestre")
    sprite = ase.read(source)
    actor, final, tags, pivot = prepare(sprite, kind, list(effect_layers))
    out.mkdir(parents=True, exist_ok=True)
    (out / "source.aseprite").write_bytes(source.read_bytes())
    files, actions = ["source.aseprite"], []
    for n, (tag, play) in enumerate(zip(tags, timeline.playback(tags))):
        indices = list(range(tag[1], tag[2] + 1))
        entry = {"name": tag[0], "indices": indices, "playback": play["indices"], "loop": play["loop"],
                 "repeat": sprite.tags[n].repeat, "direction": tag[3]}
        for variant, frames in (("actor", actor), ("final", final)):
            stem = f"action-{n:03d}-{variant}"
            sheet, data = pack([frames[i] for i in indices], indices,
                               [sprite.durations[i] for i in indices], tag, pivot, trim)
            data["meta"]["image"] = stem + ".png"
            data["meta"]["frameTags"][0]["repeat"] = str(sprite.tags[n].repeat)
            sheet.save(out / (stem + ".png"))
            proof_io.save(out / (stem + ".json"), data)
            entry[variant] = {"png": stem + ".png", "json": stem + ".json"}
            files += [stem + ".png", stem + ".json"]
        actions.append(entry)
    records = [{"index": i, "duration_ms": sprite.durations[i], "pivot": pivot,
                "actor_sha256": image_sha(a), "final_sha256": image_sha(b)} for i, (a, b) in enumerate(zip(actor, final))]
    data = {"schema": SCHEMA, "kind": kind, "canvas": [sprite.width, sprite.height], "pivot": pivot,
            "source": "source.aseprite", "effect_layers": list(effect_layers), "frames": records,
            "actions": actions, "study": study.context(), "trim": trim, "release_ready": False,
            "runtime_integration": "not_evaluated", "native_authorship": "not_proven_by_export"}
    return proof_io.seal(data, out, files)


def verify(path: str | Path) -> dict:
    path = Path(path)
    data, errors = proof_io.check(path, SCHEMA)
    if not errors:
        required = [data["source"]] + [a[v][k] for a in data["actions"] for v in ("actor", "final") for k in ("png", "json")]
        if data.get("authority", {}).get("reference"):
            required.append(data["authority"]["reference"])
        if any(name not in data["files"] for name in required):
            errors.append("ficheiro da prova sem hash no manifesto")
    if errors:
        return {"ok": False, "blocking": errors, "release_ready": False}
    sprite = ase.read(proof_io.resolve(path.parent, data["source"]))
    actor, final, tags, pivot = prepare(sprite, data["kind"], data["effect_layers"])
    plays = timeline.playback(tags)
    expected_records = [{"index": i, "duration_ms": sprite.durations[i], "pivot": pivot,
                         "actor_sha256": image_sha(a), "final_sha256": image_sha(b)}
                        for i, (a, b) in enumerate(zip(actor, final))]
    if data["frames"] != expected_records or data["canvas"] != [sprite.width, sprite.height] or data["pivot"] != pivot:
        errors.append("manifesto diverge dos pixels, tempos, canvas ou pivot do mestre")
    if len(data["actions"]) != len(tags) or len(data["frames"]) != len(actor):
        errors.append("acoes ou quadros omitidos")
    for action, tag, play in zip(data["actions"], tags, plays):
        indices = list(range(tag[1], tag[2] + 1))
        if (action["indices"] != indices or action["playback"] != play["indices"] or action["name"] != tag[0] or
                action["loop"] != play["loop"] or action["direction"] != tag[3] or
                action["repeat"] != next(t.repeat for t in sprite.tags if t.name == tag[0])):
            errors.append("ordem da acao mudou: " + tag[0])
        for variant, frames in (("actor", actor), ("final", final)):
            locations = action[variant]
            with Image.open(proof_io.resolve(path.parent, locations["png"])) as im:
                sheet = im.convert("RGBA")
            meta = json.loads(proof_io.resolve(path.parent, locations["json"]).read_text(encoding="utf-8"))
            if len(meta["frames"]) != len(indices):
                errors.append("export omite quadros: " + tag[0])
            expected_tag = {"name": tag[0], "from": 0, "to": len(indices) - 1, "direction": tag[3],
                            "repeat": str(next(t.repeat for t in sprite.tags if t.name == tag[0]))}
            if meta["meta"].get("frameTags") != [expected_tag]:
                errors.append("tags exportadas mudaram: " + tag[0])
            for row, i in zip(meta["frames"], indices):
                image = reconstruct(sheet, row)
                if (image.size != frames[i].size or image_sha(image) != image_sha(frames[i]) or
                        row["duration"] != sprite.durations[i] or row["forja"]["pivot"] != pivot or
                        row["forja"]["source_frame"] != i or row["forja"]["ground_y"] != pivot[1] or
                        row["forja"]["pixels_sha256"] != image_sha(frames[i]) or
                        row["forja"]["support"] != (list(foot_point(frames[i])) if foot_point(frames[i]) else None)):
                    errors.append(f"{tag[0]}/{variant}/{i}: pixels, tempo ou pivot divergentes")
    return {"ok": not errors, "blocking": errors, "release_ready": False,
            "runtime_integration": "not_evaluated", "frames_checked": sprite.frames}
