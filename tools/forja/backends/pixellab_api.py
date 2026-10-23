"""PixelLab API v2 (https://api.pixellab.ai/v2): gerar com o modelo deles e trazer o PNG.

Util para comparar resultados ou quando o autor tem plano do PixelLab. Os nomes
dos campos seguem a especificacao OpenAPI v2 lida em 23/10/2026; nao houve
chamada real nesta sessao (sem chave). Variaveis: PIXELLAB_API_KEY (ou PIXELLAB_SECRET).
"""
from __future__ import annotations

import io
import math
from PIL import Image

from . import http, jobs

BASE = "https://api.pixellab.ai/v2"
OUTLINES = ("single color black outline", "single color outline", "selective outline", "lineless")
SHADINGS = ("flat shading", "basic shading", "medium shading", "detailed shading", "highly detailed shading")
DETAILS = ("low detail", "medium detail", "highly detailed")
VIEWS = ("side", "low top-down", "high top-down")
DIRECTIONS = ("north", "north-east", "east", "south-east", "south", "south-west", "west", "north-west")


def _image(data: bytes) -> dict:
    return {"type": "base64", "base64": http.b64(data), "format": "png"}


def payload(prompt: str, width: int, height: int, model: str = "pixflux", **kw) -> dict:
    if model not in ("pixflux", "pixen", "bitforge"):
        raise ValueError("modelo PixelLab: pixflux, pixen ou bitforge")
    if not isinstance(prompt, str) or not prompt.strip():
        raise ValueError("descricao nao pode estar vazia")
    for name in ("seed", "init_image_strength", "style_strength"):
        if kw.get(name) is not None and type(kw[name]) is not int:
            raise ValueError(f"{name}: inteiro requerido")
    for name in ("no_background", "isometric"):
        if kw.get(name) is not None and type(kw[name]) is not bool:
            raise ValueError(f"{name}: booleano requerido")
    guide = kw.get("text_guidance_scale")
    if guide is not None and (type(guide) not in (int, float) or not math.isfinite(guide)):
        raise ValueError("text_guidance_scale: numero finito requerido")
    cap = {"pixflux": 400, "pixen": 768, "bitforge": 200}[model]
    if any(type(v) is not int or not 16 <= v <= cap for v in (width, height)):
        raise ValueError(f"{model}: cada lado deve estar entre 16 e {cap} pixels nativos")
    if model == "pixflux" and width * height < 32 * 32:
        raise ValueError("pixflux: area minima 32x32")
    if model == "pixen":
        if width % 4 or height % 4 or width * height > 512 * 512 or (min(width, height) < 32 and width != height):
            raise ValueError("pixen: lados multiplos de 4, area ate 512x512, quadrado abaixo de 32")
        if kw.get("no_background") and width * height > 256 * 256:
            raise ValueError("pixen: transparencia limitada a 65536 pixels")
    common = {"outline", "detail", "view", "direction", "no_background", "seed"}
    supported = common if model == "pixen" else common | {
        "shading", "isometric", "text_guidance_scale", "init_image_strength", "init_image", "color_image"}
    if model == "bitforge":
        supported |= {"style_image", "style_strength"}
    unsupported = {k for k, v in kw.items() if v is not None and k not in supported}
    if unsupported:
        raise ValueError(f"{model} nao suporta: {', '.join(sorted(unsupported))}")
    body: dict = {"description": prompt, "image_size": {"width": width, "height": height}}
    for name, allowed in (("outline", OUTLINES), ("shading", SHADINGS), ("detail", DETAILS),
                          ("view", VIEWS), ("direction", DIRECTIONS)):
        value = kw.get(name)
        if value:
            if value not in allowed:
                raise ValueError(f"{name} invalido: {value!r} (use {', '.join(allowed)})")
            body[name] = value
    for name in ("no_background", "seed", "isometric", "text_guidance_scale", "init_image_strength"):
        if kw.get(name) is not None:
            body[name] = kw[name]
    for name in ("init_image", "color_image", "style_image"):
        if kw.get(name):
            body[name] = _image(kw[name])
    if kw.get("style_strength") is not None:
        if not 0 <= kw["style_strength"] <= 100:
            raise ValueError("style_strength: 0 a 100")
        body["style_strength"] = kw["style_strength"]
    for name, low, high in (("init_image_strength", 1, 999), ("text_guidance_scale", 1, 20)):
        if name in body and not low <= body[name] <= high:
            raise ValueError(f"{name}: {low} a {high}")
    return body


def generate(prompt: str, width: int = 64, height: int = 64, model: str = "pixflux",
             transport: http.Transport | None = None, poll: float = 3.0, timeout: float = 600.0,
             max_polls: int = 120, on_job=None, **kw) -> dict:
    """Devolve {'images': [png...], 'model', 'request'} (o pedido sem a chave)."""
    if model not in ("pixflux", "pixen", "bitforge"):
        raise ValueError("modelo PixelLab: pixflux, pixen ou bitforge")
    body = payload(prompt, width, height, model, **kw)
    headers = auth()
    data, job = jobs.submit(f"create-image-{model}", body, headers, transport, poll, timeout, max_polls, on_job)
    return result(data, model, body, job)


def auth() -> dict[str, str]:
    return {"Authorization": "Bearer " + http.key("PIXELLAB_API_KEY", "PIXELLAB_SECRET", "PIXELLAB_API_TOKEN")}


def result(data: dict, model: str, body: dict, job: str | None = None) -> dict:
    images = http.find_images(data)
    if not images:
        raise http.ApiError("pixellab", 200, "resposta concluida sem imagem")
    return {"images": images, "model": f"pixellab/{model}", "job_id": job, "usage": data.get("usage"),
            "request": {k: v for k, v in body.items() if not k.endswith("_image") and k not in ("first_frame", "last_frame")}}


def animation_payload(first: bytes, action: str, frame_count: int = 8, last: bytes | None = None,
                      seed: int = 0) -> dict:
    if type(frame_count) is not int or not 4 <= frame_count <= 16 or frame_count % 2:
        raise ValueError("animate-with-text-v3: 4 a 16 quadros, numero par")
    if not 1 <= len(action) <= 1000 or type(seed) is not int or seed < 0:
        raise ValueError("acao: 1-1000 caracteres; seed: inteiro >= 0")
    with Image.open(io.BytesIO(first)) as image:
        w, h = image.size
    if max(w, h) > 256 or w * h * frame_count > 524288:
        raise ValueError("animacao: tela ate 256x256 e orcamento de 524288 pixels")
    body = {"first_frame": _image(first), "action": action, "frame_count": frame_count,
            "seed": seed, "no_background": True, "enhance_prompt": False}
    if last:
        with Image.open(io.BytesIO(last)) as image:
            if image.size != (w, h):
                raise ValueError("ultimo quadro deve ter a mesma tela nativa")
        body["last_frame"] = _image(last)
    return body


def animate(first: bytes, action: str, frame_count: int = 8, last: bytes | None = None,
            seed: int = 0, transport: http.Transport | None = None, on_job=None) -> dict:
    body = animation_payload(first, action, frame_count, last, seed)
    data, job = jobs.submit("animate-with-text-v3", body, auth(), transport, on_job=on_job)
    res = result(data, "animate-with-text-v3", body, job)
    if len(res["images"]) != frame_count:
        raise http.ApiError("pixellab", 200, "contagem de quadros diferente da pedida")
    with Image.open(io.BytesIO(first)) as image:
        size = image.size
    for data in res["images"]:
        with Image.open(io.BytesIO(data)) as image:
            if image.size != size:
                raise http.ApiError("pixellab", 200, "quadro devolvido fora da tela nativa")
    return res
