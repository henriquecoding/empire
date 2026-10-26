"""PixelLab API v2 (https://api.pixellab.ai/v2): gerar com os modelos deles, no tamanho nativo.

Contrato lido da especificacao publica (`/v2/openapi.json`, versao "dev"). Lida
a 23/10/2026 e revista a 26/10/2026, quando o hash mudou (sha256 abaixo):
docs/art/research/2026-10-26-pixellab-engenharia-reversa/contrato.py confere
estes limites contra a especificacao e lista o que diverge.

- Todos: cada lado de 16 px para cima; `init_image_strength` de 1 a 999 (300 por
  omissao), `text_guidance_scale` de 1 a 20, `style_strength` de 0 a 100.
- pixflux: cada lado ate 400, area de 32x32 a 400x400; init_image (imagem
  inicial), color_image (paleta forcada).
- pixen: cada lado ate 768, area ate 512x512, lados multiplos de 4, quadrado se um
  lado < 32; fundo transparente so ate 65 536 px de area; sem imagem inicial nem `shading`.
- bitforge: cada lado ate 200, area ate 200x200; init_image, color_image e style_image.
- Resposta: imagem sincrona com `usage.usd`, ou `background_job_id` para GET
  /background-jobs/{id} (processing, completed, failed) e DELETE para cancelar.
- 529 e "Rate limit exceeded" (recusa clara). Nao ha idempotencia documentada.

O que o modelo faz por dentro nao esta publicado; isto so fala do contrato da API.
Nao houve chamada real (sem chave). Uma mudanca do hash da especificacao obriga
a correr o contrato.py e rever estes limites. Variaveis: PIXELLAB_API_KEY (ou
PIXELLAB_SECRET, PIXELLAB_API_TOKEN).
"""
from __future__ import annotations

import io
import time

from PIL import Image

from . import Call, Result, http, image_refs

BASE = "https://api.pixellab.ai/v2"
SPEC_SHA256 = "1c895d3f51aadf1a4cfe8b39cf4924788c02d5a8c8f682385ff5f18ba2f2997f"
OUTLINES = ("single color black outline", "single color outline", "selective outline", "lineless")
SHADINGS = ("flat shading", "basic shading", "medium shading", "detailed shading", "highly detailed shading")
DETAILS = ("low detail", "medium detail", "highly detailed")
VIEWS = ("side", "low top-down", "high top-down")
DIRECTIONS = ("north", "north-east", "east", "south-east", "south", "south-west", "west", "north-west")
ENUMS = {"outline": OUTLINES, "shading": SHADINGS, "detail": DETAILS, "view": VIEWS, "direction": DIRECTIONS}
IMAGES = ("init_image", "color_image", "style_image")
_STYLE = ("outline", "detail", "view", "direction", "no_background", "seed")
RANGES = {"init_image_strength": (1, 999), "text_guidance_scale": (1, 20), "style_strength": (0, 100)}
CAPS = {
    "pixflux": {"min_side": 16, "max_side": 400, "min_area": 32 * 32, "max_area": 400 * 400,
                "images": ("init_image", "color_image"),
                "fields": _STYLE + ("shading", "isometric", "text_guidance_scale", "init_image_strength")},
    "pixen": {"min_side": 16, "max_side": 768, "max_area": 512 * 512, "multiple": 4, "square_below": 32,
              "transparent_max_area": 65536, "images": (), "fields": _STYLE},
    "bitforge": {"min_side": 16, "max_side": 200, "max_area": 200 * 200, "images": IMAGES,
                 "fields": _STYLE + ("shading", "isometric", "text_guidance_scale", "init_image_strength",
                                     "style_strength")},
}
REFUSED = http.REFUSED | {529}


def capabilities(model: str) -> dict:
    if model not in CAPS:
        raise ValueError(f"modelo PixelLab desconhecido: {model!r} (use {', '.join(CAPS)})")
    return {"model": model, "endpoint": f"{BASE}/create-image-{model}", "spec_sha256": SPEC_SHA256,
            "static_image_only": True, **CAPS[model]}


def _size(data: bytes) -> tuple[int, int]:
    with Image.open(io.BytesIO(data)) as im:
        return im.size


def check(model: str, width: int, height: int, **kw) -> list[str]:
    """Os erros que a API daria, ditos antes de qualquer rede (lista vazia: valido)."""
    if model not in CAPS:
        return [f"modelo PixelLab desconhecido: {model!r} (use {', '.join(CAPS)})"]
    c, area, errors = CAPS[model], width * height, []
    if area < c.get("min_area", 0):
        errors.append(f"{model}: area {width}x{height} abaixo do minimo 32x32")
    if area > c["max_area"]:
        side = round(c["max_area"] ** 0.5)
        errors.append(f"{model}: area {width}x{height} acima do maximo {side}x{side}")
    if min(width, height) < c.get("min_side", 1):
        errors.append(f"{model}: lado minimo {c['min_side']}")
    if max(width, height) > c.get("max_side", max(width, height)):
        errors.append(f"{model}: lado maximo {c['max_side']} (pedido {width}x{height})")
    if c.get("multiple") and (width % c["multiple"] or height % c["multiple"]):
        errors.append(f"{model}: largura e altura multiplas de {c['multiple']}")
    if min(width, height) < c.get("square_below", 0) and width != height:
        errors.append(f"{model}: tem de ser quadrado com um lado abaixo de {c['square_below']}")
    if kw.get("no_background") and area > c.get("transparent_max_area", area):
        errors.append(f"{model}: fundo transparente so ate {c['transparent_max_area']} px de area")
    for name, value in kw.items():
        if value is None or value is False:
            continue
        if name in IMAGES:
            if name not in c["images"]:
                errors.append(f"{model} nao aceita {name}")
            elif name == "init_image" and _size(value) != (width, height):
                errors.append(f"init_image {_size(value)} tem de ter o tamanho do pedido {(width, height)}; "
                              "a Forja nao redimensiona em silencio (use forja fit/snap antes)")
        elif name not in c["fields"]:
            errors.append(f"{model} nao aceita o campo {name}")
        elif name in ENUMS and value not in ENUMS[name]:
            errors.append(f"{name} invalido: {value!r} (use {', '.join(ENUMS[name])})")
        elif name in RANGES and not RANGES[name][0] <= value <= RANGES[name][1]:
            low, high = RANGES[name]
            errors.append(f"{name} {value!r} fora de {low}-{high}: a API recusaria o pedido (422)")
    return errors


def payload(prompt: str, width: int, height: int, model: str = "pixflux", **kw) -> dict:
    errors = check(model, width, height, **kw)
    if errors:
        raise ValueError("; ".join(errors))
    body: dict = {"description": prompt, "image_size": {"width": width, "height": height}}
    for name, value in kw.items():
        if value is None:
            continue
        body[name] = {"type": "base64", "base64": http.b64(value), "format": "png"} if name in IMAGES else value
    return body


def _headers() -> dict[str, str]:
    return {"Authorization": "Bearer " + http.key("PIXELLAB_API_KEY", "PIXELLAB_SECRET", "PIXELLAB_API_TOKEN")}


def _usd(data: dict) -> float | None:
    usage = data.get("usage") if isinstance(data, dict) else None
    if isinstance(usage, dict) and usage.get("type") == "usd" and isinstance(usage.get("usd"), (int, float)):
        return float(usage["usd"])
    return None


def parse(data: dict) -> Result:
    job = data.get("background_job_id")
    return Result(http.find_images(data), job, "processing" if job else "completed", _usd(data))


def call(prompt: str, width: int = 64, height: int = 64, model: str = "pixflux", **kw) -> Call:
    """O pedido validado. Imagens (init_image, color_image, style_image) vao em bytes PNG."""
    body = payload(prompt, width, height, model, **kw)
    url = f"{BASE}/create-image-{model}"
    descriptor = {"endpoint": url, "model": model, "spec_sha256": SPEC_SHA256,
                  "params": {k: v for k, v in body.items() if k not in IMAGES},
                  "images": image_refs([(k, kw[k]) for k in IMAGES if kw.get(k)])}
    return Call("pixellab", f"create-image-{model}", lambda: http.json_request("POST", url, body, _headers()),
                parse, descriptor, REFUSED)


def parse_job(data: dict) -> Result:
    status = data.get("status")
    last = data.get("last_response") or {}
    if status == "processing":
        return Result(state="processing", detail={"status": status, "queue_position": last.get("queue_position"),
                                                  "estimated_wait_seconds": last.get("estimated_wait_seconds")})
    if status == "completed":
        return Result(http.find_images(last), state="completed", usage_usd=_usd(last) or _usd(data),
                      detail={"status": status})
    if status == "failed":
        return Result(state="failed", detail={"status": status, "last_response": str(last)[:400]})
    return Result(state="unknown", detail={"status": status})


def poll_call(job_id: str) -> Call:
    url = f"{BASE}/background-jobs/{job_id}"
    return Call("pixellab", "background-job", lambda: http.json_request("GET", url, None, _headers()),
                parse_job, {"endpoint": url})


def cancel_call(job_id: str) -> Call:
    url = f"{BASE}/background-jobs/{job_id}"
    return Call("pixellab", "cancel-background-job", lambda: http.json_request("DELETE", url, None, _headers()),
                lambda data: Result(detail=data), {"endpoint": url})


def generate(prompt: str, width: int = 64, height: int = 64, model: str = "pixflux",
             transport: http.Transport | None = None, folder=None, budget=None,
             sleep=time.sleep, **kw) -> dict:
    """Pedir e esperar, com o job escrito em `folder`/jobs (se dado). Devolve imagens e o registo."""
    from .. import jobs
    c = call(prompt, width, height, model, **kw)
    job = jobs.create(c, folder)
    images = jobs.execute(job, c, transport, poll=poll_call, budget=budget, sleep=sleep)
    return {"images": images, "model": f"pixellab/{model}", "request": c.descriptor, "job": job.data}
