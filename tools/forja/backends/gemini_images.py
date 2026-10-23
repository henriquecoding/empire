"""Gemini (Nano Banana) por REST: texto e imagens de referencia -> imagem.

Dois caminhos documentados em 23/10/2026: a Interactions API (POST /interactions,
recomendada nos exemplos de imagem) e o generateContent classico. Os modelos
de imagem listados como estaveis incluem gemini-nano-banana-2.1,
gemini-3.1-flash-image, gemini-3-pro-image e gemini-2.5-flash-image. O Gemini
nao promete fundo transparente: pede-se fundo de chave e a Forja recorta.
Sem chamada real nesta sessao (sem chave). Variaveis: GEMINI_API_KEY (ou GOOGLE_API_KEY).
"""
from __future__ import annotations

import os

from . import http

BASE = "https://generativelanguage.googleapis.com/v1beta"
DEFAULT_MODEL = os.environ.get("FORJA_GEMINI_MODEL", "gemini-3.1-flash-image")


def interactions_payload(prompt: str, references: list[bytes], model: str, aspect: str, size: str) -> dict:
    parts = [{"type": "text", "text": prompt}]
    parts += [{"type": "image", "mime_type": "image/png", "data": http.b64(r)} for r in references]
    return {"model": model, "input": parts,
            "response_format": {"type": "image", "aspect_ratio": aspect, "image_size": size}}


def content_payload(prompt: str, references: list[bytes], aspect: str) -> dict:
    parts = [{"text": prompt}] + [{"inline_data": {"mime_type": "image/png", "data": http.b64(r)}} for r in references]
    return {"contents": [{"role": "user", "parts": parts}],
            "generationConfig": {"responseModalities": ["TEXT", "IMAGE"], "imageConfig": {"aspectRatio": aspect}}}


def generate(prompt: str, references: list[bytes] | None = None, model: str | None = None,
             aspect: str = "1:1", size: str = "1K", api: str = "interactions",
             transport: http.Transport | None = None) -> dict:
    model = model or DEFAULT_MODEL
    headers = {"x-goog-api-key": http.key("GEMINI_API_KEY", "GOOGLE_API_KEY")}
    refs = references or []
    if api == "interactions":
        req = http.json_request("POST", f"{BASE}/interactions",
                                interactions_payload(prompt, refs, model, aspect, size), headers)
    elif api == "generate_content":
        req = http.json_request("POST", f"{BASE}/models/{model}:generateContent",
                                content_payload(prompt, refs, aspect), headers)
    else:
        raise ValueError("api: interactions ou generate_content")
    data = http.send(req, transport, "gemini").json()
    images = http.find_images(data)
    if not images:
        raise http.ApiError("gemini", 200, "a resposta nao trouxe imagem")
    return {"images": images, "model": f"gemini/{model}", "request": {"api": api, "aspect": aspect, "size": size,
                                                                      "references": len(refs)}}
