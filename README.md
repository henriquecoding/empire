# Empire (nome de trabalho)

Kingdom-builder 2D em pixel art, em Godot 4.6, onde cada império é uma civilização própria.
A fonte de verdade do design é o **Dossiê Empire** — `docs/dossie.html` (v5.2). Tudo o resto deriva dele.

## Correr, testar, exportar

Precisas do Godot **4.6-stable** (a versão está fixada em `.godot-version`) no `PATH` como `godot`, ou em `GODOT`.

```bash
godot --headless --path . --import              # primeira vez num checkout frio (§69)
./run_tests.sh                                  # a suite gdUnit4 inteira (portões G1–G5, dados)
godot --headless --path . -s tools/csv_to_tres.gd            # gera os .tres a partir dos CSV
godot --headless --path . -s tools/csv_to_tres.gd -- --check # só verifica (o CI faz isto)
godot --headless --path . -s tools/lint_sim.gd               # G1, G2 e G4 sem o gdUnit4
python3 tools/check_dossie_vs_csv.py            # os números do dossiê contra os CSV
python3 tools/content_report.py                 # regenera SCHEMA, PROPOSALS, ROT_BY_DAY, NAMES
python3 tools/split_dossie.py docs/dossie.html docs/design   # regenera a spec que o agente lê
godot --headless --path . --export-debug "Linux" build/empire.x86_64   # precisa dos templates 4.6
```

Para abrir no editor: `godot --path .` (ou abre o `project.godot`). A cena principal é `scenes/boot.tscn`.

No Windows, sem `make` nem WSL: duplo clique em `JOGAR-E-TESTAR.bat`, que corre estes mesmos
comandos a partir de um menu — ver [`windows/LEIA-ME.md`](windows/LEIA-ME.md).

## Onde está o quê

| Pasta | O quê |
|---|---|
| `AGENTS.md` | O contrato de qualquer agente de IA. **Lê primeiro.** (`CLAUDE.md` aponta para ele.) |
| `docs/dossie.html` | O dossiê — design, balanceamento, especificação. A fonte única. |
| `docs/design/` | O dossiê partido por secção, **gerado** — nunca se edita à mão |
| `docs/adr/` | As decisões e porquê (0001–0010) |
| `docs/QUESTIONS.md` | As perguntas em aberto — **começa por aqui** depois do dossiê |
| `docs/backlog/` | Os tickets das Fases 0 e 1, no formato do §34 |
| `docs/content/` | Base de dados de conteúdo: dicionário, esquema, propostas, nomes, bíblia de nomes |
| `docs/art/` | Asset Bible, registo de assets, animação, expressões, efeitos |
| `docs/world/` | Produção de segmentos, greybox, registo de segmentos |
| `docs/ux/` · `docs/audio/` · `docs/localization/` | Ecrãs e HUD · som · texto e glossário |
| `docs/qa/` | Playtest, QA, regressão, desempenho, acessibilidade |
| `docs/legal/` · `docs/release/` · `docs/marketing/` | Terceiros · checklists de lançamento · assets da loja |
| `data/source/` | **Os números.** Um CSV por tabela; `_tables.csv` é o registo |
| `data/**/*.tres` | Gerados dos CSV e versionados (ADR 0004) |
| `data/i18n/strings.csv` | Todo o texto do jogo, PT-PT e EN |
| `src/core/` | Os seis *autoloads*: `event_bus`, `clock_service`, `rng_service`, `registry`, `save_service`, `sim_loop` |
| `src/sim/` | Simulação pura: `band.gd`, `game_clock.gd`, `state/`, `ai/unit_fsm.gd`, `systems/unit_system.gd` e os 28 `Resource` de dados |
| `src/world/` | `boot.gd`, `camera_rig.gd`, `band_layers.gd`, `band_probe.gd` |
| `src/actors/` | `unit_view.gd` — os cinco slots do §58 |
| `shaders/` | `palette_lut.gdshader` — um shader, quatro trabalhos (§60) |
| `tools/` | `csv_to_tres.gd`, `lint_sim.gd`, `split_dossie.py`, `check_dossie_vs_csv.py`, `content_report.py`, `export_aseprite.sh` |
| `ferramentas/` | A camada de uso do dossiê: `construir.mjs`, `extrair-dados.mjs` e os dois portões |
| `tests/` | gdUnit4: arquitetura, dados, design |
| `art/` · `audio/` | `art/source/` em Git LFS; `art/export/` é gerado (menos `_placeholder/`) |

## O estado, no dia zero

- O projeto **abre, testa e exporta** em Godot 4.6: 412 testes (9 saltados, cada um com a razão e o sistema que
  falta escritos no próprio teste), e cada corrida verde do CI deixa o jogo exportado para **Linux, Windows e
  Web** — o de Linux é arrancado no próprio *job*, e o de Web serve-se de qualquer servidor estático.
- A base de dados tem **28 tabelas** e 203 recursos com todos os números do dossiê, Parte XIII incluída; o que o
  dossiê não dá está proposto e marcado (`docs/content/PROPOSALS.md`).
- O `tools/check_dossie_vs_csv.py` confere **197 números** do dossiê contra as tabelas, e não há divergências.
- O estado medido, ficheiro a ficheiro, está em `docs/recovery/RETOMADA.md` e em `docs/recovery/validation.json`.
- O próximo *milestone* não é mais documentação (relatório mestre, §32): é **abrir o Empire, controlar uma
  personagem real numa greybox, atravessar as três faixas, construir algo com uma moeda, sobreviver à primeira
  noite e reproduzir o resultado pela mesma *seed*.** Os tickets estão em `docs/backlog/`.

## Regras que nunca se quebram

As oito invariantes do §40, defendidas por teste: simulação pura; aleatoriedade só pelo `RngService`; faixa em
todas as entidades; balanceamento em dados; passo fixo de 30 Hz; nunca `load()` num save; comunicação por evento do
catálogo; parallax em píxeis inteiros. E a do §28: **nenhum script passa das 250 linhas.**
