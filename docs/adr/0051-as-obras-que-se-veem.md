# ADR 0051 — As obras que se vêem: um sprite para cada obra, e o sítio vazio à vista

- Estado: aceite
- Data: 2026-10-02
- Secção do dossiê: §10, §21, §22, §25, §55
- Actualiza: ADR 0042 (lote 3: os estados por código por cima de um frame passam a valer para todas as obras), GB-23 (o
  convite que pisca)

## Contexto
O dono, a 02/10/2026: *«faça as casas e construções terem de fato sprites, agora estão todas invisíveis»*.

O que havia: só quatro obras tinham arte do dono — o castelo-árvore, a casa de treino, a oficina (cozinha, forja) e o
armazém (celeiro, salgadeira, curral). O resto era greybox: o muro, as torres, a casa do herdeiro, a escora e a banca
do arco eram polígonos lisos de uma cor (`Silhouette`/`StructureArt`); o canteiro, o galinheiro e o pesqueiro, formas
lisas (`SettlementArt`); as casas dos povos, um rectângulo com um telhado (`NativeArt`). E um sítio por construir —
que é o que há no começo de uma partida — era um contorno de 2 px a respirar, ou a arte do dono a **18 %**: medido
numa captura de madrugada, as torres, os muros e o galinheiro do lado oeste não se viam.

## Decisão
**Cada obra tem um sprite.** As que o dono desenhou continuam com a arte dele. As outras pintam-se no jogo, por código,
pixel a pixel (`PixelPainter`), uma vez, numa textura (`PaintedArt`) — a regra 9 não deixa tocar em `art/`, e é o
mesmo caminho do bestiário (ADR 0049) e da moeda (ADR 0050), mas para coisas que não mexem: em vez de mil
`draw_rect` por frame, uma imagem que se desenha como as do dono.

- **O estilo é o do dono**: 1 px de mundo por pixel, contorno preto de um pixel, reboco creme, enxaimel castanho,
  telhado azul em três tons, pedra creme com juntas. A paleta é uma tabela (`PaintedArt.PALETA`) e um sprite é uma
  lista de traços em constantes (`WallSprites`, `TowerSprites`, `FarmSprites`, `HouseSprites`, `NativeSprites`).
- **O muro tem um sprite por nível do §10**: estacaria (44 px), paliçada com cintas (62), pedra com ameias (80), ferro
  chapeado (96) e bastião com o estandarte (132). A subida vê-se.
- **As obras**: torre de arqueiros de madeira com escada e telhado; torre alta de pedra, quase o dobro (236 px);
  canteiro de trigo com espantalho; galinheiro em estacas com as galinhas cá fora; pesqueiro com cabana, cais e rede;
  solar de dois pisos para a casa do herdeiro e a embaixada; casa térrea para quem vem dos acampamentos; sino de vigia;
  banca do arco; estábulo; acampamento de lenha e serração; fundição; mina; escora; barril de fogo; fosso de estacas;
  altar. Uma obra nova sem linha na tabela leva o sprite da sua forma (`Silhouette`, pela `category` do CSV).
- **Os povos**: a casa, a obra e a defesa de cada um são a mesma casa térrea, com a cor e o telhado do povo — os
  mesmos que o `NativeArt` tinha —; a obra leva caixotes e um toldo, a defesa estacas à frente e o escudo à porta.
- **Os estados** são os do lote 3, por código por cima da imagem, em todas: o sítio **vazio** é a obra inteira a
  respirar entre 32 % e 55 % de opacidade (nunca apaga, e nunca parece de pé); **pago**, a 55 %; **em obra**, o fantasma
  com a parte já erguida cheia e o andaime; um muro a subir de degrau mostra o de baixo de pé dentro do andaime; **de
  pé**, a imagem; **tocada** e **em reparo**, as fissuras e as escoras; **caída**, o quarto de baixo, escurecido.
- O sítio vazio de um muro mostra o **topo da escada** (o bastião), como o `BuildView` já fazia (§25: um sítio de muro
  promete o Bastião, não a estacaria).

## Alternativas consideradas
- **Subir só o alfa do fantasma.** Resolvia o «invisível» das quatro obras com arte, e deixava as outras como
  polígonos lisos — o pedido era sprites.
- **Desenhar os traços a cada frame, como o bestiário.** Uma obra não mexe: pintar uma vez e guardar a textura custa
  o mesmo que a arte do dono.
- **Usar a exportação `gate` do dono para a torre alta.** É um recorte do conceito do castelo (`author_base_needs_refinement`),
  com metade de uma varanda e 138 px de largo num sítio de 64: tapava o pesqueiro ao lado.

## Consequências
- O `NativeArt` e o `SettlementArt` saem; o `Silhouette`/`StructureArt` fica para o que não tem forma (CAIXA) e para o
  `ImpactView`, que pisca a forma da obra atingida.
- A arte definitiva é do dono (ART-01): trocar um sprite pintado é pôr a obra no `BuildingSkins.ORIGINAIS`. O
  `docs/art/RUNTIME_ART.md` diz, obra a obra, qual é pintada e qual é dele.
- O tamanho da caixa de uma obra passa a ser o do sprite (o preço pousa em cima dele); a simulação não muda (Q-079).
- `tests/obras_sprite_test.gd` guarda que cada obra do CSV e cada nível do muro têm sprite, que as pintadas estão
  inteiras, assentes no chão e só com cores da paleta, que o muro cresce de nível para nível e que o convite nunca
  baixa de 30 % de opacidade.
