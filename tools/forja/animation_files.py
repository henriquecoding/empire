"""A criação de planos e sequências fica fora dos assets de runtime."""
from pathlib import Path


def destination(folder: str | Path) -> Path:
    out = Path(folder).resolve()
    root = Path(__file__).resolve().parents[2]
    if any(out == root / name or root / name in out.parents for name in ("art", "audio")):
        raise ValueError("usar build/forja/: a animacao nao escreve em art/ nem audio/")
    return out
