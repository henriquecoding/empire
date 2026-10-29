"""Gemini (Nano Banana) por REST: texto e imagens de referencia -> imagem.

Lido em ai.google.dev/gemini-api/docs/image-generation e nas paginas dos modelos
em 23/10/2026 (paginas atualizadas entre 2026-09-03 e 2026-10-15):

- Modelos estaveis: gemini-nano-banana-2.1, gemini-3.1-flash-image,
  gemini-3.1-flash-lite-image, gemini-3-pro-image, gemini-2.5-flash-image.
- Proporcoes: 1:1, 3:2, 2:3, 3:4, 4:3, 4:5, 5:4, 9:16, 16:9, 21:9 (listadas para o
  flash-lite); 1:4, 4:1, 1:8 e 8:1 novas no 3.1-flash-image e no nano-banana-2.1.
  Para o 3-pro e o 2.5 as paginas nao listam: assumem-se as dez comuns (inferencia).
- Resolucao (`image_size`, K maiusculo): 1K por omissao; 2K e 4K nos modelos 3.x e
  2.1; o flash-lite so 1K; para o 2.5 nada dito, fica so 1K.
- Ate 14 referencias; personagens: 4 (2.1 e 3.1-flash), 5 (3-pro), nenhum (flash-lite);
  objetos 10/6/14; estilo: 3, so no 3-pro; para o 2.5 a tabela nao diz (so o total).
  O papel de cada imagem diz-se no texto.
- Na Interactions API: `response_format: {type: image, aspect_ratio, image_size}`.
- A tabela de pixels de saida por proporcao e resolucao esta na copia em texto da
  pagina (image-generation.md.txt, lida a 28/10/2026): `gemini_pixels.json`, linha a
  linha, por modelo; o 3-pro liga-se a tabela "3.1 Pro Image" por inferencia (a
  pagina nao diz o id). Sem tabela (flash-lite), estimativa pela area. A Forja mede
  o que chega na mesma (FORJA-12). Fundo transparente nao documentado: pede-se fundo
  de chave e a Forja recorta.
Sem chamada real nesta sessao (sem chave). Variaveis: GEMINI_API_KEY (ou GOOGLE_API_KEY).
"""
from __future__ import annotations

import hashlib
import json
import math
import os
from pathlib import Path

from . import Call, Result, http, image_refs

BASE = "https://generativelanguage.googleapis.com/v1beta"
DEFAULT_MODEL = os.environ.get("FORJA_GEMINI_MODEL", "gemini-3.1-flash-image")
ASPECTS = ("1:1", "3:2", "2:3", "3:4", "4:3", "4:5", "5:4", "9:16", "16:9", "21:9")
WIDE = ("1:4", "4:1", "1:8", "8:1")
SIDES = {"1K": 1024, "2K": 2048, "4K": 4096}
MODELS = {
    "gemini-nano-banana-2.1": {"aspects": ASPECTS + WIDE, "sizes": ("1K", "2K", "4K"), "characters": 4,
                               "objects": 10, "style": 0},
    "gemini-3.1-flash-image": {"aspects": ASPECTS + WIDE, "sizes": ("1K", "2K", "4K"), "characters": 4,
                               "objects": 10, "style": 0},
    "gemini-3.1-flash-lite-image": {"aspects": ASPECTS, "sizes": ("1K",), "characters": 0, "objects": 14,
                                    "style": 0},
    "gemini-3-pro-image": {"aspects": ASPECTS, "sizes": ("1K", "2K", "4K"), "characters": 5, "objects": 6,
                           "style": 3},
    "gemini-2.5-flash-image": {"aspects": ASPECTS, "sizes": ("1K",), "characters": None, "objects": None,
                               "style": None},
}
MAX_REFERENCES = 14
PIXELS = json.loads(Path(__file__).with_name("gemini_pixels.json").read_text(encoding="utf-8"))


def capabilities(model: str | None = None) -> dict:
    model = model or DEFAULT_MODEL
    if model not in MODELS:
        raise ValueError(f"modelo Gemini de imagem desconhecido: {model!r} (use {', '.join(MODELS)})")
    table = PIXELS["models"].get(model, {}).get("table")
    return {"model": model, **MODELS[model], "pixel_table": f"{table} ({PIXELS['source']}, lida a "
            f"{PIXELS['read']})" if table else "nao publicada: estimativa pela area; tamanho medido no retorno"}


def published(model: str | None, aspect: str, size: str) -> tuple[int, int] | None:
    """Os pixels que a tabela publicada da para este modelo, proporcao e resolucao, ou nada."""
    table = PIXELS["models"].get(model or DEFAULT_MODEL, {}).get("table")
    found = PIXELS["tables"].get(table, {}).get(aspect, {}).get(size) if table else None
    return (found[0], found[1]) if found else None


def ratio(aspect: str) -> float:
    a, _, b = aspect.partition(":")
    return int(a) / int(b)


def fit_aspect(lw: int, lh: int, aspects) -> tuple[str, int, int]:
    """A proporcao suportada que menos margem obriga, e a tela logica com essa margem."""
    best = None
    for a in aspects:
        r = ratio(a)
        w, h = (math.ceil(lh * r), lh) if r >= lw / lh else (lw, math.ceil(lw / r))
        waste = w * h / (lw * lh) - 1
        if best is None or waste < best[0] - 1e-9:
            best = (waste, a, w, h)
    return best[1], best[2], best[3]


def estimate(aspect: str, size: str, model: str | None = None) -> tuple[int, int]:
    """Os pixels da saida: os da tabela publicada; sem ela, a area do quadrado da resolucao, lados multiplos de 16."""
    found = published(model, aspect, size)
    if found:
        return found
    side, r = SIDES[size], ratio(aspect)
    w = round(side * r ** 0.5 / 16) * 16
    return w, round(side * side / w / 16) * 16


def check(model: str, aspect: str, size: str, roles: list[str]) -> list[str]:
    if model not in MODELS:
        return [f"modelo Gemini de imagem desconhecido: {model!r} (use {', '.join(MODELS)})"]
    m, errors = MODELS[model], []
    if aspect not in m["aspects"]:
        errors.append(f"{model}: proporcao {aspect} nao suportada (use {', '.join(m['aspects'])})")
    if size not in m["sizes"]:
        errors.append(f"{model}: resolucao {size} nao suportada (use {', '.join(m['sizes'])})")
    counts = {r: roles.count(r) for r in set(roles)}
    if len(roles) > MAX_REFERENCES:
        errors.append(f"ate {MAX_REFERENCES} imagens de referencia; vieram {len(roles)}")
    others = len(roles) - counts.get("identity", 0) - counts.get("style", 0)
    for cap, used, what in (("characters", counts.get("identity", 0), "referencias de personagem"),
                            ("style", counts.get("style", 0), "referencias de estilo"),
                            ("objects", others, "imagens de objeto/guia")):
        if m[cap] is not None and used > m[cap]:
            errors.append(f"{model}: ate {m[cap]} {what}")
    return errors


def interactions_payload(prompt: str, references: list[bytes], model: str, aspect: str, size: str) -> dict:
    parts = [{"type": "text", "text": prompt}]
    parts += [{"type": "image", "mime_type": "image/png", "data": http.b64(r)} for r in references]
    return {"model": model, "input": parts,
            "response_format": {"type": "image", "aspect_ratio": aspect, "image_size": size}}


def content_payload(prompt: str, references: list[bytes], aspect: str) -> dict:
    parts = [{"text": prompt}] + [{"inline_data": {"mime_type": "image/png", "data": http.b64(r)}} for r in references]
    return {"contents": [{"role": "user", "parts": parts}],
            "generationConfig": {"responseModalities": ["TEXT", "IMAGE"], "imageConfig": {"aspectRatio": aspect}}}


def parse(data: dict) -> Result:
    """So a imagem final. Os modelos 3.x pensam antes de desenhar: ate duas imagens intermedias ("thought images",
    nao cobradas) vem nos passos `type: "thought"` (Interactions) ou nas partes `thought: true` (generateContent), e
    a ultima imagem e a final. Antes, todas as imagens da resposta saiam por ordem e a Forja forjava a primeira — um
    rascunho (FORJA-08, B01). `output_image` e "o ultimo bloco de imagem gerado" (documentacao lida a
    27/10/2026)."""
    if not isinstance(data, dict):
        return Result([])
    out = data.get("output_image")
    thoughts = len(http.find_images(_thoughts(data)))
    if isinstance(out, dict) and isinstance(out.get("data"), str):
        images = [http.unb64(out["data"])]
    else:
        images = http.find_images(_final(data))
    detail = {"text": str(data.get("output_text") or "")[:300]}
    if thoughts:
        detail["thought_images_skipped"] = thoughts
    return Result(images, detail=detail)


def _is_thought(node) -> bool:
    return isinstance(node, dict) and (node.get("type") == "thought" or node.get("thought") is True)


def _final(node):
    """A resposta sem os passos e as partes de pensamento."""
    if isinstance(node, dict):
        return {k: _final(v) for k, v in node.items() if not _is_thought(v)}
    if isinstance(node, list):
        return [_final(v) for v in node if not _is_thought(v)]
    return node


def _thoughts(node) -> list:
    """Os passos e as partes de pensamento, para contar as imagens intermedias que ficaram de fora."""
    if _is_thought(node):
        return [node]
    if isinstance(node, dict):
        return [t for v in node.values() for t in _thoughts(v)]
    if isinstance(node, list):
        return [t for v in node for t in _thoughts(v)]
    return []


def call(prompt: str, references: list[tuple[str, bytes]] | None = None, model: str | None = None,
         aspect: str = "1:1", size: str = "1K", api: str = "interactions") -> Call:
    """`references` sao (papel, png): identity, style, palette, layout. Validado antes de qualquer rede."""
    model = model or DEFAULT_MODEL
    refs = references or []
    if api == "generate_content" and size != "1K":
        raise ValueError("generate_content: a Forja so pede 1K por este caminho (o campo de resolucao nao "
                         "foi confirmado na documentacao); use api=interactions")
    errors = check(model, aspect, size, [r for r, _ in refs])
    if errors:
        raise ValueError("; ".join(errors))
    data = [d for _, d in refs]
    if api == "interactions":
        url, body = f"{BASE}/interactions", interactions_payload(prompt, data, model, aspect, size)
    elif api == "generate_content":
        url, body = f"{BASE}/models/{model}:generateContent", content_payload(prompt, data, aspect)
    else:
        raise ValueError("api: interactions ou generate_content")
    headers = lambda: {"x-goog-api-key": http.key("GEMINI_API_KEY", "GOOGLE_API_KEY")}  # noqa: E731
    descriptor = {"endpoint": url, "params": {"model": model, "api": api, "aspect_ratio": aspect, "image_size": size},
                  "prompt_sha256": hashlib.sha256(prompt.encode("utf-8")).hexdigest(), "images": image_refs(refs),
                  "estimated_output": list(estimate(aspect, size, model))}
    return Call("gemini", api, lambda: http.json_request("POST", url, body, headers()), parse, descriptor)


def generate(prompt: str, references: list[bytes] | list[tuple[str, bytes]] | None = None,
             model: str | None = None, aspect: str = "1:1", size: str = "1K", api: str = "interactions",
             transport: http.Transport | None = None, folder=None, budget=None) -> dict:
    from .. import jobs
    refs = [r if isinstance(r, tuple) else ("identity", r) for r in references or []]
    c = call(prompt, refs, model, aspect, size, api)
    job = jobs.create(c, folder)
    images = jobs.execute(job, c, transport, budget=budget)
    return {"images": images, "model": f"gemini/{c.descriptor['params']['model']}", "request": c.descriptor,
            "job": job.data}
