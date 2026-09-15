#!/usr/bin/env bash
# O unico comando de testes. Usa-o tu e usa-o o agente: assim ha um so sitio
# para mudar quando o gdUnit4 mudar de caminho.
set -euo pipefail
GODOT="${GODOT:-godot}"
"$GODOT" --headless --import --path . >/dev/null 2>&1 || true
# v5.2: o gdUnit4 6.x recusa --headless sem --ignoreHeadlessMode (sai com 103).
# A suite nao usa InputEvents, por isso e seguro. ADR 0009.
"$GODOT" --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a tests "$@"
