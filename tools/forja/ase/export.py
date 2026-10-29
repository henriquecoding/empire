"""Exportar folha PNG + JSON como a CLI do Aseprite (`--sheet --data --format json-array`), sem o Aseprite (FORJA-13).

O formato reproduz-se pela saida observada da CLI 1.3.18.6, nao pelo codigo dela: quadros em linha (`rows`,
`horizontal`; com `columns`, N por linha) ou em coluna (`columns`, `vertical`); o nome de cada quadro e
«titulo [(camada)] quadro.aseprite» (sem numero quando ha um so quadro); a folha e RGBA (`RGBA8888`), ou a paleta
(`I8`) num sprite Indexed. `--layer` deixa so essa camada, que fica visivel com os grupos acima dela (os
descendentes escondidos continuam escondidos), e so esses se listam. `frameTags`, `layers` e `slices` como a CLI os
escreve: a repeticao em texto e so quando existe, a cor em `#rrggbbaa` (e so quando ha), as slices pela ordem inversa
a do ficheiro (a do Aseprite em memoria), as camadas escondidas fora, a opacidade e a mistura so nas camadas de
imagem, e cada cel so com o que nao e omissao (num grupo, as dos descendentes). `app` e `version` dizem que foi a
Forja; o resto confere-se contra a CLI na prova de conformidade.
"""
from __future__ import annotations

from PIL import Image

from .blend import MODES
from .describe import plain
from .model import DIRECTIONS, Sprite, UserData
from .render import _chain, forced, render

NAMES = {"hue": "hsl_hue", "saturation": "hsl_saturation", "color": "hsl_color", "luminosity": "hsl_luminosity"}


def _hex(c) -> str:
    return "#" + "".join(f"{v:02x}" for v in c)


def _user(u: UserData, out: dict) -> dict:
    if u.color and u.color[3]:
        out["color"] = _hex(u.color)
    if u.text:
        out["data"] = u.text
    if u.properties.get(""):
        out["properties"] = plain(u.properties[""])
    return out


def _cels(sprite: Sprite, indices: list[int]) -> list[dict]:
    found: dict[int, dict] = {}
    for index in indices:
        for frame in range(sprite.frames):
            cel = sprite.cels.get((index, frame))
            if cel is None:
                continue
            src = sprite.cels[(index, cel.link)] if cel.link is not None else cel
            e = {"frame": frame}
            if cel.opacity != 255:
                e["opacity"] = cel.opacity
            if cel.z:
                e["zIndex"] = cel.z
            _user(src.user, e)
            if len(e) > 1:
                found.setdefault(frame, e)
    return [found[f] for f in sorted(found)]


def _layers(sprite: Sprite, chosen: set[int] | None) -> list[dict]:
    parents = sprite.parents()
    shown = forced(chosen, parents)
    out = []
    for i, layer in enumerate(sprite.layers):
        if chosen is not None and i not in shown:  # com --layer: a camada e os grupos acima dela
            continue
        if chosen is None and not all(sprite.layers[j].has("visible") for j in _chain(i, parents)):
            continue
        e: dict = {"name": layer.name}
        if parents[i] is not None:
            e["group"] = sprite.layers[parents[i]].name
        if layer.kind != "group":
            mode = MODES[layer.blend]
            e.update(opacity=layer.opacity, blendMode=NAMES.get(mode, mode))
        _user(layer.user, e)
        kids = [j for j in range(len(sprite.layers)) if i in _chain(j, parents)[1:]
                and sprite.layers[j].kind != "group"] if layer.kind == "group" else [i]
        cels = _cels(sprite, kids)
        if cels:
            e["cels"] = cels
        out.append(e)
    return out


def _tags(sprite: Sprite) -> list[dict]:
    out = []
    for t in sprite.tags:
        e = {"name": t.name, "from": t.first, "to": t.last, "direction": DIRECTIONS[t.direction]}
        if t.repeat:
            e["repeat"] = str(t.repeat)
        _user(t.user, e)
        out.append(e)
    return out


def _slices(sprite: Sprite) -> list[dict]:
    out = []
    for s in reversed(sprite.slices):  # o Aseprite guarda-as ao contrario da ordem do ficheiro
        e = _user(s.user, {"name": s.name})
        e["keys"] = []
        for k in s.keys:
            key = {"frame": k.frame, "bounds": {"x": k.x, "y": k.y, "w": k.w, "h": k.h}}
            if k.center and k.w:
                key["center"] = dict(zip("xywh", k.center))
            if k.pivot and k.w:
                key["pivot"] = dict(zip("xy", k.pivot))
            e["keys"].append(key)
        out.append(e)
    return out


def sheet(sprite: Sprite, title: str, image: str, layer: str | None = None, kind: str = "rows",
          columns: int | None = None, tags: bool = True, layers: bool = False, slices: bool = False
          ) -> tuple[Image.Image, dict]:
    """A folha e o JSON (`json-array`) da CLI do Aseprite para este sprite."""
    chosen = None
    if layer is not None:
        chosen = {i for i, lay in enumerate(sprite.layers) if lay.name == layer}
        if not chosen:
            raise ValueError(f"camada {layer!r} nao existe ({', '.join(lay.name for lay in sprite.layers)})")
    w, h, n = sprite.width, sprite.height, sprite.frames
    across = kind in ("rows", "horizontal")
    per = columns or (n if across else 1)
    cols, rows = (per, -(-n // per)) if across else (-(-n // (columns or n)), columns or n)
    indexed = sprite.depth == 8
    out = Image.new("P" if indexed else "RGBA", (cols * w, rows * h), sprite.transparent if indexed else 0)
    frames = []
    for f in range(n):
        x, y = ((f % per) * w, (f // per) * h) if across else ((f // (columns or n)) * w, (f % (columns or n)) * h)
        img = render(sprite, f, chosen, native=indexed)
        if indexed:
            out.putpalette(img.getpalette())
            out.info["transparency"] = img.info.get("transparency")
        out.paste(img, (x, y))
        label = f"{title} ({layer})" if layer is not None else title
        frames.append({"filename": f"{label} {f}.aseprite" if n > 1 else f"{label}.aseprite",
                       "frame": {"x": x, "y": y, "w": w, "h": h}, "rotated": False, "trimmed": False,
                       "spriteSourceSize": {"x": 0, "y": 0, "w": w, "h": h}, "sourceSize": {"w": w, "h": h},
                       "duration": sprite.durations[f]})
    meta = {"app": "forja (Empire)", "version": "FORJA-13, formato da CLI do Aseprite 1.3.18.6", "image": image,
            "format": "I8" if indexed else "RGBA8888", "size": {"w": out.width, "h": out.height}, "scale": "1"}
    if tags:
        meta["frameTags"] = _tags(sprite)
    if layers:
        meta["layers"] = _layers(sprite, chosen)
    if slices:
        meta["slices"] = _slices(sprite)
    return out, {"frames": frames, "meta": meta}
