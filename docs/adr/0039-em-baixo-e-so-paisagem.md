# ADR 0039 — Em baixo é só paisagem, até o rei descer

- Estado: aceite
- Data: 2026-09-30
- Secção do dossiê: §11 (o mundo em duas camadas), §60 (`dither_reveal`), §80, §22
- Complementa: ADR 0038 (o mundo contínuo), Q-150 (as terras bravias), Q-173

## Contexto
O dono, a 30/09/2026, com uma captura das terras geradas: *«O subsolo só fica aparente ao acessá-lo, quero que tenha
vegetação aparente sempre, ou lagos, caminhos, dentre outras coisas, mas o subsolo só aparece ao acessar eles»*.

O que estava: o corte de solo (y 517–720) desenhava-se sempre aberto. Na região via-se a cave das raízes com as
abóbadas e os pilares; nas terras geradas, o túnel de mina com as escoras a intervalos. O terço de baixo do ecrã era
sempre subsolo, com o rei lá em cima.

A §11 já o pedia assim: *«a tela é dividida ao meio, em baixo é só paisagem, mas ao aceder a uma passagem secreta
encontras níveis, porões, dungeons»*, e *«uma cavidade não descoberta desenha-se como terra normal. Ao encontrar a
entrada, a terra dissolve-se com o shader de dither e revela o interior.»* O catálogo da §60 tem o shader para isso:
`dither_reveal`, com `progress` e `matrix`.

## Decisão
**Por cima do corte de solo há terra: erva, lagos, caminhos, plantas e pedras. Dissolve-se com o `dither_reveal`
quando o rei desce e volta quando ele sobe.**

- **A terra** (`Lowland`, `LowlandLayout`, `LowlandArt`). É cenário, gerado pela semente e preso ao sítio, como o
  campo do Wilds:
  - três faixas de erva que escurecem para a frente, com a terra batida da beira da estrada;
  - caminhos que saem da estrada e descem até ao fundo do ecrã, mais largos à frente e com rodados;
  - lagos com orla de lodo, fundo, reflexos, nenúfares e juncos. A chance de cada um é a do bioma do sítio;
  - as plantas do campo do bioma, mais densas, e erva e pedra em todo o lado. Usam o mesmo ruído do bosque do campo
    de cima, e ficam maiores na fila da frente.
  - Nas terras geradas, as cores e as plantas passam de um povo para o outro como o chão delas (WildGround).
- **Tapar e revelar** (`SoilCover`, `SoilReveal`, `shaders/dither_reveal.gdshader`). A terra é um nó entre a faixa do
  subsolo e a da superfície. Tapa a cave, o túnel, as masmorras, quem está lá em baixo e os morcegos. Fica por baixo
  de quem anda em cima dela.
  - Com o rei no subsolo, o progresso vai a 1 em 0,45 s; com ele à superfície, volta a 0.
  - O quadrado do dither tem 2 px (§80) e está preso ao mundo, e não ao ecrã. Os dezasseis limiares da matriz de
    Bayer estão no `SoilReveal`, onde se testam.
- **A boca da passagem** (`PassageArt`). Com a terra por cima, vê-se só a boca: a moldura e os primeiros degraus. O
  poço abre até ao chão de baixo ao ritmo da terra a ir-se. As bocas das masmorras já eram o arco caído, à superfície.
- **O que está tapado não pisca.** O golpe e a orla de uma obra lá em baixo não se desenham por cima da terra
  (`ImpactView`, `SoilCover.covers`).
- **Custo.** Os caminhos estão presos às beiras do plano, e não ao que já foi gerado. Por isso um troço feito não
  muda quando nasce o seguinte, e as plantas de cada troço guardam-se. Cada troço desenha as dele num nó filho, que o
  motor deixa de fora longe da câmara. O mundo inteiro faz-se a frio em cerca de 90 ms, só no arranque. Um segmento
  novo custa cerca de 5 ms.

## Alternativas consideradas
- **Revelar a cavidade para sempre, depois de a achar.** É a letra da §11 (*«ao encontrar a entrada»*). Rejeitado
  agora, porque o dono pede o subsolo *«só ao acessar»*. Fica na Q-182, com a outra metade: ver o que sobe de baixo.
- **Uma segunda câmara ou um ecrã à parte para o subsolo.** É a opção A da §11, rejeitada pelo dossiê: mais código,
  bugs de transição, e perde-se a superfície de vista.
- **Um desvanecer por transparência.** Rejeitado: a §11 pede o dither, e o dither é o que a §80 já usa na candeia.
- **Desenhar a terra num nó só e refazê-la a cada segmento novo.** Rejeitado pelo custo medido: 160 a 420 ms de cada
  vez que nasce um segmento.

## Consequências
- O corte de solo passa a ler-se como paisagem. Com o rei lá em baixo, lê-se como antes.
- Quem está lá em baixo não se vê com o rei à superfície: o Cavador e as criaturas do subsolo só se veem quando sobem.
  É o que o pedido diz, e a Q-182 pergunta se deve ficar assim.
- A `game.tscn` muda de ordem: o Subsolo desenha-se antes da Superfície, com a Terra entre os dois.
- A arte são formas e sprites em código (FloraArt), à espera de arte a sério. Trocar é mudar o `LowlandArt`, e não o
  gerador.
- Como desfazer: tirar o nó `Terra` da `game.tscn` volta a mostrar o corte de solo sempre aberto, com o poço
  inteiro: sem a terra na cena, `SoilCover.opened()` vale 1.
