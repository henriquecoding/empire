# ADR 0076 — A tocha na mão quando há pouca luz

- **Estado:** aceite, pedido direto do dono a 06/10/2026.
- **Tarefa:** UX-07.
- **Estende:** ADR 0048 (a noite que se vê) e Q-029 (o archote).

## Problema

O dono: *«Na alvorada e nos momentos de pouca iluminação os imperadores carregam tochas ou algo
luminoso na mão para não ficar tão escuro o jogo.»* A única luz que o monarca levava era o archote
do Q-029, que se compra numa fogueira, arde 60 segundos e só se acende de noite, no escuro. Na
alvorada (escuro 0,80 a 0,12, medido pelo `Lighting.darkness`), no fim da tarde e no crepúsculo
não havia luz nenhuma à volta de quem se conduz.

## Decisão

1. Quem se conduz (`Assume.driven()`) leva uma tocha acesa na mão sempre que o escuro que o olho vê
   passa de 0,15: o princípio da alvorada, o fim da tarde, o crepúsculo e a noite. A manhã e o
   meio-dia não chegam lá (`HandLight.ACESA`).
2. É só luz e desenho (`src/world/hand_light.gd`): um cabo de madeira e uma chama de `FlameArt` na
   mão do lado para onde anda, e uma luz no `LightField` com 70 % do raio do archote e força 0,4
   (o archote tem 0,5). A luz já soma ao ambiente na medida do escuro, por isso cresce com ele.
3. Não é o archote. Não se gasta, não ocupa o armazenamento e não conta para o
   `Torchlight.in_dark`: sem archote comprado, o escuro da noite continua a trazer emboscadas.
   Quando o archote arde, é ele que se vê e alumia, e a tocha da mão sai.
4. Nenhum número de balanceamento muda.

## Consequências

- A alvorada e o crepúsculo deixam de ser um ecrã castanho à volta do monarca.
- A luz menor e a chama mais pequena distinguem a tocha da proteção do archote. Se o dono quiser que
  a tocha também afaste a emboscada do escuro, é uma regra de jogo e fica na Q-247.
