"""Verifica downloads e caches antes de executar o motor ou usar templates."""
import argparse
import hashlib
import json
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("kind", choices=["motor", "templates", "archive-linux", "archive-templates"])
parser.add_argument("path", type=Path)
args = parser.parse_args()
manifest = json.loads(Path("tools/godot-checksums.json").read_text())
if manifest["version"] != Path(".godot-version").read_text().strip():
    raise SystemExit("Godot: falta atualizar o manifesto de hashes da versão fixada")

def verify(path, expected):
    if not path.is_file():
        raise SystemExit(f"Godot: falta {path}")
    with path.open("rb") as source:
        digest = hashlib.file_digest(source, "sha256").hexdigest()
    if digest != expected:
        raise SystemExit(f"Godot: SHA-256 incorreto em {path}; limpa/reconstroi o cache")

if args.kind == "templates":
    for name, digest in manifest["templates"].items():
        verify(args.path / name, digest)
else:
    expected = manifest["motor"] if args.kind == "motor" else manifest["archives"][args.kind.removeprefix("archive-")]
    verify(args.path, expected)
print(f"Godot: hashes de {args.kind} confirmados")
