"""Ligacoes opcionais a geradores de imagem: OpenAI (gpt-image), Gemini e PixelLab.

A Forja funciona sem nenhuma: o agente pode gerar a imagem com a sua propria
ferramenta e passar o ficheiro. Com uma chave no ambiente, `forja generate`
pede a imagem e ja devolve o PNG, pronto para `forja forge`.

Cada adaptador monta um `Call` (o pedido, validado localmente antes de qualquer
rede) e sabe ler a resposta num `Result`. Quem envia, regista e retoma e o
`tools/forja/jobs.py`: os adaptadores nao repetem POSTs nem guardam estado.
"""
from __future__ import annotations

import hashlib
import json
from dataclasses import dataclass, field
from typing import Callable

from . import http


@dataclass
class Result:
    """Resposta normalizada: imagens, id remoto, estado do job remoto e custo, se o fornecedor o diz."""

    images: list[bytes] = field(default_factory=list)
    remote_id: str | None = None
    state: str = "completed"
    usage_usd: float | None = None
    detail: dict = field(default_factory=dict)


@dataclass
class Call:
    """Um pedido pronto a sair. `request` le a chave so na hora de enviar.

    `descriptor` e o que se guarda e se resume no hash do pedido: endpoint,
    parametros efetivos, hashes e papeis das imagens — nunca base64 nem chaves.
    """

    service: str
    operation: str
    request: Callable[[], http.Request]
    parse: Callable[[dict], Result]
    descriptor: dict
    refused: frozenset[int] = http.REFUSED
    estimate_usd: float | None = None


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def digest(descriptor: dict) -> str:
    """Hash estavel do pedido (JSON canonico)."""
    return sha(json.dumps(descriptor, sort_keys=True, ensure_ascii=False).encode("utf-8"))


def image_refs(images: list[tuple[str, bytes]]) -> list[dict]:
    """[(papel, png)] -> o que entra no descritor: papel, hash e tamanho em bytes."""
    return [{"role": role, "sha256": sha(data), "bytes": len(data)} for role, data in images]


def poller(service: str):
    """Quem sabe consultar um job remoto deste fornecedor (so o PixelLab tem jobs)."""
    if service == "pixellab":
        from . import pixellab_api
        return pixellab_api.poll_call
    return None


def canceller(service: str):
    if service == "pixellab":
        from . import pixellab_api
        return pixellab_api.cancel_call
    return None
