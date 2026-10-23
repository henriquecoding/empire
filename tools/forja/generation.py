"""Planeamento por fornecedor e execucao de imagens, com referencias rastreaveis."""
from __future__ import annotations

import hashlib
import io
import json
from pathlib import Path

from PIL import Image

from . import guides
from .backends import gemini_images, http, openai_images, pixellab_api


def png(image: Image.Image) -> bytes:
    out = io.BytesIO()
    image.save(out, "PNG")
    return out.getvalue()


def plan(built: dict, backend: str, model: str | None, refs: list[bytes], palette=None,
         seed: int | None = None, attempts: int = 1) -> dict:
    if not 1 <= attempts <= 20:
        raise ValueError("attempts deve estar entre 1 e 20")
    if backend == "pixellab" and built["expect"]["frames"] != 1:
        raise ValueError("use animate-native com um primeiro quadro aprovado; create-image nao e animacao")
    chosen = model or ({"openai": openai_images.DEFAULT_MODEL, "gemini": gemini_images.DEFAULT_MODEL,
                       "pixellab": "bitforge" if refs else "pixflux"}[backend])
    params = {}
    if backend == "pixellab":
        if len(refs) > 1:
            raise ValueError("este conector PixelLab aceita uma referencia nativa; nao descarta as restantes")
        params = {k: v for k, v in built["pixellab"].items() if k not in ("description", "image_size")}
        if chosen == "pixen":
            params.pop("shading", None)
        if seed is not None:
            params["seed"] = seed
        size = built["pixellab"]["image_size"]
        if refs:
            with Image.open(io.BytesIO(refs[0])) as img:
                if img.size != (size["width"], size["height"]):
                    raise ValueError("a referencia PixelLab deve estar na tela nativa pedida; use snap e reveja primeiro")
            params["init_image"] = refs[0]
        if palette is not None and chosen != "pixen":
            params["color_image"] = png(guides.palette_swatch(palette))
        pixellab_api.payload(built["prompt"], size["width"], size["height"], chosen, **params)
    elif backend == "openai":
        openai_images.check_size(built["size"], chosen)
        if len(refs) + 2 > 16:
            raise ValueError("OpenAI: no maximo 14 referencias mais duas guias")
    elif backend == "gemini":
        if chosen not in ("gemini-3.1-flash-image", "gemini-nano-banana-2.1", "gemini-3-pro-image", "gemini-3.1-pro-image"):
            raise ValueError("auto Gemini exige um modelo com suporte ao plano 2K; use generate para outro modelo")
        if len(refs) + 1 + bool(palette) > 14:
            raise ValueError("Gemini: referencias e guias excedem o limite local de 14")
    else:
        raise ValueError("fornecedor desconhecido")
    return {"backend": backend, "model": chosen, "size": built["size"], "seed": seed,
            "max_submissions": attempts, "references": [hashlib.sha256(r).hexdigest() for r in refs],
            "content_box": built["expect"].get("content_box"),
            "palette_mode": "remote" if backend == "pixellab" and chosen != "pixen" else "reference_and_local",
            "parameters": {k: (hashlib.sha256(v).hexdigest() if isinstance(v, bytes) else v) for k, v in params.items()}}


def execute(built: dict, proposal: dict, refs: list[bytes], palette=None, transport=None, on_job=None) -> dict:
    backend, model = proposal["backend"], proposal["model"]
    if backend == "pixellab":
        size = built["pixellab"]["image_size"]
        params = dict(proposal["parameters"])
        if refs:
            params["init_image"] = refs[0]
        if "color_image" in params:
            params["color_image"] = png(guides.palette_swatch(palette))
        result = pixellab_api.generate(built["prompt"], size["width"], size["height"], model,
                                       transport=transport, on_job=on_job, **params)
        for data in result["images"]:
            with Image.open(io.BytesIO(data)) as img:
                if img.size != (size["width"], size["height"]):
                    raise http.ApiError("pixellab", 200, "imagem devolvida fora da tela nativa pedida")
        return result
    expected = built["expect"]
    attached = refs + [png(guides.template(expected))]
    if palette:
        attached.append(png(guides.palette_swatch(palette)))
    return generate(backend, built["prompt"], built["size"], attached, model, transport=transport,
                    background="transparent" if expected["background"] == "transparent" else "opaque")


def generate(backend: str, prompt: str, size: str, references: list[bytes], model: str | None,
             n: int = 1, transport=None, background: str = "auto", on_job=None) -> dict:
    if not 1 <= n <= 10 or (backend != "openai" and n != 1):
        raise ValueError("n: 1-10 no OpenAI; os outros conectores aceitam uma chamada por vez")
    if backend == "openai":
        if references:
            result = openai_images.edit(prompt, references, None, size, model, n=n, background=background, transport=transport)
        else:
            result = openai_images.generate(prompt, size, model, n=n, background=background, transport=transport)
    elif backend == "gemini":
        w, h = map(int, size.split("x"))
        ratios = ("1:1", "2:3", "3:2", "3:4", "4:3", "4:5", "5:4", "9:16", "16:9", "21:9")
        def distance(r: str) -> float:
            a, b = map(int, r.split(":"))
            return abs(w / h - a / b)
        aspect = min(ratios, key=distance)
        if distance(aspect) > 0.01:
            raise ValueError("proporcao sem suporte Gemini; compile uma prancha com celulas quadradas")
        result = gemini_images.generate(prompt, references, model, aspect,
                                        size="2K" if max(w, h) > 1024 else "1K", transport=transport)
    elif backend == "pixellab":
        w, h = map(int, size.split("x"))
        if len(references) > 1:
            raise ValueError("PixelLab: apenas uma referencia neste conector")
        if references:
            with Image.open(io.BytesIO(references[0])) as image:
                if image.size != (w, h):
                    raise ValueError("referencia PixelLab deve estar na tela nativa pedida")
        params = {"init_image": references[0]} if references else {}
        result = pixellab_api.generate(prompt, w, h, model or ("bitforge" if references else "pixflux"),
                                       transport=transport, no_background=True, on_job=on_job, **params)
    else:
        raise ValueError("fornecedor desconhecido")
    if not result["images"]:
        raise http.ApiError(backend, 200, "resposta sem imagem")
    return result


def save_json(path: Path, value: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_suffix(path.suffix + ".tmp")
    temp.write_text(json.dumps(value, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    temp.replace(path)
