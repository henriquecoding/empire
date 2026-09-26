# Backlog — Fases 0 e 1

> Os tickets do §34 do dossiê, um ficheiro cada, no formato do §34, com os caminhos da §70 e os ficheiros reais de
> `docs/design/`. A v5.2 acrescentou seis que a §65 e a §66 pediam e o §34 não tinha (F0-11 a F0-15 e F1-17), e nove
> de arte, *greybox*, nomes e dados, que correm em paralelo aos sábados (§22, opção C).

**Como se usa:** abre o ticket, lê as secções da linha *Spec*, e dá-o ao agente tal e qual — uma tarefa por sessão.
Quando acabar, muda o **Estado** no próprio ficheiro e nesta tabela, no mesmo *commit*.

## Fase 0 — Fundação

| Ticket | Tarefa | Depende | Estado |
|---|---|---|---|
| [F0-00](F0-00.md) | Repositório do dia zero: as ondas 1 e 2 da §68 | — | feito |
| [F0-01](F0-01.md) | Criar o projeto Godot 4.6 com as definições do §19 | F0-00 | feito |
| [F0-02](F0-02.md) | Git LFS para *.aseprite e art/**/*.png | F0-00 | parcial — configurado; a arte que há (art/source/originals, art/export/enramados) está fora do LFS de propósito (.gitattributes), e git lfs ls-files não mostra nada |
| [F0-03](F0-03.md) | AGENTS.md e os primeiros ADRs | F0-00 | feito |
| [F0-04](F0-04.md) | Instalar o gdUnit4 e o workflow de CI | F0-00 | feito |
| [F0-05](F0-05.md) | Band: enum, planos e a matriz de colisão | F0-01 | feito |
| [F0-06](F0-06.md) | GameClock e o ClockData (prompt 1 da §29) | F0-01 | feito |
| [F0-07](F0-07.md) | EventBus com os sinais do §46 | F0-01 | feito |
| [F0-08](F0-08.md) | Câmara com lookahead e limites de região | F0-05 | feito |
| [F0-09](F0-09.md) | Spike: decidir a escala e fechar a ADR 0001 | F0-01 | por fazer |
| [F0-10](F0-10.md) | Cena de teste: um sprite anda nas três faixas | F0-05, F0-08 | feito |
| [F0-11](F0-11.md) | Registry e boot.tscn | F0-01 | feito |
| [F0-12](F0-12.md) | RngService: os seis fluxos, snapshot e restore | F0-11 | feito |
| [F0-13](F0-13.md) | SaveService: escrita atómica e três slots | F0-11 | feito |
| [F0-14](F0-14.md) | UnitView com cinco slots e o shader da paleta | F0-10 | feito |
| [F0-15](F0-15.md) | Spike: importar arte do Aseprite e fechar a ADR 0010 | F0-02 | por fazer |

## Fase 1 — Núcleo jogável

| Ticket | Tarefa | Depende | Estado |
|---|---|---|---|
| [F1-01](F1-01.md) | Moeda física: largar, arco, queda, apanhar, saco | F0-07 | feito |
| [F1-02](F1-02.md) | UnitData e as seis unidades do §07 | F0-03 | feito |
| [F1-03](F1-03.md) | UnitSystem com arrays paralelos e time-slicing | F1-02 | feito |
| [F1-04](F1-04.md) | Recrutar um vagabundo por uma moeda; ele segue-te | F1-01, F1-03 | feito |
| [F1-05](F1-05.md) | JobBoard (prompt 4 da §29) | F1-03 | feito |
| [F1-06](F1-06.md) | Muro: cinco níveis, dois caminhos, slots de contacto | F1-05 | feito |
| [F1-07](F1-07.md) | Arqueiro: alcance, precisão 0,34 em campo e 1,0 em torre | F1-06 | feito |
| [F1-08](F1-08.md) | RotSystem (prompt 2 da §29) | F0-06 | feito |
| [F1-09](F1-09.md) | Criaturas: Rastejante, Alado, Bruto e a tabela de invocação | F1-08 | feito |
| [F1-10](F1-10.md) | Economy (prompt 3 da §29) e a curve.tres | F1-01 | feito |
| [F1-11](F1-11.md) | Plantação, pesqueiro e galinheiro com os valores do §06 | F1-10 | feito |
| [F1-12](F1-12.md) | Moral e fuga com o raio do rei | F1-05 | feito |
| [F1-13](F1-13.md) | CanvasModulate por faixa, animado pelo GameClock | F0-06 | feito |
| [F1-14](F1-14.md) | Save e load do estado de src/sim/ com save_version | F1-10 | feito |
| [F1-15](F1-15.md) | Cenário de combate noturno para afinação | F1-09 | feito |
| [F1-16](F1-16.md) | Afinar até sobreviver dez dias ser possível e não trivial | tudo | feito |
| [F1-17](F1-17.md) | Arte da mancha: a Podridão e a candeia | F1-08, ART-02 | feito |

## Em paralelo — arte, *greybox*, nomes e dados

| Ticket | Tarefa | Depende | Estado |
|---|---|---|---|
| [ART-01](ART-01.md) | A primeira personagem real em cinco slots | F0-14, F0-15 | por fazer |
| [ART-02](ART-02.md) | A paleta mestra e o LUT | F0-01 | por fazer |
| [ART-03](ART-03.md) | As seis camadas de parallax com teto de valores | ART-02, F0-08 | por fazer |
| [ART-04](ART-04.md) | Rostos e expressões: o catálogo do §60 | ART-01 | por fazer |
| [GB-01](GB-01.md) | Greybox do segmento zero | F0-10 | parcial — falta a cara fixa do vagabundo (ART-01, Q-104) |
| [GB-02](GB-02.md) | Greybox dos seis biomas | GB-01 | feito |
| [GB-03](GB-03.md) | Regras de densidade medidas no greybox | GB-02 | feito |
| [GB-04](GB-04.md) | O passo do §21: a região atravessa-se em 40–60 s | GB-01 | feito |
| [GB-05](GB-05.md) | O preço daquilo em cima de que estás | GB-01 | feito |
| [GB-06](GB-06.md) | Largar em contínuo, que o §24 já mandava | F1-01 | feito |
| [GB-07](GB-07.md) | O rei não fica preso em combate | F1-03 | feito |
| [GB-08](GB-08.md) | O golpe que se vê | F1-07 | feito |
| [GB-09](GB-09.md) | A sombra de contacto da moeda | F1-01 | feito |
| [GB-10](GB-10.md) | O render interpola, e o rei deixa de andar aos solavancos | F0-06 | feito |
| [GB-11](GB-11.md) | O gatilho direito, num comando | F1-07 | feito |
| [GB-12](GB-12.md) | A câmara livre pelo rato na margem | F0-08 | feito |
| [GB-13](GB-13.md) | Pausa e opções: desligar o tremor e os clarões | GB-08 | feito |
| [GB-14](GB-14.md) | O sinal da passagem, onde o Verbo 2 pega | GB-05 | feito |
| [GB-15](GB-15.md) | Os glifos do comando que se está a usar | GB-06 | feito |
| [GB-16](GB-16.md) | A derrota diz a verdade, e dá um jogo novo | GB-13 | feito |
| [GB-17](GB-17.md) | O amanhecer que se vê chegar | F1-13 | feito |
| [GB-18](GB-18.md) | O sol e a lua dizem a hora | F1-13 | feito |
| [GB-19](GB-19.md) | O pequeno bounce da moeda | GB-09 | feito |
| [GB-20](GB-20.md) | A cara de quem está ferido | F0-14 | feito |
| [GB-21](GB-21.md) | As tropas saem dos postos atrás da luz | GB-17 | feito |
| [GB-22](GB-22.md) | As legendas de som | GB-13 | feito |
| [GB-23](GB-23.md) | A silhueta fantasma a piscar | GB-05 | feito |
| [GB-24](GB-24.md) | A duração do dia, ao ritmo de quem joga | GB-13 | feito |
| [GB-25](GB-25.md) | O controlo de contraste | GB-13 | feito |
| [GB-26](GB-26.md) | Os modos para daltonismo | GB-25 | feito |
| [GB-27](GB-27.md) | O painel fala por chave | GB-15 | feito |
| [GB-28](GB-28.md) | O idioma escolhe-se na pausa | GB-27 | feito |
| [NB-01](NB-01.md) | Bíblia de nomes e a escolha do nome do jogo | — | por fazer |
| [CD-01](CD-01.md) | A base de dados de conteúdo, uma tabela por sessão | F0-03 | feito |
| [PUB-01](PUB-01.md) | O jogo passa a jogar-se no browser | F0-04 | feito |
| [PUB-02](PUB-02.md) | O site passa a ser a página do jogo | PUB-01 | feito |

## Fase 2 — Fatia vertical

| Ticket | Tarefa | Depende | Estado |
|---|---|---|---|
| [F2-01](F2-01.md) | A classe do Monarca: a aura e a evolução | F1-12, XIII-03 | parcial |

## Auditoria de gameplay de 26/09 — o que o relatório mandou fazer

> `docs/recovery/AUDITORIA-GAMEPLAY-2026-09-26.md`. As decisões estão nas Q-115 em diante.

| Ticket | Tarefa | Depende | Estado |
|---|---|---|---|
| [AUD-01](AUD-01.md) | Integridade da simulação: a moeda, o muro, a torre, o rei e o save | — | feito |
| [AUD-02](AUD-02.md) | A economia verdadeira: o que o CI afina é o que o jogo corre | AUD-01 | feito — a produção cresce, paga nobres e pede o trabalhador; a manutenção e o vagabundo da alvorada na partida; o D8 passa para o AUD-04 (o Cavador do dia 10, Q-101) |
| [AUD-03](AUD-03.md) | A noite legível e com gestos | AUD-01 | por fazer |
| [AUD-04](AUD-04.md) | As faixas: o subsolo como expedição e o Alado com alvo | AUD-01 | por fazer |
| [AUD-05](AUD-05.md) | Uma campanha mínima: sucessão, fim de região e decay | AUD-02, AUD-03 | por fazer |

## Parte XIII — a candeia, a Oferta, o Nome, a Colheita e os Capítulos

> Onze tickets novos, pela ordem de custo da §82. O caminho mínimo que dá a transformação inteira é
> XIII-01 + XIII-02 + XIII-03 + XIII-04 + XIII-10 + XIII-11: 52 horas, e é aí que está quase todo o efeito.

| Ticket | Tarefa | Depende | Horas | Estado |
|---|---|---|---|---|
| [XIII-01](XIII-01.md) | §80 · O preto na paleta e a noite castanha | ART-02 | 4 (2 código + 2 arte) | feito |
| [XIII-02](XIII-02.md) | §74 · O termo dos Amargueiros na massa | F1-08 | 1 | feito |
| [XIII-03](XIII-03.md) | §74 · O Amargueiro e a candeia, completos | XIII-02, F1-06, ART-04 | 13 (10 + 3 arte) | feito |
| [XIII-04](XIII-04.md) | §75 · A Oferta e a Dívida da Candeia | XIII-03 | 20 (12 + 4 arte + 2 som + 2 escrita) | feito — 4 das 12 ofertas com preço e efeito ligados (Q-099) |
| [XIII-05](XIII-05.md) | §76 · O Nome | F1-12 | 11 (7 + 2 arte + 1 som + 1 escrita) | feito — 5 dos 9 feitos com o que observar (Q-102) |
| [XIII-06](XIII-06.md) | §78 · A Colheita | F1-16 | 11 (8 + 3 arte) | parcial — falta a conquista que a começa e o gesto da decisão (Q-103) |
| [XIII-07](XIII-07.md) | §77 · Os dez capítulos | GB-02, XIII-06 | 106 (30 + 50 arte + 20 som + 6 escrita) | parcial — a colocação e os diários feitos (D-09, D-11, D-12); as leis, a arte e as canções por fazer |
| [XIII-08](XIII-08.md) | §79 · Os doze diários e os três epílogos | XIII-04, XIII-07 | 13 (3 + 10 escrita) | parcial — a atribuição, o D-12, o D-13 e o diário 1 legível; os outros onze esperam pelas fortalezas e pelos capítulos |
| [XIII-09](XIII-09.md) | §81 · Som: o cante, os motivos e a encomendação | XIII-05, XIII-06 | 44 (6 + 38 som) | por fazer |
| [XIII-10](XIII-10.md) | §83 · Os primeiros vinte minutos | GB-01, XIII-03 | 8 (3 + 4 arte + 1 escrita) | feito |
| [XIII-11](XIII-11.md) | §84 · Os catorze testes de design e as seis linhas de risco | XIII-02 | 6 | feito |

## Ordem sugerida

**Código, dias de semana:** F0-00 → F0-02 → F0-05 → F0-07 → F0-06 → F0-11 → F0-13 → F0-12 → F0-08 → F0-14 → F0-10,
com os dois *spikes* (F0-09, F0-15) numa tarde cada. Depois a Fase 1 pela ordem dos doze *commits* da §66:
F1-02 → F1-03 → F1-01 → F1-04 → F1-05 → F1-06 → F1-07 → F1-08 → F1-09 → F1-15 → F1-10 → F1-11 → F1-12 → F1-13 → F1-14 → F1-17 → F1-16.

**Arte, aos sábados (§28):** ART-02 → ART-01 → GB-01 → ART-03 → GB-02 → GB-03 → ART-04. O NB-01 começa já e fecha antes
da Fase 4; o CD-01 faz-se antes do F1-02 e do F1-09, uma tabela por sessão.

**Parte XIII:** XIII-11 e XIII-02 primeiro (os testes e o termo da massa, que são 7 h e guardam tudo o resto),
depois XIII-01 antes de se desenhar cenário. XIII-03 → XIII-04 → XIII-10 fecham o caminho mínimo de 52 h.
As XIII-05, XIII-07 e XIII-09 podem cair inteiras sem que as outras deixem de funcionar (§82).

**O marco que fecha a pré-produção** (relatório mestre, §32; dossiê, §71): abrir o Empire, controlar uma personagem real
numa *greybox*, atravessar as três faixas, construir algo com uma moeda, sobreviver à primeira noite e reproduzir o
resultado pela mesma *seed*. São o F0-10, o ART-01, o GB-01, o F1-01, o F1-06, o F1-08 e o F0-11.
