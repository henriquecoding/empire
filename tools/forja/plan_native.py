"""Planeamento PixelLab separado: geracao nativa e conversao nativa sao pedidos diferentes."""
from __future__ import annotations

from . import guides, native_prompt as native_mod, prompts, refs as refs_mod
from .backends import pixellab_api, pixellab_convert
from .imageops import png_bytes as png


def prepare(d: dict, c, refs, palette, model, guides_mode, init_strength, seed) -> list[tuple[str, bytes]]:
    model = d["model"] = model or "pixflux"
    if model == pixellab_convert.MODEL:
        if palette is not None:
            d['notes'].append('image-to-pixelart nao recebe color_image: paleta so no acabamento, nao no pedido')
        return pixellab_convert.prepare(d, c, refs, init_strength, seed)
    caps = pixellab_api.CAPS.get(model)
    if caps is None:
        d["errors"].append(f"modelo PixelLab desconhecido: {model!r} (use {', '.join(pixellab_api.CAPS)})")
        return []
    if d["frames"] > 1:
        d["errors"].append("PixelLab: os endpoints create-image-* geram uma imagem estatica; a animacao "
                           "nativa usa forja anim-plan e animar com um mestre nativo; text-v3 pede contagens "
                           "pares e skeleton-v3 recebe poses observadas. Para prancha use openai|gemini")
    if not c.canvas:
        d["errors"].append(f"{d['kind']}: contrato sem tela fixa; o PixelLab precisa de um tamanho nativo")
        return []
    w, h = (v // c.cluster for v in c.canvas)
    params = prompts.pixellab_params(d["subject"], c, (w, h), d["facing"], d['mode'])
    kw = {k: v for k, v in params.items() if k not in ("description", "image_size")}
    for name in [k for k in kw if k not in caps["fields"]]:
        d["notes"].append(f"{model} nao tem o campo {name}: nao enviado")
        kw.pop(name)
    images: list[tuple[str, bytes]] = []
    for role, field_name in (("identity", "init_image"), ("style", "style_image")):
        mine = [data for r, data in refs if refs_mod.family(r) == role]
        if not mine:
            continue
        if field_name not in caps["images"] or len(mine) > 1:
            d["errors"].append(f"{model}: aceita no maximo uma {field_name}" if field_name in caps["images"]
                               else f"{model} nao aceita {field_name} (papel {role}); use pixflux ou bitforge")
            continue
        images.append((field_name, mine[0]))
    if any(f == "init_image" for f, _ in images):
        kw["init_image_strength"] = 300 if init_strength is None else init_strength
        d["notes"].append("o create-image do PixelLab nao tem campo de identidade: a referencia "
                          f"({', '.join(d['authority']['states'])}) vai como init_image (imagem inicial), forca "
                          f"{kw['init_image_strength']} — maior preserva mais")
    if palette is not None and guides_mode != "none" and "color_image" in caps["images"]:
        images.append(("color_image", png(guides.color_image(palette))))
        d["notes"].append(f"paleta forcada pelo color_image ({len(palette)} cores)")
    elif palette is not None:
        d["notes"].append("o modelo nao recebe a paleta: aplica-se so no acabamento")
    if seed is not None:
        kw["seed"] = seed
    d["errors"] += pixellab_api.check(model, w, h, **kw, **dict(images))
    d["request"] = {"endpoint": f"{pixellab_api.BASE}/create-image-{model}", "width": w, "height": h,
                    "params": kw, "spec_sha256": pixellab_api.SPEC_SHA256}
    d["prompt"] = native_prompt(d, c, palette)
    d["expect"] = {"kind": d["kind"], "cells": [w, h], "content": [0, 0, w, h], "scale": 1, "scale_exact": True,
                   "grid": "native", "layout": [1, 1], "frames": 1, "tags": None, "background": "transparent",
                   "size": [w, h], "cluster": c.cluster, "attached": [r for r, _ in images]}
    d["authoring"] = "generated_native"
    return images



def native_prompt(d: dict, contract, palette) -> str:
    built = native_mod.build(d['subject'], contract, palette, d['facing'], d['mode'], d['fidelity_prompt'])
    d.update(constraints=built['constraints'], implicit=built['implicit'])
    return built['prompt']
