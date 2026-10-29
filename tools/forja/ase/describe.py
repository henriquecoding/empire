"""O sprite descrito na forma em que o proprio Aseprite o descreve (o `ler.lua` da conformidade), e a diferenca
entre duas descricoes (FORJA-14).

Serve a prova: o mesmo ficheiro lido pela Forja e pelo Aseprite tem de dar a mesma descricao — camadas e os pais,
flags, mistura, opacidade, cels (posicao, tamanho, opacidade, z-index), dados e propriedades de cada objeto, tags,
slices, duracoes, paleta e tilesets.
"""
from __future__ import annotations

import uuid

from .model import BYTES, Sprite, Typed, UserData

EMPTY = ({}, [])


def plain(value):
    """Uma propriedade em JSON, como o Aseprite a converte: ponto {x, y}, tamanho {w, h}, retangulo {x, y, w, h}."""
    if isinstance(value, Typed):
        k, v = value.kind, value.value
        if k == 0x0E:
            return {"x": v[0], "y": v[1]}
        if k == 0x0F:
            return {"w": v[0], "h": v[1]}
        if k == 0x10:
            return {"x": v[0], "y": v[1], "w": v[2], "h": v[3]}
        if k == 0x13:
            return str(uuid.UUID(bytes=bytes(v)))
        return plain(v)
    if isinstance(value, dict):
        return {k: plain(v) for k, v in value.items()}
    if isinstance(value, (list, tuple)):
        return [plain(v) for v in value]
    if isinstance(value, bytes):
        return value.hex()
    return value


def user(u: UserData | None) -> dict:
    u = u or UserData()
    out: dict = {"properties": plain(u.properties.get("", {}))}
    if u.text:
        out["text"] = u.text
    if u.color and u.color[3]:
        out["color"] = list(u.color)
    return out


def _cels(sprite: Sprite, index: int) -> list[dict]:
    out = []
    layer = sprite.layers[index]
    for frame in range(sprite.frames):
        cel = sprite.cels.get((index, frame))
        if cel is None:
            continue
        src = sprite.cels[(index, cel.link)] if cel.link is not None else cel
        w, h = src.width, src.height
        if src.tilemap:
            ts = sprite.tilesets[layer.tileset or 0]
            w, h = w * ts.tile_w, h * ts.tile_h
        out.append({"frame": frame, "x": cel.x, "y": cel.y, "w": w, "h": h, "opacity": cel.opacity, "z": cel.z,
                    "user": user(src.user)})
    return out


def _key(k) -> dict:
    e = {"frame": k.frame, "bounds": {"x": k.x, "y": k.y, "w": k.w, "h": k.h}}
    if k.center:
        e["center"] = dict(zip("xywh", k.center))
    if k.pivot:
        e["pivot"] = dict(zip("xy", k.pivot))
    return e


def describe(sprite: Sprite, full: bool = False) -> dict:
    """A descricao do `ler.lua`; com `full`, tambem todas as chaves de cada slice (o Lua so ve a primeira)."""
    parents = sprite.parents()
    layers = []
    for i, layer in enumerate(sprite.layers):
        group = layer.kind == "group"
        valid = sprite.flags & (2 if group else 1)
        e = {"name": layer.name, "group": group, "tilemap": layer.kind == "tilemap",
             "visible": layer.has("visible"), "editable": layer.has("editable"),
             "background": layer.has("background"), "continuous": layer.has("prefer_linked"),
             "reference": layer.has("reference"), "collapsed": layer.has("collapsed"),
             "user": user(layer.user), "cels": [] if group else _cels(sprite, i)}
        if not group:  # o Lua do Aseprite nao expoe a mistura nem a opacidade de um grupo
            e.update(blend=layer.blend, opacity=layer.opacity if valid else 255)
        if parents[i] is not None:
            e["parent"] = sprite.layers[parents[i]].name
        if layer.kind == "tilemap":
            e["tileset"] = sprite.tilesets[layer.tileset or 0].name
        layers.append(e)
    slices = []
    for s in sprite.slices:
        k = s.keys[0]
        e = {"name": s.name, "bounds": {"x": k.x, "y": k.y, "w": k.w, "h": k.h}, "user": user(s.user)}
        if k.center:
            e["center"] = dict(zip("xywh", k.center))
        if k.pivot:
            e["pivot"] = dict(zip("xy", k.pivot))
        if full:
            e["keys"] = [_key(key) for key in s.keys]
        slices.append(e)
    slices.sort(key=lambda e: e["name"])  # a ordem interna das slices nao conta
    return {"width": sprite.width, "height": sprite.height, "mode": sprite.mode, "transparent": sprite.transparent,
            "durations": list(sprite.durations), "layers": layers,
            "tags": [{"name": t.name, "from": t.first, "to": t.last, "dir": t.direction, "repeats": t.repeat,
                      "user": user(t.user)} for t in sprite.tags],
            "slices": slices, "palette": [list(c[:4]) for c in sprite.palette(0)] if sprite.depth == 8 else [],
            "tilesets": [{"name": t.name, "w": t.tile_w, "h": t.tile_h, "count": t.count} for t in sprite.tilesets],
            "user": user(sprite.user), "bytes_per_pixel": BYTES[sprite.depth]}


def diff(a, b, path: str = "") -> list[str]:
    """As diferencas entre duas descricoes (vazia: iguais). Um {} e um [] vazios sao o mesmo."""
    if a in EMPTY and b in EMPTY:
        return []
    if isinstance(a, dict) and isinstance(b, dict):
        out = []
        for k in sorted(set(a) | set(b)):
            out += diff(a.get(k), b.get(k), f"{path}.{k}")
        return out
    if isinstance(a, list) and isinstance(b, list):
        if len(a) != len(b):
            return [f"{path}: {len(a)} contra {len(b)} elementos"]
        return [d for i, (x, y) in enumerate(zip(a, b)) for d in diff(x, y, f"{path}[{i}]")]
    if isinstance(a, float) or isinstance(b, float):
        return [] if a is not None and b is not None and abs(a - b) < 1e-6 else [f"{path}: {a!r} contra {b!r}"]
    return [] if a == b else [f"{path}: {a!r} contra {b!r}"]
