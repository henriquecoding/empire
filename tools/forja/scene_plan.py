"""O plano de uma cena por gerador, validado sem rede (FORJA-11). Devolve um `plan.Plan`: o `generate`/`auto` e os
jobs nao mudam.

- O tamanho vem da extensao do contrato de cena (`scene.py`), nunca de uma tela de personagem por omissao.
- O PixelLab desenha nas celulas da cena (uma celula de 2 px = um pixel do pedido); acima do lado ou da area do
  modelo o plano falha e propoe a particao em regioes com sobreposicao (`partition`) — aritmetica, nao costura: as
  regioes partilham o mestre, as coordenadas e a faixa protegida, e a juncao revê-se (relatorio de 28/10, §22).
- gpt-image e Gemini recebem o prompt de elevacao lateral, as referencias da cena no papel de cada uma, a regua em
  imagem e a amostra da paleta.
Uma referencia `approved` so vale pelo registo do dono (`refs`); uma rejeitada nao entra. Registada e enviada sao
campos diferentes (`sent`): uma referencia que o gerador nao pode receber da erro, nao fica so escrita no plano
(auditoria de 28/10, A5). No PixelLab o conceito vai como `init_image` (no tamanho do pedido) e o mestre de estilo
como `style_image` (bitforge); os outros papeis nao tem entrada no create-image.
"""
from __future__ import annotations

import hashlib
import math
from pathlib import Path

from PIL import Image

from . import guides, plan as plan_mod, refs as refs_mod, scene as scene_mod, scene_prompt
from .backends import gemini_images, openai_images, pixellab_api, sha
from .imageops import png_bytes as png
from .palette import Palette

PIXELLAB_INPUTS = {"asset_concept": "init_image", "style_master": "style_image"}


def partition(total: int, max_side: int, overlap: int, step: int = 1) -> list[list[int]]:
    """Regioes [inicio, fim) que cobrem `total` com lados <= `max_side` e pelo menos `overlap` em comum."""
    if total <= max_side:
        return [[0, total]]
    if overlap >= max_side:
        raise ValueError("a sobreposicao tem de ser menor do que o lado maximo")
    n = math.ceil((total - overlap) / (max_side - overlap))
    size = min(max_side, math.ceil((total + (n - 1) * overlap) / n / step) * step)
    starts = [round(i * (total - size) / (n - 1) / step) * step for i in range(n)]
    return [[s, s + size] for s in starts]


def references(sc: dict, base: Path, register: dict | None, d: dict) -> list[tuple[str, bytes]]:
    """As referencias da cena com o estado no registo (em `d`); a rejeitada fica de fora e da erro."""
    out = []
    for r in sc.get("references", []):
        with Image.open(base / r["file"]) as im:
            img = im.convert("RGBA")
        rec = refs_mod.lookup(register, img) if register else None
        state = rec["state"] if rec else refs_mod.UNRECORDED
        entry = {"role": r["role"], "path": str(base / r["file"]), "state": state, "id": rec["id"] if rec else None,
                 "crop": r.get("crop")}
        if state == "rejected":
            d["errors"].append(f"referencia {r['file']}: rejeitada no registo; nao entra no pedido")
        if r.get("crop"):
            img = img.crop(tuple(r["crop"]))
        data = png(img)
        entry["sha256"] = sha(data)
        d["references"].append(entry)
        if state != "rejected":
            out.append((r["role"], data))
    return out


def _attach(res: dict, refs: list, palette: Palette | None, guides_mode: str, expect: dict) -> list[tuple[str, bytes]]:
    images = list(refs)
    if guides_mode in ("auto", "layout", "all"):
        images.append(("ruler", png(scene_prompt.ruler_guide(res, expect))))
    if palette is not None and (guides_mode in ("palette", "all") or (guides_mode == "auto" and len(palette) > 24)):
        images.append(("palette", png(guides.palette_swatch(palette))))
    return images


def _built(d: dict, res: dict, palette, target: str, roles: list[str], geo: dict) -> dict:
    built = scene_prompt.build(res, target, roles, geo, palette)
    d.update(prompt=built["prompt"], expect=built["expect"], advice=built["advice"],
             constraints=built["constraints"], authoring="generated_high_resolution_then_grid_recovered")
    d["errors"] += [f"assunto: {c}" for c in built["conflicts"]]
    return built


def _openai(d, res, refs, palette, model, guides_mode) -> list:
    try:
        model = d["model"] = openai_images.check_model(model or openai_images.DEFAULT_MODEL)
    except ValueError as err:
        d["errors"].append(str(err))
        return []
    geo = scene_prompt.geometry(res, "gpt-image")
    images = _attach(res, refs, palette, guides_mode, scene_prompt.build(res, "gpt-image", [], geo)["expect"])
    built = _built(d, res, palette, "gpt-image", [r for r, _ in images], geo)
    try:
        openai_images.check_size(built["size"], model)
    except ValueError as err:
        d["errors"].append(str(err))
    d["request"] = {"endpoint": "images.edits" if images else "images.generations", "size": built["size"],
                    "background": "transparent"}
    return images


def _gemini(d, res, refs, palette, model, guides_mode, size) -> list:
    try:
        caps = gemini_images.capabilities(model)
    except ValueError as err:
        d["errors"].append(str(err))
        return []
    model = d["model"] = caps["model"]
    base = scene_prompt.geometry(res, "gemini")
    lw, lh = base["logical"]
    aspect, w, h = gemini_images.fit_aspect(lw, lh, caps["aspects"])
    ox, oy = (w - lw) // 2, (h - lh) // 2
    if size and size not in caps["sizes"]:
        d["errors"].append(f"{model}: resolucao {size} nao suportada (use {', '.join(caps['sizes'])})")
        size = None
    size = size or next((s for s in caps["sizes"] if gemini_images.estimate(aspect, s, model)[0] / w >= 8),
                        caps["sizes"][-1])
    est = gemini_images.estimate(aspect, size, model)
    geo = {**base, "logical": [w, h], "content": [ox, oy, ox + lw, oy + lh], "scale": round(est[0] / w, 2),
           "size": list(est), "exact": False}
    images = _attach(res, refs, palette, guides_mode, scene_prompt.build(res, "gemini", [], geo)["expect"])
    _built(d, res, palette, "gemini", [r for r, _ in images], geo)
    d["errors"] += gemini_images.check(model, aspect, size, [refs_mod.family(r) for r, _ in images])
    d["request"] = {"endpoint": "interactions", "aspect_ratio": aspect, "image_size": size,
                    "estimated_output": list(est),
                    "output_size_known": gemini_images.published(model, aspect, size) is not None}
    return images


def _pixellab_refs(d: dict, refs: list, model: str, caps: dict) -> list[tuple[str, bytes]]:
    images: list[tuple[str, bytes]] = []
    for role, data in refs:
        field = PIXELLAB_INPUTS.get(role)
        if field is None:
            d["errors"].append(f"PixelLab {model}: a referencia {role} nao chega ao modelo (o create-image nao tem "
                               "entrada para esse papel); use openai ou gemini, ou tire-a do contrato")
        elif field not in caps["images"] or any(f == field for f, _ in images):
            d["errors"].append(f"PixelLab {model}: a referencia {role} nao chega ao modelo ({field}: "
                               + ("so uma)" if field in caps["images"] else "use bitforge)"))
        else:
            images.append((field, data))
    return images


def _pixellab(d, res, refs, palette, model, seed) -> list:
    model = d["model"] = model or "pixflux"
    caps = pixellab_api.CAPS.get(model)
    if caps is None:
        d["errors"].append(f"modelo PixelLab desconhecido: {model!r} (use {', '.join(pixellab_api.CAPS)})")
        return []
    w, h = res["cells"]
    params = scene_prompt.pixellab_params(res)
    kw = {k: v for k, v in params.items() if k not in ("description", "image_size") and k in caps["fields"]}
    images = _pixellab_refs(d, refs, model, caps)
    if any(f == "init_image" for f, _ in images):
        kw["init_image_strength"] = 300
        d["notes"].append("o conceito vai como init_image (imagem inicial, forca 300): no tamanho do pedido")
    if palette is not None and "color_image" in caps["images"]:
        images.append(("color_image", png(guides.color_image(palette))))
    if seed is not None:
        kw["seed"] = seed
    found = pixellab_api.check(model, w, h, **kw, **dict(images))
    d["errors"] += found
    side = min(caps["max_side"], int(caps["max_area"] ** 0.5))
    if found and max(w, h) > side:
        d["notes"].append(f"{w}x{h} celulas excede {model}: particao proposta em x {partition(w, side, 32)} e y "
                          f"{partition(h, side, 32)} (32 celulas de sobreposicao), com o mesmo mestre e a juncao "
                          "revista; ou divida a cena em objetos e planos")
    d["request"] = {"endpoint": f"{pixellab_api.BASE}/create-image-{model}", "width": w, "height": h, "params": kw,
                    "spec_sha256": pixellab_api.SPEC_SHA256}
    d["prompt"] = params["description"]
    exp = scene_prompt.build(res, "generic")["expect"]  # o PixelLab recebe a descricao; o expect so mede
    d["expect"] = {**exp, "scale": 1, "scale_exact": True, "grid": "native", "size": [w, h],
                   "attached": [r for r, _ in images], "background": scene_prompt.backdrop(res, "pixellab")}
    d["authoring"] = "generated_native"
    return images


def make(backend: str, scene_path: str | Path, palette: Palette | None = None, model: str | None = None,
         guides_mode: str = "auto", size: str | None = None, seed: int | None = None,
         register: dict | None = None) -> plan_mod.Plan:
    """O plano de uma cena: o que se pediria, a quem, com que imagens. Nada sai para a rede."""
    sc = scene_mod.load(scene_path)
    res = scene_mod.resolve(sc)
    raw = Path(scene_path).read_bytes()
    d: dict = {"schema": 1, "backend": backend, "model": model, "kind": res["kind"], "subject": sc["subject"],
               "facing": None, "tags": None, "frames": 1, "references": [], "mode": "scene",
               "scene": {"id": res["id"], "file": str(scene_path), "sha256": hashlib.sha256(raw).hexdigest(),
                         "cells": res["cells"], "extent_px": res["extent_px"], "lattice": res["lattice"]},
               "authority": {"stage": "recovery", "states": [], "register": register and register["path"]},
               "errors": [], "notes": [f"cena: {w}" for w in res["warnings"]] + [
                   "recuperacao: o que sair e uma adaptacao em revisao, nao um mestre nativo"],
               "prompt": "", "expect": None, "request": None, "advice": None, "constraints": [], "implicit": [],
               "training_permission": plan_mod.PERMISSION.get(backend), "contracts": res["contract"]}
    refs = references(sc, Path(sc["_base"]), register, d)
    d["authority"]["states"] = [r["state"] for r in d["references"]]
    if backend == "openai":
        images = _openai(d, res, refs, palette, model, guides_mode)
    elif backend == "gemini":
        images = _gemini(d, res, refs, palette, model, guides_mode, size)
    elif backend == "pixellab":
        images = _pixellab(d, res, refs, palette, model, seed)
    else:
        raise ValueError(f"gerador desconhecido: {backend} (use {', '.join(plan_mod.BACKENDS)})")
    pool = [(r, sha(b)) for r, b in images]  # uma a uma: o mesmo ficheiro pode ir em dois papeis
    for e in d["references"]:
        hit = next((p for p in pool if p[1] == e["sha256"]), None) if e["state"] != "rejected" else None
        if hit:
            pool.remove(hit)
        e["sent"] = hit[0] if hit else None
        if e["state"] != "rejected" and e["sent"] is None and not any(e["role"] in x for x in d["errors"]):
            d["errors"].append(f"referencia {e['path']} ({e['role']}): registada mas nao enviada ao {backend}")
    if d["expect"]:
        d["expect"].update(canvas_px=res["extent_px"], pivot_px=[res["extent_px"][0] // 2, res["extent_px"][1] - 1])
    d["attachments"] = [{"index": i, "role": refs_mod.family(r), "prompt_role": r, "sha256": sha(b), "bytes": len(b)}
                        for i, (r, b) in enumerate(images, 1)]
    d["prompt_sha256"] = hashlib.sha256(d["prompt"].encode("utf-8")).hexdigest()
    return plan_mod.Plan(d, images)


def from_args(args, palette) -> plan_mod.Plan:
    """O plano de `forja plan`/`auto --scene`; sem cena nem assunto, recusa. `palette` so se chama com cena."""
    get = lambda name, default=None: getattr(args, name, default)  # noqa: E731
    if not get("scene"):
        raise ValueError("diga o assunto, ou --scene com um contrato forja.scene/1")
    return make(args.backend, args.scene, palette(), get("model"), get("guides", "auto"), get("image_size"),
                get("seed"), refs_mod.load(get("refs")) if get("refs") else None)
