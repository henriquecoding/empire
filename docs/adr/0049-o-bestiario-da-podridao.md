# ADR 0049 — O bestiário da Podridão: sete formas, sete portes, os mesmos olhos

- Estado: aceite
- Data: 2026-10-02
- Secção do dossiê: §07, §22, §25, §51, §74, §75, §80
- Actualiza: ADR 0042 (os sprites temporários das criaturas saem de uso)

## Contexto
O dono, a 02/10/2026: *«a variedade, formato e tamanho dos inimigos deve ser mesmo bem feita»*.

O que havia: quatro criaturas com sprites gratuitos de dois packs (ADR 0042) — o Rastejante era um goblin com faca, o
Alado um olho voador, o Bruto um cogumelo e o Cavador um esqueleto de escudo — e três polígonos de greybox. Não eram uma
família, e os tamanhos não contavam nada: o **Devorador**, o colosso do §74 a que se sobe, tinha 62 px de alto, menos do
que o rei (94); o **Ariete de lodo** era uma barra roxa de 24 px; o **Zelador** um rectângulo.

## Decisão
As sete criaturas desenham-se no jogo, em pixeis, por código (`Bestiary`, `BeastPen`, `BeastsSmall`, `BeastsLarge`,
`BeastsGiant`) — a regra 9 não deixa tocar em `art/`, e é o mesmo caminho do `FaunaArt` e do `FloraArt`. São uma
família: a mesma carne pisada de pouca saturação, o mesmo osso, e os **olhos acesos em roxo**, que não levam luz e se
vêem no escuro (roxo é dela, ADR 0034; ADR 0048). Um bicho encantado pelo Bardo tem os olhos âmbar: é teu.

| Criatura | Porte (px) | O que se lê de longe |
| --- | --- | --- |
| Rastejante | 56 × 28 | Pelo joelho de uma tropa, patas de aranha arqueadas por cima do corpo; são muitos |
| Cavador | 60 × 40 | A broca no focinho a rodar e as garras de cavar; atira terra para trás |
| Alado | 80 × 52 | As asas de membrana a bater; o único que não toca no chão |
| Bruto | 80 × 80 | Corcunda, anda nos nós dos dedos; o braço é a arma e arma-se por cima da cabeça |
| Zelador | 32 × 96 | Da altura do rei, fino, encapuzado e sem cara; paira um pouco acima do chão |
| Ariete de lodo | 140 × 60 | Uma lesma de lodo comprida e baixa com um crânio de carneiro à frente |
| Devorador | 184 × 164 | Quase duas vezes o rei, quatro patas-pilar, uma bocarra e um dorso que se lê como terreno |

Cada uma mexe-se: o enxame treme as patas, as asas batem, a broca roda, o lodo ondula e pinga, a boca do Devorador abre
e fecha, o manto do Zelador baloiça. O golpe da simulação (`StrikePose`) chega ao desenho: o Bruto ergue o braço e
bate, o Rastejante abre as mandíbulas, o Ariete recua e investe. A morte e o branco do golpe usam a forma da criatura,
e não uma caixa.

Os portes são greybox (Q-079): a caixa de cada uma serve o desenho, a flecha que a segue e a barra de vida, e não muda
nada na simulação.

## Alternativas consideradas
- **Manter os sprites temporários e só aumentar os tamanhos.** Continuavam a ser quatro estilos de quatro autores, e o
  Ariete, o Devorador e o Zelador ficavam sem nada (a ADR 0042 já o dizia).
- **Mais packs gratuitos.** Nenhum tem as sete, e com um pack por criatura voltava a não haver família.

## Consequências
- O `CreatureSkins` sai; os PNG temporários das criaturas ficam em `art/` (não se tocam) e fora de uso. O arqueiro e o
  lanceiro temporários continuam.
- A arte definitiva é do Henrique (ART-01); trocar é dar ao `CreatureView` o sprite em vez do `Bestiary`, que fica como
  referência de porte. O `DeathBurst` e o `LastSeen` continuam a saber desfazer uma criatura com pele.
- `tests/bestiary_test.gd` guarda que cada criatura do `creatures.csv` tem desenho, que nenhum porte se repete, que o
  Rastejante é o mais pequeno e o Devorador o maior, e que nenhum corpo é frio e saturado (§80).
