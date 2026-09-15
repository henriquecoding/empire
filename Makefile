# Makefile — os portoes, definidos uma vez.
#
# O CI chama estes alvos. Nao repete os comandos: um portao que corre de forma
# diferente na tua maquina e no runner e um portao que so descobres quando
# chumba em sitio nenhum. `make portoes` e exactamente o job "Portoes
# estaticos"; `make tudo` e o workflow inteiro menos o export e o dossie.
#
# Precisas do Godot fixado em .godot-version no PATH como `godot`, ou em GODOT.

GODOT ?= godot
DOSSIE := docs/dossie.html

.DEFAULT_GOAL := ajuda
.PHONY: ajuda tudo portoes formato estilo rng dossie-numeros conteudo spec \
        afirmacoes afirmacoes-escrever importar dados dados-gerar testes \
        exportar ferramentas ferramentas-python hooks limpar

ajuda:  ## Mostra os alvos
	@grep -hE '^[a-z0-9-]+:.*?## ' $(MAKEFILE_LIST) \
	  | sed 's/:.*## /\t/' | expand -t26 | sort

# ── O que corre sem abrir o motor ────────────────────────────────────────────

portoes: formato estilo rng dossie-numeros conteudo spec afirmacoes  ## Todos os portoes estaticos

formato:  ## gdformat: o formato do GDScript
	gdformat --check src/ tests/ tools/

estilo:  ## gdlint: estilo e o limite de 250 linhas (§28)
	gdlint src/ tests/

rng:  ## G2 (§40 I2): nenhuma aleatoriedade fora do RngService
	@! grep -rnE '\b(randi|randf|randomize|randi_range|randf_range)\s*\(' \
	    src/ --include='*.gd' | grep -v 'src/core/rng_service.gd'
	@echo "G2: sem RNG solto"

dossie-numeros:  ## Os numeros do dossie contra os CSV
	python3 tools/check_dossie_vs_csv.py $(DOSSIE)

conteudo:  ## SCHEMA, PROPOSALS, ROT_BY_DAY e NAMES em dia
	python3 tools/content_report.py --check

spec:  ## docs/design/ e gerado do dossie e nao foi editado a mao (§69)
	python3 tools/split_dossie.py $(DOSSIE) docs/design
	git diff --exit-code -- docs/design

afirmacoes:  ## A prosa e o validation.json contra a contagem real
	python3 tools/check_claims.py

afirmacoes-escrever:  ## Corrige os campos contaveis do validation.json
	python3 tools/check_claims.py --write

# ── O que precisa do motor ───────────────────────────────────────────────────

tudo: portoes dados testes  ## Portoes + dados + suite

importar:  ## Importa os recursos (obrigatorio num checkout frio, §69)
	$(GODOT) --headless --import --path . || true

dados:  ## ADR 0004/0008: os .tres estao sincronizados com os CSV
	$(GODOT) --headless --path . -s tools/csv_to_tres.gd -- --check

dados-gerar:  ## Regera os .tres a partir de data/source/*.csv
	$(GODOT) --headless --path . -s tools/csv_to_tres.gd

testes:  ## A suite gdUnit4 inteira
	./run_tests.sh

exportar:  ## Exporta o Linux e confirma que o binario arranca
	mkdir -p build
	$(GODOT) --headless --path . --export-debug "Linux" build/empire.x86_64
	test -s build/empire.x86_64
	test -s build/empire.pck
	cd build && ./empire.x86_64 --headless --quit-after 30
	@echo "export: o binario arrancou"

# ── Fora do jogo ─────────────────────────────────────────────────────────────

ferramentas:  ## Constroi o dossie e corre os dois portoes da camada de uso
	cd ferramentas && node extrair-dados.mjs .. saida/dados.json
	cd ferramentas && node construir.mjs ../$(DOSSIE) saida/dados.json saida/dossie-empire.html
	cd ferramentas && node verificar-dossie.mjs saida/dossie-empire.html
	cd ferramentas && node verificar-novo.mjs saida/dossie-empire.html

ferramentas-python:  ## Instala o gdtoolkit na versao fixada
	python3 -m pip install -r tools/requirements.txt

hooks:  ## Liga o hook de pre-commit (corre `make portoes` antes de cada commit)
	git config core.hooksPath .githooks
	@echo "hooks: core.hooksPath = .githooks"

limpar:  ## Apaga o que e gerado e nao versionado
	rm -rf build reports .godot ferramentas/saida
