# ADR 0050 — As moedas que se vêem: grandes, com física e com cara de moeda

- Estado: aceite
- Data: 2026-10-02
- Secção do dossiê: §02, §16, §24, §55, §80
- Actualiza: GB-19 (o pequeno bounce passa a ressaltar várias vezes e a girar), Q-167 (a coroa no chão)

## Contexto
O dono, a 02/10/2026, com uma imagem do Kingdom: *«as moedas e itens que são dropados devem ser bem grandes para serem
bem vistos como é em Kingdom e devem ter física e se parecerem com o que são, trabalhe bastante nisso também»*.

O que havia: a moeda no chão era um círculo de 3 px de raio — seis píxeis de largo ao lado de uma tropa de 47 e de um
rei de 94 —, à noite um ponto que não se encontrava. O arco saía do chão, e ao pousar dava um salto só, de 4 px (GB-19).
Uma moeda de 12 era o mesmo círculo que uma de 1. A coroa caída era uma forma lisa de 18 px, que aparecia no chão sem
cair.

## Decisão
**A moeda desenha-se como moeda** (`CoinArt`), em píxeis de 2 — a grelha do dither do §80 e do bestiário: um disco de
ouro de 18 px com o aro escuro, a face, o brilho de cima, a sombra de baixo e um cunho ao meio. A quantia lê-se pela
forma: **uma** moeda de pé; **duas a nove** uma pilha de moedas deitadas que cresce (até seis); **dez ou mais** um saco
de couro atado com ouro à boca. O ouro apanha a luz que houver e guarda 40 % da sua cor longe dela, e uma moeda pousada
**pisca** de vez em quando — um brilho que não leva luz, como a chama (ADR 0048) —, desencontrada das outras: é por ele
que se dá com uma moeda no escuro.

**A física que se vê** (`CoinBounce`) põe-se por cima do arco da simulação, e só na vertical e no rodar — o x é o da
simulação, sempre, porque é ele que decide em que obra a moeda cai (§55):

- sai da **mão** (30 px acima do chão) e desce até ao arco ao longo do voo;
- **gira** no ar — de frente, de lado (só o aro), de frente —, que é o que faz de um disco dourado uma moeda;
- **ressalta** ao pousar, cada salto metade do anterior (de 12 px até abaixo de um píxel), cada um com a duração do voo
  da sua altura na gravidade que a `economy.csv` já dá ao arco; e **balança** no chão até assentar de frente;
- quando sai da simulação — apanhada, ou paga a uma obra —, **sobe e apaga-se**, para se ver que foi levada.

A sombra de contacto (GB-09) segue a moeda e mede-a pelo desenho. Um saco não gira (tomba); uma pilha também não.

**A coroa** (`CrownView`) desenha-se da mesma maneira — 30 px, três pontas com a bola de ouro, o aro com as pedras —, e
**cai** da cabeça do rei até ao chão na mesma gravidade, ressalta, balança e pisca. **O preço** (`PriceTag`), o gesto
do Kingdom de dizer quanto custa em moedas, conta-se em moedas de píxeis (14 px) e não em discos.

Os números são de ecrã e de greybox (Q-079): alturas, tamanhos, cores e ritmos, em constantes. Nenhum toca na
simulação, e por isso nenhum vai para `data/`.

## Alternativas consideradas
- **Só aumentar o raio do círculo.** Ficava uma bola: o que faz de um disco uma moeda é o aro, o brilho e o rodar.
- **Física a sério na moeda (ressaltar para os lados).** Mexia em onde ela pousa, que é o §55 — uma obra existe quando
  uma moeda cai nela. O GB-19 já o deixava de fora, e continua.
- **Sprites de um pack.** A regra 9 não deixa tocar em `art/`, e a moeda é a animação mais importante do jogo (§24): é
  do Henrique (ART-01), e isto é a referência de porte.

## Consequências
- `WorldPalette.MOEDA_R` continua a ser o raio das marcas de moedas pagas na base de uma obra (`SiteMarks`), que são um
  instrumento de progresso, e não uma moeda que se apanha.
- `tests/coin_bounce_test.gd` guarda a mão, os saltos que diminuem, o rodar e o assentar, e a moeda levada;
  `tests/coin_art_test.gd` o tamanho contra uma tropa, a quantia pela forma, os mapas, o brilho desencontrado, o ouro
  que não se apaga e a coroa que cai.
- `tools/captura.gd` ganha `--moedas "-80@1,40@4,120@12,200@coroa"` e `--moedas_antes N`, para fotografar a moeda no
  ar, a ressaltar e pousada.
- O som com pitch variável continua de fora: `audio/` não se toca.
