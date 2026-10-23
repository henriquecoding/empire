"""OpenAI Images (gpt-image) por REST: gerar e editar com mascara.

Referencia lida em 23/10/2026: o gpt-image-1 sai hoje; o gpt-image-1.5 sai a
1/12/2026. Modelos atuais: gpt-image-2, gpt-image-2.5-sunburst (qualidade) e
gpt-image-2.5-flare (rapido). Tamanhos livres nos 2.x: lados multiplos de 16,
proporcao entre 1:3 e 3:1, ate 3840 por lado. Fundo transparente: estavel nos
2.5, em preview no 2. Edicao: ate 16 imagens em `image[]`; na mascara, alfa 0
marca o que muda, e so vale para a primeira imagem.

Sem chamada real nesta sessao (sem chave). Variavel: OPENAI_API_KEY.
"""
from __future__ import annotations

import os

from . import http

BASE = "https://api.openai.com/v1"
DEFAULT_MODEL = os.environ.get("FORJA_OPENAI_MODEL", "gpt-image-2.5-sunburst")
MODELS = ("gpt-image-2.5-sunburst", "gpt-image-2.5-flare", "gpt-image-2", "gpt-image-1.5",
          "gpt-image-1-mini", "chatgpt-image-latest")
FIXED_SIZES = ("1024x1024", "1536x1024", "1024x1536", "auto")


def check_size(size: str, model: str) -> str:
    if size in FIXED_SIZES:
        return size
    if not model.startswith("gpt-image-2"):
        raise ValueError(f"{model} so aceita {', '.join(FIXED_SIZES)}")
    w, _, h = size.partition("x")
    w, h = int(w), int(h)
    if w % 16 or h % 16 or max(w, h) > 3840 or max(w / h, h / w) > 3 or not 655360 <= w * h <= 8294400:
        raise ValueError(f"tamanho {size} fora das regras do {model} (multiplos de 16, 1:3 a 3:1, "
                         "655360 a 8294400 pixels)")
    return size


def _headers() -> dict[str, str]:
    return {"Authorization": "Bearer " + http.key("OPENAI_API_KEY")}


def generate(prompt: str, size: str = "1024x1024", model: str | None = None, quality: str = "high",
             background: str = "auto", n: int = 1, transport: http.Transport | None = None) -> dict:
    model = model or DEFAULT_MODEL
    body = {"model": model, "prompt": prompt, "size": check_size(size, model), "quality": quality,
            "background": background, "n": n, "output_format": "png"}
    resp = http.send(http.json_request("POST", f"{BASE}/images/generations", body, _headers()),
                     transport, "openai").json()
    return {"images": http.find_images(resp.get("data", [])), "model": f"openai/{model}", "request": body,
            "revised_prompts": [d.get("revised_prompt") for d in resp.get("data", []) if d.get("revised_prompt")]}


def edit(prompt: str, images: list[bytes], mask: bytes | None = None, size: str = "1024x1024",
         model: str | None = None, quality: str = "high", background: str = "auto", n: int = 1,
         transport: http.Transport | None = None) -> dict:
    """Editar: a primeira imagem e a que muda; as outras sao referencia de estilo e identidade."""
    model = model or DEFAULT_MODEL
    if not 1 <= len(images) <= 16:
        raise ValueError("a edicao aceita de 1 a 16 imagens")
    fields: list[tuple[str, str | bytes, str | None]] = [
        ("model", model, None), ("prompt", prompt, None), ("size", check_size(size, model), None),
        ("quality", quality, None), ("background", background, None), ("n", str(n), None),
        ("output_format", "png", None)]
    fields += [("image[]", data, f"image{i}.png") for i, data in enumerate(images)]
    if mask is not None:
        fields.append(("mask", mask, "mask.png"))
    body, ctype = http.multipart(fields)
    req = http.Request("POST", f"{BASE}/images/edits", {**_headers(), "Content-Type": ctype}, body)
    resp = http.send(req, transport, "openai").json()
    return {"images": http.find_images(resp.get("data", [])), "model": f"openai/{model}",
            "request": {"model": model, "size": size, "quality": quality, "background": background,
                        "images": len(images), "mask": mask is not None}}
