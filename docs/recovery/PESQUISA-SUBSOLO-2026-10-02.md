# O subsolo delimitado — pesquisa e desenho (Q-186)

_2 de outubro de 2026. O pedido do dono, com uma captura do porão da região com o painel do combate por cima:_

> «O subsolo não é infinito acompanhando o piso de cima, é sempre algo delimitado, pode ser grande, mas nunca
> infinito, é gerado proceduralmente e a primeira vez que é acessado naquela jogatina é algo distinto, o local onde
> aparece é aleatório, mas coerente com o local, nos impérios é comum ter subsolos com locais de onde se pode
> armazenar coisas ou com uma sala secreta no imperador. Esses botões não devem estar ali na frente atrapalhando,
> pois ao entrar no subsolo eles ficam por cima. Pesquise a fundo na web para ver melhor como desenvolver esses
> subsolos e dungeons, entre outras possibilidades.»

_O que se segue é o que estava, o que a pesquisa mostrou (jogos com masmorras geradas e lugares reais debaixo de
palácios), a regra que saiu dela e onde está no código. A decisão está na ADR 0046; o que fica para o dono, na Q-186._

## O que estava

- **O subsolo era uma faixa.** Por baixo da região, a cave das raízes (`RootCellars`) desenhava abóbadas de ponta a
  ponta dos seis ecrãs; nas terras geradas seguia um túnel de mina (`WildTunnel`) por baixo de todos os segmentos. O
  rei descia numa passagem e podia andar lá em baixo até à borda do mundo, como em cima. É o que o dono chama
  *«infinito acompanhando o piso de cima»*.
- **A terra ia-se toda.** Com o rei lá em baixo, o `SoilCover` dissolvia a terra do mundo inteiro: o terço de baixo
  do ecrã passava a ser cave de uma ponta à outra.
- **O painel do combate estava no corte de solo.** O `CombatBar` (ADR 0045) ficava ao fundo do ecrã, ao meio, de
  y 558 a 662 — e o chão onde se anda lá em baixo está em y 620. Com o rei no subsolo, os dois botões tapavam-no.

## O que a pesquisa mostrou

### Jogos

| Peça | Como funciona | Fonte |
|---|---|---|
| **Spelunky: a grelha e o caminho garantido** | Um nível é uma grelha de 4 × 4 salas de 10 × 8 blocos. O caminho crítico começa numa sala do topo e desce aos ziguezagues até ao fundo (40% esquerda, 40% direita, 20% baixo); cada sala recebe um molde feito à mão conforme as saídas que tem de ter. As salas fora do caminho são opcionais. | [How Spelunky random generation works](https://shanemartin2797blog.wordpress.com/2015/11/20/how-spelunky-random-generation-works/), [TCRF](https://tcrf.net/Spelunky_(2008)) |
| **Dead Cells: peças feitas à mão num grafo** | *«Each tile has a specific layout of platforms designed for a specific purpose»* (combate, tesouro, mercador). Por bioma há um grafo-conceito que diz o comprimento do nível, quantas salas especiais e quantas separam a entrada da saída; o gerador sorteia salas que cumpram cada nó. O mundo e as ligações entre biomas são fixos. | [Deepnight, *The level design of Dead Cells: a hybrid approach*](https://deepnight.net/tutorial/the-level-design-of-dead-cells-a-hybrid-approach/) |
| **Unexplored: ciclos e o tamanho pequeno** | Reescrita de grafos: uma grelha 5 × 5 com um ciclo entre a entrada e a saída, 24 tipos de ciclo (chave e porta, atalho, válvula de sentido único), depois elaboração, e só no fim as salas. *«It is so much more interesting to generate small levels than it is to generate large ones.»* | [Boris the Brave, *Dungeon generation in Unexplored*](https://www.boristhebrave.com/2021/04/10/dungeon-generation-in-unexplored/), [Game Developer, *Unexplored's secret: cyclic dungeon generation*](https://www.gamedeveloper.com/design/unexplored-s-secret-cyclic-dungeon-generation-) |
| **Rogue Legacy: o castelo de zonas fixas** | Cada zona fica sempre no mesmo sítio do mundo (o castelo ao centro, a floresta à direita, a torre em cima, as trevas em baixo), mas as 23–27 salas de cada uma sorteiam-se a cada entrada, 2–3 delas de bónus, de onze tipos (normal, chefe, secreta, bónus…). | [Rogue Legacy Wiki, *Biomes*](https://rogue-legacy.fandom.com/wiki/Biomes), [*Rooms*](https://roguelegacy.wiki.gg/wiki/Rooms) |
| **Minecraft: a estrutura tem tamanho máximo** | As estruturas de peças (aldeias, cidades antigas, câmaras de provação) crescem a partir de uma peça inicial por *template pools*, mas com dois limites: a profundidade (`size`, até 20) e a distância máxima ao centro. As câmaras de provação usam `encapsulate`: nascem fechadas dentro da rocha. | [minecraft.wiki, *Jigsaw structure*](https://minecraft.wiki/w/Jigsaw_structure), [*Trial Chambers*](https://minecraft.wiki/w/Trial_Chambers) |
| **Starbound e Terraria: pequenas masmorras metidas no terreno** | O Starbound põe *microdungeons* de uma ou duas salas à superfície e debaixo dela, por bioma, com regras de ancoragem (ar aqui, sólido ali). O Terraria espalha cabanas subterrâneas com o bloco do bioma — 35–40 num mundo pequeno, 140–160 num grande. | [Starbounder, *Dungeons*](https://starbounder.org/Dungeons), [Terraria Wiki, *Underground*](https://terraria.fandom.com/wiki/Underground) |
| **Valheim: a cripta é um monte de salas a partir da entrada** | Cada cripta junta salas de um conjunto temático a partir da entrada, até um número de salas (20–40) ou até não haver mais encaixes. | [Valheim Wiki, *Burial Chambers*](https://valheim.fandom.com/wiki/Burial_Chambers) |
| **Caves of Qud: o abstrato primeiro, o concreto à entrada** | O mundo gera-se em abstrato ao começar; cada zona só se fabrica quando o jogador lá entra, e a partir daí fica gravada nessa partida. | [Aidan Page, *Generating anything and everything in Caves of Qud*](https://aidanpage.medium.com/generating-anything-and-everything-in-caves-of-qud-d6336e9afda0), [Caves of Qud Wiki, *World map*](https://wiki.cavesofqud.com/wiki/World_map) |
| **Kingdom Two Crowns: a caverna é um lugar à parte, e cresce** | A caverna dos Greed fica atrás do portal da falésia, na ponta da ilha. Lá dentro há ninhos em fila e a colmeia no fim: um ninho na primeira ilha, dois na segunda, até cinco na quinta. | [Kingdom Wiki, *Cliff portal*](https://kingdomthegame.fandom.com/wiki/Cliff_portal), [*Cave*](https://kingdomthegame.fandom.com/wiki/Cave) (lido pelo resumo da pesquisa: a wiki recusou a leitura direta) |

### Lugares reais debaixo de impérios

| Lugar | O que era | Fonte |
|---|---|---|
| **A *undercroft* medieval** | O piso de baixo, abobadado e de pedra, de casas, salões e castelos: à prova de fogo e por isso o armazém de comida, de pipas de vinho e de valores, *«watched at all times»* por estar debaixo da casa. | [Wikipedia, *Undercroft*](https://en.wikipedia.org/wiki/Undercroft) |
| **O *Passetto di Borgo*** | Um corredor de 800 m do Vaticano ao Castelo de Sant'Angelo (1277). No saque de Roma de 1527 o papa Clemente VII fugiu por ele. É a saída secreta do soberano. | [Tourist in Rome, *Passetto di Borgo*](https://www.tourist-in-rom.com/en/rome-vatican-passetto-di-borgo/) |
| **O criptopórtico de Nero** | Um corredor subterrâneo de 130 m no Palatino, com janelas rasteiras, mosaico e estuque, que ligava as partes do palácio imperial. | [Madain Project, *Neronian cryptoporticus*](https://madainproject.com/neronian_cryptoporticus_on_the_palatine_hill) |
| **A cisterna da Basílica** | Justiniano (século VI): 336 colunas e 80 000 toneladas de água por baixo da Estoa, para o Grande Palácio de Constantinopla. Há centenas de cisternas debaixo de Istambul. | [Basilica Cistern, *History*](https://www.basilica-cistern.com/history) |
| **O hipogeu do Coliseu** | Dois pisos debaixo da arena (Domiciano): jaulas, armazéns de cenário, 80 elevadores e 60 alçapões por onde homens e feras apareciam *«as if from nowhere»*. | [Colosseum Underground](https://thecolosseumrome.com/colosseum-underground/) |
| **Derinkuyu** | Uma cidade de pelo menos oito pisos e 85 m de fundo na Capadócia: adegas, lagares de vinho e de azeite, estábulos, armazéns, capelas, e portas de pedra redondas de meia tonelada que só se abriam por dentro. | [Wikipedia, *Derinkuyu underground city*](https://en.wikipedia.org/wiki/Derinkuyu_underground_city) |
| **O palácio subterrâneo de Qin Shi Huang** | O túmulo do primeiro imperador, a 35 m, por abrir: Sima Qian descreve rios de mercúrio e armadilhas, e o solo do monte tem mercúrio 1000 a 2000 vezes acima do normal. | [Wikipedia, *Mausoleum of Qin Shi Huang*](https://en.wikipedia.org/wiki/Mausoleum_of_Qin_Shi_Huang) |
| **Os túneis do Kremlin** | A lenda da biblioteca de Ivan, o Terrível, selada nas caves do Kremlin; as escavações acharam câmaras e túneis, vazios, e os túneis serviram de saída em caso de cerco. | [Wikipedia, *Lost Library of Ivan the Terrible*](https://en.wikipedia.org/wiki/Lost_Library_of_Ivan_the_Terrible) |

### A interface

As regras de leitura de HUD repetem a mesma: *«do not obscure core gameplay with HUD components»*; o que é leve vai
para os cantos, e o que é contextual só aparece quando serve. ([Game UX Master Guide, *Layout of the HUD*](https://gameuxmasterguide.com/2019-05-07-HUDLayout/),
[GDKeys, *Keys to efficient user interfaces*](https://gdkeys.com/keys-efficient-user-interfaces/))

## O que se tirou de cada um

| Da pesquisa | Aqui |
|---|---|
| A estrutura de Minecraft tem profundidade e raio máximos; a cripta de Valheim, um número de salas | Um sítio é uma fila de salas com **duas paredes**: nunca passa do tecto que o lugar lhe dá (os muros, o castelo, o segmento), nem de 12 salas, mesmo sem tecto (`UndergroundSites.MAX_ROOMS`). É o *«nunca infinito»*. |
| O Caves of Qud fabrica a zona à entrada | Cada sítio tem uma metade **autorada** (a boca, o que tem de lá caber, o tecto e de que é feito), posta de cada vez que se monta o mundo, e uma metade **gerada** (as salas), que só nasce na **primeira descida** e vai no save (`UnderWatch.enter`). |
| As salas de Dead Cells e Spelunky são feitas à mão e sorteadas | Os tipos de sala são poucos e autorados (o armazém, a adega, o celeiro…), com o recheio desenhado como dados (`UnderProps`); o sorteio escolhe quantas, de que largura, de que tipo e para que lado crescem. |
| A semente e o sítio, como no mundo contínuo (ADR 0038) | Os sorteios vêm do `RngService.scatter` com a chave do sítio: a mesma partida dá sempre o mesmo porão, outra partida dá outro (*«a primeira vez que é acessado naquela jogatina é algo distinto»*). Há um teste que o prova. |
| A *undercroft*, o celeiro, as adegas de Derinkuyu | O **porão de cada passagem** do império é armazém, adega ou celeiro, entre os dois muros que a passagem tem de cada lado — e cresce até ao poço de minério e à câmara da Semente Real que já lá estavam (§25 11:00), que dão o tipo à sala onde caem. |
| O *Passetto*, o criptopórtico, o túmulo imperial | A **sala secreta debaixo do castelo**: um alçapão num sítio sorteado do chão do castelo (nunca no meio, onde o rei nasce), que só se vê depois de achado; por baixo, a câmara com o estandarte e a arca, e salas de tesouro ou de fuga com frestas. O tesouro cai uma vez, na primeira descida, como o da masmorra (Q-176). |
| A cripta, a cisterna, o ossário | As **masmorras** das ruínas (Q-173, Q-176) passam a ser sítios presos ao segmento delas: a câmara do arco caído é a sala de entrada, e as outras são cripta, desabamento, cisterna ou ossário. |
| *«Do not obscure core gameplay»* | O painel do combate passa ao **canto de cima, à direita**, por baixo do objetivo e acima do aviso e das legendas, mais baixo (66 px). É céu, onde não há jogo. |

## A regra

1. **O subsolo é um sítio, e acaba.** A maior parte do corte é terra maciça (§11). Onde há passagem, ruína ou alçapão
   há um sítio: uma fila de salas entre duas paredes de rocha.
2. **O sítio fica onde faz sentido.** O porão fica entre os muros da passagem, a sala secreta debaixo do castelo, a
   masmorra no segmento da ruína. O sítio exato e o tamanho sorteiam-se dentro disso.
3. **Nasce na primeira descida, e fica.** Antes disso só existe a parte autorada; as salas vão no save e não mudam
   mais. Um save de antes desta regra abre: os sítios nascem na descida seguinte.
4. **Lá em baixo não se passa das paredes.** Antes do movimento (passo 5), quem está lá em baixo dentro de um sítio
   não tem alvo para lá delas (`UndergroundSites.confine`). Quem cava — o Cavador, a mancha — continua a passar pela
   terra (§07, §51).
5. **A terra só se abre por cima do sítio.** O `dither_reveal` ganha janelas com orla e força: com o rei lá em baixo,
   abre-se de parede a parede do sítio onde ele está, ao ritmo de sempre, e o resto continua paisagem (Q-181).

## Onde está

- `src/sim/systems/underground_sites.gd` — os sítios, o desenho das salas e o confinamento. Puro.
- `src/core/under_watch.gd` — onde há sítios, as receitas, a primeira descida e o tesouro da sala secreta.
- `src/world/under_art.gd`, `src/world/under_props.gd` — as salas escavadas e o recheio de cada tipo.
- `src/world/root_cellars.gd`, `src/world/wild_tunnel.gd` — a terra maciça da região e das terras.
- `src/world/soil_cover.gd`, `src/world/soil_reveal.gd`, `shaders/dither_reveal.gdshader` — a janela do sítio.
- `src/world/passage_art.gd`, `src/world/passage_cue.gd` — o poço de cada boca e o sinal do Verbo 2 na boca certa.
- `src/ui/combat_bar.gd` — o painel no canto.
- `data/source/rules.csv` — `und_room_min_px`, `und_room_max_px`, `und_extra_rooms` (propostas, em `_proposed`).
- Testes: `tests/subsolo_delimitado_test.gd`, `tests/subsolo_sitios_test.gd`, `tests/painel_combate_test.gd`.

## Outras possibilidades (para o dono escolher, nenhuma aplicada)

- **O armazém que guarda mesmo.** Hoje o porão *é* armazém, adega ou celeiro, mas não guarda nada. O Kingdom tem o
  banqueiro (§02: 7% de juro diário, teto de 8 moedas por dia); o porão podia ser o cofre do reino, onde o rei larga
  moedas que a noite não leva. É uma mecânica nova de economia: fica na Q-186.
- **Profundidade em pisos.** Derinkuyu tem oito pisos. Uma masmorra podia descer: uma segunda faixa de salas abaixo da
  primeira, ligada por uma escada numa das salas. Pede uma faixa nova (§53) e câmara.
- **Chave e porta, à Unexplored.** Uma masmorra com uma porta trancada e a chave numa sala do lado: o ciclo mais curto
  de Dormans, numa fila. Pede um objeto novo (a chave) no armazenamento (Q-153).
- **A saída do soberano.** O *Passetto*: uma sala de fuga que liga a sala secreta a uma passagem do porão, para o rei
  fugir do núcleo cercado sem passar pela superfície.
- **A cisterna que serve.** A cisterna de Justiniano dava água ao palácio: uma cisterna achada podia dar uma
  capacidade ao reino, como as casas de conversão do §06.
- **Masmorras que crescem com o capítulo.** Como os ninhos da caverna do Kingdom: mais salas e mais guardas quanto
  mais longe da casa.
