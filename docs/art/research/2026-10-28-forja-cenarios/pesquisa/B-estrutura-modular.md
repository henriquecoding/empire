# B — Estrutura modular de cenários: tiles, quebra da grelha, kits de edifícios, parallax, metadados e água

Pesquisa para o Empire (Godot 4.7, GDScript; Forja em Python). Acedido a 2026-10-28.
Fontes numeradas `[Fnn]` — lista completa, com URL e afirmação, em `B-fontes.json` (mesma pasta).

> **Nota de integração (28/10, FORJA-11).** Depois desta pesquisa entraram na Forja `tiles.pairs` (V1, os 64+64
> pares pela topologia da aresta) e `tiles.junctions` (V2, os cachos partidos nas emendas e nos 512 cruzamentos),
> a revisão estrutural (V6, V10, V11, V12 em parte) e a régua. O resto da §7 continua proposta. Síntese:
> [README](../README.md).

Convenções deste documento:

- **Facto** — afirmação com fonte `[Fnn]`. Quando a fonte é secundária ou só foi vista por resumo de
  pesquisa, diz-se.
- **[Inferência]** — conclusão minha a partir das fontes; não está escrita em nenhuma delas.
- **[Proposta]** — sugestão para o Empire. Proposta não é decisão (AGENTS.md, ADR 0079); qualquer adoção passa
  pelo dono, por `docs/QUESTIONS.md` e por ADR.
- **[Repo]** — observação lida no repositório, com caminho. Nenhum ficheiro do repositório foi alterado.

---

## 0. Resumo

1. Um conjunto **Wang de 2 cantos (16 tiles)** e um de **2 arestas (16)** não são o mesmo sistema: a aresta só
   afeta um vizinho, o canto afeta três [F04]. Os tiles de aresta sofrem do "problema do canto" (os vizinhos em
   diagonal não são restringidos); os de canto não [F61]. O conjunto da Forja (canto, `NW<<3|NE<<2|SW<<1|SE`) é
   o certo para manchas e cavidades.
2. Nos 16 tiles de canto há **64 pares horizontais e 64 verticais compatíveis** (128 adjacências orientadas), e
   **512 blocos 2×2 distintos** (2⁹ valores na grelha 3×3 de cantos) [Inferência, contado por script]. Um teste
   topológico deve percorrer estes 512 blocos, não só medir o contraste médio da borda.
3. Para a **faixa de superfície** de um mundo "num plano nivelado" como o de Kingdom [F31], um Wang 16 completo
   é excessivo e produz tiles ambíguos (as diagonais). Uma família 1D (topo × 3 variantes, pontas, corpo,
   faces, estrato, curinga) cobre o caso com ~11 tiles; o Wang 16 fica para o subsolo e as cavidades [Proposta].
4. A peça que "quebra a grelha" é sempre uma **camada de decoração com origem própria** por cima de tiles limpos:
   relva e plantas sobre o topo, mantendo a colisão limpa [F20]; *multitiles* de Terraria com `Origin` e
   `AnchorBottom` [F28]; decoração do Dead Cells colocada por secções com regras [F29].
5. Em kits, a **pegada (footprint)** é a fundação; o pivô fica no plano do chão; evitar kits que repetem em todos
   os eixos; o jogador nota mais o **detalhe repetido** do que a arquitetura repetida [F40].
6. Esticar textura (9-slice em modo *stretch*) distorce; em pixel art usa-se **repetir** (tile), nunca escalar
   [F52][F53]; a escala não inteira desfaz o tamanho do pixel [F51].
7. Parallax: o fator de deslocamento multiplica a câmara; perto = mais saturado, contrastado, claro, quente e
   detalhado; longe = o inverso, a fundir-se com o céu [F18][F23]. Em loops fechados, o deslocamento por frame
   tem de dividir a largura [F22]. No Godot, `repeat_size` faz o salto; a textura deve começar em (0,0) e ter
   pelo menos a largura do ecrã [F47].
8. [Repo] Os planos pintados do Empire repetem por **espelho** (`draw_mirrored`, `src/world/scenery_art.gd`):
   não há junta, mas cada período ímpar inverte a luz — o SLYNYRD só aceita espelhar com luz simétrica [F20], e o
   ASSET_BIBLE proíbe espelhar o que tenha lado iluminado.
9. Água de Kingdom: segundo relatos de terceiros sobre o devlog do autor, é uma cópia da cena virada, passada por
   distorção e tingida de azul [F35][F36]; o autor diz que aprendeu o método nos fóruns do Flixel [F32]. Uma
   reflexão renderizada fica coerente com o estado do edifício por construção; uma reflexão desenhada obriga a um
   frame de reflexo por estado [Inferência].
10. Metadados que tornam uma cena remontável: pivô (Aseprite *slice* com pivô e 9-slice [F42]), deslocamento do
    recorte (`spriteSourceSize` / `sourceSize` no JSON da Aseprite [F46]), âncora de contacto, conectores, luz e
    camada emissiva (`LIGHT_MODE_UNSHADED` [F55]).

---

## 1. Anatomia de um tileset de vista lateral

### 1.1 As peças

| Peça | O que é | Fonte |
|---|---|---|
| Tile mestre | Um tile "cheio" que repete nas 4 arestas: esboçar, deslocar 50%, refazer o centro, deslocar outra vez | [F17] |
| Topo / meio / fundo | Os três tiles principais de aresta (TOP, MID, BOT); "fazer primeiro as arestas do meio"; evitar tocar nas zonas junto às arestas | [F17] |
| Tubos horizontal e vertical, tile isolado, cantos internos, forma em cruz | "Depende do motor e do sistema"; lista de formas habituais | [F17] |
| Curinga ("wildcard") | Tile para "situações onde nenhum tile serve" | [F17] |
| Variantes | Sobretudo do meio e do topo; "mudar só o centro do tile" | [F17] |
| Arestas e cantos com volume | A face exterior "inclina para o fundo", essencial à profundidade; cantos inclinados nos dois lados exteriores, "como uma projeção cabinet" | [F20] |
| Topo irregular | Tiles extra de relva e plantas evitam um "topo plano abrupto", preservando "limites de colisão limpos" | [F20] |
| Suportes | Tiles de suporte desenhados como estando "no fundo imediato" | [F20] |
| Rampas | Tiles que guardam a altura do chão em cada lado: no exemplo do Mega Man X, 4:1 em quatro tiles ({0,3},{4,7},{8,11},{12,15}) e 2:1 em dois ({0,7},{8,15}); com espelhos, 12 tiles | [F24] |
| Plataforma de sentido único | Nunca obstáculo em x; em y só se o jogador estava inteiramente por cima antes do movimento | [F24] |
| Escada | Estado alternativo; o topo da escada é muitas vezes também plataforma de sentido único | [F24] |
| Fundo (paredes de trás) | Celeste separa *tilesets* de primeiro plano (`ForegroundTiles.xml`) dos de fundo (`BackgroundTiles.xml`) | [F26] |

Tamanho: 16×16 é "dos mais comuns" e "acima de 32×32 parece exagero" [F20][F21].
[Inferência] O tile de 32 px do Empire, com cachos de 2 px, tem 16×16 células lógicas — o mesmo grão
que o SLYNYRD recomenda. As regras de composição desses textos aplicam-se à escala de 2 px.

**Rampas no Empire [Inferência].** Com tile de 32 px e cacho de 2 px, uma rampa 1:1 sobe 32 px num tile (degraus
de 2×2 px) e uma 1:2 sobe 16 px por tile, em dois tiles (degraus de 4×2 px). São as duas linhas "limpas" do pixel
art. A regra de Monteiro de não deixar uma rampa "parar a meio" de um tile [F24] evita casos de colisão. O ASSET_BIBLE
proíbe espelhar o que tem lado iluminado, por isso cada rampa precisa de versão esquerda e direita desenhadas.

**Cortes de solo e estratos [Inferência].** Nenhuma fonte primária trata o corte de terra com estratos em vista
lateral como peça própria. A decomposição TOP/MID/BOT [F17] encaixa: o topo leva relva e lábio, o meio é o
corpo do solo (tile mestre), e uma banda de estrato horizontal faz a transição para o subsolo. Como só tem de
repetir em x, é uma tira, não um Wang.

### 1.2 Sistemas de *autotiling*

| Sistema | O que se compara | Tiles num conjunto completo de 2 terrenos | Fonte |
|---|---|---|---|
| Wang 2 cantos ("marching squares", S-V2) | 4 cantos | 16 (6 com rotação e espelho) | [F01][F04] |
| Wang 2 arestas (S-E2) | 4 arestas | 16 | [F01][F08] |
| Misto canto+aresta (S-V2E2) | 8 vizinhos | 256 | [F03][F08] |
| Blob (S-V2E2-Blob) | 8 vizinhos; um canto só conta se as duas arestas adjacentes contam | 47 (7×7 com duplicados) | [F01][F03] |
| Godot 3 "2x2" | 4 cantos | 15 | [F14] |
| Godot 3 "3x3 (minimal)" | 4 cantos + 4 arestas | 47 | [F14] |
| Godot 3 "3x3" | 8 células, cantos só na diagonal | 256 | [F14] |
| *Quarter-tile* (RPG Maker) | cada quarto vê a célula e 3 vizinhos | 5 quartos com rotação; 14–20 sem | [F02] |
| *Dual grid* (Stålberg; jess::codes) | grelha de visualização deslocada meio tile; cada tile vê 4 células | 16 (6 com simetria) | [F02][F06] |
| 1-side corner | todas as arestas iguais; casa sempre | 16 + variantes, sem cálculo de índice | [F05] |

Notas das fontes:

- "Os *autotilers* usam um esquema muito mais simples: pinta-se cada célula e as arestas e vértices inferem-se
  daí" [F01]. A classificação descreve estrutura, não arte [F01].
- No *dual grid* "cada tile só verifica 4 vizinhos em vez de 8", os cantos podem ser "perfeitamente arredondados"
  e os tiles ficam alinhados com a grelha do mundo; a implementação usa uma `TileMapLayer` "mundo" e uma ou mais
  de "visualização", e não usa os terrenos do Godot [F06]. Boris the Brave chama-lhe "um grande esquema", mas
  "difícil de perceber" e com "tiles ambíguos" [F02]. A docstring de `tools/forja/tiles.py` já diz que os 16
  tiles de canto são "também o conjunto da dual grid" [Repo].
- Os cantos de Wang "criam áreas (manchas) de terreno"; a aresta "só afeta um tile adjacente, o canto afeta três"
  [F04].
- O *quarter-tile* não faz curvas maiores do que meio tile [F02].

### 1.3 Godot 4: `TileSet`, terrenos e `TileMapLayer`

- Três modos de terreno: `MATCH_CORNERS_AND_SIDES`, `MATCH_CORNERS`, `MATCH_SIDES` [F10]. Os *peering bits*
  decidem que tile aparece; `-1` é vazio [F09]. A enumeração `CellNeighbor` tem 16 posições (lados e cantos,
  para quadrado, isométrico e hexagonal) [F10].
- [Inferência, contagem] Num conjunto de 2 terrenos, `MATCH_CORNERS` tem 4 bits → 16 combinações e
  `MATCH_SIDES` também 16. `MATCH_CORNERS_AND_SIDES` corresponde ao "3x3 minimal" do Godot 3 (47), segundo o
  README do plugin Better Terrain e um fórum (só lidos por resumo de pesquisa) [F15].
- Tiles alternativos: Flip H, Flip V e Transpose dão as rotações; "ao criar um tile alternativo, nenhuma
  propriedade do tile base é herdada" [F09]. Desde 4.2 pode-se rodar e espelhar no editor sem alternativos [F09].
- `TileData.probability`: "probabilidade relativa de este tile ser escolhido ao desenhar um padrão de tiles
  aleatórios" [F11]. A documentação não diz se o pintor de terrenos a usa quando vários tiles servem [F09][F13]
  — fica por verificar no 4.7.
- Pintura de terreno: modo *Connect* (liga aos vizinhos na mesma camada) e *Path* (liga só ao traço) [F13].
  Pintura aleatória e *scattering* ("há uma probabilidade de não se pôr tile", para "detalhe ocasional, sem
  repetir") [F13]. Padrões guardam-se no `TileSet` [F13]. Coleções de cenas permitem "scene tiles" [F13].
- Colisão de sentido único por polígono (`set_collision_polygon_one_way`, `..._one_way_margin`) [F11]. Camadas de
  oclusão para luz, polígono por tile [F09]. Dados personalizados por tile (iguais em todas as instâncias; para
  outro valor, um alternativo) [F09].
- `texture_origin` desloca onde o tile se desenha; `y_sort_origin`, `z_index`, `modulate`, `material` por tile
  [F11]. Um tile pode ocupar várias células do atlas (`create_tile(coords, size)`) [F16]. `use_texture_padding`
  junta 1 px transparente à volta de cada tile contra *bleeding* quando há filtragem [F09][F16].
- `TileMapLayer` tem uma só camada; várias substituem o antigo `TileMap` [F12]. `set_cells_terrain_connect` e
  `set_cells_terrain_path` resolvem terrenos por código [F12]. `_tile_data_runtime_update` deixa mudar
  `TileData` em runtime, tile a tile [F12].

**Tiled**: conjuntos *Corner* e *Edge* têm 16 tiles; *Mixed* 256 ou reduzidos como o blob; o *Edge* "é comum
para estradas, cercas ou plataformas" [F08]. A probabilidade 0 mantém o tile na informação de terreno mas não o
põe automaticamente [F08]. Sem a transição necessária, o pincel "não sabe como ajudar" [F08] — daí a validação de
completude (§7d).

**Celeste**: máscaras 3×3 com `1`, `0` e `x`, uma camada `padding` (uma para dentro da orla) e `center` (o
resto); listas de coordenadas de tiles por regra; `ignores` impede um tileset de se ligar a outros; grelha de 8×8
[F25][F26].

### 1.4 Que emendas validar, e como

**Contagens** [Inferência, contadas com o script
um guião da sessão, não guardado; a contagem repete-se com `tiles.pairs` e `tiles.junctions`]:

| Conjunto | Pares horizontais compatíveis (A à esquerda de B) | Pares verticais | Configurações de junção a testar |
|---|---|---|---|
| Wang canto 16 | 64 (para cada A, a aresta esquerda de B fica fixa; os 2 cantos da direita são livres → 4) | 64 | 512 blocos 2×2 (grelha 3×3 de cantos, 2⁹) |
| Wang aresta 16 | 128 (só 1 bit por aresta) | 128 | — o canto não é restringido |
| Blob 47 | 169 pares cheio-cheio horizontais | 169 (simetria) | vizinhanças 4×4 |

**Porque o contraste médio não chega.** [Repo] `tiles.seams()` em `tools/forja/tiles.py` compara a diferença
média entre colunas e linhas opostas com a média do interior (limiar 1,5× + 1). [Inferência] O teste deixa passar
(a) uma linha de relva desencontrada 2 px na emenda quando as cores dos dois lados são parecidas; (b) um cacho de
1 px criado pela junção de dois tiles; (c) erros que só aparecem numa junção de 4 tiles. E chumba um tile legítimo
cuja borda tem uma linha de contraste alto. Serve para texturas de enchimento (toroidais); não serve para um
conjunto Wang.

[Repo, árvore de trabalho por confirmar a 28/10] Durante esta pesquisa apareceu, ainda sem commit, um
`tiles.pairs()` (FORJA-11) em `tools/forja/tiles.py`: percorre os 64 pares horizontais e os 64 verticais e
compara o perfil de classe das duas arestas (mesmo número de mudanças de terreno, nas mesmas alturas até 2 px).
Cobre o passo 1 abaixo pela topologia da aresta. Ficam por cobrir a junção 2×2 (passo 2), os cachos partidos na
emenda e a completude.

**O problema do canto.** Os tiles de Wang de aresta "não restringem diretamente os vizinhos em diagonal", o que dá
"problemas de continuidade junto aos cantos"; os tiles de canto restringem os diagonais e não têm o problema
[F61]. Cohen et al. enchem o plano "sem repetição visível" com poucos tiles de Wang de arestas coloridas, e
propõem codificar informação nos cantos para que objetos discretos "sobreponham mais do que uma aresta" [F60].

**Teste topológico** [Proposta; algoritmo no §7d]:

1. **Função de aresta.** Num conjunto de canto feito como o da Forja, a tira de 2 px junto a uma aresta só pode
   depender dos 2 cantos dessa aresta. Agrupar os 16 tiles pela assinatura de cada aresta (4 assinaturas por
   orientação) e exigir que a tira seja **idêntica ao pixel** dentro do grupo. Isto prova as 128 adjacências
   (§1.4) num só passo.
2. **Blocos 2×2.** Montar os 512 blocos e procurar, numa janela de 4 px à volta das emendas, componentes ligados
   por índice de paleta com área < 4 px ou lado < 2 px (cacho partido), e descontinuidades da máscara
   "terreno de cima" (o contorno tem de atravessar a emenda à mesma altura).
3. **Rebordo.** Onde há rebordo (relva por cima), a espessura medida na coluna 31 de A e na coluna 0 de B tem
   de ser igual.
4. **Completude.** Para cada terreno pintável, todas as assinaturas de vizinhança que o mapa pode produzir têm um
   tile (o caso em que o Tiled "não sabe ajudar" [F08]).

---

## 2. Quebrar a grelha

### 2.1 O que as fontes mostram

| Jogo / fonte | Técnica | Fonte |
|---|---|---|
| SLYNYRD (vista lateral) | Tiles extra de relva e plantas por cima do topo; o topo deixa de ser plano e a colisão fica limpa. "Pelo menos uma variante dos tiles que se repetem em fila chega" | [F20] |
| SLYNYRD (vista de cima) | "Se uma zona do tile tiver dominância visual, o padrão torna-se óbvio"; cachos que passam a aresta e dão a volta ao tile escondem a emenda; não pôr cachos-chave a tocar-se | [F21] |
| Saint11 | Variantes do meio e do topo mudando só o centro; tile curinga | [F17] |
| Celeste | Camadas `padding` e `center` com listas de tiles; tilesets que se ignoram | [F25][F26] |
| Terraria | Tiles "emoldurados" (terreno muda de aspeto com os vizinhos) e *multitiles* "FrameImportant" com aspeto fixo | [F27] |
| Terraria (`TileObjectData`) | *Multitile* com `Origin`, `AnchorBottom`/`Top`/`Left`/`Right`/`Wall`, `Width`/`Height` em tiles, `CoordinateHeights` (16 px, "a última pode ser 18"), `CoordinatePadding` 2, `RandomStyleRange` | [F28] |
| Dead Cells | Fundo dividido "em secções de tamanho variável", cada tipo de decoração com regras próprias; o fundo e as colisões contrastam "o mais possível"; inimigos e projéteis com mais saturação, contraste e brilho | [F29] |
| Dead Cells (níveis) | Salas desenhadas à mão (biblioteca de "tiles" de sala, por bioma) dispostas proceduralmente — só lido por resumo de pesquisa | [F62] |
| Hollow Knight | Níveis com "assets 2D em camadas num ambiente 3D"; luz feita com "formas transparentes suaves"; arte desenhada à mão guardada como PNG simples | [F30] |
| Kingdom | O mapa é feito de "blocos de construção" postos lado a lado, depois vegetação no chão; "tudo num plano nivelado"; "stubs" de torres e muros nas secções onde são permitidos, "para evitar sobreposições" | [F31] |
| Skyrim (kits) | Os jogadores reagem mais depressa ao detalhe repetido do que à arquitetura repetida; *hero pieces* poucas vezes; peças de "cola" entre kits | [F40] |
| Godot | *Scattering* para "detalhe ocasional, sem repetir" | [F13] |

Não encontrei fonte primária sobre como Owlboy e Blasphemous montam os cenários. Ficam fora deste relatório,
para não lhes atribuir técnicas sem prova.

[Inferência] O 18 da última linha de um *multitile* de Terraria [F28] faz o objeto entrar 2 px no chão, por baixo
da linha da grelha. É o mesmo truque que o Empire precisa nos edifícios: a base desenhada afunda na linha do solo
em vez de pousar exatamente nela.

### 2.2 *Stamps* contra tiles

| | Tile | *Stamp* (objeto com origem) |
|---|---|---|
| Posição | célula da grelha (32 px) | âncora livre, ou com passo e fase próprios |
| Emendas | com os vizinhos (Wang/terreno) | nenhuma; sobrepõe-se às emendas |
| Repete-se | em x/y | não; variantes e espaçamento mínimo |
| Exemplo | corpo do solo, topo, face | tufo, raiz, rocha, trepadeira, árvore, edifício |
| Godot | `TileMapLayer` | `Sprite2D`, *scene tile* [F13], `MultiMeshInstance2D` para milhares (ASSET_BIBLE §6) |

[Proposta] No Empire: os tiles dão a colisão e a massa; os *stamps* dão a silhueta e o pormenor. Regras de
colocação por secção como no Dead Cells [F29]: cada *stamp* declara âncora, faixa permitida, espaçamento mínimo e
probabilidade. O ASSET_BIBLE já diz "4 variantes no mínimo; nunca a mesma variante a menos de 400 px".

---

## 3. Kits modulares de edifícios em vista lateral

### 3.1 Princípios de kit (Skyrim, transpostos para 2D)

- "Os kits são, antes de tudo, sistemas" e valem "muito mais do que a soma das partes" [F40].
- A **pegada** (*footprint*) é "a fundação do kit inteiro", "a grelha imaginária onde as coisas se alinham";
  "as peças existem sempre dentro da pegada"; as pegadas de sub-kits são múltiplos umas das outras; o passo de
  encaixe deve ser "o maior possível", em geral metade da pegada [F40].
- Pivôs no plano do chão e ao centro; mudá-los depois custa caro [F40].
- "Evitar um kit que repita em todos os eixos"; corredores repetem num eixo, salas em dois [F40].
- Variantes com sufixo `01/02/03` para ficarem juntas na lista [F40].
- *Art fatigue*: a repetição torna-se óbvia "e corrói a autenticidade do mundo" [F40].

[Inferência] Em vista lateral um edifício repete **só em x**: a fachada é um kit de 1 eixo (tira), o telhado
outro, e a altura é um parâmetro discreto (número de andares), não um eixo de repetição.

### 3.2 9-slice e 3-slice: repetir, não esticar

- Aseprite: um *slice* pode ter um retângulo interior de 9-slice e um pivô [F42].
- Godot `NinePatchRect`: `STRETCH` "pode distorcer a textura"; `TILE` "repete o centro… não causa distorção";
  `TILE_FIT` repete mas também estica, para cada repetição ficar inteira [F52].
- Unity: em *Sliced* os cantos mantêm o tamanho e arestas e centro esticam; em *Tiled* "o sprite mantém o
  tamanho e não escala", arestas e centro repetem; *Adaptive* só repete ao atingir o *Stretch Value*; escalar pela
  Transform "escala o sprite sem aplicar o 9-slicing" [F53].
- Rodar pixel art produz *aliasing* [F33]; a escala não inteira provoca "escala de pixel desigual" [F51].

[Inferência] Em pixel art só `TILE` mantém um pixel de arte igual a um pixel de ecrã. `TILE_FIT` estica e cria
cachos de 1 px ou de 3 px — viola a lei dos 2 px. Por isso o comprimento de um módulo repetível tem de ser um
múltiplo inteiro do período da textura, e o período múltiplo do cacho (2 px; 4 px nos planos de fundo).
**3-slice horizontal** (ponta esquerda, meio repetido, ponta direita) é o caso geral de fachadas, telhados,
alicerces e muros; o 9-slice só se usa onde a altura também varia (torres com andares).

### 3.3 Módulos de um edifício lateral

| Módulo | Função | Repete | Notas |
|---|---|---|---|
| Alicerce / soco | contacto com o chão, soleira | x (3-slice) | define a pegada; afunda 2–4 px no chão [Inferência, §2.1] |
| Parede (corpo) | massa da fachada | x (3-slice), andares em y | postes ou pilares como separadores do período |
| Porta (inserção) | abertura | não | *slice* `door_clear` com a abertura livre (§7d) |
| Janela (inserção) | ritmo e luz | não | camada emissiva separada (§5.4) |
| Beiral / empena | pontas do telhado | não (L e R desenhados) | o perfil da ponta é silhueta |
| Telhado (campo) | massa do telhado | x | período ≥ 32 px |
| Cumeeira / remate | identidade do povo | x | **80% da identidade** (ASSET_BIBLE) → camada própria, trocável por povo |
| Chaminé | marco vertical; fumo | não | âncora de emissor de fumo e de luz |
| Vigas / escoras / andaime | estados de obra | x | partilhadas pelos estados `scaffold` e `building` |
| Letreiro | ofício | não | ícone entalhado, sem texto (ASSET_BIBLE §6) |

### 3.4 Estados como base + deltas

- [Repo] Os estados `empty · scaffold · building · done · damaged · ruin` são **frames do mesmo ficheiro**
  (`docs/art/ASSET_BIBLE.md` §1, "Edifícios e cenário").
- Aseprite: dois *cels* ligados "partilham a imagem e a coordenada xy"; mudar um muda todos [F45]. As *tags*
  indicam animações [F63] e exportam-se uma a uma com `--tag` [F43].
- Dead Cells desenha as texturas de parallax em cinzento e colore-as com um *gradient map*: mudar o mapa basta
  para mudar a paleta de um bioma [F29].

[Proposta] Cada estado é uma **composição de camadas** sobre uma base comum, com *cels* ligados:

| Camada | empty | scaffold | building | done | damaged | ruin |
|---|---|---|---|---|---|---|
| marca do sítio (estacas, cordel) | ● | ● | | | | |
| alicerce | contorno | ● | ● | ● | ● | ● (partido) |
| parede | | | máscara de altura h% | ● | ● | ruína baixa |
| telhado + remate | | | | ● | ● com falhas (máscara) | |
| andaime | | ● | ● | | | |
| dano (fissuras, tábuas soltas) | | | | | ● | |
| entulho | | | | | | ● |
| emissiva (janelas, forja) | | | | ● | ● (intermitente) | |

O "building" pode ser uma máscara de altura aplicada à parede, em vez de um desenho por cada percentagem
[Inferência]. Neve, noite e estação são deltas de cor (LUT ou *gradient map*) e uma camada de neve nos beirais e
na cumeeira — não são outro desenho [Proposta].

### 3.5 Kingdom Two Crowns como referência de escada

- Muros: monte de terra (nível 0, gerado no mapa) → barricada (1 moeda, era da madeira) → muro de madeira (3) →
  muro de pedra (5, era da pedra) → muro de castelo (8, pedra) → muro de ferro (12, era do ferro) [F38].
- Centro do reino: acampamento → fogueira (abre arqueiro e martelo dos dois lados) → acampamento com tendas →
  aldeia (barreiras de madeira e muros de nível 1 grátis) → vila (edifício grande "tipo igreja") → forte (muros de
  pedra) → castelo (no meio do reino) → castelo de ferro [F39].
- As fontes só descrevem o aspeto pela era do material e pela resistência ("quanto maior o nível, mais golpes
  aguenta") [F38].

[Inferência] A escada lê-se porque cada nível muda **material** (madeira → pedra → ferro) e **massa** (barricada
baixa → muro → castelo). [Proposta] Para os 5 níveis × segmento/remate/portão de cada povo: cada nível difere do
anterior em pelo menos dois de {altura da silhueta, perfil do topo, material}. Validar com a silhueta preenchida a
preto (o mesmo teste do remate do telhado no ASSET_BIBLE: tapar tudo abaixo do solo).

### 3.6 O que o autor de Kingdom e a Raw Fury publicaram

- 2015, 80.lv: arte "tosca, mas coerentemente tosca", e "o motor cola-a com luz e efeitos"; renderizar em baixa
  resolução tem vantagem de desempenho; luz em tempo real e reflexos "não são obstáculo" [F31].
- 2016, Game Developer: o shader de água e as nuvens estão entre as partes preferidas do autor; o método de reflexo
  veio dos fóruns do Flixel [F32].
- 2019, Game Developer: pixel art "porque é divertido de aprender e fazer, e económico"; caminho curto do esboço
  ao motor; problemas de *aliasing* ao rodar e de tamanhos de fonte e UI [F33].
- 2023, 80.lv (outro projeto do mesmo autor): reflexos com "uma câmara que renderiza a cena por baixo"; píxeis
  alinhados com a geometria e do mesmo tamanho em todo o modelo [F34].

Não encontrei nenhum texto da Raw Fury ou do autor sobre o *pipeline* de edifícios e muros de Two Crowns. O devlog
original no TIGSource (tópico 40539) está atrás de um desafio Cloudflare e não pôde ser lido; o que se diz dele
vem de terceiros [F35][F36].

---

## 4. Parallax

### 4.1 Regras das fontes

- Pseudo-código: `render_x = (x − camera.x) × scroll_factor + offset.x` (o mesmo em y); a câmara anda 2 px por
  frame e cada camada a outra velocidade; um primeiro plano com fator > 1 "dá muita profundidade"; a UI tem fator
  0; "com raras exceções o fator é sempre maior do que zero" [F18].
- Perto / longe: saturação alta/baixa, contraste alto/baixo, luz clara/escura, matiz quente/fria, detalhe
  muito/pouco ("há exceções"); os objetos longe "podem fundir-se com a cor do céu" [F18].
- Perspetiva atmosférica: o objeto distante "toma a cor da neblina", tem menos saturação e "menos cores"; quanto
  mais perto da linha do horizonte, mais distante parece [F23].
- Loop fechado: movimento só em píxeis inteiros; "os píxeis por frame têm de dividir a dimensão da tela"; abaixo
  de 1 px/frame o movimento "pode parecer aos solavancos" (usar 1 px a cada 2 frames); animações em loop dentro da
  cena têm de dividir o número total de frames; "camadas equilibradas sem pontos de interesse dominantes ajudam a
  esconder o loop" [F22].
- Dead Cells: profundidade exterior com paletas análogas, "texturas de parallax, partículas que dão densidade ao
  ar", nuvens no primeiro plano; texturas de parallax em cinzento + *gradient map* [F29].

### 4.2 Godot 4 `Parallax2D`

| Propriedade | O que faz | Fonte |
|---|---|---|
| `scroll_scale` | multiplicador da velocidade; 1 = câmara, < 1 longe, > 1 perto, 0 parado | [F47][F48] |
| `repeat_size` | o nó salta para a frente ou para trás quando a câmara anda esse valor; 0 num eixo = não repete | [F47][F48] |
| `repeat_times` | "solução de força bruta" para zoom out | [F47][F48] |
| `scroll_offset` | deslocamento próprio, que dá a volta se `repeat_size` > 0 | [F47][F48] |
| `screen_offset` | deslocamento atualizado automaticamente, salvo com `ignore_camera_scroll` | [F48] |
| `autoscroll` | velocidade automática em px/s (nuvens) | [F48] |
| `follow_viewport` | desloca pela posição da câmara | [F48] |
| `limit_begin` / `limit_end` | limites do deslocamento | [F48] |

- A textura deve repetir sem emenda e ter "o mesmo tamanho ou maior do que o viewport"; o canvas de repetição
  "começa em (0,0)" e cresce para baixo e para a direita; texturas centradas ou em coordenadas negativas cortam
  meia imagem no salto [F47]. `repeat_size` e `region_rect` não contam com a escala [F47].
- O nó controla a sua `position`; um deslocamento persistente vai em `scroll_offset` [F48].
- O `Parallax2D` não deve ser interpolado pela interpolação de física, porque "depende de saltar entre dois pontos"
  para a repetição; o PR que a introduziu (4.3) desliga-a para ele [F49]; a classe sobrepõe por omissão
  `physics_interpolation_mode` [F48].
- Pixel art: o modo `viewport` dá baixa resolução esticada; `canvas_items` pode ter artefactos porque deixa de
  haver 1:1 entre píxeis; escala inteira evita píxeis desiguais [F51]. O 4.3 simplificou o *snap* de transformadas
  2D (arredonda a posição de cada `CanvasItem` em vez de truncar em vários sítios) [F50].

### 4.3 O Empire hoje [Repo] e o que as fontes sugerem

- `project.godot`: 1280×720, `stretch/mode="canvas_items"`, filtro por omissão *nearest*; sem *snap* 2D ligado.
  A câmara trunca x a inteiros (`src/world/camera_rig.gd:174`, `floorf`). Os planos arredondam a origem
  (`src/world/scenery_plane.gd`, `roundf`). A 1:1 nativo, `canvas_items` e `viewport` dão o mesmo píxel.
- Fatores: 0,03125 / 0,07 / 0,125 / 0,25 / 0,5 (`docs/art/NATIVE_SCENERY.md`); a cena
  `scenes/segments/enramados/enramados_start_base_01.tscn` tem ainda um plano `Grove` a 0,65. O
  `data/source/parallax_layers.csv` define, por camada, `motion_scale` e os deltas de saturação, valor, matiz,
  detalhe mínimo e cores por 16 px — a forma tabular da tabela "perto/longe" do Saint11 [F18].
- Os planos pintados não usam `repeat_size`: `SceneryArt.draw_layer`/`draw_mirrored` desenham os quadros, e o
  modo espelho vira os quadros ímpares para que "as pontas de dois quadros vizinhos sejam a mesma coluna"
  (`src/world/scenery_art.gd:158`).

[Inferência] **Cadência.** Com câmara inteira, o plano anda `s × Δx`. Fatores diádicos (1/32, 1/16, 1/8, 1/4,
1/2) dão passos regulares: 1 px a cada 32, 16, 8, 4 ou 2 px de câmara. 0,07 dá passos de 14 ou 15 px de câmara
alternados, e 0,65 um ritmo irregular de 1 e 2. Não é um erro, mas é a origem provável de "tremuras" num plano
lento. [Proposta] 0,07 → 0,0625 (1/16) e 0,65 → 0,625 (5/8), se o dono aceitar; o `PlaneContract` já garante a
ordem estrita.

[Inferência] **Período e emenda.** Num parallax seguido pela câmara, o loop não precisa da regra do SLYNYRD (essa
é para animações fechadas [F22]); precisa de (1) bordas esquerda e direita que repitam, (2) período `W` múltiplo
do cacho da camada (2 px; 4 px no fundo), senão a grelha de cachos parte-se na emenda, e (3) `W ≥ 1280` com
`repeat_times = 1` [F47]. Para nuvens em `autoscroll`, uma velocidade em px/s que dê um loop exato a 60 Hz
(`W` divisível pelo passo por frame) evita o salto de fase [F22 transposto].

[Inferência] **Espelho.** A repetição por espelho elimina a emenda mas cria um eixo de simetria a cada período e
inverte o lado iluminado nos quadros ímpares. O SLYNYRD só aceita espelhar "com luz simétrica ou omnidirecional
ambígua" [F20], e o ASSET_BIBLE proíbe espelhar o que tenha lado iluminado. [Proposta] Para planos com luz lateral,
tile mestre toroidal (o método do Saint11: deslocar 50% e refazer o centro [F17]) com 2–3 variantes de quadro, em
vez do espelho.

[Proposta] **Ancoragem vertical.** Hoje `scroll_scale.y = 1` (planos presos ao mundo em y). Com três faixas e uma
câmara que muda de faixa, um `scroll_scale.y` < 1 nos planos de fundo dá profundidade vertical [F18]. Só vale se o
horizonte de cada plano ficar acima da linha do solo em todas as posições de câmara: mede-se.

---

## 5. Estrutura de assets e metadados

### 5.1 Origem, âncora e recorte

- Aseprite: o *slice* tem nome, limites, centro de 9-slice e "um pivô para indicar o local central/base do sprite
  dentro do slice"; no JSON vem em `meta.slices` com `keys` por frame (`frame`, `bounds`, `center`) [F42].
- Recorte: no JSON exportado, `frame` é a caixa na folha; `sourceSize` é o tamanho antes do recorte;
  `spriteSourceSize` é onde estava o recorte na tela original. "Trim Sprite" recorta todos os frames pelo mesmo
  retângulo; "Trim Cels" recorta cada frame, e o deslocamento tem de se ler frame a frame; `sourceSize` fica igual
  à tela nos dois modos (exemplos com JSON no fórum da Aseprite) [F46].
- Terraria: o `Origin` de um *multitile* é a célula de onde é colocado; `AnchorBottom` define os apoios por baixo
  [F28].
- Godot: `AtlasTexture` recorta outra textura por `region`; `margin` serve para "pequenos ajustes"; `filter_clip`
  evita *bleeding* [F57]. `Sprite2D` tem `centered`, `offset`, `region_enabled`, `region_rect`,
  `region_filter_clip_enabled` [F58].

[Inferência] O que se perde num recorte é a posição do pivô relativamente aos píxeis. Para não perder: guardar o
pivô na tela de autoria (`pivot_src`) e o retângulo recortado (`crop = spriteSourceSize`); no Godot, `offset =
crop.position − pivot_src` com `centered = false`. Com `centered = true` e largura ímpar, o centro cai em meio
píxel. [Proposta] Os deslocamentos de recorte no cenário têm de ser múltiplos do cacho (2 px), senão o recorte muda
a fase da grelha de 2 px.

### 5.2 Exportação pela linha de comandos da Aseprite

Opções úteis [F43]: `--data` e `--format json-array|json-hash`; `--sheet` e `--sheet-type`; `--split-layers`,
`--split-tags`, `--split-slices` (1.2-beta8), `--split-grid` (1.3-beta21); `--layer`, `--all-layers`, `--tag`,
`--slice`; `--trim`, `--trim-by-grid`, `--ignore-empty`; `--list-layers`, `--list-tags`, `--list-slices`,
`--list-layer-hierarchy` (com `--data`, vão para `meta`); `--export-tileset` (1.3-beta21); `--filename-format`
com `{layer}`, `{tag}`, `{frame}`; `--extrude`, `--shape-padding`, `--border-padding`, `--inner-padding`;
`--merge-duplicates`; `--script`.

Camadas de *tilemap* (Aseprite 1.3): cada célula referencia um tile do *tileset* da camada; o índice 0 é o tile
vazio; modos de desenho *Manual*, *Auto* (cria e reutiliza tiles) e *Stack* [F44].

[Inferência] `--trim-by-grid` junto com `--split-slices` permite exportar módulos de edifício recortados à grelha
de 32 px sem perder o alinhamento; `--list-slices --data` leva os pivôs e o 9-slice para o JSON que a Forja ou um
importador lê. [Repo] O ASSET_BIBLE (§5) avisa que `tools/export_aseprite.sh` nunca correu com a Aseprite.

### 5.3 Godot: importação

- Tiles de várias células e margem/separação do atlas [F16]; *padding* de textura [F09].
- `TileData.texture_origin` para tiles que desenham fora da célula (topos com relva que sobe acima da grelha)
  [F11]. [Inferência] É a forma nativa do Godot de "quebrar a grelha" sem largar o `TileMapLayer`.

### 5.4 Luz, oclusão e emissão

- 2D: `PointLight2D` para tochas e fogo; `DirectionalLight2D` com sombras sempre infinitas; `LightOccluder2D`
  com polígono; máscaras de *cull* de luz e de sombra; mapas de normais e especular por `CanvasTexture`; com
  normais, subir a `Height` das luzes [F54][F56].
- "O motor calcula a luz 2D à resolução do viewport, não à dos texels"; o filtro *nearest* não chega; para luz
  pixelizada, arredondar `LIGHT_VERTEX` e `SHADOW_VERTEX` à grelha num shader; filtro de sombra `None` para pixel
  art [F54].
- `CanvasItemMaterial.light_mode`: `UNSHADED` desenha "como se não houvesse luz"; `LIGHT_ONLY` "como se só
  houvesse luz"; modos de mistura `ADD`, `MUL`, etc. [F55].
- Dead Cells desenha os mapas de normais à mão no Photoshop [F29]; Hollow Knight fez a luz com formas
  transparentes suaves [F30].

[Proposta] Uma **camada emissiva** por edifício (janelas, boca da forja) exportada como folha própria, com
`LIGHT_MODE_UNSHADED`, alinhada ao mesmo pivô e frames; uma âncora `light:*` no JSON para o `PointLight2D`. Assim a
noite escurece a fachada (LUT ou `CanvasModulate`) e a janela continua acesa. O snap de `LIGHT_VERTEX` ao cacho
de 2 px mantém a luz no grão do cenário [F54 transposto]. [Repo] O projeto já tem luz própria por shader
(`src/world/scenery_light.gd`, ADR 0048); a camada emissiva junta-se a esse sistema, não o substitui.

### 5.5 Métricas documentadas

- Métricas são "o sentido de escala, distância e medida em todo o nível"; *player metrics* (tamanho, altura do
  salto) e *building metrics* (largura mínima de corredor, tamanho de porta, altura de teto) [F41].
- Recomenda-se um mapa de métricas ("metrics zoo"/"playground") com todos os módulos e *prefabs*; em kits
  "mede-se uma vez" e reutiliza-se [F41]. As caixas de colisão são em geral maiores do que o modelo [F41].
- Psychonauts 2 tem uma ferramenta que desenha o arco do salto no editor [F41].

[Proposta] Uma tabela `metrics` única para o cenário: altura útil do rei (66 px visíveis), largura do corpo,
abertura livre mínima de porta, soleira (12–20 px, ASSET_BIBLE), altura de degrau de rampa, largura de travessia e
de escada, recuo mínimo entre *stamp* e porta. A galeria de revisão (`tools/native_scenery_review.tscn`) é o
"metrics zoo" natural.

---

## 6. Água e reflexos

### 6.1 Fontes

- Kingdom, por relato de terceiros que seguiram o devlog do autor: desenhar o que se quer refletido num canvas
  ("o chão, as árvores e os pássaros"), virá-lo, passá-lo por um shader de distorção de água e tingi-lo de azul
  [F35]. No fórum do Defold sugere-se que Kingdom usa uma segunda passagem de distorção a outra velocidade [F36].
- O autor diz que o shader de água está entre as suas partes favoritas e que aprendeu o método nos fóruns do
  Flixel [F32]; noutro projeto usa "uma câmara que renderiza a cena por baixo" [F34].
- Saint11: água com duas camadas — a de cima com "círculos a mudar de tamanho", sem "mexer mais de 1 px"; a de baixo
  deslocada a velocidade constante; pequenas ondas animadas com um só cacho cada [F19].
- Godot: um shader com `hint_screen_texture` lê o que já foi desenhado; a primeira leitura copia o ecrã inteiro e
  as seguintes reutilizam a cópia; `BackBufferCopy` copia num ponto da árvore; ler fora da região copiada é
  indefinido [F59].
- Um shader do godotshaders "inspirado no post de Kingdom": espelha as UV na linha da água, arredonda as UV a uma
  grelha de 480×270 antes e depois da distorção, duas texturas de deslocamento a escalas diferentes, distorção e
  tinta que crescem com a profundidade [F37].

### 6.2 Desenhado contra renderizado

| | Reflexo renderizado (espelho do ecrã ou `SubViewport`) | Reflexo desenhado |
|---|---|---|
| Coerência com o estado do edifício | automática: reflete o frame atual [Inferência] | um frame de reflexo por estado e por luz [Inferência] |
| Custo de arte | zero | duplica edifícios e árvores |
| Pixel art | precisa de *snap* das UV à grelha [F37] | controlo total |
| Limite | só reflete o que já foi desenhado antes da água [F59] | — |

[Proposta] Reflexo renderizado, com amostragem arredondada ao cacho de 2 px em x e y (o equivalente a 640×360 no
Empire), linha da água igual à linha da superfície onde o `water_back` e o `water` se separam
(`docs/art/NATIVE_SCENERY.md`), e a camada emissiva incluída na captura para as janelas se refletirem de noite.
Ordem de desenho: estruturas, adereços e camada emissiva **antes** do nó de água; `BackBufferCopy` limitado à
faixa da água [F59].

---

## 7. Proposta para o Empire

Tudo nesta secção é **[Proposta]**. Os números marcados "a medir" não foram medidos.

### 7a. Receita de cena (`scene_recipe`)

Objetivo: descrever uma cena de forma que um script a monte, a Forja a valide e uma pessoa a leia. Cada camada e
cada objeto declaram papel, âncora, origem, grelha, repetição, conectores, estados e luzes.

```json
{
  "id": "enramados_start_base_01",
  "viewport": [1280, 720],
  "ground_y": 517,
  "under_y": 618.5,
  "bands": ["AERIAL", "SURFACE", "UNDERGROUND"],
  "layers": [
    {"id": "far", "role": "parallax", "z": -50, "scroll_scale": [0.125, 1.0],
     "cluster_px": 4, "outline_px": 0, "palette_delta": "parallax_layers.csv#open_2",
     "repeat": {"axes": "x", "period_px": 1536, "mode": "wrap", "variants": 2},
     "anchor": {"kind": "horizon", "y": 380}},
    {"id": "terrain", "role": "tilemap", "z": 0, "cluster_px": 2,
     "grid": {"step": 32, "phase": [0, 5]}, "tileset": "enramados_tiles_surface",
     "rows": {"cap": 517, "body": [549, 613], "strata": 581}},
    {"id": "structures", "role": "objects", "z": 10, "cluster_px": 2},
    {"id": "props", "role": "stamps", "z": 12, "cluster_px": 2,
     "scatter": {"min_gap_same_variant_px": 400, "variants_min": 4}},
    {"id": "water", "role": "water", "z": 20, "waterline_y": 517,
     "reflection": {"mode": "screen_mirror", "snap_px": 2, "sources": ["structures", "props", "emissive"]}}
  ],
  "objects": [
    {"id": "forge_01", "asset": "enramados/buildings/enramados_forge",
     "layer": "structures", "role": "building",
     "anchor": {"kind": "base_center", "world": [2048, 517]},
     "origin_src": [64, 126], "crop": {"x": 4, "y": 6, "w": 120, "h": 120, "src_w": 128, "src_h": 128},
     "footprint_px": [128, 0], "sink_px": 2,
     "grid": {"step": 32, "phase": 0},
     "states": {"tag_by_state": {"empty": "empty", "scaffold": "scaffold", "building": "building",
                                 "done": "done", "damaged": "damaged", "ruin": "ruin"},
                "overlays": ["snow", "night"]},
     "slices": {"door_clear": [52, 54, 26, 72], "threshold": [40, 120, 48, 6]},
     "lights": [{"kind": "point", "anchor": "light:forge_mouth", "emissive_layer": "emissive",
                 "states": ["done", "damaged"]}],
     "occluder": "auto_from_alpha"},
    {"id": "wall_w1", "asset": "enramados/walls/enramados_wall_l3_segment", "role": "wall",
     "anchor": {"kind": "base_center", "world": [1600, 517]},
     "repeat": {"axes": "x", "count": 3, "period_px": 32},
     "connectors": {"left": "wall.l3.enramados.cap", "right": "wall.l3.enramados.segment"}}
  ]
}
```

| Campo | Significado | Regra de validação (§7d) |
|---|---|---|
| `role` | `parallax`, `tilemap`, `stamps`, `objects`, `building`, `wall`, `water`, `foreground` | o papel diz que testes correm |
| `anchor.kind` | `feet`, `base_center`, `horizon`, `top`, `free` | `base_center`/`feet` exigem contacto com `ground_y` |
| `origin_src` | pivô na tela de autoria, antes do recorte | invariância do recorte |
| `crop` | `spriteSourceSize` + `sourceSize` da Aseprite [F46] | offsets múltiplos do cacho |
| `grid.step`, `grid.phase` | passo e fase da grelha em que o objeto encaixa | `world.x − phase ≡ 0 (mod step)` |
| `repeat` | eixos, período, modo `wrap`/`mirror`/`none`, variantes | emenda, cadência, visibilidade da repetição |
| `connectors` | rótulo das pontas (`<família>.<nível>.<povo>.<perfil>`) | compatibilidade de perfil |
| `states` | estado → *tag* da Aseprite; *overlays* de cor | mesmo pivô e tela em todos os estados |
| `slices` | retângulos com nome (`door_clear`, `threshold`, `light:*`) | porta livre, soleira |
| `lights` | âncora, camada emissiva, estados em que acende | emissiva dentro do *slice* da janela |
| `palette_delta` | linha do `parallax_layers.csv` | saturação e valor medidos na ordem certa |

Notas:

- A receita não substitui a cena `.tscn`; gera-a ou verifica-a. A posição dos sítios continua a vir da simulação
  (`PlaneContract`: "a porta, o preço e a colisão ficam onde a simulação os põe").
- [Repo] Em `data/source/buildings.csv` a forja tem `width_px = 120`, e o ASSET_BIBLE pede larguras "múltiplas de
  32 px sempre que possível". O exemplo usa uma tela de 128 com 120 de desenho; quem decide é o dono
  (pergunta para `docs/QUESTIONS.md`).

### 7b. Família mínima de tiles da faixa de superfície (32 px, cachos de 2 px)

Hipótese: a superfície é um plano nivelado em `y = 517` (como Kingdom [F31]); a geometria funcional dos sítios é
da simulação; os buracos (passagens, cavidades) e os desníveis são exceções.

**Núcleo (11 tiles)** — autoria em módulos de 64×64 (2×2 tiles), como pede o ASSET_BIBLE:

| Id | Papel | Repete sem emenda em | Notas |
|---|---|---|---|
| `cap_a`, `cap_b`, `cap_c` | topo: lábio + relva | x | variantes só no centro [F17]; relva pode subir acima da célula com `texture_origin` [F11] |
| `cap_end_l`, `cap_end_r` | canto exterior (margem de água, falésia, boca de passagem) | — | L e R desenhados (sem espelho) |
| `body_a`, `body_b` | corpo do solo | x e y (toroidal) | tile mestre; sem cachos dominantes [F21] |
| `face_l`, `face_r` | corte vertical do solo, com estratos | y | por baixo das pontas |
| `strata` | banda de transição para o subsolo | x | liga a superfície à faixa de baixo |
| `wild` | curinga | — | "onde nenhum tile serve" [F17] |

**Extensões, só quando o sítio pede:**

| Id | Quando | Tiles |
|---|---|---|
| `inner_l`, `inner_r` | degrau (topo encontra uma face) | 2 |
| `slope11_l/r` | rampa 1:1 (degraus 2×2 px) | 2 |
| `slope12_l1/l2/r1/r2` | rampa 1:2 em dois tiles | 4 |
| `oneway_l/m/r` | ponte, travessia, plataforma (3-slice) | 3, com polígono de sentido único [F11] |
| `bg_wall_*` | parede de trás nas cavidades | tileset separado, como o *background* do Celeste [F26] |

**Total:** 11 no núcleo, 22 com todas as extensões, contra 16 de um Wang de canto que, em vista lateral com relva
só por cima, inclui os dois tiles de diagonal (índices 6 e 9) sem sentido numa superfície [Inferência]. O Wang 16 da
Forja (`forja tileset`, `--rim-side top`) fica para o **corte de solo e cavidades** do UNDERGROUND, onde as manchas
são 2D [Proposta]. Decoração (tufos, raízes, pedras, trepadeiras) é *stamp*, não tile (§2.2).

### 7c. Kit modular mínimo de uma oficina (forja), com estados

Pegada: 4 tiles (128 px) — a confirmar com o `width_px` de 120 (§7a). Grelha de encaixe: 32 px; período de
repetição dos módulos: 32 px; cacho de 2 px; contorno de 2 px na silhueta (ASSET_BIBLE).

| # | Módulo | Tamanho (px, proposta) | Repete | Usado nos estados |
|---|---|---|---|---|
| 1 | `plinth_l`, `plinth_m`, `plinth_r` | 32×16 cada | `m` em x | todos menos `empty` (contorno no `empty`) |
| 2 | `wall_l`, `wall_m`, `wall_r` | 32×48 cada | `m` em x | `building` (mascarado), `done`, `damaged` |
| 3 | `door` (inserção) | 32×80, abertura livre ≥ 28×72 | — | `done`, `damaged` |
| 4 | `window` (inserção) | 32×32 | — | `done`, `damaged` |
| 5 | `eave_l`, `eave_r` (empenas/beirais) | 32×48 | — | `done`, `damaged` |
| 6 | `roof_m` | 32×32 | x | `done`, `damaged` (com máscara de falhas) |
| 7 | `ridge_trim_<povo>` | 32×16 | x | `done`, `damaged`; troca por povo |
| 8 | `chimney` | 16×48 | — | `done`, `damaged`; âncoras `smoke`, `light:forge_mouth` |
| 9 | `scaffold_m`, `scaffold_end` | 32×64 | `m` em x | `scaffold`, `building` |
| 10 | `damage_overlay` | tela inteira | — | `damaged` |
| 11 | `rubble` | tela inteira | — | `ruin` |
| 12 | `site_marker` | 32×16 | — | `empty`, `scaffold` |
| 13 | `emissive` | tela inteira | — | `done`, `damaged` |
| 14 | `sign_<ofício>` | 16×16 | — | `done`, `damaged` |

Regras:

1. Todos os módulos partilham a tela, o pivô (centro da base na linha do solo) e as *tags* de estado; os *cels*
   repetidos entre estados são ligados [F45].
2. A identidade do povo vive no módulo 7 e nos 5 (perfil das empenas) — os 80% do ASSET_BIBLE — e troca-se sem
   redesenhar 1–4.
3. Neve: camada `snow` só sobre 5–7; noite: LUT sobre tudo menos `emissive`.
4. A abertura livre da porta (`door_clear`) cabe o rei (66 px visíveis) com folga; 72 px é proposta, a medir na
   galeria com o sprite real.

### 7d. Validações automáticas (o que uma ferramenta pode correr)

| # | Verificação | Como | Passa se | Base |
|---|---|---|---|---|
| V1 | Pares de emenda Wang | agrupar por assinatura de aresta; comparar tiras de 2 px (o `tiles.pairs()` em curso já compara perfis) | tiras idênticas no grupo; máscara contínua nos 64+64 pares | §1.4; [F04][F61] |
| V2 | Junções 2×2 | montar os 512 blocos; componentes por índice junto às emendas | nenhum componente < 4 px ou com lado < 2 px a tocar a emenda | §1.4 |
| V3 | Completude do terreno | enumerar as vizinhanças que o pintor pode gerar | há tile para cada uma | [F08] |
| V4 | Emenda toroidal (enchimento, parallax) | `tiles.seams` atual + teste de máscara e de cachos na borda | os dois passam | [Repo] `tools/forja/tiles.py` |
| V5 | Visibilidade da repetição | autocorrelação normalizada no período contra lags vizinhos; saliência por cacho | pico ≤ limiar (a calibrar); nenhum cacho com saliência > k × mediana | [F21][F22][F60] |
| V6 | Compatibilidade de conectores | perfil da coluna de ligação (topo e base opacos, rampa de cor) dos dois módulos | perfis iguais ao píxel; rótulos iguais | [F40] |
| V7 | Invariância da origem após o recorte | compor a tela original e a recortada com `offset` | imagem idêntica ao píxel; offsets múltiplos do cacho | [F46] |
| V8 | Alfa binário | histograma do canal alfa | só 0 e 255 | NATIVE_SCENERY |
| V9 | Cacho ≥ 2 px (≥ 4 px no fundo) | reduzir por *nearest* a 1/2 (1/4) com a fase da grelha e voltar a ampliar | igual ao original | ASSET_BIBLE §1 |
| V10 | Contacto com a linha do solo | última linha opaca contra `anchor.y`, com `sink_px` | linha opaca = `ground_y + sink_px`; ≥ 60% da pegada com contacto (limiar a calibrar) | [F28][F40] |
| V11 | Porta livre | *slice* `door_clear` sem píxeis opacos de camadas não-porta no estado `done` | altura ≥ 72, largura ≥ 28 (a medir) | [F41] |
| V12 | Mesmo pivô em todos os estados | `sourceSize` e `origin_src` iguais por *tag* | iguais | ASSET_BIBLE §1 |
| V13 | Ordem dos planos | `PlaneContract` + valor e saturação médios por plano | `scroll_scale` crescente; saturação e contraste crescentes para a frente | [F18][F23]; [Repo] |
| V14 | Cadência do parallax | padrão de passos de `round(s × x)` para x inteiro | período do padrão ≤ 32 px de câmara (ou fator diádico) | §4.3 |
| V15 | Período do parallax | `W` contra cacho e viewport | `W mod cacho = 0`; `W ≥ 1280` | [F47] |
| V16 | Espelho com luz lateral | modo `mirror` num plano com lado iluminado | proibido | [F20]; ASSET_BIBLE |
| V17 | Emissiva dentro das janelas | píxeis da camada `emissive` contra *slices* `window*`/`light:*` | todos dentro | §5.4 |
| V18 | Oclusor dentro da silhueta | polígono do `LightOccluder2D` contra o alfa | contido | [F54] |
| V19 | Escada de muros | silhueta preenchida de cada nível | cada nível difere do anterior em ≥ 2 de {altura, perfil, material} | §3.5 |
| V20 | Reflexo coerente | trocar o estado de um edifício na água e capturar | o reflexo muda no mesmo frame | §6.2 |

V1, V2, V7, V8, V9 e V15 são exatos e baratos (milissegundos por asset). V5, V10 e V19 precisam de limiares
calibrados com arte aprovada pelo dono antes de chumbarem alguma coisa; até lá dão aviso, não erro.

---

## 8. Lacunas e perguntas (para o dono / `docs/QUESTIONS.md`)

1. A forja tem 120 px em `buildings.csv`; o ASSET_BIBLE pede múltiplos de 32. Tela de 128 com 120 de desenho, ou
   pegada de 128?
2. Mudar os fatores 0,07 e 0,65 para 1/16 e 5/8? (só cadência; a ordem não muda)
3. Trocar a repetição por espelho por tile toroidal + variantes nos planos com luz lateral?
4. Adotar uma família 1D para a superfície e deixar o Wang 16 para o subsolo?
5. `scroll_scale.y < 1` nos planos de fundo, com a câmara a mudar de faixa?
6. Medidas de porta e soleira para o rei de 66 px: medir na galeria de revisão.
7. Fontes que faltam: o devlog de Kingdom no TIGSource (bloqueado por Cloudflare), os tutoriais do Saint11 no
   blog da Studio Miniboss (`blog.studiominiboss.com` não resolve nesta sessão; usei as imagens em `saint11.art`),
   Owlboy e Blasphemous (sem fonte primária encontrada), e o wiki de Kingdom no Fandom (HTTP 402).

---

## 9. Fontes

Ver `B-fontes.json`. Resumo por tipo:

- Documentação: Godot [F09–F14, F16, F47, F48, F51, F52, F54–F59], Aseprite [F42–F45, F63], Tiled [F08],
  Unity [F53], tModLoader [F28].
- Textos de autor e tutoriais: Boris the Brave [F01–F05], jess::codes [F06, F07], Saint11 [F17–F19], SLYNYRD
  [F20–F23], Monteiro [F24], Burgess [F40], Level Design Book [F41].
- Desenvolvedores de jogos: Kingdom [F31–F34], Dead Cells [F29, F62], Hollow Knight [F30], Celeste (wiki de
  modding) [F25, F26], Terraria [F27, F28].
- Artigos científicos: Cohen et al. 2003 [F60]; Lagae & Dutré 2006 [F61].
- Secundárias ou de fórum, assinaladas como tal: [F15, F35–F39, F46, F50, F62]. Só por resumo de pesquisa, sem
  leitura direta: [F07, F15, F61 (resumo), F62].
