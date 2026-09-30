# O mundo contínuo — pesquisa e desenho (Q-173)

_30 de setembro de 2026. Dois pedidos do dono, um a seguir ao outro:_

> «Os personagens não devem caminhar sobre nada, o mapa deve ser gerado proceduralmente como minecraft, conforme a
> pessoa anda é gerado mapa que faz sentido, e o mapa fica salvo daquele jeito o resto da gameplay, pesquise a fundo
> como minecraft faz para poder implementar, coloque um limite saudável de até quanto pode se expandir e com algo ao
> fim como é em kingdom»

> «Entre as regiões devem haver caminhos e trilhas para fazerem transições suaves, parece que foi programado para
> pular de um ponto a outro, não é assim que quero, deve haver essa transição, principalmente porque nesses caminhos
> se encontra acampamentos de mendigos, mercenarios, dungeons, etc»

_O que se segue é o que estava, o que a pesquisa mostrou (Minecraft, Kingdom e, de passagem, Terraria), a regra que
saiu dela e onde está no código. A decisão está na ADR 0038; as partes que ficam para o dono, nas Q-174 a Q-180._

## O que estava

- **A região tinha chão; as terras bravias não.** A Q-154 abriu seis ecrãs de terra de cada lado da região (o
  `wild_px`), mas o chão (`EnramadosLayer._ground`), o corte de solo (`RootCellars`) e o campo (`WildsLayer`) só se
  desenhavam em `[0, 3840]`. Fora disso o rei andava sobre o céu liso, com um vazio preto por baixo. Foi isto que o
  dono viu: *«os personagens não devem caminhar sobre nada»*.
- **Os outros povos não estavam em lado nenhum do mundo.** A campanha tem um plano de povos (`chapters.csv`), a
  bifurcação e a marcha (ADR 0035), mas nenhum deles tinha um sítio: a região de casa acabava em mais terreno igual, e
  a marcha levava a gente para uma fortaleza que não se via. É o *«pular de um ponto a outro»*.
- **Os encontros eram fixos.** Os acampamentos de vagabundos estavam em dois x autorados (Q-122) e não havia
  mercenários à espera nem masmorras.

## O que a pesquisa mostrou

### Minecraft

| Peça | Como funciona | Fonte |
|---|---|---|
| **A semente** | Um inteiro de 64 bits: *«any 64-bit signed integer value can be entered and will create a world with that seed»*. A mesma semente dá sempre o mesmo terreno. | [Seed (level generation)](https://minecraft.wiki/w/Seed_(level_generation)) |
| **Ruído, e não sorte pura** | *«Pure randomness makes terrain and biomes too chaotic with no continuity»*; o ruído de gradiente (Perlin) faz *«blocks and chunks fit with their neighbors»*. Somam-se oitavas de frequências e amplitudes diferentes. | [World generation](https://minecraft.wiki/w/World_generation) |
| **O chunk** | 16 × 16 blocos. *«Chunks generate around players when they first enter the world»*; o que não está carregado não é processado. | [Chunk](https://minecraft.wiki/w/Chunk) |
| **Gerar por etapas** | Doze estados, de `empty` a `full` (estruturas, biomas, ruído, superfície, cavernas, decoração, luz, bichos). Um chunk a meio chama-se *proto-chunk*. | [World generation](https://minecraft.wiki/w/World_generation) |
| **Biomas por vários ruídos** | Seis parâmetros no Overworld: temperatura, humidade, continentalidade, erosão, profundidade e *weirdness* (picos e vales). | [World generation](https://minecraft.wiki/w/World_generation), [Noise router](https://minecraft.wiki/w/Noise_router) |
| **Do ruído ao relevo** | Continentalidade, erosão e picos e vales passam por *splines* que dão a altura: quanto mais continental, mais alto; quanto mais erosão, mais plano. | Henrik Kniberg, [*Reinventing Minecraft world generation*](https://www.youtube.com/watch?v=ob3VwY4JyzE) (JFokus 2022) |
| **Estruturas espalhadas** | `random_spread`: uma grelha de `spacing` chunks, um desvio aleatório por célula até `spacing − separation − 1`, e um `salt` somado à semente. As aldeias usam 34 e 8: cerca de 34 chunks entre tentativas, nunca menos de 8. A posição só depende da semente e da célula, e não da ordem em que se anda. | [Structure set](https://minecraft.wiki/w/Structure_set) |
| **Gravar o que nasceu** | Ficheiros de região com 32 × 32 chunks, em setores de 4 KiB, comprimidos com zlib. Cada chunk grava o `Status` (até onde foi gerado) e o `DataVersion`. | [Region file format](https://minecraft.wiki/w/Region_file_format), [Chunk format](https://minecraft.wiki/w/Chunk_format) |
| **Sem costuras entre o velho e o novo** | Desde a 1.18, `blending_data` guarda 16 alturas na borda do chunk para o gerador novo *«smoothly transition between old and new terrain rather than creating visible seams»*. | [Chunk format](https://minecraft.wiki/w/Chunk_format) |
| **O limite** | A borda do mundo fica a 29 999 984 blocos da origem. Nas edições de consola antigas o mundo era finito: o clássico tinha 864 × 864 blocos (54 × 54 chunks), *«surrounded by an endless sea of water preceded by an invisible barrier»*, e os dois chunks de fora eram *«a smooth transition from the main landmass»* para o mar. | [World border](https://minecraft.wiki/w/World_border), [World size](https://minecraft.wiki/w/World_size) |

### Kingdom

| Peça | Como funciona | Fonte |
|---|---|---|
| **O mapa em blocos** | *«The map is built out of 'building blocks' that are randomly laid out side-by-side. These 'blocks' each contain a single item like a statue or other structure. Then the game figures out which sections of ground need which kind of vegetation and plants that. Finally it adds stubs for towers and walls…»* Num plano, *«the challenge of generating a procedural map is much easier»*. | [80.lv, *How 2 guys created a side-scrolling strategy*](https://80.lv/articles/kingdom-how-2-guys-created-a-side-scrolling-strategy) |
| **Pouca geração, muito baralhar** | Thomas van den Berg: *«On paper there was supposed to be a lot more procedural generation going on, but in the end we limited that to basically shuffling the map.»* | [Game Developer, *Road to the IGF: Kingdom*](https://www.gamedeveloper.com/design/road-to-the-igf-noio-and-licorice-s-i-kingdom-i-) |
| **O reino ao centro, o perigo nas pontas** | Two Crowns: *«The kingdom is located in the center of the procedurally generated level, and at night, the Greed attack it from the left and right»*; o portal fica *«at the far end of each level»*. | [Wikipedia, *Kingdom Two Crowns*](https://en.wikipedia.org/wiki/Kingdom_Two_Crowns) |
| **O fim da ilha** | O portal da falésia fica *«on the cliff face at the edge of the land»* e é a entrada da caverna dos Greed; cada ilha tem uma doca central e outra no lado de lá. | Kingdom Wiki: [Cliff portal](https://kingdomthegame.fandom.com/wiki/Cliff_portal), [Dock portal](https://kingdomthegame.fandom.com/wiki/Dock_portal) (lidos pelos resumos da pesquisa: a wiki recusou a leitura direta) |
| **O que fica** | Quem perde a coroa continua como herdeiro, que *«inherits a partially destroyed version of the player's previous realm»*. | [Wikipedia, *Kingdom Two Crowns*](https://en.wikipedia.org/wiki/Kingdom_Two_Crowns) |

### Terraria, de passagem

Três larguras fixas de mundo (4200, 6400 e 8400 blocos) e um oceano nas duas pontas, com *«a sandy beach and a large
body of water»*, a menos de 340 blocos da borda ([Ocean](https://terraria.wiki.gg/wiki/Ocean)). É a mesma resposta do
Minecraft de consola: um mundo finito acaba em água, e a água avisa antes de acabar.

## O que se tirou de cada um

| Do Minecraft | Aqui |
|---|---|
| O chunk, gerado quando o jogador se aproxima | O **segmento do §21** (640 px), numa linha. Gera-se o que começa a um ecrã do rei (`Frontier.ALCANCE_PX`, 1280 px), de dentro para fora e sem saltar nenhum. |
| A aleatoriedade presa à semente e ao sítio (o `salt` do `random_spread`) | Os sorteios de cada segmento vêm do `RngService.scatter` com a chave `(sal, lado, índice)`: o mesmo segmento sai igual venha o rei a andar ou aos saltos, e não gasta a sequência de quem simula (§42). Há um teste que o prova. |
| Gravar cada chunk com o que tem | Cada segmento gerado é um registo (`WildSegments`): zona, povo, de onde e para onde, tipo, linha do `segments.csv`, assunto, sítio e semente da decoração. Vai no save (`world.wilds`, versão 4, com a migração) e não muda mais, nem quando o gerador mudar. |
| Os biomas por ruído contínuo | Numa dimensão: um ruído do clima (`RngService.noise`) junta os bosques e as clareiras (`wild_cluster`). |
| O `blending_data`: sem costuras | Ao longo de um trilho, a paisagem passa **em gradiente** do povo de onde se vem para o povo para onde se vai (`WorldPlan.mix_ends`), e a estrada estreita-se em trilho ao sair de uma terra e alarga-se ao chegar ao limiar seguinte (`WorldPlan.trail_ends`). Cada segmento acaba com a cor e a largura com que o seguinte começa; há um teste para cada uma. Por baixo, a cave da região fecha num pilar e sai dela o túnel das terras, com os mesmos estratos. |
| As estruturas com espaçamento mínimo | Os encontros (acampamento de mendigos, de mercenários, a ruína que é masmorra) saem pelos pesos e regras do `segments.csv` (`gap=`, `not_adjacent=`, `not_near_base`), e cada trilho tem pelo menos um. |
| O mundo finito que acaba em água, com uma transição | O mundo tem o tamanho da campanha (abaixo), e acaba numa **borda** do §21. |

| Do Kingdom | Aqui |
|---|---|
| O mapa como blocos lado a lado, cada um com uma coisa | É o §21 tal e qual: um segmento, uma coisa em que o olho pousa (o poço, a carroça, a pedra de pé, o gigante caído, o arco caído, as tendas, a tenda listada). |
| O reino ao centro e o perigo nas pontas | A região de casa ao centro; os povos da campanha pela ordem do plano, alternando de lado (o primeiro a leste, onde fica a bifurcação). |
| A ilha que acaba na praia com a doca, ou na falésia | A borda de cada lado é a do bioma do último povo desse lado (`biomes.csv`, `edge_subject`): **o mar** com a praia e o cais, **a falésia** sobre a névoa, **o desfiladeiro** com a outra parede ao longe, ou **a muralha de rocha**. Não se passa da beira. |
| O herdeiro herda o reino | O mundo gerado vai no save da partida: o herdeiro anda no mesmo mundo. |

## A regra

- **O plano** (`WorldPlan`, puro): para cada povo da campanha além do de casa, um trilho (4 a 6 segmentos,
  `world_trail_segments`), um limiar (§21: portão, ponte, falha na rocha, muralha em ruínas), a terra (3 segmentos,
  com aldeias e casais) e a fortaleza na ponta (`world_land_segments` 4). Depois do último povo de cada lado, um
  último trilho e a borda. O comprimento de cada trilho sorteia-se pelo sítio.
- **O limite saudável** é esse: o mundo é do tamanho da campanha, e não cresce mais. Na semente 20260930 vai de
  −22 656 a 31 616 px — 54 272 px, catorze regiões de largura. Do núcleo à borda de leste são 29 696 px: seis
  minutos a andar (80 px/s), três e meio a correr (144 px/s).
- **Os encontros**:
  - o acampamento de mendigos entra nos acampamentos da alvorada (Q-122);
  - o de mercenários tem um mercenário à espera, que se contrata ao preço dele como qualquer recruta, e a alvorada
    repõe-no quando é contratado;
  - a ruína com passagem (§21) é uma masmorra: a boca pega no Verbo 2, e lá em baixo há uma câmara com um monte de
    moedas (`dungeon_coins` 3 a 6), só da primeira vez — as moedas vão no save.
- **As bocas das masmorras** não entram no `SimLoop.passages`, que a noite lê (Q-132).
- **O guia** diz de quem é a terra (*«Horta · terra deles; a fortaleza fica na ponta»*, ou *«terra de vassalos
  teus»*) e, na borda, o que lá há.
- **Números**: todos propostos (`_proposed`) no `economy.csv` e no `segments.csv`, cada um com a regra na nota.

## Onde está

| O quê | Onde |
|---|---|
| O plano, as misturas e as larguras nas pontas | `src/sim/systems/world_plan.gd` — `tests/mundo_plano_test.gd` |
| Os segmentos gerados e gravados | `src/sim/systems/wild_segments.gd`, `src/sim/systems/trail_pick.gd` — `tests/mundo_segmentos_test.gd` |
| A cola ao jogo (gerar, encontros, masmorras, limites) | `src/core/frontier.gd`, `src/core/camps.gd` — `tests/mundo_fronteira_test.gd` |
| O save v4 | `src/core/save_migrations.gd` — `tests/save_migrations_test.gd` |
| O chão, o subsolo, os assuntos, os limiares e a borda | `src/world/wild_ground.gd`, `wild_tunnel.gd`, `wild_subjects.gd`, `wild_lands.gd`, `wild_edge.gd`, `shape_art.gd` |
| A câmara que segue o que já foi gerado | `src/world/frontier_view.gd` |
| O guia | `src/ui/guide_sites.gd` (`wilds`) |
| Os dados | `segments.csv` (11 linhas novas), `biomes.csv` (`edge_subject`), `economy.csv` (grupo «Mundo contínuo») |

## O que não se fez, e porquê

- **Arte.** Tudo o que se vê nas terras são formas lisas escritas como dados (`ShapeArt`), à espera de arte a sério:
  `art/` não se toca daqui.
- **A linha de árvores do horizonte** continua a do bioma de casa em todo o mundo: vive num `Parallax2D`, e pô-la por
  povo pede outra conta de coordenadas.
- **As decisões que mudam o jogo** — obras nas terras, uma tabela de segmentos por povo, o que há numa masmorra, o
  soldo dos mercenários, o que o rei pode fazer na terra de outro povo, de onde vem a noite agora que o mundo tem
  pontas, e o mapa revelado do §16 — ficaram como perguntas (Q-174 a Q-180).
