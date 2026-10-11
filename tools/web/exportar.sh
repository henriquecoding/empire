#!/usr/bin/env bash
# Preserva o resultado do motor, mesmo que o log filtrado fique vazio.
set -euo pipefail
motor="$1"
destino="$2"
log_export=$(mktemp)
trap 'rm -f "$log_export"' EXIT
resultado=0
"$motor" --headless --path . --export-release Web "$destino" >"$log_export" 2>&1 || resultado=$?
grep -vE 'savepack|Storing File|^\s*(at:|GDScript backtrace)|^\s*$' "$log_export" || true
if [ "$resultado" -ne 0 ]; then
  echo "construir: o motor falhou no export (codigo $resultado)" >&2
  exit "$resultado"
fi
for f in index.html index.js index.wasm index.pck; do
  test -s "$(dirname "$destino")/$f" || { echo "construir: falta jogar/$f — o export falhou" >&2; exit 1; }
done
