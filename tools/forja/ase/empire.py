"""As convencoes do Empire num .aseprite (FORJA-14): slots, variantes, camadas de trabalho, tags e pivot, e a
exportacao por camada do `tools/export_aseprite.sh`, feita sem o Aseprite.

Regras: ASSET_BIBLE §2 (os slots da §58 com o `storage` da Q-153; `Knight`, `References` e `Background` sao de
trabalho e nao se exportam; um ficheiro por corpo, uma folha por camada) e §3 (camadas `<slot>` ou
`<slot>_<variante>`; tags do ANIMATION_BIBLE em minusculas; num edificio, tags = estados), e RUNTIME_ART (as tags
`<accao>_left`/`_right`). Os slots e as tags da Animation Bible sao de figuras (contrato com ancora nos pes); uma
cena da Forja (forja.scene/1 nos dados) confere as tags contra os estados dela. O que o lint acha e informacao para
o autor: so impede a exportacao o que a CLI nao consegue separar (duas camadas com o mesmo nome) e uma tela
diferente da do contrato pedido.
"""
from __future__ import annotations

import re

from PIL import Image

from .. import contracts
from .describe import plain
from .export import sheet
from .model import Sprite, UserData

SLOTS = {"shadow": -1, "body": 0, "storage": 1, "head": 2, "face": 3, "weapon": 4, "shield": 4, "overlay": 5}
WORK = ("Knight", "References", "Background")
LEGACY = {"Body": "body", "Equipments": "storage", "Face": "face", "Sword": "weapon", "Arms and Weapons": "weapon",
          "Shield": "shield"}  # a tabela de correspondencia da §2
SIDES = ("_left", "_right")
PIVOTS = ("pivot", "ground_pivot")  # a da Forja e a dos V15 do dono (Q-302)
SNAKE = re.compile(r"^[a-z][a-z0-9]*(_[a-z0-9]+)*$")


def slot(name: str) -> str | None:
    """O slot de uma camada com nome da §3 (`weapon_bow_l1` -> `weapon`); None se o nome nao e de slot."""
    head = name.split("_", 1)[0]
    return head if head in SLOTS and SNAKE.match(name) else None


def layer_user(name: str) -> UserData:
    """Os dados que a Forja poe numa camada de slot: o slot e a variante, para o importador nao adivinhar."""
    s = slot(name)
    if s is None:
        return UserData()
    props = {"slot": s}
    if name != s:
        props["variant"] = name[len(s) + 1:]
    return UserData(properties={"": props})


def z_order(name: str) -> tuple[int, int]:
    """A ordem Z da §58 (de baixo para cima); o que nao e slot fica por cima, na ordem dada."""
    s = slot(name)
    return (0, SLOTS[s]) if s else (1, 0)


def listed(sprite: Sprite) -> list[int]:
    """As camadas que `aseprite --list-layers` lista: as visiveis (com os pais), cada grupo depois dos filhos."""
    parents = sprite.parents()
    order: list[int] = []

    def walk(parent: int | None) -> None:
        for j in (j for j in range(len(sprite.layers)) if parents[j] == parent):
            if sprite.layers[j].has("visible"):
                walk(j)
                order.append(j)

    walk(None)
    return order


def export_name(layer: str) -> str:
    """O nome da camada no ficheiro exportado, como o script o faz (`tr '[:upper:] ' '[:lower:]_'`)."""
    return layer.lower().replace(" ", "_")


def export_layers(sprite: Sprite, title: str, slices: bool = False) -> list[tuple[str, Image.Image, dict]]:
    """O que `tools/export_aseprite.sh` escreve: por cada camada listada fora das de trabalho, a folha em linha e o
    JSON com as tags (`<titulo>_<camada>.png/.json`). Com `slices`, o JSON leva tambem as slices (o pivot)."""
    out = []
    for i in listed(sprite):
        name = sprite.layers[i].name
        if name in WORK:
            continue
        stem = f"{title}_{export_name(name)}"
        img, data = sheet(sprite, title, f"{stem}.png", layer=name, kind="rows", slices=slices)
        out.append((stem, img, data))
    return out


def _tag_base(name: str) -> str:
    for side in SIDES:
        if name.endswith(side):
            return name[:-len(side)]
    return name


def _tags(sprite: Sprite, add, states: list[str] | None, figure: bool) -> None:
    bible, fps = contracts.tags(), contracts.load_data()["fps"]
    covered: set[int] = set()
    for t in sprite.tags:
        span = set(range(t.first, t.last + 1))
        if covered & span:
            add("tag_overlap", "warn", f"a tag {t.name!r} repete quadros de outra tag: cada tag e uma animacao")
        covered |= span
        if states is not None and t.name not in states:
            add("tag_state", "warn", f"{t.name!r} nao e um estado do contrato da cena ({', '.join(states)})")
        if not figure:
            continue
        base = _tag_base(t.name)
        if not SNAKE.match(t.name) or base not in bible:
            add("tag_name", "warn", f"{t.name!r} nao e nome do ANIMATION_BIBLE em minusculas (com _left/_right)")
            continue
        info = bible[base]
        if info.get("frames") and len(span) != info["frames"]:
            add("tag_frames", "info", f"{t.name!r}: {len(span)} quadros, o ANIMATION_BIBLE diz {info['frames']}")
        ms = round(1000 / info.get("fps", fps))
        odd = sorted({sprite.durations[f] for f in span if sprite.durations[f] != ms})
        if odd:
            add("tag_duration", "info", f"{t.name!r}: duracoes {odd} ms onde o ritmo da tag da {ms} ms")
    loose = [f for f in range(sprite.frames) if f not in covered]
    if loose and sprite.tags:
        add("untagged_frames", "warn", f"quadros fora de qualquer tag: {loose[:12]}")


def _layers(sprite: Sprite, add, figure: bool) -> list[dict]:
    out, names = [], [layer.name for layer in sprite.layers]
    shown = set(listed(sprite))
    for i, layer in enumerate(sprite.layers):
        name, s = layer.name, slot(layer.name)
        role = "work" if name in WORK else "slot" if s else "legacy" if name in LEGACY else "group" \
            if layer.kind == "group" else "other"
        exported = i in shown and name not in WORK
        out.append({"name": name, "role": role, "slot": s or LEGACY.get(name), "exported": exported})
        if names.count(name) > 1 and names.index(name) == i:
            add("duplicate_layer", "error", f"{names.count(name)} camadas chamam-se {name!r}: o --layer nao as separa")
        if role == "legacy":
            add("legacy_layer_name", "info", f"{name!r} e o nome antigo do slot {LEGACY[name]!r} (§2)")
        elif role == "other" and exported and figure:
            add("layer_name", "warn", f"{name!r} exporta-se mas nao e <slot> nem <slot>_<variante> (§3)")
        if (s or name in LEGACY) and i not in shown:
            add("slot_hidden", "warn", f"{name!r} esta escondida (ou o grupo dela): o export por camada salta-a")
        if name == "References" and not layer.has("reference"):
            add("reference_layer", "info", "References nao e camada de referencia: marca-a para nunca entrar num "
                                           "composto")
        if exported and layer.kind != "group" and (layer.blend or layer.opacity != 255):
            add("layer_blend", "warn", f"{name!r}: mistura {layer.blend} e opacidade {layer.opacity} ficam na folha "
                                       "dela; o jogo compoe as camadas por alfa normal")
        if exported and any(sprite.cels.get((i, f)) and sprite.cels[(i, f)].z for f in range(sprite.frames)):
            add("z_index", "warn", f"{name!r} muda de ordem por z-index: a folha por camada nao leva essa ordem")
    return out


def check(sprite: Sprite, kind: str | None = None) -> dict:
    """O .aseprite contra as convencoes do Empire (forja.ase_check/1)."""
    findings: list[dict] = []

    def add(code: str, severity: str, detail: str) -> None:
        findings.append({"code": code, "severity": severity, "detail": detail})

    props = plain(sprite.user.properties.get("", {})) if sprite.user else {}
    scene = props.get("schema") == "forja.scene/1"
    states = props.get("states") if scene else None
    figure = not scene and (kind is None or contracts.get(kind).anchor == "feet")
    layers = _layers(sprite, add, figure)
    _tags(sprite, add, states, figure)
    pivots = [s for s in sprite.slices if s.name in PIVOTS and s.keys and s.keys[0].pivot]
    if not pivots:
        add("pivot_slice", "info", "sem slice 'pivot' (nem 'ground_pivot') com ponto: o pivot vive so no contrato")
    if kind:
        c = contracts.get(kind)
        if c.canvas and (sprite.width, sprite.height) != tuple(c.canvas):
            add("canvas", "error", f"tela {sprite.width}x{sprite.height}, o contrato {kind} pede {c.canvas[0]}x"
                                   f"{c.canvas[1]}")
        if c.pivot and pivots:
            got = tuple(_pivot(pivots[0])["px"])
            if got != tuple(c.pivot):
                add("pivot", "warn", f"pivot {got}, o contrato {kind} diz {tuple(c.pivot)}")
    return {"schema": "forja.ase_check/1", "ok": not any(f["severity"] == "error" for f in findings),
            "asset": "scene" if scene else "figure" if figure else "other", "mode": sprite.mode,
            "size": [sprite.width, sprite.height], "frames": sprite.frames,
            "layers": layers, "exported": [export_name(sprite.layers[i].name) for i in listed(sprite)
                                           if sprite.layers[i].name not in WORK],
            "tags": [t.name for t in sprite.tags], "pivot": _pivot(pivots[0]) if pivots else None,
            "findings": findings}


def _pivot(s) -> dict:
    k = s.keys[0]
    return {"slice": s.name, "px": [k.x + k.pivot[0], k.y + k.pivot[1]]}
