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

# `make captura` — o ponto do dia sai daqui, para nao ficar escrito no alvo.
CAPTURA ?= build/empire.png
SEGUNDOS ?= 3
AVANCAR ?= 0
EXTRA ?=

# O MEIO da noite, em segundos de jogo. Sai do clock.csv e nao de uma conta
# escrita a mao: mudar uma duracao no CSV muda a fotografia sozinha. O meio e o
# ponto em que a cor da fase e ela propria — a mesma regra do BandLight.
NOITE_PY := import csv; r = next(csv.DictReader(open("data/source/clock.csv"))); \
	    print(int(sum(float(r[f]) for f in "dawn morning noon afternoon dusk".split()) \
	    + float(r["night"]) / 2))
NOITE_S := $(shell python3 -c '$(NOITE_PY)')

# A versao do actionlint vive aqui e so aqui; o CI chama `make workflows`.
ACTIONLINT_VERSION := 1.7.7
ACTIONLINT := $(HOME)/.cache/actionlint/actionlint

.DEFAULT_GOAL := ajuda
.PHONY: ajuda tudo portoes formato estilo rng workflows dossie-numeros conteudo spec \
        afirmacoes afirmacoes-escrever importar dados dados-gerar testes captura \
        captura-noite silhueta vistoria exportar exportar-windows exportar-web exportar-tudo \
        ferramentas ferramentas-python hooks limpar

ajuda:  ## Mostra os alvos
	@grep -hE '^[a-z0-9-]+:.*?## ' $(MAKEFILE_LIST) \
	  | sed 's/:.*## /\t/' | expand -t26 | sort

# ── O que corre sem abrir o motor ────────────────────────────────────────────

portoes: formato estilo rng workflows dossie-numeros conteudo spec afirmacoes  ## Todos os portoes estaticos

formato:  ## gdformat: o formato do GDScript
	gdformat --check src/ tests/ tools/

estilo:  ## gdlint: estilo e o limite de 250 linhas (§28)
	gdlint src/ tests/

workflows: $(ACTIONLINT)  ## actionlint: o workflow tem de ser valido PARA O GITHUB
	@$(ACTIONLINT)
	@echo "actionlint: workflows validos"

# O yaml.safe_load do Python le o ficheiro e diz que esta bem — so ve YAML. As
# expressoes ${{ }} sao outra linguagem, e um erro nelas invalida o ficheiro
# INTEIRO: nenhum job chega a ser criado, a corrida morre em zero segundos e nao
# deixa registo nenhum para ler. Aconteceu onze vezes seguidas (PR #4).
$(ACTIONLINT):
	@mkdir -p $(dir $(ACTIONLINT))
	@curl -fsSL "https://github.com/rhysd/actionlint/releases/download/v$(ACTIONLINT_VERSION)/actionlint_$(ACTIONLINT_VERSION)_linux_amd64.tar.gz" \
	  | tar xz -C $(dir $(ACTIONLINT)) actionlint
	@$(ACTIONLINT) --version | head -1

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

tudo: portoes dados testes vistoria  ## Portoes + dados + suite + vistoria

importar:  ## Importa os recursos (obrigatorio num checkout frio, §69)
	$(GODOT) --headless --import --path . || true

dados:  ## ADR 0004/0008: os .tres estao sincronizados com os CSV
	$(GODOT) --headless --path . -s tools/csv_to_tres.gd -- --check

dados-gerar:  ## Regera os .tres a partir de data/source/*.csv
	$(GODOT) --headless --path . -s tools/csv_to_tres.gd

testes:  ## A suite gdUnit4 inteira
	./run_tests.sh

captura:  ## Uma fotografia da cena de jogo (precisa de xvfb-run num servidor)
	mkdir -p build
	$(GODOT) --path . --resolution 1280x720 tools/captura.tscn -- \
	  --segundos $(SEGUNDOS) --avancar $(AVANCAR) --saida $(CAPTURA) $(EXTRA)
	test -s $(CAPTURA)

# O ponto do dia nao e um parametro aqui: a regra das duas excepcoes do §80 so
# existe a noite, e o NOITE_S conta o meio dela do clock.csv. `--novo` porque
# uma captura que retomasse um save era de um dia qualquer.
captura-noite: CAPTURA = build/noite.png
captura-noite: AVANCAR = $(NOITE_S)
captura-noite: EXTRA = --novo
captura-noite: captura  ## Uma fotografia do meio da noite, com ficha ao lado

silhueta: captura-noite  ## XIII-01 (§80): a regra das duas excecoes, contada
	python3 tools/check_silhueta.py build/noite.png

# DIAS= para correr mais. Nao mede balanceamento — mede se o estado se mantem
# coerente com o jogo a andar, e por isso chumba com o que encontrar.
DIAS ?= 8

vistoria:  ## Uma partida longa com piloto, vigiada tick a tick
	$(GODOT) --headless --path . scenes/tests/vistoria.tscn -- --dias $(DIAS)

exportar:  ## Exporta o Linux e confirma que o binario arranca
	mkdir -p build
	$(GODOT) --headless --path . --export-debug "Linux" build/empire.x86_64
	test -s build/empire.x86_64
	test -s build/empire.pck
	cd build && ./empire.x86_64 --headless --quit-after 30
	@echo "export: o binario arrancou"

# O Windows nao se pode arrancar aqui para confirmar; o que se confirma e que o
# .exe e o .pck sairam com tamanho. Um .pck vazio e o defeito que este teste
# apanha, e e o unico que apanha sem uma maquina Windows.
exportar-windows:  ## Exporta o Windows (nao arranca: o runner e Linux)
	mkdir -p build/windows
	$(GODOT) --headless --path . --export-debug "Windows Desktop" build/windows/empire.exe
	test -s build/windows/empire.exe
	test -s build/windows/empire.pck
	@echo "export: o .exe saiu"

# O preset tem thread_support desligado, e por isso NAO precisa dos cabecalhos
# COOP/COEP: serve-se de qualquer servidor estatico, incluindo o
# `python3 -m http.server`. E o caminho para jogar sem instalar nada.
exportar-web:  ## Exporta o Web (release: o debug nao cabe em lado nenhum)
	mkdir -p build/web
	$(GODOT) --headless --path . --export-release "Web" build/web/index.html
	test -s build/web/index.wasm
	test -s build/web/index.pck
	@echo "export: o web saiu"

exportar-tudo: exportar exportar-windows exportar-web  ## Os tres exports

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
