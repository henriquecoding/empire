"""A native lighting study and its editable Aseprite source, from one PNG or an animation."""
from __future__ import annotations

import json
from hashlib import sha256
from pathlib import Path

from PIL import Image

from . import anim, ase, aseprite, contracts, pixel_lighter
from .ase.empire import LIGHT_MAPS
from .ase.export import sheet
from .ase.model import LAYER_FLAGS, Layer, Sprite
from .cmd_ase import outside_art
from .imageops import open_rgba, upscale

ASE_EXTENSIONS = (".ase", ".aseprite")
MAX_ATLAS_PIXELS = 16 * 1024 * 1024


def preset_for(kind: str) -> str:
    if kind == "building":
        return "architecture"
    if kind in ("tile", "parallax_far", "parallax_mid", "foreground"):
        return "terrain"
    if kind in ("free", "item", "prop", "fx", "ui"):
        return "object"
    return "character"


def _maps(sprite: Sprite) -> dict[str, int]:
    found = {}
    for i, layer in enumerate(sprite.layers):
        if layer.name not in LIGHT_MAPS:
            continue
        if layer.name in found or layer.kind != "image" or layer.level != 0 or layer.has("reference"):
            raise ValueError(f"luz: {layer.name} deve ser uma unica camada de imagem na raiz")
        found[layer.name] = i
        layer.flags &= ~LAYER_FLAGS["visible"]
    return found


def _validate(albedo: Image.Image, normal: Image.Image, mask: Image.Image, frame: int) -> None:
    alpha = albedo.getchannel("A").tobytes()
    if any(img.getchannel("A").tobytes() != alpha for img in (normal, mask)):
        raise ValueError(f"luz: alfa dos mapas diferente do albedo no quadro {frame}")
    if any(r != g or r != b for r, g, b, a in mask.get_flattened_data() if a):
        raise ValueError(f"luz: mascara deve ser cinzenta no quadro {frame}")
    if any(b < 128 or not 126 ** 2 <= sum((c - 127.5) ** 2 for c in (r, g, b)) <= 129 ** 2
           for r, g, b, a in normal.get_flattened_data() if a):
        raise ValueError(f"luz: normal fora do hemisferio visivel no quadro {frame}")


def _attach(sprite: Sprite, layers: dict[str, int], normals: list, masks: list) -> None:
    stack = ase.build((sprite.width, sprite.height),
                      [(Layer(name, flags=LAYER_FLAGS["editable"]), frames)
                       for name, frames in zip(LIGHT_MAPS, (normals, masks))])
    for local, layer in enumerate(stack.layers):
        index = layers.get(layer.name, len(sprite.layers))
        if index == len(sprite.layers):
            sprite.layers.append(layer)
        else:
            sprite.layers[index] = layer
            for f in range(sprite.frames):
                sprite.cels.pop((index, f), None)
        for f in range(sprite.frames):
            if (local, f) in stack.cels:
                sprite.cels[index, f] = stack.cels[local, f]


def export(source: str | Path, out: str | Path, *, preset: str, kind: str | None = None,
           edited: bool = False, frame: int = 0, light: tuple[int, int] | None = None) -> dict:
    path = Path(source).resolve()
    out = outside_art(out)
    outputs = {"albedo": out / "albedo.png", "normal": out / "normal.png", "mask": out / "light_mask.png",
               "surface": out / "surface.png", "preview": out / "preview.png", "aseprite": out / "source.aseprite",
               "json": out / "lighting.json"}
    if path in {p.resolve() for p in outputs.values()}:
        raise ValueError("luz: escolher uma pasta de saida que preserve a fonte")
    from_ase = path.suffix.lower() in ASE_EXTENSIONS
    if edited and not from_ase:
        raise ValueError("luz: --mapas-editados requer uma fonte Aseprite RGB")
    contract = contracts.get(kind) if kind else None
    if from_ase:
        sprite = ase.read(path)
    else:
        png = open_rgba(path)
        sprite = aseprite.assemble(png.size, {"body": [png]}, pivot=contract.pivot if contract else None, kind=kind)
    size = sprite.width, sprite.height
    if contract and contract.canvas and size != contract.canvas:
        raise ValueError(f"luz: tela {size} diferente da tela {contract.canvas} de {kind}")
    if not 0 <= frame < sprite.frames:
        raise ValueError(f"luz: quadro {frame} fora da timeline com {sprite.frames} quadros")
    if sprite.width * sprite.height > pixel_lighter.MAX_PIXELS:
        raise ValueError(f"luz: quadro nativo acima de {pixel_lighter.MAX_PIXELS} pixels")
    cols = min(sprite.frames, 8)
    if cols * (-(-sprite.frames // cols)) * sprite.width * sprite.height > MAX_ATLAS_PIXELS:
        raise ValueError("luz: atlas demasiado grande, exportar por acao")
    layers = _maps(sprite)
    if edited and (sprite.depth != 32 or set(layers) != set(LIGHT_MAPS)):
        raise ValueError("luz: --mapas-editados requer as duas camadas de luz num .aseprite RGB")
    frames = [ase.render(sprite, f) for f in range(sprite.frames)] if from_ase else [png]
    normals, masks = [], []
    for f, albedo in enumerate(frames):
        if edited:
            n, m = (ase.render(sprite, f, {layers[name]}) for name in LIGHT_MAPS)
            _validate(albedo, n, m, f)
        else:
            n, m = pixel_lighter.generate(albedo, preset)
        normals.append(n)
        masks.append(m)
    original_depth = sprite.depth
    if original_depth != 32:
        companion = aseprite.assemble(size, {"body": frames}, sprite.durations)
        companion.tags, companion.slices, companion.grid = sprite.tags, sprite.slices, sprite.grid
        companion.pixel_ratio = sprite.pixel_ratio
        sprite, layers = companion, {}
    _attach(sprite, layers, normals, masks)

    out.mkdir(parents=True, exist_ok=True)
    aseprite.save(sprite, outputs["aseprite"])
    _, layout = sheet(sprite, path.stem, outputs["albedo"].name, columns=cols, layers=True, slices=True)
    for name, images in (("albedo", frames), ("normal", normals), ("mask", masks)):
        anim.strip(images, cols)[0].save(outputs[name])
    packed = Image.new("RGB", (layout["meta"]["size"]["w"], layout["meta"]["size"]["h"]), (128, 128, 255))
    for n, m, entry in zip(normals, masks, layout["frames"]):
        rect = entry["frame"]
        packed.paste(pixel_lighter.pack_surface(n, m), (rect["x"], rect["y"]))
    packed.save(outputs["surface"])
    w, h = size
    left, right = light or (-w // 4, h // 3), (w + w // 4, h // 3)
    shots = [frames[frame], *(pixel_lighter.preview(frames[frame], normals[frame], masks[frame], p)
                              for p in (left, right))]
    upscale(anim.strip(shots)[0], 4).save(outputs["preview"])
    result = {"ok": True, "schema": "forja.lighting/1", "preset": preset, "edited_maps": edited,
              "source_sha256": sha256(path.read_bytes()).hexdigest(), "source_depth": original_depth,
              "source_layers_preserved": original_depth == 32, "canvas": list(size), "frames": len(frames),
              "atlas": layout, "preview_frame": frame, "preview_lights": [left, right],
              "artistic_review": "pending", "files": {k: str(p) for k, p in outputs.items()}}
    outputs["json"].write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return result


def after_forge(files: dict, out: Path, kind: str) -> None:
    result = export(files["aseprite"], out / "lighting" / Path(files["aseprite"]).stem,
                    preset=preset_for(kind))
    files["lighting"] = result["files"]["json"]
    files["lit_aseprite"] = result["files"]["aseprite"]
