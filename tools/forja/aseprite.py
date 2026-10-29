"""Escrever e conferir o .aseprite das entregas da Forja (`sheet`, `anim`, `aseprite`, `forge --aseprite`).

O formato e o de `tools/forja/ase` (FORJA-13): o que a Forja escreve abre no Aseprite 1.3.18.6 igual, provado
contra o aplicativo compilado (docs/art/research/2026-10-29-forja-aseprite/) e repetido no CI sem ele
(tools/forja/tests/test_ase_conformidade.py). Cada camada de slot leva o slot e a variante nos dados; os slots
empilham-se pela ordem Z da §58; a camada `References` entra como camada de referencia (o Aseprite nunca a compoe
nem a exporta); um quadro igual ao anterior da mesma camada fica cel ligada; uma tag do ANIMATION_BIBLE sem ciclo
toca uma vez; o pivot e a slice `pivot`. Abrir ESTE ficheiro no aplicativo continua a ser outra etapa
(`opened_in_aseprite_app`, o guia de personagens §6).
"""
from __future__ import annotations

import struct
from pathlib import Path

from PIL import Image

from . import contracts
from .ase import empire, model
from .ase import read as read_ase
from .ase import render
from .ase import write as write_ase
from .ase.build import sprite as build_sprite

DIRECTIONS = {name: i for i, name in enumerate(model.DIRECTIONS)}
REFERENCE = "References"


def tag(name: str, first: int, last: int, direction: str = "forward") -> model.Tag:
    """Uma tag; a do ANIMATION_BIBLE sem ciclo (`loop: false`, como `die`) repete uma vez."""
    base = name.removesuffix("_left").removesuffix("_right")
    loop = (contracts.tag(base) or {}).get("loop", True)
    return model.Tag(name, first, last, DIRECTIONS.get(direction, 0), 0 if loop else 1)


def pivot_slice(size: tuple[int, int], pivot: tuple[int, int], name: str = "pivot") -> model.Slice:
    """A slice da tela inteira com o pivot (no Aseprite, relativo a slice: aqui, a origem da tela)."""
    return model.Slice(name, [model.SliceKey(0, 0, 0, size[0], size[1], None, tuple(pivot))])


def assemble(size: tuple[int, int], layers: dict[str, list[Image.Image | None]], durations: list[int] | None = None,
             tags: list[tuple[str, int, int, str]] | None = None, palette: list[tuple] | None = None,
             pivot: tuple[int, int] | None = None, reference: Image.Image | None = None,
             kind: str | None = None) -> model.Sprite:
    """O sprite de um corpo: uma camada por slot (pela ordem Z da §58), uma tag por animacao, o pivot em slice."""
    n = max(len(frames) for frames in layers.values())
    if any(len(frames) not in (1, n) for frames in layers.values()):
        raise ValueError("todas as camadas de um corpo partilham o numero de quadros (ASSET_BIBLE §2)")
    order = sorted(layers, key=empire.z_order)
    stack: list[tuple] = []
    if reference is not None:
        stack.append((model.Layer(REFERENCE, flags=1 | 64), [reference]))
    for name in order:
        frames = layers[name] if len(layers[name]) == n else layers[name] * n
        stack.append((model.Layer(name, user=empire.layer_user(name)), frames))
    pal = [(*c[:3], c[3] if len(c) > 3 else 255) for c in palette] if palette else None
    sprite = build_sprite(size, stack, durations or [100] * n, palette=pal)
    sprite.tags = [tag(*t) for t in tags or []]
    if pivot:
        sprite.slices = [pivot_slice(size, pivot)]
    if kind:
        sprite.user = model.UserData(properties={"": {"kind": kind, "made_by": "forja"}})
    return sprite


def tilemap(sheet: Image.Image, size: int, indices: list[list[int]], name: str = "wang",
            layer: str = "map") -> model.Sprite:
    """Um conjunto Wang de 16 (`tiles.wang16`) como tileset do Aseprite — a peca 0 e a vazia do formato, a peca k+1
    e o indice k — e uma camada tilemap com o mapa dado, para editar as pecas no modo Tilemap sem as reordenar."""
    strip = Image.new("RGBA", (size, size * 17))
    for k in range(16):
        x, y = (k % 4) * size, (k // 4) * size
        strip.paste(sheet.crop((x, y, x + size, y + size)), (0, (k + 1) * size))
    rows, cols = len(indices), len(indices[0])
    sprite = model.Sprite(cols * size, rows * size, durations=[100], grid=(0, 0, size, size))
    sprite.tilesets = [model.Tileset(0, name, size, size, 17, pixels=strip.tobytes())]
    sprite.layers = [model.Layer(layer, "tilemap", tileset=0)]
    cells = [k + 1 for row in indices for k in row]
    sprite.cels[(0, 0)] = model.Cel(0, 0, width=cols, height=rows, pixels=struct.pack(f"<{len(cells)}I", *cells),
                                    tilemap={"bits": 32, "id": model.TILE_ID, "xflip": model.TILE_XFLIP,
                                             "yflip": model.TILE_YFLIP, "dflip": model.TILE_DFLIP})
    return sprite


def write(path: str | Path, size: tuple[int, int], layers: list[str],
          frames: list[dict[int, Image.Image]], durations: list[int] | None = None,
          tags: list[tuple[str, int, int, str]] | None = None,
          palette: list[tuple[int, int, int]] | None = None,
          slices: list[tuple[str, tuple[int, int, int, int], tuple[int, int] | None]] | None = None,
          grid: tuple[int, int] = (0, 0)) -> Path:
    """`frames[i]` mapeia indice de camada -> imagem do tamanho da tela; as camadas ficam pela ordem dada."""
    stack = [(model.Layer(name, user=empire.layer_user(name)), [cels.get(k) for cels in frames])
             for k, name in enumerate(layers)]
    pal = [(*c[:3], 255) for c in palette] if palette else None
    sprite = build_sprite(size, stack, durations or [100] * len(frames), palette=pal)
    sprite.tags = [tag(*t) for t in tags or []]
    for name, (x, y, w, h), pivot in slices or []:
        rel = (pivot[0] - x, pivot[1] - y) if pivot else None
        sprite.slices.append(model.Slice(name, [model.SliceKey(0, x, y, w, h, None, rel)]))
    if grid != (0, 0):
        sprite.grid = (0, 0, grid[0], grid[1])
    return save(sprite, path)


def save(sprite: model.Sprite, path: str | Path) -> Path:
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    write_ase(sprite, path)
    return path


def from_frames(path: str | Path, frames: list[Image.Image], layer: str = "body",
                durations: list[int] | None = None, tags=None, palette=None, pivot=None) -> Path:
    """O caso comum: uma camada, um quadro por imagem; o pivot vira a slice `pivot`."""
    size = frames[0].size
    slices = [("pivot", (0, 0, size[0], size[1]), pivot)] if pivot else None
    return write(path, size, [layer], [{0: f} for f in frames], durations, tags, palette, slices)


def verify(path: str | Path, frames: list[Image.Image] | None, layers: dict[str, list] | None = None) -> dict:
    """Le o ficheiro com o leitor exato e compara cada quadro composto, pixel a pixel, com as imagens (None: sem
    composto a comparar); com `layers`, compara cada camada sozinha (como o export por camada a ve) com os seus."""
    src = read_ase(path)
    equal = None if frames is None else src.frames == len(frames) and all(
        render(src, i).tobytes() == f.convert("RGBA").tobytes() for i, f in enumerate(frames))
    out = {"frames": src.frames, "layers": [layer.name for layer in src.layers],
           "tags": {t.name: {"from_frame": t.first, "to_frame": t.last, "direction": t.direction,
                             "repeat": t.repeat} for t in src.tags},
           "durations": list(src.durations), "pixel_equal": equal, "opened_in_aseprite_app": False}
    if layers:
        names = [layer.name for layer in src.layers]
        out["layer_equal"] = {name: name in names and _layer_equal(src, names.index(name), images)
                              for name, images in layers.items()}
    return out


def _layer_equal(src: model.Sprite, index: int, images: list[Image.Image | None]) -> bool:
    blank = Image.new("RGBA", (src.width, src.height))
    for f in range(src.frames):
        img = images[f] if len(images) > 1 else images[0]  # um quadro so repete-se (a sombra)
        if render(src, f, {index}).tobytes() != (img or blank).convert("RGBA").tobytes():
            return False
    return True
