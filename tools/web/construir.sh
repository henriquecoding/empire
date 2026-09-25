#!/usr/bin/env bash
# tools/web/construir.sh — o site do Empire, de um checkout frio (ADR 0024).
#
# E o `buildCommand` do vercel.json, e corre igual numa maquina qualquer com
# Node e bash: `make site`. Nao precisa de nada instalado — o motor e o
# template Web vem dos releases oficiais, na versao de .godot-version, por
# pedidos parciais (tools/web/obter_godot.mjs).
#
# Sai em build/site/:
#   /          a pagina de entrada (tools/web/site/, com os numeros contados agora)
#   /jogar/    o export Web do jogo, com a casca tools/web/shell.html
#   /dossie/   o dossie construido pela camada de uso (ferramentas/)
#
# Se o motor ja estiver no PATH ou em GODOT, usa esse (e o caso local).
set -euo pipefail
cd "$(dirname "$0")/../.."

SAIDA="${SAIDA:-build/site}"
CACHE="${EMPIRE_CACHE:-node_modules/.cache/empire}"
T0=$(date +%s)
passo() { echo "── $(( $(date +%s) - T0 ))s · $*"; }

passo "o motor"
if [ -z "${GODOT:-}" ]; then
  node tools/web/obter_godot.mjs "$CACHE"
  GODOT="$CACHE/godot-$(tr -d '[:space:]' < .godot-version)"
else
  # Com motor proprio, o template Web tem de estar na mesma: sem ele o export chumba.
  node tools/web/obter_godot.mjs "$CACHE" --so-templates
fi
"$GODOT" --version

rm -rf "$SAIDA"
mkdir -p "$SAIDA/jogar" "$SAIDA/dossie"
# O Godot nao desce a build/: sem isto, o que la estiver de uma construcao
# anterior (capturas, o proprio site) era importado e ia parar ao .pck.
touch build/.gdignore

# §69: num checkout frio os recursos tem de ser importados antes do export. O
# import sai com erro quando ha avisos de recursos que nao sao do jogo; o que
# conta e o export a seguir, que chumba de verdade.
passo "importar os recursos"
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true

passo "exportar o Web"
# O export escreve uma linha por ficheiro guardado; fica so o que nao e isso.
"$GODOT" --headless --path . --export-release "Web" "$SAIDA/jogar/index.html" 2>&1 \
  | grep -vE 'savepack|Storing File|^\s*(at:|GDScript backtrace)|^\s*$' || true
for f in index.html index.js index.wasm index.pck; do
  test -s "$SAIDA/jogar/$f" || { echo "construir: falta jogar/$f — o export falhou" >&2; exit 1; }
done

passo "o dossie"
node ferramentas/extrair-dados.mjs . build/dossie-dados.json
node ferramentas/construir.mjs docs/dossie.html build/dossie-dados.json "$SAIDA/dossie/index.html"

passo "a pagina de entrada"
node tools/web/pagina.mjs "$SAIDA"

passo "pronto"
du -sh "$SAIDA" | sed "s/^/   /"
ls -la "$SAIDA/jogar" | awk '/index\.(wasm|pck|js)$/ {printf "   %6.1f MB  %s\n", $5/1048576, $9}'
