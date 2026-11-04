"""Ficheiros e fingerprints das provas; nenhum caminho do manifesto sai da sua pasta."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path


def digest(data: dict) -> str:
    return hashlib.sha256(json.dumps(data, sort_keys=True, ensure_ascii=False,
                                    separators=(",", ":")).encode("utf-8")).hexdigest()


def file_sha(path: str | Path) -> str:
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def save(path: str | Path, data: dict) -> None:
    Path(path).write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def resolve(base: Path, name: str) -> Path:
    if not isinstance(name, str) or not name or Path(name).is_absolute():
        raise ValueError("prova: caminho relativo esperado")
    path = (base / name).resolve()
    if base.resolve() not in path.parents:
        raise ValueError("prova: caminho fora da pasta")
    return path


def seal(data: dict, base: Path, files: list[str]) -> dict:
    data.pop("manifest_sha256", None)
    data["files"] = {name: file_sha(resolve(base, name)) for name in files}
    data["manifest_sha256"] = digest(data)
    save(base / "manifest.json", data)
    return data


def check(path: str | Path, schema: str) -> tuple[dict, list[str]]:
    path = Path(path)
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict) or data.get("schema") != schema:
        raise ValueError("prova: schema invalido")
    errors = []
    if not isinstance(data.get("files"), dict) or not data["files"]:
        raise ValueError("prova: ficheiros e hashes obrigatorios")
    fingerprint = digest({k: v for k, v in data.items() if k != "manifest_sha256"})
    if data.get("manifest_sha256") != fingerprint:
        errors.append("manifesto alterado")
    for name, sha in data.get("files", {}).items():
        p = resolve(path.parent, name)
        if not p.is_file() or file_sha(p) != sha:
            errors.append("ficheiro ausente ou alterado: " + name)
    return data, errors
