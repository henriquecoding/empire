"""HTTP minimo com a biblioteca padrao: JSON, multipart, tentativas e um transporte trocavel.

Nenhuma dependencia nova (AGENTS.md, regra 8). Os testes trocam `transport` por
um falso e conferem o pedido que sairia, sem rede nem chave. As chaves vem do
ambiente e nunca entram em relatorios nem em mensagens de erro.
"""
from __future__ import annotations

import base64
import json
import os
import math
import time
import urllib.error
import urllib.request
import uuid
from dataclasses import dataclass, field
from email.utils import parsedate_to_datetime
from typing import Callable


@dataclass
class Request:
    method: str
    url: str
    headers: dict[str, str]
    body: bytes | None = None
    meta: dict = field(default_factory=dict)


@dataclass
class Response:
    status: int
    body: bytes
    headers: dict[str, str]

    def json(self):
        return json.loads(self.body.decode("utf-8"))


def urllib_transport(req: Request, timeout: float = 300.0) -> Response:
    r = urllib.request.Request(req.url, data=req.body, method=req.method, headers=req.headers)
    try:
        with urllib.request.urlopen(r, timeout=timeout) as resp:
            return Response(resp.status, resp.read(), dict(resp.headers))
    except urllib.error.HTTPError as err:
        return Response(err.code, err.read(), dict(err.headers or {}))


Transport = Callable[[Request], Response]
RETRY = {408, 409, 423, 425, 429, 500, 502, 503, 504, 529}


class ApiError(RuntimeError):
    def __init__(self, service: str, status: int, detail: str):
        super().__init__(f"{service}: HTTP {status}: {detail[:400]}")
        self.status = status


def send(req: Request, transport: Transport | None = None, service: str = "api",
         attempts: int = 4, wait: float = 2.0, sleep: Callable[[float], None] = time.sleep) -> Response:
    """GET pode repetir; uma geracao so repete uma recusa explicita por limite.

    Um 5xx/timeout depois de POST pode ter sido cobrado: nunca o repetir
    automaticamente. Corpos de erro podem repetir credenciais e nao sao logs.
    """
    if attempts < 1 or not math.isfinite(wait) or wait < 0:
        raise ValueError("tentativas e intervalo invalidos")
    transport = transport or urllib_transport
    retryable = RETRY if req.method in ("GET", "HEAD") else {429, 529}
    for attempt in range(attempts):
        try:
            resp = transport(req)
        except (OSError, ValueError):
            raise ApiError(service, 0, "falha de transporte; pedido nao repetido (resultado remoto desconhecido)") from None
        if resp.status < 400:
            return resp
        if resp.status not in retryable or attempt == attempts - 1:
            raise ApiError(service, resp.status, "pedido recusado; consulte o estado no fornecedor antes de repetir")
        retry_after = resp.headers.get("Retry-After") or resp.headers.get("retry-after")
        delay = wait * 2 ** attempt
        if retry_after:
            try:
                delay = float(retry_after)
            except ValueError:
                try:
                    delay = parsedate_to_datetime(retry_after).timestamp() - time.time()
                except (ValueError, TypeError, OverflowError):
                    pass
        if not math.isfinite(delay) or delay > 60:
            raise ApiError(service, resp.status, "Retry-After excede a espera automatica; retome mais tarde")
        sleep(max(0.0, delay))
    raise ApiError(service, 0, "sem resposta")


def json_request(method: str, url: str, payload: dict | None, headers: dict[str, str]) -> Request:
    body = json.dumps(payload).encode("utf-8") if payload is not None else None
    return Request(method, url, {**headers, "Content-Type": "application/json"}, body)


def multipart(fields: list[tuple[str, str | bytes, str | None]]) -> tuple[bytes, str]:
    """(nome, valor, nome_de_ficheiro|None) -> corpo e Content-Type."""
    boundary = "forja" + uuid.uuid4().hex
    out = bytearray()
    for name, value, filename in fields:
        out += f"--{boundary}\r\n".encode()
        if filename:
            out += (f'Content-Disposition: form-data; name="{name}"; filename="{filename}"\r\n'
                    "Content-Type: image/png\r\n\r\n").encode()
            out += value if isinstance(value, bytes) else value.encode()
        else:
            out += f'Content-Disposition: form-data; name="{name}"\r\n\r\n'.encode()
            out += value.encode() if isinstance(value, str) else value
        out += b"\r\n"
    out += f"--{boundary}--\r\n".encode()
    return bytes(out), f"multipart/form-data; boundary={boundary}"


def key(*names: str) -> str:
    for name in names:
        value = os.environ.get(name)
        if value:
            return value
    raise RuntimeError(f"falta a chave: defina {' ou '.join(names)} no ambiente")


def b64(data: bytes) -> str:
    return base64.b64encode(data).decode("ascii")


def unb64(text: str) -> bytes:
    if text.startswith("data:"):
        text = text.split(",", 1)[1]
    return base64.b64decode(text)


def find_images(node) -> list[bytes]:
    """Todas as imagens base64 numa resposta, venha ela como vier (inlineData, b64_json, base64...)."""
    found: list[bytes] = []
    if isinstance(node, dict):
        mime = node.get("mimeType") or node.get("mime_type") or node.get("format") or ""
        for k in ("b64_json", "base64", "data"):
            v = node.get(k)
            is_image = k != "data" or "image" in str(mime) or node.get("type") == "image"
            if isinstance(v, str) and len(v) > 64 and is_image:
                found.append(unb64(v))
        for k, v in node.items():
            if k not in ("b64_json", "base64", "data") or isinstance(v, (dict, list)):
                found += find_images(v)
    elif isinstance(node, list):
        for item in node:
            found += find_images(item)
    return found
