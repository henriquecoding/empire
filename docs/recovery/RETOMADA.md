# Retomada — o que existe, o que foi medido, e o que não foi

_Este ficheiro é o estado verificável. Os números saem de `validation.json`, que é escrito por medição
e não à mão; a nota de abertura do dossiê cita-o e o painel de estado da camada de uso volta a contá-los
a cada construção._

## As três edições, e o que cada uma trouxe

| Edição | Data | O que trouxe |
|---|---|---|
| v5.1 | — | O dossiê como prosa: 69 secções, sem repositório. |
| v5.2 | 11/09/2026 | O repositório: projeto Godot 4.6, 23 tabelas de dados, 120 recursos, as bíblias de produção, 23 testes, 11 ADRs. Mais 105 correções de português PT-PT (AO90) e 27 edições de conteúdo, todas listadas em `docs/dossie-v5.2-correcoes.md`. |
| v6 | 13/09/2026 | A Parte XIII (§70–§85) e a camada de uso do dossiê (`ferramentas/`). O repositório recuperado trazia 17 tabelas e 154 recursos — menos dez tabelas do que a v5.2 tinha. |
| v6 + F0 | 15/09/2026 | A Fase 0 de codigo: EventBus (61 sinais), GameClock e ClockService, RngService, Registry, SaveService e o SimLoop com a ordem do §43. O relogio anda, o dia vira, o save faz ida e volta, e a semente reproduz. Mais a ADR 0020 e o portao G6. |
| v6 + XIII | 14/09/2026 | A Parte XIII em dados: quatro tabelas novas, seis alargadas, quatro `Resource` novos, catorze testes de design, nove ADRs, 19 perguntas registadas, 53 tickets, e o texto: 64 chaves de conteúdo e os doze diários da §79 escritos. |

## Como se verificou

- **Motor** — Godot 4.6-stable (`89cea1439`) em *headless*: o projeto importa sem erros e arranca.
- **Dados** — `tools/csv_to_tres.gd --check` sem diferenças: 28 tabelas, 203 recursos gerados.
- **Dossiê contra dados** — `tools/check_dossie_vs_csv.py` confere 193 números do dossiê contra as
  tabelas, e não há divergências. Eram 127 antes da Parte XIII.
- **Testes** — gdUnit4 6.2.1: 132 casos, 127 a passar, 5 saltados **com a razão escrita no próprio teste**,
  zero falhas, zero *orphans*. Eram 43 casos e 6 saltados antes do F0-07.
- **Estilo** — `gdformat --check` e `gdlint` limpos sobre `src/`, `tests/` e `tools/`.
- **Portões de arquitetura** — `lint_sim` limpo em G1, G2, G4 e **G6** (o save nunca usa `load()`),
  e os três modos de quebrar o G6 estão medidos, não supostos.
- **As três faixas** — as nove combinações do §53 medidas com o motor de física, não deduzidas da
  tabela: a diagonal bate e tudo o resto atravessa. `scenes/tests/bands.tscn` escreve-a no arranque.
- **O ciclo anda** — dois dias de simulação a 30 Hz, 21 600 ticks, as doze transições de fase nos
  segundos exatos da tabela do §48 (15, 100, 140, 225, 255, 360…), e a fila de eventos a voltar a
  zero em todos os ticks.
- **Afirmações** — `tools/check_claims.py` reconta a árvore e confere 14 afirmações em prosa, 13
  campos do `validation.json` e o `tickets.json`. Um número escrito à mão que a contagem desminta
  chumba o CI.
- **A camada de uso** — os dois portões de `ferramentas/` passam sobre a construção de hoje:
  `verificar-dossie.mjs` (telemóvel, âncoras, JavaScript, pesquisa) e `verificar-novo.mjs`
  (plano, saúde, tabelas, recorte).

## O que NÃO foi verificado, e é por isso que o dossiê continua a dizer que não há jogo

| O quê | Porquê |
|---|---|
| Jogabilidade | Ninguém jogou, e continua a não haver jogo: o ciclo anda e o dia vira, mas não há uma única unidade, moeda, muralha ou Podridão. São os passos 2 a 10 do `SimLoop`, escritos e vazios, cada um com o ticket que o preenche. |
| GPU e arte | A medição correu sem placa gráfica. O LUT, a luz e as silhuetas continuam por ver. |
| CI remoto | O `run_tests.sh` corre localmente; nunca correu num *runner* limpo. É a Q-052. |
| As nove cenas de segmento | Não sobreviveram ao ZIP recuperado. É a Q-048. |
| Áudio | 73 pistas escritas na bíblia, zero gravadas. |
| A prosa | Os doze diários estão escritos e são **primeira versão**. Não há teste que apanhe prosa morna (§84): o único controlo é o espécime do diário 9. |

## Onde está cada coisa

| Pasta | O que lá está |
|---|---|
| `data/source/` | As 28 tabelas, com `_phase`, `_src`, `_proposed` e `_notes` em cada linha. É a fonte. |
| `data/**/*.tres` | Os 203 recursos gerados. Versionados de propósito (ADR 0004). |
| `src/sim/` | Puro: sem `Node`, sem `import` para fora. O portão G1 chumba se alguém o quebrar. |
| `tests/` | Arquitetura (G1, G2, G4), dados (tabelas, referências, chaves de texto) e design (§07, §31, §84). |
| `docs/design/` | Este dossiê partido por secção, 87 ficheiros, gerado por `tools/split_dossie.py`. |
| `docs/adr/` | 20 decisões. A 0011 fecha a noite castanha; a 0012 a 0019 são a Parte XIII; a 0020 é a ordem do tick. |
| `docs/backlog/` | 53 tickets, um ficheiro cada, no formato da §34. |
| `docs/content/` | Esquema, propostas, a Podridão dia a dia, os nomes. Tudo gerado. |
| `data/i18n/strings.csv` | 271 chaves PT-PT e EN, zero por escrever. É o `strings.csv` único da §27. |
| `ferramentas/` | A camada de uso do dossiê: construtor, extrator e os dois portões. |

## A regra que continua a valer

A §72 fechou a pré-produção: o dossiê só muda por correção, por decisão que vira ADR, ou por número que um
*playtest* desmentiu. Tudo o que a Parte XIII decidiu virou ADR antes de virar dados, e cada valor que não
estava escrito no dossiê entrou marcado em `_proposed`, com a razão em `_notes`. Nada foi decidido em silêncio.
