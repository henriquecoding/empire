#!/usr/bin/env bash
# tools/export_aseprite.sh — exporta um .aseprite como uma folha PNG + JSON por camada.
# Regras: docs/art/ASSET_BIBLE.md, secoes 2, 3 e 5.
#
# Uso:  tools/export_aseprite.sh art/source/enramados/enramados_villager.aseprite
#       ASEPRITE=/caminho/para/aseprite tools/export_aseprite.sh <ficheiro>
#
# ATENCAO: nao foi testado no ambiente onde o repositorio foi montado (sem Aseprite).
# Corre-o uma vez com o "Empire troop" e confere pivot, tags e nomes antes de confiar nele.
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
