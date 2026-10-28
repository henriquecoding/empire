# A — Escala personagem↔cenário e adaptação de referências para pixel art nativa

Pesquisa para o Empire (Godot 4, 1280×720 renderizado 1:1). Data de acesso de todas as fontes: 2026-10-28.
Lista de fontes legível por máquina: `A-fontes.json` (mesma pasta). Os identificadores `[Sxx]` remetem para ela.

> **Nota de integração (28/10, FORJA-09).** O método do §4.2 (marcos, s_porta, s_planta, r) e a tabela do §5.1
> entraram na Forja como `forja escala` e `tools/forja/scenery.json`, com as métricas como propostas (Q-292).
> Síntese e piloto: [README](../README.md).

Convenções deste documento:

- **FACTO [Sxx]** — afirmado por uma fonte citada.
- **MEDIÇÃO [Mxx]** — medido por mim em capturas oficiais da loja Steam (1920×1080), reconstruindo a grelha de
  píxeis da arte por autocorrelação das arestas e contando píxeis nativos com grelha sobreposta. Erro típico
  ±1–2 px nativos. Ver §0.2.
- **INFERÊNCIA** — raciocínio meu a partir de factos e medições.
- **PROPOSTA** — número derivado para o Empire. Não é decisão (AGENTS.md: proposta ≠ decisão).

---

## 0. Âncoras do projeto e método

### 0.1 Dados do projeto (verdade do repositório, fornecidos pelo coordenador)

| Grandeza | Valor |
|---|---|
| Resolução interna | 1280×720, 1:1 (1 px de arte = 1 px de ecrã a 720p) |
| Detalhe das personagens | 1 px |
| Detalhe de cenário/edifícios | células de 2×2 px (grelha efetiva 640×360), fase (0,0) no ecrã |
| Camadas de parallax distantes | células de 4×4 px (grelha efetiva 320×180) |
| Tile | 32 px (= 16 células de 2 px) |
| Linha de chão | y = 517; subsolo y = 618,5; fundo do ecrã 720 |
| Altura visível do King (body_bounds) | **65 px** |
| Ator jogável mais baixo (Nia) | **50 px** |
| Outras alturas medidas | Archer 64, Shadow 60, Bard 58, Quiver 54, Squire 52, Dancer 36 |
| Canvas | tropas 64×64 (pivô 32,62); classe King 80×80 (pivô 40,78) |
| Guia de edifício pequeno | ≈120×130 px; larguras múltiplas de 32 |
| `project.godot` (lido por mim) | `window/stretch/mode="canvas_items"`, sem `scale_mode` (logo `fractional`, o padrão), `default_texture_filter=0` (nearest), sem snapping 2D |

Conversões úteis (INFERÊNCIA aritmética):

- King 65 px = 32,5 células; Nia 50 px = 25 células; tile 32 px = 16 células.
- Em "unidades de cenário", o Empire é um mundo 640×360 com um rei de ~33 células. É a mesma grelha de base de
  Kingdom Two Crowns, Owlboy, Blasphemous e Sea of Stars (§1), mas com as personagens desenhadas com o dobro da
  densidade (1 px em vez de 1 célula).
- Altura relativa no ecrã: King 65/720 = 9,0 %; Nia 50/720 = 6,9 %. Linha de chão a 517/720 = 71,8 % do topo.

### 0.2 Método de medição (para reprodutibilidade)

1. Descarreguei as capturas oficiais via `store.steampowered.com/api/appdetails?appids=<id>&filters=screenshots`.
2. Para cada imagem calculei, para k = 2…12, a concentração de arestas fortes nas fases de período k
   (horizontal e vertical). O menor k com pico claro é o tamanho do píxel de arte no ecrã.
3. Reamostrei a imagem no centro de cada bloco k×k (reconstrução da arte nativa) e contei píxeis com uma
   grelha de 10 px nativos sobreposta.
4. Limitações: JPEG, capturas promocionais podem ter zoom diferente do jogo, e alguns jogos (HD-2D, 3D)
   não têm grelha global. Onde a deteção falhou, digo-o.

Os guiões de medição da sessão de pesquisa (`pxscale.py`, `period.py`, `native.py`) não foram guardados no repositório: as capturas são de terceiros. O método acima repete-as.

---

## 1. Como jogos publicados fixam a escala personagem↔ambiente

### 1.1 Tabela de números

"Vista" = resolução de arte nativa (largura×altura em píxeis de arte). Alturas em píxeis **nativos** da arte.

| Jogo | Vista nativa | Escala a 1080p | Personagem (altura) | Tile/bloco | Outros números | Fonte |
|---|---|---|---|---|---|---|
| Kingdom Two Crowns | 640×360 (capturas k1, k2, k4) | 3× | aldeões/arqueiros 17–20 px; monarca montado ~40 px | — | muralha baixa 26 px; base de pedra da torre 41 px; torre ~104 px; chão a ~58 % da altura | MEDIÇÃO [M01] |
| Kingdom Two Crowns (Olympus) | 384×216 (captura k5) | 5× | pessoa ~10 px (≈52 px de ecrã) | — | porta ~87 px de ecrã, beiral ~110, telhado até ~199 (ver §2.3) | MEDIÇÃO [M02] |
| Kingdom (série) | variável | "cada quadrado de 3 a 8 píxeis, conforme o zoom"; 2 opções de zoom por dispositivo | — | — | — | FACTO (comunidade, sem desmentido do estúdio) [S02] |
| Stardew Valley | 480×270 | 4× | quadro do agricultor 16×32 | 16×16 | porta = 2 tiles de altura (32 px) | FACTO [S04][S05]; MEDIÇÃO [M08] |
| Celeste | 320×180 | 6× | hitbox da Madeline 8×11; sprite visível ~14 px | 8 (INFERÊNCIA: 320 e 180 divisíveis por 8; não confirmado por fonte primária) | cabana: porta ~20, janela ~10–11, beiral ~39, cumeeira ~55 | FACTO [S06]; MEDIÇÃO [M03] |
| Terraria | — | — | hitbox do jogador 20×42 px | 16×16 | porta fechada 1×3 tiles (48 px) | FACTO [S07][S08][S09] |
| Starbound | — | — | jogador "2×4 blocos" | 8×8 (tutorial de comunidade de 2013, desatualizado segundo o próprio) | — | FACTO fraco [S10][S11] |
| Owlboy | 640×360 | 2× a 720p, 3× a 1080p | Otus ~36–38 px | — | balcão da loja ~45 px | MEDIÇÃO [M04]; FACTO (640×360 como padrão do estúdio) [S12] |
| Blasphemous | 640×360 | 3× | inimigo de pé ~44–45 px | — | — | MEDIÇÃO [M05] |
| Dead Cells | n/d | — | personagem ~50 px | — | 3D renderizado pequeno, sem anti-aliasing, toon shader | FACTO [S13] |
| Shovel Knight | 400×240 | 4,5× (não inteiro em 1080p; INFERÊNCIA aritmética) | n/d | 16×16 | 4–5 cores por sprite + transparência | FACTO [S15] |
| Hyper Light Drifter | 480×270 | 4× (uma captura a 5×: 384×216) | Drifter ~28 px | — | portal do templo ~54 px de altura | MEDIÇÃO [M06]; FACTO "o nosso jogo é 480p, intencionalmente" [S16] |
| Sea of Stars | 640×360 | 3× | Garl ~50 px; Zale agachado ~42 px | — | — | MEDIÇÃO [M07] |
| Coromon | 480×270 | 4× | n/d | n/d | — | MEDIÇÃO [M09] |
| Chained Echoes | 640×360 (2 de 6 capturas) | 3× | n/d | n/d | — | MEDIÇÃO parcial [M10] |
| Eastward | n/d | — | n/d | — | arte base em Aseprite, separada por estrutura (telhado ≠ parede) e reconstruída em 3D com bump maps pintados | FACTO [S17] |
| Octopath Traveler | sem grelha global | — | — | — | HD-2D: sprites em cena 3D com profundidade de campo | MEDIÇÃO negativa [M11] |
| Songs of Conquest | sem grelha global | — | — | — | — | MEDIÇÃO negativa [M11] |
| Moonlighter, Children of Morta | inconclusivo | — | — | — | provavelmente escala não inteira ou pós-processamento | MEDIÇÃO negativa [M11] |
| Katana ZERO | inconsistente (3× e 6× em capturas diferentes) | — | — | — | — | MEDIÇÃO inconclusiva [M11] |
| The Last Night | sem dados | — | — | — | — | — |

Notas:

- Kingdom: o criador, Thomas van den Berg (noio), diz que escolheu pixel art por ser económica e pelo
  "impressionist feel", e que "pixel art does not let itself be scaled to arbitrary sizes" [S01]. O devlog do
  TIGSource, a matéria da Retronator, o Behance de Maarten Boot (ambientes de New Lands), o PCGamingWiki e o
  Spriters Resource devolveram 403 (ver §7). Segundo resumos de pesquisa, não verificados: o Kingdom renderiza
  para uma "screen texture" pequena que depois é ampliada, e New Lands aproxima o zoom em ecrãs mais largos.
- A diferença entre k1/k4 (3×, aldeões ~17–20 px) e k5 (5×, pessoa ~10 px) com o **mesmo tamanho em ecrã
  (~50 px)** sugere que a textura de render do Kingdom muda de resolução com o zoom ou com a plataforma. Os sprites
  seriam então reamostrados. INFERÊNCIA compatível com [S02]. Consequência: no Kingdom são fiáveis as
  **razões** (porta/pessoa, beiral/pessoa), não os píxeis absolutos.
- Celeste: os retratos dos diálogos são ilustrações de alta resolução sobre o jogo a 320×180 [M03]. É mistura
  deliberada de resoluções, mas em "mundos" separados (ver §3).

### 1.2 Altura relativa do herói no ecrã

| Jogo | Herói / vista | % da altura do ecrã |
|---|---|---|
| Kingdom Two Crowns (aldeão) | 17–20 / 360 | 4,7–5,6 % |
| Kingdom Two Crowns (monarca montado) | ~40 / 360 | ~11 % |
| Celeste | ~14 / 180 | ~7,8 % |
| **Empire — Nia** | 50 / 720 | **6,9 %** |
| **Empire — King** | 65 / 720 | **9,0 %** |
| Owlboy | ~37 / 360 | ~10,3 % |
| Hyper Light Drifter | ~28 / 270 | ~10,4 % |
| Stardew Valley (quadro) | 32 / 270 | 11,9 % (visível < quadro) |
| Blasphemous (inimigo) | ~45 / 360 | ~12,5 % |
| Sea of Stars | ~50 / 360 | ~13,9 % |

INFERÊNCIA: o Empire tem um enquadramento largo, entre Kingdom e Celeste: muito mundo à volta de personagens
pequenas no ecrã. A densidade de detalhe das personagens (65 px reais) é, porém, a de um Blasphemous ou de um Sea of
Stars. Por isso o cenário a 2 px, que é um mundo 640×360, fica com uma densidade igual à desses jogos e as
personagens destacam-se por terem o dobro do detalhe.

### 1.3 Relação monarca/povo

- Kingdom: o monarca montado tem ~40 px contra 17–20 px dos aldeões, ≈2,0–2,35× [M01]. O monarca destaca-se pela
  montada e pela altura.
- Empire: King 65 contra tropas de 52–64, ≈1,0–1,25×. INFERÊNCIA: o King destaca-se pela silhueta e pela cor,
  não pela altura. Isto tem impacto nas portas (§5): uma porta "à escala do King" serve a todos os atores.

---

## 2. Proporções arquitetónicas relativas à personagem

### 2.1 Métricas publicadas (3D e realidade) — FACTO [S18]

| Origem | Jogador (A) | Porta (L×A) | Parede interior (A) | Degrau (A×P) | Corredor mín. |
|---|---|---|---|---|---|
| Real (adulto EUA, polegadas) | 69 | 36×80 | 96 | 7×11 | 48 |
| Source/Quake (unidades) | 72 | 56×112 | 128 | 8×12 | 64 |
| Unreal (cm) | 176 | 110×220 | 300 | 15×25 | 150 |
| Unity (m) | 1,8 | 1,25×2,5 | 3,0 | 0,1×0,15 | 2,0 |

Razões derivadas (INFERÊNCIA aritmética):

| Razão | Real | Source | Unreal | Unity |
|---|---|---|---|---|
| porta / jogador | **1,16** | 1,56 | 1,25 | 1,39 |
| parede interior / jogador | 1,39 | 1,78 | 1,70 | 1,67 |
| degrau / jogador | 0,10 | 0,11 | 0,085 | 0,056 |
| largura da porta / altura da porta | 0,45 | 0,50 | 0,50 | 0,50 |

Outras afirmações do mesmo livro [S18]: "build at the player's scale", "Video game spaces are not human",
"Don't follow real world scale". O corredor mínimo deve ter o dobro da largura do jogador, as portas devem ser
mais estreitas que os corredores e as escadas devem ter 30–35° de inclinação.

INFERÊNCIA: em 3D na primeira e na terceira pessoa as portas **crescem** (1,25–1,56×) por causa da câmara e da
colisão. Em 2D lateral não há câmara dentro da porta, e a tendência medida é a **inversa** (§2.2).

### 2.2 Medições em jogos 2D: portas e casas à escala dos atores

| Jogo | Porta / herói | Beiral / herói | Altura total / herói | Fonte |
|---|---|---|---|---|
| Stardew Valley | porta de 2 tiles = 32 px = altura do quadro do agricultor → ≈1,0–1,1 | — | — | FACTO [S04][S05] |
| Terraria | 48 / 42 = **1,14** (porta exige vão de exatamente 3 blocos) | — | — | FACTO [S07][S08] |
| Celeste (cabana) | ~20 / ~14 = **≈1,4** | ~39 / 14 ≈ 2,8 | ~55 / 14 ≈ 3,9 | MEDIÇÃO [M03] |
| Kingdom Two Crowns (casa olímpica, porta dupla pública) | ~87 / ~52 (px de ecrã) = **≈1,67** | ~110 / 52 ≈ 2,1 | ~199 / 52 ≈ 3,8 | MEDIÇÃO [M02] |
| Hyper Light Drifter (portal monumental, 3/4) | ~54 / ~28 ≈ 1,9 | — | — | MEDIÇÃO [M06] |
| Kingdom Two Crowns (Shogun) | — | muralha 26 / 17 ≈ 1,5; base de pedra 41/17 ≈ 2,4 | torre ~104 / 17 ≈ 6,1 | MEDIÇÃO [M01] |

INFERÊNCIAS:

1. **Portas comuns**: 1,0–1,2× o ator (Stardew, Terraria, e o real 1,16). **Portas públicas ou monumentais**:
   1,4–1,9× (Celeste, Kingdom Olympus, HLD). A porta é a medida que o jogador usa para ler a escala.
2. **Compressão**: as casas pequenas ficam perto da escala humana em altura (beiral 2–3×, total ~3,8–3,9×). As
   estruturas grandes são muito comprimidas: a muralha do Kingdom tem 1,5× um aldeão e a torre ~6×, quando uma
   muralha real teria várias alturas humanas (estimativa minha, sem fonte). Em 2D lateral, o que se comprime é o
   número de vãos e de pisos e a altura das estruturas defensivas, não a porta.
3. Anedota de assets (fraca, mas é o sintoma clássico) [S20]: com portas e janelas grandes demais, "their size
   seems like that of a child in relation to the door". O utilizador notou que o problema estava **só** nas portas
   e janelas; com carros, camas e mesas a escala da personagem estava certa. O autor do asset admitiu que
   "orthographic viewpoints often cause issues with visual scale" e prometeu portas menores. Conclusão: corrige-se
   a porta, não a personagem.

### 2.3 Diretrizes de artistas de ambiente (pixel art)

- SLYNYRD (Raymond Schlitter):
  - Tiles de 16×16, potências de 2, pares e quadrados; "Anything over 32x32px seems like overkill" [S21].
  - Com 1 px de argamassa, os tijolos que dividem 16 têm 15, 7, 3 ou 1 px [S22].
  - As sombras não devem passar de um tile [S22].
  - Num city builder, a planta de cada edifício é medida em unidades de 16×16. A altura pode sair um pouco da
    planta por cima, mas nunca por baixo nem pelos lados [S23].
  - Ordem de trabalho: telhado e estrutura → janelas e portas → sombras → contornos → envolvente [S23].
  - Contornos subtis: "a slightly darker color than the adjacent pixels" [S23].
  - Simplificar para "key characteristics to be easily recognizable" [S23].
  - Em vistas 3/4, os lados encurtam para ~3/4 da largura real. Os seus edifícios geométricos são "often more
    conservative than what is possible in real life" [S24].
  - "push the detail just far enough until the mind can fill in the rest"; evitar "too many small scattered
    clusters" [S25].
- Derek Yu:
  - "The smaller a sprite gets … the more responsibility each individual pixel has". O bigode do Mario existe para
    separar o nariz da cara; o detalhe é **inventado** para ser legível [S26].
  - Em tamanhos pequenos, começar com manchas de cor em vez de contorno [S26].
  - "if you squint, a few large clusters of light and dark should still emerge" [S26].
  - Um fundo mais indistinto ajuda as personagens a destacar-se, desde que seja intencional [S27].
- Dead Cells (fundos): "the background of the levels and the collisions have to contrast as much as possible".
  Os interativos ficam num contraste intermédio e as ameaças saturadas [S14].

Lacuna: não encontrei nenhuma fonte de pixel art com uma regra numérica explícita do tipo "porta = X × altura da
personagem". Os números de §5 derivam por isso das métricas reais e 3D [S18] e das medições de §2.2.

---

## 3. Densidade de texel e "mixels"

### 3.1 O que dizem as fontes

- Pedro Medeiros (Saint11, diretor de arte de Celeste):
  - "you can scale up pixel art forever" mas só em múltiplos inteiros; 2,5× quebra a resolução; usar Nearest
    Neighbor e nunca bilinear ou bicúbico [S28].
  - "you shouldn't scale pixel art down—it will ruin it". Exceção: se a imagem já foi ampliada, conta-se o tamanho
    de um "píxel grande", reduz-se para a escala original e depois amplia-se [S28].
  - Escala não inteira: "Up and Down", ou seja, nearest até ao inteiro mais próximo e depois bilinear até ao alvo;
    ou um shader próprio [S28].
  - Mistura de resoluções: "Every time someone mixes pixel art resolutions, an angel dies". Se for preciso, usar
    canvases separados (UI vs jogo), só múltiplos inteiros (100 % e 200 %, nunca 150 %) e **no máximo duas
    resoluções** [S28].
  - A estratégia principal é "choose a resolution and stick to it" [S29].
  - "The trick here is the quarantine; styles never leak from one world to another" [S29].
  - "Scale all sprites by the same integer number"; "Avoid drawing anything smaller than 1 pixel to the game
    screen" [S29].
  - Camadas de pixel art "always stabilize in integer coordinates when it stops" [S29].
- Pixel Logic (Michael Azzi), citado em segunda mão: "never mix resolutions"; contornos com a mesma espessura em
  todos os sprites [S31]. Não verifiquei no livro.
- Comunidade: mixels são aceitáveis só numa camada de fundo, e mesmo aí sem mudar o tamanho do píxel **dentro**
  da camada [S32]. Efeitos de resolução mais baixa (corações, pó) podem separar-se de propósito da imagem
  principal [S33].
- SLYNYRD (parallax): arte a 1× e velocidades em píxeis inteiros (1 px/frame, 1 px/2 frames). Abaixo de 1 px/frame
  o movimento parece aos solavancos [S30].

### 3.2 O que se observa nos jogos

- Celeste: o jogo a 320×180 e os retratos de diálogo em alta resolução sem grelha [M03]. É a "quarentena" de
  [S29] aplicada (mundo do jogo vs mundo da UI).
- Kingdom Two Crowns: montanhas e floresta de fundo estão na **mesma** grelha de 3 px de ecrã que o primeiro
  plano. Há um ligeiro sinal de aglomerados de 2×2 (período 6) nas montanhas distantes, inconclusivo [M01]. A
  distância lê-se pela forma simplificada, pelo valor e pelo reflexo, não por píxeis maiores.
- Terraria, Stardew e Minecraft são citados como jogos com mixels deliberados [S33], sem detalhe técnico.
- Dead Cells mistura pipelines (3D renderizado a baixa resolução + fundos pintados com gradient map) mas mantém
  o resultado num só ecrã sem anti-aliasing [S13][S14].

### 3.3 Avaliação para o Empire (INFERÊNCIA)

O Empire usa três tamanhos: 1 px nos atores, 2 px no cenário e 4 px nos planos distantes. Isto excede a regra
"no máximo duas resoluções" de [S28]. Para que leia como estilo e não como erro:

1. **Quarentena por plano, nunca por objeto**:
   - Cada plano tem um só tamanho de célula: atores e FX de combate a 1 px, cenário do plano de ação a 2 px,
     parallax distante a 4 px.
   - Nenhum objeto mistura dentro de si 1 px e 2 px. Um sinal pendurado num edifício é cenário: 2 px.
   - Os adereços que o ator **segura** (arma, lanterna de mão) são do ator: 1 px.
2. **Múltiplos inteiros**: 1, 2 e 4 são inteiros entre si, o que cumpre [S28]. Nunca usar 3 px nem escalas
   fracionárias dentro do jogo.
3. **O plano a 4 px tem de parecer longe**: menos contraste, valores mais próximos do céu e movimento diferente
   (parallax). Um plano a 4 px com o mesmo contraste do primeiro plano lê-se como erro, porque o olho compara
   grelhas vizinhas. Isto vem da regra de contraste de colisões [S14] e da regra de fundo indistinto [S27].
4. **Contorno**: o ator tem contorno escuro de 1 px. O cenário não deve ter contornos pretos de 2 px, que pareceriam
   "gordos" ao lado do ator. Usar contorno seletivo um tom abaixo do vizinho [S23][S26]. Isto também separa os
   planos.
5. **Bónus a 1080p**: com `canvas_items` e escala fracionária (estado atual do `project.godot`), 1280→1920 é ×1,5.
   - Uma célula de 2 px passa a exatamente 3 px de ecrã (uniforme).
   - Um píxel de ator alterna entre 1 e 2 px de ecrã (irregular).
   - Uma célula de 4 px passa a 6 px de ecrã (uniforme).
   - A 1440p (×2) e a 4K (×3) tudo é inteiro.

   Conclusão: o cenário a 2 px é robusto a 1080p e o ator a 1 px é o elemento frágil (ver §3.4).

### 3.4 Godot 4: escala inteira, sub-píxel e snapping

FACTO [S34][S35]:

- `display/window/stretch/mode="viewport"` é "Recommended for games that use a pixel art aesthetic".
  `canvas_items` faz com que "there is no longer a 1:1 correspondence between sprite pixels and screen pixels".
  A documentação diz que `canvas_items` é o padrão para projetos criados a partir do Godot 4.7.
- `display/window/stretch/scale_mode="integer"`: "the screen size will always be an integer multiple of the base
  viewport size. This provides a crisp pixel art appearance" (o padrão é `fractional`).
- "Most pixel art games use viewport sizes between 256×224 and 640×480"; "640×360 is a good baseline" [S34].
- `rendering/2d/snap/snap_2d_transforms_to_pixel`: "CanvasItem nodes will internally snap to full pixels … the
  decimals will not have effect as the position is rounded … crisper appearance at the cost of less smooth
  movement, especially when Camera2D smoothing is enabled".
- `rendering/2d/snap/snap_2d_vertices_to_pixel`: só afeta as posições finais dos vértices. A documentação diz que
  não se deve combinar com o anterior e prefere apenas `snap_2d_transforms_to_pixel` [S35].
- Ambas são lidas no arranque. Em tempo real usa-se `RenderingServer.viewport_set_snap_2d_transforms_to_pixel()`
  [S35].

INFERÊNCIAS e PROPOSTAS para o Empire (não verificadas no motor):

- Com uma base de 1280×720, a escala inteira a 1080p dá 1× com margens, o que é inaceitável. A 1080p a escala é
  forçosamente 1,5×.
- Opções para o 1 px dos atores:
  - (a) aceitar;
  - (b) renderizar o mundo num `SubViewport` de 1280×720, ampliar 2× com nearest e reduzir para o alvo com linear.
    É o "Up and Down" de [S28], e os píxeis ficam todos iguais com uma ligeira suavização;
  - (c) um shader "sharp bilinear" [S28].
- `snap_2d_transforms_to_pixel` só arredonda a 1 px, não a 2 px. A fase (0,0) das células de 2 px só se mantém se:
  - as **posições de mundo** do cenário forem pares (garantido na colocação ou no dado);
  - todo o cenário do mesmo plano se mover em conjunto (mesmo nó-pai ou mesma câmara).

  Com a câmara num x ímpar, o plano inteiro desloca-se 1 px. Cada célula continua com 2 px (a textura não muda), mas
  a fase "no ecrã" deixa de ser (0,0). O que não pode acontecer é duas peças do mesmo plano ficarem com fases
  diferentes: as costuras ficariam com células de 1 px.
- Parallax: arredondar o deslocamento de cada camada a px inteiros. Idealmente, as camadas de 4 px devem parar
  em múltiplos de 4 quando a câmara para ([S29], "stabilize in integer coordinates").
- `Smoothing` (interpolação entre ticks, referida no AGENTS.md) e o snapping podem competir: a interpolação gera
  posições fracionárias. Testar o snapping de transformações apenas no nó do plano de cenário, ou arredondar no
  próprio `Smoothing`. Não verificado.
- **Paridade das linhas do projeto**:
  - Com a fase (0,0), as linhas de células de 2 px ocupam y = 2n e 2n+1. A linha de chão y = 517 é ímpar. Se 517 é a
    **última** linha de píxeis dos pés, a última célula de um edifício cobre 516–517 e a base fica em 518
    (exclusivo): bate certo. Se 517 é a **primeira** linha de chão, a base de um edifício cai a meio de uma célula.
  - O subsolo y = 618,5 não é inteiro: atores e cenário pousados aí renderizam a meio píxel (com `nearest`,
    arredondamento instável).
  - Recomendo confirmar ambas as convenções.

---

## 4. Processo: de uma referência (pintura ou IA) a arte nativa

### 4.1 O que dizem os artistas

- **Não reduzir: redesenhar**. "you shouldn't scale pixel art down—it will ruin it" [S28]. A exceção (reduzir uma
  imagem que já é pixel art ampliada por um inteiro) **não se aplica** às imagens de IA, porque o tamanho de píxel
  aparente é inconsistente (INFERÊNCIA a partir do enunciado do problema e de [S28]).
- Medeiros usa referência e redesenha tudo. Com modelos 3D:
  1. regista a rotação;
  2. reduz tamanho e paleta no Aseprite ("It's horrible … since we will just redraw the whole thing");
  3. redesenha numa camada por cima;
  4. ajusta o tempo e verifica no jogo [S36].

  Uma das suas peças grandes foi feita "using an AI-generated image as base" [S37]. Precedente profissional
  direto para o caso do Empire.
- Dead Cells: o modelo 3D parte de uma "model sheet" de pixel art e é renderizado "in a very small size and
  without antialiasing". O detalhe ficou aquém do desejado e o estúdio aceitou essa troca pela animação [S13]. O
  gradient map sobre cinzentos permite trocar a paleta de um bioma inteiro [S14].
- Eastward: base em Aseprite, separada por estrutura (telhado e parede em camadas distintas) e depois
  reconstruída para iluminação e bump map [S17]. Separar telhado e parede facilita a oclusão e a luz.
- Derek Yu [S26][S27]:
  - esboço → cor → sombreado → polimento;
  - em pequeno, manchas de cor em vez de contorno;
  - testar com o desenho espelhado e dessaturado;
  - reduzir formas complexas a volumes simples: uma copa como "a few green spheres", um ninho como "a brown bowl";
  - evitar pillow shading e cores parecidas demais.
- SLYNYRD [S23][S25]:
  - telhado e estrutura → aberturas → sombras → contornos;
  - manter as "key characteristics";
  - empurrar o detalhe só até onde "the mind can fill in the rest".
- Shovel Knight [S15]: 4–5 cores por sprite (mais a transparência), com uma paleta quase igual à da NES e
  poucas cores extra. A restrição de paleta é uma ferramenta de consistência, tal como a de [S29]: "you only have
  one palette".
- noio (Kingdom) [S01]: escolheu pixel art pelo "shortest possible path between sketch/production/in-engine".
  Desenhar logo ao tamanho final é o caminho curto; reescalar não é.

### 4.2 Processo recomendado para o Empire (PROPOSTA, baseada em 4.1)

**Passo 0 — Fixar o alvo antes de olhar para os detalhes da referência**

- Papel no jogo, plano (ação a 2 px ou parallax a 4 px) e planta em tiles (larguras múltiplas de 32).
- Altura máxima (§5.1) e onde estão a porta e a linha de chão.
- O orçamento de altura sai das alturas dos atores (King 65, Nia 50), não da referência.

**Passo 1 — Medir a referência**

1. Tamanho de píxel aparente p_r: contar 5–10 "píxeis grandes" numa zona plana ou correr a autocorrelação de §0.2.
   A Forja do repositório já estima a grelha (AGENTS.md).
2. Altura da porta h_porta,r ou de uma figura humana h_fig,r, se houver.
3. Largura do edifício L_r e altura até à cumeeira A_r.

**Passo 2 — Calcular três fatores**

| Fator | Fórmula | Significado |
|---|---|---|
| s_porta | h_porta,alvo / h_porta,r | Escala que põe a porta à medida do King |
| s_planta | L_alvo / (L_r · s_porta) | < 1 → é preciso **comprimir a arquitetura** (menos vãos, pisos e janelas), nunca encolher a porta |
| r (detalhe) | p_r · s_porta / 2 px | Células de 2 px por "píxel" da referência. r ≫ 1: a referência é mais grosseira que o alvo e é preciso **inventar** detalhe. r ≈ 1: pode decalcar-se. r < 1: há detalhe mais fino que uma célula e é preciso **cortar ou exagerar** |

Se a referência tiver uma figura humana, ver se h_porta,r / h_fig,r cai em 1,0–1,9 (§2.2). Fora desse intervalo
a escala interna da imagem de IA é incoerente: usar a referência só para identidade, nunca para medidas.

**Passo 3 — Escolher 3 a 5 sinais de identidade**

Os sinais que, se desaparecerem, tornam o edifício irreconhecível. Exemplos (PROPOSTA, a validar pelo dono):

- **Forja/oficina**: chaminé larga com fumo, boca do forno com brilho, bigorna à porta, alpendre aberto, fole.
- **Porto**: estacas do cais, grua ou guindaste de madeira, cabos e redes, casco atracado, cabeços de amarração.
- **Forja vulcânica**: blocos de basalto, canal ou fenda de lava com brilho, rampa de pedra escura, chaminé
  natural (rocha) com vapor.

Tudo o resto é negociável.

**Passo 4 — Esboço ao tamanho final na grelha de 2 px**

- Desenhar o cenário num canvas de **meia resolução** (1 px do canvas = 1 célula) e exportar com ampliação ×2
  nearest. As células de 2 px e a fase ficam garantidas por construção. Para os planos distantes: um quarto da
  resolução e ×4.
- Silhueta e valores primeiro, com 3–4 valores de cinzento. Depois o gradient map ou a paleta [S14].
- Fazer o teste de semicerrar os olhos [S26].

**Passo 5 — Orçamento de detalhe por tamanho no ecrã**

- Uma feature com menos de 1 célula (2 px) não existe neste plano. Com 1 célula é um traço. Para ler como forma
  precisa de 2 células ou mais.
- Tudo o que na referência for menor do que isto ao tamanho final tem uma de três saídas:
  - cortar: ornamentos de friso, pregos, telhas individuais, frestas;
  - agrupar: telhas em fiadas, pedras em grupos de 2–3 tamanhos;
  - exagerar se for sinal de identidade: a chaminé fica mais larga, a boca do forno maior, a grua mais grossa.

  É o princípio do bigode do Mario [S26].
- Para as dimensões mínimas de porta, janela, chaminé e beiral ver §5.

**Passo 6 — Paleta por material**

- Uma rampa de 3–5 tons por material (pedra, madeira, telha ou colmo, metal, brilho de fogo), partilhada por todo o
  bioma [S15][S29].
- O brilho do fogo é a única família muito saturada, porque é o sinal de identidade da forja. Na leitura de jogo
  compete com as ameaças: Dead Cells reserva a saturação para elas [S14]. Testar.

**Passo 7 — Contornos**

- Cenário: contorno seletivo um tom abaixo do vizinho [S23], sem preto de 2 px. Atores: o contorno atual.
- A silhueta do edifício contra o céu pode ter uma aresta escura de 1 célula onde o contraste de valor não basta.

**Passo 8 — Verificar a 1× com os atores reais**

- Colocar no mesmo PNG, à mesma linha de chão: King (65), Nia (50) e Archer (64, com arma).
- Confirmar:
  - folga da porta ≥ 6 px acima do King;
  - a janela não fica escondida pelas cabeças (§5);
  - o edifício cabe no orçamento de altura.
- Ver em 1280×720 a 100 % e simulado a 1920×1080 (×1,5 nearest). Espelhar e dessaturar [S26].

**Passo 9 — Fidelidade**

- Comparar com a referência só pelos sinais do Passo 3, não pelos píxeis.
- No repositório isto passa pela Forja (`forja fidelity`, `forja verify`, AGENTS.md). A aprovação artística é
  sempre do dono.

---

## 5. Proposta concreta para o Empire

**Tudo nesta secção é PROPOSTA derivada**, exceto as âncoras do projeto e as razões das fontes citadas
entre parênteses.

Âncoras: King H_K = 65 px; Nia H_N = 50 px; tropas 52–64 px; célula = 2 px; tile = 32 px = 16 células.
Todos os valores são pares (múltiplos de 2 px).

### 5.1 Tabela de tradução arquitetura → píxeis do Empire

| Elemento | Proposta (px de ecrã) | Células de 2 px | × King (65) | × Nia (50) | Base / raciocínio |
|---|---|---|---|---|---|
| Porta comum (vão livre, altura) | **72–80** (padrão 76) | 36–40 (38) | 1,11–1,23 | 1,44–1,60 | real 1,16 e Unreal 1,25 [S18]; Terraria 1,14 [S07][S08]; folga mínima de 6–8 px acima do King; abaixo de 1,05× parece apertado, acima de 1,3× faz o ator parecer criança [S20] |
| Porta comum (largura) | 28–36 (padrão 32 = 1 tile) | 14–18 | — | — | largura/altura 0,45–0,5 [S18]; 32 px alinha com o tile |
| Porta pública ou monumental (forja, armazém do porto, portão) | 88–104 | 44–52 | 1,35–1,60 | 1,76–2,08 | Source 1,56 [S18]; Kingdom Olympus ~1,67 [M02]; HLD ~1,9 (portal sagrado) [M06] |
| Largura do portão | 48–64 | 24–32 | — | — | 1,5–2 tiles; folhas duplas |
| Ombreira e lintel (espessura) | 4–6 | 2–3 | — | — | < 2 células não lê como moldura |
| Soleira / degrau de entrada | 2–4 | 1–2 | — | — | separa a porta do chão sem criar outra linha de chão |
| Beiral de casa térrea (chão→topo da parede) | **88–104** (padrão 96) | 44–52 | 1,35–1,60 | 1,76–2,08 | porta 76 + lintel 4–6 + parede 8–20; coerente com o guia ≈120×130; Kingdom ≈2,1× e Celeste ≈2,8× [M02][M03]: o Empire é **mais comprimido**; se ficar "achatado", subir até 112–120 |
| Altura de piso (casa de 2 pisos) | 88–96 por piso | 44–48 | 1,35–1,48 | — | real 1,39 (parede interior) e 3D 1,67–1,78 [S18], comprimido |
| Beiral de 2 pisos | 176–192 | 88–96 | 2,7–3,0 | — | 2 × piso; usar só em marcos |
| Inclinação do telhado | 2:1 (26,6°) por omissão; 1:1 (45°) para colmo, torres e frontões íngremes; 1:2 (63,4°) só em pináculos | degraus 2×1 ou 1×1 células | — | — | só passos regulares evitam "jaggies" [S26]; na grelha de 2 px o degrau mínimo é 2 px; 3:2 (33,7°) admite-se em formas orgânicas |
| Subida do telhado (edifício de 128 px) | 32 (2:1) a 64 (1:1) sobre meia largura de 64 | 16–32 | 0,5–1,0 | — | 96 + 32–40 = 128–136, ≈ guia de 130 px |
| Altura total de edifício pequeno | 120–136 | 60–68 | 1,85–2,1 | 2,4–2,7 | guia do projeto 120×130; Kingdom e Celeste ~3,8–3,9× (aqui mais comprimido) |
| Marco ou edifício grande (forja vulcânica, armazém) | 160–224 | 80–112 | 2,5–3,4 | — | Kingdom: torre ~6× o aldeão mas só ~2,6× o monarca montado [M01] |
| Janela (largura × altura) | 16–24 × 20–28 | 8–12 × 10–14 | — | — | Celeste: janela ≈0,75× o herói [M03]; mínimo legível 8×10 px (vidro 4×6 + moldura de 1 célula) |
| Peitoril da janela (do chão) | 36–44 | 18–22 | 0,55–0,68 | 0,72–0,88 | verga alinhada com o topo da porta (72–80); as cabeças das tropas (52–65) cobrem só o terço inferior da janela. Alternativa estilo Celeste: peitoril ≈ altura da cabeça (64–66) e janelas pequenas por cima das cabeças |
| Degrau (espelho) | 6–8 | 3–4 | 0,09–0,12 | — | real 0,10, Source 0,11 [S18] |
| Degrau (cobertor, profundidade visível) | 8–12 | 4–6 | — | — | razão espelho/cobertor ≈ 7/11 [S18] |
| Plataforma, alpendre ou cais (altura sobre o chão) | 8–16 | 4–8 | — | — | 1–2 degraus |
| Guarda ou corrimão | 32–40 | 16–20 | 0,5–0,6 | 0,64–0,8 | INFERÊNCIA a partir de guardas reais de ~0,9–1,07 m num adulto de ~1,75 m (sem fonte nesta pesquisa); corrimão ≥ 2 células, balaústres de 1 célula a cada 3–4 células |
| Cerca de campo ou animais | 28–36 | 14–18 | 0,43–0,55 | — | postes de 4 px (2 células) a cada 32 px (1 tile) |
| Tronco de árvore jovem | 4–6 | 2–3 | — | — | 1 célula lê como vara ou poste |
| Tronco de árvore adulta | 8–16 | 4–8 | — | — | da largura de uma perna à do tronco de um ator |
| Tronco de árvore velha ou monumental | 20–32 | 10–16 | — | — | até 1 tile |
| Lanterna de parede (corpo) | 8×12 | 4×6 | — | — | centro a 80–88 px (acima do lintel, fora das cabeças) |
| Poste de lanterna (total) | 96–120 | 48–60 | 1,5–1,85 | — | acima de todas as cabeças, abaixo do beiral alto |
| Lanterna de mão | (do ator, 1 px) a ~30–36 do chão | — | ~0,5 | — | pertence ao ator e segue a quarentena de §3.3 |
| Chaminé (largura) | 12–20; forja 20–32 | 6–10; 10–16 | — | — | sinal de identidade: exagerar [S26] |
| Chaminé (acima do telhado) | 12–24 | 6–12 | — | — | — |
| Bigorna (topo) | 28–32 | 14–16 | 0,43–0,5 | — | trabalho à altura da mão |
| Bancada ou balcão | 32–36 | 16–18 | 0,5–0,55 | — | Owlboy tem o balcão acima do herói (~1,2× Otus [M04]); para o Empire convém que o tampo fique abaixo do peito |
| Barril | 28–36 × 20–24 | 14–18 × 10–12 | ~0,5 | — | — |
| Caixote | 24–32 | 12–16 | 0,37–0,5 | — | — |
| Cabeço de amarração | 16–20 | 8–10 | ~0,3 | — | — |
| Estaca de cais (largura) | 8–12 | 4–6 | — | — | — |

### 5.2 Verificações aritméticas da tabela

- Porta 76 = King 65 + 11 px (5,5 células) de folga, a cobrir coroa e cabelo. Com 72, a folga é de 7 px.
- Com 80, o Archer (64 + arco) também passa com folga. A Dancer (36) fica a 0,45× a porta, o que é plausível para uma
  figura pequena.
- Beiral 96 = 76 (porta) + 6 (lintel) + 14 (parede acima). Telhado 2:1 sobre 128 px de largura: 64 × 0,5 = 32 →
  cumeeira a 128. Com chaminé (+16) chega a 144. Cabe em 4 tiles × ~4,5 tiles e alinha com o guia 120×130.
- Telhado 1:1 (colmo) no mesmo edifício: cumeeira a 96 + 64 = 160. Fica mais alto, por isso reservar para
  edifícios mais estreitos (96 px) ou para marcos.
- Em células: porta 38, beiral 48, cumeeira 64, King 32,5. A razão porta/King em células (38/32,5 = 1,17) é a
  mesma da realidade (1,16) [S18].

### 5.3 Exemplo trabalhado: referência 1672×941, porta ~80 px, píxel aparente ~5–6 px

1. **Medições da referência**: p_r ≈ 5,5 px (intervalo 5–6). A grelha aparente é ≈ 1672/5,5 × 941/5,5 ≈ 304×171
   "píxeis". A porta tem 80 px ≈ 14,5 píxeis aparentes (13,3–16).
2. **Porta alvo**: h_porta,alvo = 76 px (38 células). Para a forja escolher-se-ia a porta pública de 88–104 px.
   Aqui uso a comum para o exemplo.
3. **s_porta** = 76 / 80 = **0,95** (0,90–1,0 para alvos de 72–80).
   - Consequência: a referência inteira à escala da porta teria 1672 × 0,95 ≈ 1588 × 894 px. É **maior que o
     ecrã** (1280×720), porque a imagem mostra muito mais arquitetura do que um edifício do Empire pode ter.
4. **Planta**: o papel de jogo define a largura, não a imagem. Exemplo: oficina de 5 tiles = 160 px.
   - Se o edifício ocupar ~900 px da largura da referência: L_r · s_porta = 855 px.
   - s_planta = 160 / 855 ≈ **0,19**. É preciso comprimir para cerca de 1/5 da largura **mantendo a porta a 76 px**.
     Na prática, de ~5 vãos com janela fica 1 porta + 1 janela + o sinal de identidade (forno ou chaminé).
   - A altura comprime-se também: de, por exemplo, 600 px × 0,95 = 570 para 128–160. Cortam-se pisos e
     simplifica-se o telhado, não se encolhe a porta.
5. **r (detalhe)** = 5,5 × 0,95 / 2 ≈ **2,6 células por píxel aparente** (2,4–2,9).
   - A referência é mais grosseira que o alvo. Decalcá-la daria blocos de 2–3 células sem textura nenhuma.
   - A referência serve para silhueta, massas de valor, materiais e posição dos sinais de identidade. A
     textura (pedra, madeira, telha) é redesenhada à célula de 2 px.
6. **Contraexemplo**: se a mesma porta tivesse 200 px na referência, s = 0,38 e r ≈ 1,05. Os píxeis aparentes
   coincidiriam com as células e daria para decalcar formas, mas tudo o que na referência fosse mais fino que 1
   píxel aparente (fios, frisos, pregos) teria de ser cortado ou exagerado.
7. **Figura humana na referência**: se existir uma com, por exemplo, 100 px, então h_porta/h_fig = 0,8 < 1,0. A
   imagem de IA desenhou a porta pequena demais para a figura, por isso ignora-se a escala interna e mantém-se a
   porta do Empire (76). Se a figura tiver 60 px, a razão é 1,33 e é plausível como porta pública.
8. **Resultado em células** (oficina de 5 tiles):
   - porta 38 × 16 células;
   - lintel de 3 células;
   - beiral a 48 células;
   - telhado 2:1 com cumeeira a 64–72 células (consoante a largura da água);
   - chaminé de 10 células de largura, 8 acima do telhado;
   - boca do forno (sinal de identidade) de 14 × 12 células com rampa de brilho;
   - verificação final com o King e a Nia no mesmo PNG (Passo 8 de §4.2).

### 5.4 Planos de parallax (PROPOSTA)

| Plano | Célula | Pode conter | Regra de contraste |
|---|---|---|---|
| Ação (edifícios, adereços, chão) | 2 px | portas, janelas, sinais de identidade | contraste total com os atores, contornos seletivos |
| Médio (casas de fundo, falésias) | 2 px | silhuetas sem portas legíveis | −1 a −2 passos de valor em direção ao céu |
| Distante (montanhas, vulcão, mar) | 4 px | só massas e silhuetas | valores próximos do céu; nunca ao lado de um elemento de 2 px com o mesmo contraste |

Posições arredondadas a px inteiros. As camadas a 4 px param em múltiplos de 4 quando a câmara para [S29][S30].

---

## 6. Respostas curtas às 5 perguntas

1. **Escala em jogos publicados**:
   - Os jogos medidos agrupam-se em três bases nativas: 320×180 (Celeste), 480×270 (HLD, Stardew, Coromon) e 640×360
     (Kingdom Two Crowns, Owlboy, Blasphemous, Sea of Stars, Chained Echoes), sempre ampliadas por inteiros (3×–6×).
     A exceção é o Shovel Knight, com 400×240.
   - Heróis: 14 px (Celeste) a ~50 px (Sea of Stars, Dead Cells); Kingdom ~17–20 px nos aldeões e ~40 px no
     monarca montado.
   - O Empire equivale a um mundo 640×360 com um rei de ~33 células, mas com personagens a 1 px (§1).
2. **Proporções**:
   - Portas comuns 1,0–1,2× o ator e públicas ou monumentais 1,4–1,9×.
   - A compressão 2D atinge vãos, pisos e estruturas grandes, não a porta (§2).
   - Não há regra numérica publicada em pixel art; as razões vêm do real e do 3D [S18] e das medições.
3. **Mixels**:
   - As fontes rejeitam a mistura salvo com quarentena, múltiplos inteiros e no máximo duas resoluções [S28][S29].
   - O Empire (1/2/4) é defensável com uma célula por plano, sem mistura dentro de um objeto, plano de 4 px de
     contraste baixo e contornos seletivos no cenário.
   - Em Godot: hoje `canvas_items` fracionário → a 1080p as células de 2 px ficam uniformes (3 px) e o 1 px dos
     atores fica irregular. `snap_2d_transforms_to_pixel` só arredonda a 1 px, por isso a fase das células de 2 px
     tem de ser garantida pelas posições pares (§3).
4. **Processo**: medir a referência, calcular s_porta, s_planta e r, escolher os sinais de identidade, esboçar em
   meia resolução, decidir o orçamento de detalhe, fazer paleta por material e contorno seletivo, e verificar a 1×
   com King e Nia. Nunca reduzir a imagem: redesenhar [S28][S36][S37] (§4).
5. **Proposta**: tabela de §5.1 (porta 72–80 px / 36–40 células, beiral 88–104, cumeeira 120–136, degrau 6–8,
   guarda 32–40…) e o exemplo de §5.3 (s ≈ 0,95, r ≈ 2,6, compressão da planta ≈ 0,19).

---

## 7. Fontes inacessíveis, fracas ou não verificadas

| Fonte | Estado | O que se perdeu |
|---|---|---|
| TIGSource, devlog do Kingdom (noio) — https://forums.tigsource.com/index.php?topic=40539.0 | 403 (WebFetch e curl); web.archive.org bloqueado | detalhes de render ("screen texture"), conhecidos só por resumo de pesquisa |
| Retronator, "The fall and rise of Kingdom" — https://medium.com/retronator-magazine/the-fall-and-rise-of-kingdom-f6a3da699f0d | 403 | rotação de sprites, por resumo de pesquisa |
| Behance, Maarten Boot, "ENVIRONMENTS of Kingdom: New Lands" — https://www.behance.net/gallery/41885085/ENVIRONMENTS-of-Kingdom-New-Lands | 403 | processo de ambientes do Kingdom |
| PCGamingWiki, Kingdom: New Lands — https://www.pcgamingwiki.com/wiki/Kingdom:_New_Lands | 403 | zoom por largura de ecrã (só por resumo) |
| The Spriters Resource (todas as páginas) | 403 | medições de sprites rasgados (Kingdom, Shovel Knight, Blasphemous) |
| noio.nl, "Kingdom Devlog" e "Kingdom for Mobile" | acessíveis, sem conteúdo técnico | — |
| Celeste 320×180 em discussão Steam (https://steamcommunity.com/app/504230/discussions/0/3832043350345268297) | não lido diretamente (só resumo); substituído pela minha MEDIÇÃO [M03] | — |
| Tile de 8 px do Celeste | sem fonte primária; INFERÊNCIA | — |
| Terraria "16 px por tile" | resumo de pesquisa de um artigo da Nexus Mods (não aberto) [S09] | — |
| Starbound, bloco de 8 px | tutorial de comunidade de 2013, desatualizado segundo o próprio [S11] | — |
| Pixel Logic (Azzi), "never mix resolutions" | citação em segunda mão [S31] | — |
| HLD "480p" | entrevista indireta (GamingBolt/Nintendo Life, por resumo); a minha medição dá 480×270 [M06] | — |
| Hyper Light Drifter, Sea of Stars, Octopath, Songs of Conquest, Children of Morta, Moonlighter, Chained Echoes, Katana ZERO, The Last Night: entrevistas com números de sprite | não encontradas nesta sessão | substituídas por medições onde foi possível |
| Mark Ferrari (Living Worlds), Paul Robertson, Arne Jansson, Daniel Silber, Brandon James Greer, AdamCYounis, MortMort, Luis Zuno, Pixel Pete | não pesquisados por limite de tempo | candidatos a uma segunda volta |
