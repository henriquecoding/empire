#!/usr/bin/env bash
# tools/owner_scenery/capture.sh — capturas do jogo com as composicoes do dono (ADR 0085).
#
#   GODOT=... bash tools/owner_scenery/capture.sh SAIDA
#
# Semente 1791458153, sem interface: a casa dos Enramados ao meio-dia, ao crepusculo e de noite,
# o lago na agua de casa, e os limiares que levam aos outros povos (os x do CV-02).
set -euo pipefail
GODOT="${GODOT:-godot}"
SAIDA="${1:-build/owner_scenery}"
mkdir -p "$SAIDA"
tirar() {  # nome, x do rei, segundos de relogio
	xvfb-run -a "$GODOT" --path . --resolution 1280x720 tools/captura.tscn -- --novo \
		--semente 1791458153 --segundos 3 --avancar "$3" --limpo true --rei "$2" \
		--saida "$SAIDA/$1.png" > "$SAIDA/$1.log" 2>&1
	echo "capture: $1"
}
tirar casa_meio_dia 0 110
tirar casa_crepusculo 0 240
tirar casa_noite 0 300
tirar lago_meio_dia 1292 110
tirar lago_noite 1292 300
tirar orla_dos_campos 5120 110
tirar boca_da_fenda 12160 110
tirar cicatriz_de_basalto 18560 110
tirar fronteira_sobraiz -4480 110
