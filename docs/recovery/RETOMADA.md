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
| v6 + F0 | 15/09/2026 | A Fase 0 de código, catorze dos dezasseis tickets: EventBus (61 sinais), GameClock e ClockService, RngService, Registry, SaveService, o SimLoop com a ordem do §43, a câmara única, o BandLayers com as três faixas provadas por física, e o UnitView com os cinco slots e o `palette_lut`. O relógio anda, o dia vira, o save faz ida e volta, e a semente reproduz. Mais a ADR 0020, o portão G6, o `check_claims` e a tabela 28 (`camera`). |
| v6 + F1 | 15/09/2026 | A Fase 1 **inteira**: os dezassete tickets, pela ordem do §66. As tropas em colunas, a moeda física, o minuto 0:20, o JobBoard, a muralha do §10 com os dois caminhos, o arqueiro e a certeza da torre, a Podridão e as criaturas nas três faixas, a economia e o *payback* do §06, a moral e a fuga, a luz por faixa, o save do estado da simulação, e a cena de jogo com os dois verbos ligados. Fecha com o **F1-15** (o cenário fechado do §07 em *headless*) e o **F1-16**, que é o critério de saída: *"sobreviver 10 dias é possível e não é trivial"* mede-se e passa nas duas metades — a defesa do décimo dia aguenta dez noites com o núcleo intacto, e os oito degraus abaixo dela caem. Para lá chegar foi preciso fechar a Q-076: o `contact_slots` passou a ser coluna do `buildings.csv`, e o castelo-árvore passou a poder ser atacado. E fecha com o **F1-17**: a mancha passou a trazer a candeia do §74 — três paragens do §80, lidas de `data/`, com o *dither* de 2 px —, e é a luz que entra no ecrã antes dela. |
| v6 + jogo | 16/09/2026 | O *greybox* passa a jogar-se, e a lista é a do §24. A lei da travessia do §21 aplicada — a região atravessa-se em 48 s a pé e não em 148 (ADR 0021, Q-082). O preço do que está debaixo do rei, em moedas por cima da coisa (§55). «Largar em contínuo», que estava no mapa de comando e ninguém lia (Q-083). O rei deixa de ficar preso em combate, porque o §24 dá a «Mover» o contexto *Sempre* (Q-085). O golpe passa a ver-se — flash de 80 ms, partícula, e a orla da obra que está a ser comida (Q-084). E a moeda ganha sombra de contacto, que o §24 chama «a animação mais importante do jogo». Seis tickets: GB-04 a GB-09. |
| v6 + comando | 24/09/2026 | O comando do §24, afinado. O *render* passa a interpolar entre ticks, que é a segunda metade da I5 da §40 — o rei andava aos solavancos de 2,67 px e zero, e passa a 1,33 px por frame; e deixa de baloiçar parado. O gatilho direito marca uma vez por puxão e a partir do rei (Q-086); a câmara livre anda também com o rato na margem (Q-087). A pausa ganha as duas opções que o §26 diz obrigatórias — tremor e clarões —, gravadas em `user://settings.cfg` com a regra da ADR 0007 (Q-090). A passagem passa a dizer onde o Verbo 2 pega, com uma seta para a faixa de destino. O rodapé mostra os botões do dispositivo que se está a usar (§26). A derrota deixa de dizer «ESC para continuar» e oferece um jogo novo, como o §16 manda (Q-088). E o amanhecer atravessa a região a 900 px/s, e as tropas saem dos postos atrás dessa luz, uma a uma (Q-089). Depois, o resto do HUD diegético do §24: o sol e a lua passam a dizer a hora, a moeda dá o pequeno salto ao pousar, e a cara de quem está ferido muda abaixo de metade da vida. Do §26 e do §25 entram ainda as legendas de som, o slider de duração do dia (240–540 s, pela fila de intenções e guardado no save — Q-091) e a silhueta fantasma a piscar. E o contraste e os três modos para daltonismo do §26, num filtro de ecrã medido contra a própria conta (Q-093). O painel passa a falar por chave, como o §27 manda, e o idioma escolhe-se na pausa. Dezanove tickets: GB-10 a GB-28; a vistoria dá a mesma tabela, linha a linha, e a única mudança na simulação é a cascata do amanhecer. |
| v6 + XIII | 14/09/2026 | A Parte XIII em dados: quatro tabelas novas, seis alargadas, quatro `Resource` novos, catorze testes de design, nove ADRs, 19 perguntas registadas, 53 tickets, e o texto: 64 chaves de conteúdo e os doze diários da §79 escritos. |

## Como se verificou

- **Motor** — Godot 4.6-stable (`89cea1439`) em *headless*: o projeto importa sem erros e arranca.
- **Dados** — `tools/csv_to_tres.gd --check` sem diferenças: 28 tabelas, 203 recursos gerados.
- **Dossiê contra dados** — `tools/check_dossie_vs_csv.py` confere 197 números do dossiê contra as
  tabelas, e não há divergências. Eram 127 antes da Parte XIII.
- **Testes** — gdUnit4 6.2.1: 607 casos, 599 a passar, 8 saltados **com a razão escrita no próprio teste**,
  zero falhas, zero *orphans*. Eram 43 casos antes do F0-07 e 173 antes do núcleo jogável.
- **Estilo** — `gdformat --check` e `gdlint` limpos sobre `src/`, `tests/` e `tools/`.
- **Portões de arquitetura** — `lint_sim` limpo em G1, G2, G4 e **G6** (o save e as preferências nunca usam `load()`),
  e os três modos de quebrar o G6 estão medidos, não supostos.
- **As três faixas** — as nove combinações do §53 medidas com o motor de física, não deduzidas da
  tabela: a diagonal bate e tudo o resto atravessa. `scenes/tests/bands.tscn` escreve-a no arranque.
- **O orçamento do §63** — 300 unidades, medidas: FSM **81 µs** por passagem contra os 800 orçados, e
  movimento **42 µs** contra 1000. Nesta máquina e não no Deck, que é onde o orçamento é do §63 — o
  número fica no registo do CI para lá ser comparado.
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
| Jogabilidade | **Ninguém jogou** — com um teclado e olhos. O ciclo está todo lá e corre em *headless*: nove dos onze passos do `SimLoop` escritos (faltam o 9 e o 10, os dois da Fase 2), o mundo montado, a mancha a chegar ao crepúsculo, e a noite e a partida de dez dias medidas por instrumento (`noite_do_07_test.gd`, `dez_dias_test.gd`, `jogo_noite_test.gd`). A partida de dez dias já se perde e já se ganha, e a fronteira entre as duas está numa tabela de nove defesas. O que medir deixou por fechar está escrito em vez de calado: os números do microteste do §07 não batem (**Q-073**) e o Alado atravessa a muralha, pousa no castelo e não faz nada (**Q-077**). |
| GPU e arte | A medição correu sem placa gráfica. O LUT, a luz e as silhuetas continuam por ver. |
| Os dois *spikes* da Fase 0 | O **F0-09** pede a escala testada *em 1080p e no Deck* — é hardware, e nenhuma medição headless o substitui; a ADR 0001 continua proposta. O **F0-15** pede o `export_aseprite.sh` testado *com um ficheiro real* — e não há um: zero `.aseprite` na árvore, sem Aseprite instalado e sem o Wizard; a ADR 0010 continua proposta. São os dois únicos tickets da Fase 0 por fazer, e nenhum dos dois é código. |
| CI remoto | **Correu.** O workflow era inválido e nunca criou um único job — onze corridas de zero segundos — até à PR #4 o corrigir. A partir daí: portões estáticos, suite gdUnit4 e export de Linux verdes num *runner* limpo. A camada do dossiê chumbava em duas verificações de disposição, e **a corrida #19 pôs os cinco *jobs* verdes na mesma corrida**. A causa era uma só: os portões escolhiam o Chromium pela ordem errada e mediam com o 1194 enquanto o CI media com o 1243, onde o salto animado assenta aos 1712 ms contra a espera fixa de 900 ms — a segunda falha era consequência da primeira, medida sobre uma página ainda em movimento (Q-062, com a série medida e a reprodução local). Os portões passam a declarar que página mediram (motor e tipos de letra) e a dizer com que números chumbam. |
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
| `docs/adr/` | 23 decisões. A 0011 fecha a noite castanha; a 0012 a 0019 são a Parte XIII; a 0020 é a ordem do tick, a 0021 a lei da travessia do §21, a 0022 o sítio onde o jogo se publica e a 0023 o dia da primeira oferta. |
| `docs/backlog/` | 79 tickets, um ficheiro cada, no formato da §34. |
| `docs/content/` | Esquema, propostas, a Podridão dia a dia, os nomes. Tudo gerado. |
| `data/i18n/strings.csv` | 305 chaves PT-PT e EN, zero por escrever. É o `strings.csv` único da §27. |
| `ferramentas/` | A camada de uso do dossiê: construtor, extrator e os dois portões. |

## A regra que continua a valer

A §72 fechou a pré-produção: o dossiê só muda por correção, por decisão que vira ADR, ou por número que um
*playtest* desmentiu. Tudo o que a Parte XIII decidiu virou ADR antes de virar dados, e cada valor que não
estava escrito no dossiê entrou marcado em `_proposed`, com a razão em `_notes`. Nada foi decidido em silêncio.
