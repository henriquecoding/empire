"""PixelLab API v2 (https://api.pixellab.ai/v2): gerar com o modelo deles e trazer o PNG.

Util para comparar resultados ou quando o autor tem plano do PixelLab. Os nomes
dos campos seguem a especificacao OpenAPI v2 lida em 23/10/2026; nao houve
chamada real nesta sessao (sem chave). Variaveis: PIXELLAB_API_KEY (ou PIXELLAB_SECRET).
"""
from __future__ import annotations

import time

from . import http

BASE = "https://api.pixellab.ai/v2"
OUTLINES = ("single color black outline", "single color outline", "selective outline", "lineless")
SHADINGS = ("flat shading", "basic shading", "medium shading", "detailed shading", "highly detailed shading")
DETAILS = ("low detail", "medium detail", "highly detailed")
VIEWS = ("side", "low top-down", "high top-down")
DIRECTIONS = ("north", "north-east", "east", "south-east", "south", "south-west", "west", "north-west")


def _image(data: bytes) -> dict:
    return {"type": "base64", "base64": http.b64(data), "format": "png"}


def payload(prompt: str, width: int, height: int, model: str = "pixflux", **kw) -> dict:
    body: dict = {"description": prompt, "image_size": {"width": width, "height": height}}
    for name, allowed in (("outline", OUTLINES), ("shading", SHADINGS), ("detail", DETAILS),
                          ("view", VIEWS), ("direction", DIRECTIONS)):
        value = kw.get(name)
        if value:
            if value not in allowed:
                raise ValueError(f"{name} invalido: {value!r} (use {', '.join(allowed)})")
            if not (model == "pixen" and name == "shading"):
                body[name] = value
    for name in ("no_background", "seed", "isometric", "text_guidance_scale", "init_image_strength"):
        if kw.get(name) is not None:
            body[name] = kw[name]
    if kw.get("init_image"):
        body["init_image"] = _image(kw["init_image"])
    if kw.get("color_image"):
        body["color_image"] = _image(kw["color_image"])
    return body


def generate(prompt: str, width: int = 64, height: int = 64, model: str = "pixflux",
             transport: http.Transport | None = None, poll: float = 5.0, **kw) -> dict:
    """Devolve {'images': [png...], 'model', 'request'} (o pedido sem a chave)."""
    if model not in ("pixflux", "pixen", "bitforge"):
        raise ValueError("modelo PixelLab: pixflux, pixen ou bitforge")
    headers = {"Authorization": "Bearer " + http.key("PIXELLAB_API_KEY", "PIXELLAB_SECRET", "PIXELLAB_API_TOKEN")}
    body = payload(prompt, width, height, model, **kw)
    req = http.json_request("POST", f"{BASE}/create-image-{model}", body, headers)
    data = http.send(req, transport, "pixellab").json()
    job = data.get("background_job_id")
    while job and not http.find_images(data):
        time.sleep(poll) if transport is None else None
        status = http.send(http.json_request("GET", f"{BASE}/background-jobs/{job}", None, headers),
                           transport, "pixellab").json()
        if status.get("status") == "failed":
            raise http.ApiError("pixellab", 200, str(status.get("last_response")))
        if status.get("status") == "completed":
            data = status.get("last_response") or {}
            break
    return {"images": http.find_images(data), "model": f"pixellab/{model}",
            "request": {k: v for k, v in body.items() if k not in ("init_image", "color_image")}}
