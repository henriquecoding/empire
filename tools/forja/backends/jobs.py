"""Trabalhos PixelLab: uma submissao, espera limitada e retoma pelo mesmo id."""
from __future__ import annotations

import math
import re
import time
from typing import Callable

from . import http


def poll_job(job_id: str, headers: dict[str, str], transport: http.Transport | None = None,
             interval: float = 3.0, timeout: float = 600.0, max_polls: int = 120,
             sleep: Callable = time.sleep, clock: Callable = time.monotonic) -> dict:
    if not re.fullmatch(r"[A-Za-z0-9_-]{1,160}", job_id):
        raise ValueError("id de trabalho invalido")
    if not math.isfinite(timeout) or timeout <= 0 or not math.isfinite(interval) or interval < 0 or max_polls < 1:
        raise ValueError("limites de espera invalidos")
    end = clock() + timeout
    for _ in range(max_polls):
        remaining = end - clock()
        if remaining <= 0:
            break
        req = http.json_request("GET", f"https://api.pixellab.ai/v2/background-jobs/{job_id}", None, headers)
        fetch = transport or (lambda r: http.urllib_transport(r, min(60.0, remaining)))
        data = http.send(req, fetch, "pixellab", attempts=1).json()
        status = data.get("status")
        if status == "completed":
            return data.get("last_response") or {}
        if status in ("failed", "canceled", "cancelled"):
            raise http.ApiError("pixellab", 200, f"trabalho {job_id}: {status}")
        if status not in ("pending", "queued", "processing", "running"):
            raise http.ApiError("pixellab", 200, f"estado desconhecido no trabalho {job_id}")
        if transport is None:
            sleep(min(interval, max(0.0, end - clock())))
    raise http.ApiError("pixellab", 0, f"prazo de espera esgotado; retome o trabalho {job_id}, sem gerar novamente")


def submit(endpoint: str, body: dict, headers: dict[str, str], transport: http.Transport | None = None,
           poll: float = 3.0, timeout: float = 600.0, max_polls: int = 120,
           on_job: Callable[[str], None] | None = None) -> tuple[dict, str | None]:
    req = http.json_request("POST", f"https://api.pixellab.ai/v2/{endpoint}", body, headers)
    data = http.send(req, transport, "pixellab").json()
    job = data.get("background_job_id")
    if job:
        if on_job:
            on_job(job)
        data = poll_job(job, headers, transport, poll, timeout, max_polls)
    return data, job
