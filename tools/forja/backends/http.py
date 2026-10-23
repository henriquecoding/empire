"""HTTP minimo com a biblioteca padrao: JSON, multipart, tentativas e um transporte trocavel.

Nenhuma dependencia nova (AGENTS.md, regra 8). Os testes trocam `transport` por
um falso e conferem o pedido que sairia, sem rede nem chave. As chaves vem do
ambiente e nunca entram em relatorios, registos nem mensagens de erro.

Regra das tentativas (auditoria F01): um POST de geracao e cobrado e nenhum dos
fornecedores ligados documenta idempotencia, por isso sai UMA vez. Se o servidor
o recusa com uma resposta clara (4xx), o erro diz `rejected` — nada foi aceite.
Se a resposta se perde (rede, tempo esgotado, 5xx), o erro e `SubmissionUnknown`:
pode ter sido aceite e cobrado, e quem chamou reconcilia antes de pedir outra vez
(`tools/forja/jobs.py`). So as consultas (GET, HEAD, DELETE de um job) se repetem,
com espera exponencial, jitter, `Retry-After` e um prazo total.
"""
from __future__ import annotations

import base64
import email.utils
import http.client
import json
import os
import random
import time
import urllib.error
import urllib.request
import uuid
from dataclasses import dataclass, field
from datetime import datetime, timezone
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
SAFE = frozenset({"GET", "HEAD", "OPTIONS", "DELETE"})
RETRY = frozenset({408, 425, 429, 500, 502, 503, 504, 529})
NETWORK = (OSError, http.client.HTTPException)
REFUSED = frozenset(range(400, 500)) - {408}


class ApiError(RuntimeError):
    """`outcome`: rejected (o servidor recusou), unknown (pode ter sido aceite) ou failed (consulta sem fim)."""

    def __init__(self, service: str, status: int, detail: str, outcome: str = "failed",
                 retry_after: float | None = None):
        super().__init__(f"{service}: HTTP {status}: {detail[:400]}" if status else f"{service}: {detail[:400]}")
        self.service, self.status, self.outcome, self.retry_after = service, status, outcome, retry_after


class SubmissionUnknown(ApiError):
    """O POST saiu e a resposta nao chegou (ou foi um 5xx): nao se sabe se foi aceite."""

    def __init__(self, service: str, detail: str, status: int = 0, retry_after: float | None = None):
        super().__init__(service, status, detail, "unknown", retry_after)


def retry_after(headers: dict[str, str], now: datetime | None = None) -> float | None:
    """Segundos pedidos pelo servidor: `Retry-After` em segundos ou em data HTTP."""
    value = headers.get("Retry-After") or headers.get("retry-after")
    if not value:
        return None
    try:
        return max(0.0, float(value))
    except ValueError:
        pass
    try:
        when = email.utils.parsedate_to_datetime(value)
    except (TypeError, ValueError):
        return None
    return max(0.0, (when - (now or datetime.now(timezone.utc))).total_seconds())


def _entry(req: Request, started: float, clock: Callable[[], float], **result) -> dict:
    return {"method": req.method, "url": req.url.split("?")[0], **result,
            "ms": round((clock() - started) * 1000)}


def send(req: Request, transport: Transport | None = None, service: str = "api", *, deadline: float = 120.0,
         attempts: int = 6, wait: float = 1.0, max_wait: float = 30.0,
         sleep: Callable[[float], None] = time.sleep, clock: Callable[[], float] = time.monotonic,
         rand: Callable[[], float] = random.random, log: list | None = None,
         refused: frozenset[int] = REFUSED) -> Response:
    """Envia um pedido. POST: uma vez. GET/DELETE: repete nos codigos de espera ate ao prazo.

    `log` recebe uma entrada por tentativa (metodo, URL sem query, estado, tempo, espera),
    sem cabecalhos. `refused` sao os codigos em que um POST foi claramente recusado.
    """
    transport = transport or urllib_transport
    log = [] if log is None else log
    safe = req.method.upper() in SAFE
    start = clock()
    status, detail, pause = 0, "sem resposta", None
    for attempt in range(attempts if safe else 1):
        t0 = clock()
        try:
            resp = transport(req)
        except NETWORK as err:
            log.append(_entry(req, t0, clock, error=type(err).__name__))
            if not safe:
                raise SubmissionUnknown(service, f"sem resposta ({type(err).__name__}): o pedido pode ter "
                                                 "sido aceite; reconcilie antes de pedir outra vez") from err
            status, detail, pause = 0, f"sem resposta ({type(err).__name__})", None
        else:
            log.append(_entry(req, t0, clock, status=resp.status))
            if resp.status < 400:
                return resp
            status, detail = resp.status, resp.body.decode("utf-8", "replace")
            pause = retry_after(resp.headers)
            if not safe:
                if status in refused:
                    raise ApiError(service, status, detail, "rejected", pause)
                raise SubmissionUnknown(service, detail, status, pause)
            if status not in RETRY:
                raise ApiError(service, status, detail, "rejected", pause)
        if attempt == attempts - 1:
            break
        delay = pause if pause is not None else min(max_wait, wait * 2 ** attempt) * (0.5 + rand() / 2)
        if clock() - start + delay > deadline:
            raise ApiError(service, status, f"prazo de {deadline:g}s esgotado: {detail}", "failed", pause)
        log[-1]["wait_s"] = round(delay, 3)
        sleep(delay)
    raise ApiError(service, status, f"{attempts} tentativas: {detail}", "failed", pause)


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


class MissingKey(RuntimeError):
    """Sem chave no ambiente: nada saiu para a rede."""


def key(*names: str) -> str:
    for name in names:
        value = os.environ.get(name)
        if value:
            return value
    raise MissingKey(f"falta a chave: defina {' ou '.join(names)} no ambiente (nada foi enviado)")


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
            if k not in ("b64_json", "base64", "data"):
                found += find_images(v)
    elif isinstance(node, list):
        for item in node:
            found += find_images(item)
    return found
