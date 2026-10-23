"""De onde veio cada asset, para a revisao nao ter de adivinhar.

O guia de personagens (§5) pede referencia, prompt integral, ferramenta usada,
quantidade pedida e recebida. A Forja grava o que sabe e marca o que nao pode
saber: a aprovacao artistica e do autor, nunca da ferramenta.
"""
from __future__ import annotations

import datetime
import subprocess
from pathlib import Path

from . import __version__
from .imageops import sha256

ROOT = Path(__file__).resolve().parents[2]


def commit() -> str | None:
    try:
        out = subprocess.run(["git", "-C", str(ROOT), "rev-parse", "HEAD"], capture_output=True,
                             text=True, timeout=5, check=False)
    except (OSError, subprocess.SubprocessError):
        return None
    return out.stdout.strip() or None


def record(source: str | Path | None, generator: str | None, prompt: str | None, params: dict) -> dict:
    src = Path(source) if source else None
    return {
        "tool": "forja", "version": __version__, "commit": commit(),
        "created_utc": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "input": {"path": str(src) if src else None, "sha256": sha256(src) if src and src.exists() else None},
        "generator": generator or "desconhecido", "prompt": prompt,
        "params": {k: (list(v) if isinstance(v, tuple) else v) for k, v in params.items()},
        "state": {"adapted_from_generated_image": True, "manual_review": "pendente",
                  "artistic_approval": False, "tested_in_godot": False},
    }
