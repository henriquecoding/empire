#!/usr/bin/env bash
# tools/export_aseprite.sh — exporta um .aseprite como uma folha PNG + JSON por camada.
# Regras: docs/art/ASSET_BIBLE.md, secoes 2, 3 e 5.
#
# Uso:  tools/export_aseprite.sh art/source/enramados/enramados_villager.aseprite
#       ASEPRITE=/caminho/para/aseprite tools/export_aseprite.sh <ficheiro>
#
# Testado a 29/10/2026 (FORJA-14) com o Aseprite 1.3.18.6 sobre o "Empire troop": nomes, quadros, tags e
# duracoes conferem; o pivot nao vai no JSON (sem --list-slices; Q-302). `python3 -m tools.forja exportar`
# escreve o mesmo sem o Aseprite (tools/forja/tests/test_ase_conformidade.py confere-o contra este script).
set -euo pipefail
ASEPRITE="${ASEPRITE:-aseprite}"
SRC="${1:?uso: tools/export_aseprite.sh <ficheiro.aseprite>}"
REL="${SRC#art/source/}"
DIR="art/export/$(dirname "$REL")"
BASE="$(basename "$SRC" .aseprite)"
# Camadas de trabalho que nunca se exportam (ASSET_BIBLE §2).
SKIP='^(Knight|References|Background)$'
mkdir -p "$DIR"
"$ASEPRITE" -b --list-layers "$SRC" | while IFS= read -r LAYER; do
  [[ "$LAYER" =~ $SKIP ]] && continue
  NAME="$(printf '%s' "$LAYER" | tr '[:upper:] ' '[:lower:]_')"
  "$ASEPRITE" -b --layer "$LAYER" "$SRC" \
    --sheet "$DIR/${BASE}_${NAME}.png" --sheet-type rows \
    --data "$DIR/${BASE}_${NAME}.json" --format json-array --list-tags
  echo "exportado: $DIR/${BASE}_${NAME}.png"
done
