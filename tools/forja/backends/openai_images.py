"""OpenAI Images (gpt-image) por REST: gerar e editar com mascara.

Referencia lida em 23/10/2026: o gpt-image-1 sai hoje; o gpt-image-1.5 sai a
1/12/2026. Modelos atuais: gpt-image-2, gpt-image-2.5-sunburst (qualidade) e
gpt-image-2.5-flare (rapido). Tamanhos livres nos 2.x: lados multiplos de 16,
proporcao entre 1:3 e 3:1, ate 3840 por lado. Fundo transparente: estavel nos
2.5, em preview no 2. Edicao: ate 16 imagens em `image[]`; na mascara, alfa 0
marca o que muda, e so vale para a primeira imagem. A resposta traz `usage` em
tokens, nao em dolares: o custo fica "desconhecido" no registo do job.

Sem chamada real nesta sessao (sem chave). Variavel: OPENAI_API_KEY.
"""
from __future__ import annotations

import hashlib
import os

from . import Call, Result, http, image_refs

BASE = "https://api.openai.com/v1"
DEFAULT_MODEL = os.environ.get("FORJA_OPENAI_MODEL", "gpt-image-2.5-sunburst")
MODELS = ("gpt-image-2.5-sunburst", "gpt-image-2.5-flare", "gpt-image-2", "gpt-image-1.5",
          "gpt-image-1-mini", "chatgpt-image-latest")
FIXED_SIZES = ("1024x1024", "1536x1024", "1024x1536", "auto")
MAX_IMAGES = 16


def check_model(model: str) -> str:
    if not model.startswith(("gpt-image", "chatgpt-image")):
        raise ValueError(f"modelo OpenAI de imagem desconhecido: {model!r} (ex.: {', '.join(MODELS[:3])})")
    return model


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


def parse(resp: dict) -> Result:
    data = resp.get("data", [])
    return Result(http.find_images(data), detail={
        "usage": resp.get("usage"), "revised_prompts": [d.get("revised_prompt") for d in data
                                                        if isinstance(d, dict) and d.get("revised_prompt")]})


def _prompt_hash(prompt: str) -> str:
    return hashlib.sha256(prompt.encode("utf-8")).hexdigest()


def generate_call(prompt: str, size: str = "1024x1024", model: str | None = None, quality: str = "high",
                  background: str = "auto", n: int = 1) -> Call:
    model = check_model(model or DEFAULT_MODEL)
    body = {"model": model, "prompt": prompt, "size": check_size(size, model), "quality": quality,
            "background": background, "n": n, "output_format": "png"}
    url = f"{BASE}/images/generations"
    descriptor = {"endpoint": url, "params": {k: v for k, v in body.items() if k != "prompt"},
                  "prompt_sha256": _prompt_hash(prompt), "images": []}
    return Call("openai", "images.generations", lambda: http.json_request("POST", url, body, _headers()),
                parse, descriptor)


def edit_call(prompt: str, images: list[bytes], mask: bytes | None = None, size: str = "1024x1024",
              model: str | None = None, quality: str = "high", background: str = "auto", n: int = 1,
              roles: list[str] | None = None) -> Call:
    """Editar: a primeira imagem e a que muda; as outras sao referencia. `roles` diz o papel de cada uma."""
    model = check_model(model or DEFAULT_MODEL)
    if not 1 <= len(images) <= MAX_IMAGES:
        raise ValueError(f"a edicao aceita de 1 a {MAX_IMAGES} imagens")
    roles = roles or ["edit_target"] + ["reference"] * (len(images) - 1)
    fields: list[tuple[str, str | bytes, str | None]] = [
        ("model", model, None), ("prompt", prompt, None), ("size", check_size(size, model), None),
        ("quality", quality, None), ("background", background, None), ("n", str(n), None),
        ("output_format", "png", None)]
    fields += [("image[]", data, f"image{i}.png") for i, data in enumerate(images)]
    if mask is not None:
        fields.append(("mask", mask, "mask.png"))
    url = f"{BASE}/images/edits"

    def request() -> http.Request:
        body, ctype = http.multipart(fields)
        return http.Request("POST", url, {**_headers(), "Content-Type": ctype}, body)

    refs = list(zip(roles, images)) + ([("mask", mask)] if mask is not None else [])
    descriptor = {"endpoint": url, "prompt_sha256": _prompt_hash(prompt), "images": image_refs(refs),
                  "params": {"model": model, "size": size, "quality": quality, "background": background, "n": n,
                             "output_format": "png"}}
    return Call("openai", "images.edits", request, parse, descriptor)


def _run(c: Call, transport, folder, budget) -> dict:
    from .. import jobs
    job = jobs.create(c, folder)
    images = jobs.execute(job, c, transport, budget=budget)
    return {"images": images, "model": f"openai/{c.descriptor['params']['model']}", "request": c.descriptor,
            "job": job.data, "revised_prompts": (job.data.get("response") or {}).get("revised_prompts", [])}


def generate(prompt: str, size: str = "1024x1024", model: str | None = None, quality: str = "high",
             background: str = "auto", n: int = 1, transport: http.Transport | None = None,
             folder=None, budget=None) -> dict:
    return _run(generate_call(prompt, size, model, quality, background, n), transport, folder, budget)


def edit(prompt: str, images: list[bytes], mask: bytes | None = None, size: str = "1024x1024",
         model: str | None = None, quality: str = "high", background: str = "auto", n: int = 1,
         transport: http.Transport | None = None, folder=None, budget=None, roles: list[str] | None = None) -> dict:
    return _run(edit_call(prompt, images, mask, size, model, quality, background, n, roles), transport, folder,
                budget)
