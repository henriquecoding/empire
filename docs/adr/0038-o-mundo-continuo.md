# ADR 0038 — O mundo contínuo: gerado ao andar, gravado, com a borda no fim

- Estado: aceite
- Data: 2026-09-30
- Secção do dossiê: §21 (geração procedural do território), §11, §13, §16, §62
- Complementa: ADR 0035 (a marcha e os vassalos), ADR 0007 (o save), Q-154 (as terras bravias)

## Contexto
O dono pediu, a 30/09/2026, que os personagens deixassem de andar *«sobre nada»*, que o mapa se gerasse *«como
minecraft, conforme a pessoa anda»* e ficasse gravado *«daquele jeito o resto da gameplay»*, com *«um limite saudável»*
e *«algo ao fim como é em kingdom»*. Logo a seguir pediu *«caminhos e trilhas»* entre as regiões, *«para fazerem
transições suaves»*, porque *«nesses caminhos se encontra acampamentos de mendigos, mercenarios, dungeons»*.

O que estava: a Q-154 abriu seis ecrãs de terra bravia de cada lado da região, mas o chão, o corte de solo e o campo
só se desenhavam na região. Os povos da campanha não tinham sítio no mundo: a marcha levava a gente para uma fortaleza
que não se via. A pesquisa (`docs/recovery/PESQUISA-MUNDO-2026-09-30.md`) juntou o que o Minecraft faz (o chunk gerado
ao aproximar-se, a aleatoriedade presa à semente e ao sítio, o chunk gravado com o estado dele, a mistura sem costuras
e o mundo finito que acaba em mar) e o que o Kingdom faz (o mapa em blocos lado a lado, o reino ao centro, o perigo
nas pontas, e a ilha que acaba na praia, com a doca, ou na falésia).

## Decisão
**O mundo é uma linha de segmentos do §21 à volta da região de casa, do tamanho da campanha. Gera-se ao andar, grava-se
no save, e acaba de cada lado numa borda.**

- **O plano** (`WorldPlan`, puro). Os povos da campanha ficam pela ordem do plano, a alternar de lado: o primeiro a
  leste, onde fica a bifurcação. Cada um tem um trilho, um limiar, a terra e a fortaleza na ponta. Depois do último de
  cada lado há um trilho e a borda. O comprimento de cada trilho sorteia-se pelo sítio.
- **O segmento é o chunk** (`WildSegments`, puro; `TrailPick`). Gera-se o que começa a um ecrã do rei
  (`Frontier`), de dentro para fora. Os sorteios vêm do `RngService.scatter` com a chave do sítio: o mesmo mundo
  sai igual, ande o rei ou salte.
  - Nos trilhos, o tipo sai dos pesos e regras do `segments.csv`, com um ruído de clima a juntar os bosques. Cada
    trilho tem pelo menos um encontro.
  - O limiar, a terra e a borda saem das linhas novas do `segments.csv`. A borda é a do bioma do último povo
    (`biomes.csv`, `edge_subject`): mar, falésia, desfiladeiro ou muralha.
- **Gravado.** Cada segmento gerado é um registo, e vai no save (`world.wilds`). O save sobe para a versão 4, com a
  migração no mesmo commit (ADR 0007): um save de antes abre sem terras geradas e gera-as ao andar.
- **Os encontros fazem o que dizem.**
  - O acampamento de mendigos entra na alvorada (Q-122).
  - O de mercenários tem um mercenário à espera, reposto na alvorada quando é contratado.
  - A ruína com passagem é uma masmorra: a boca pega no Verbo 2, e o monte de moedas da câmara cai só da primeira vez.
    As bocas não entram no `SimLoop.passages` (Q-132).
- **Sem saltos.**
  - A paisagem passa em gradiente de um povo para o seguinte ao longo do trilho (`WorldPlan.mix_ends`).
  - A estrada estreita-se em trilho e volta a alargar-se (`WorldPlan.trail_ends`).
  - A cave da região fecha num pilar, e o túnel das terras sai dele com os mesmos estratos.
- **O limite** é o plano: não se anda para lá da beira de nenhuma borda. A câmara segue o que já foi gerado
  (`FrontierView`). O guia diz de quem é a terra e o que há no fim.
- **Os números são propostas** (`_proposed`), cada um com a regra na nota.
- **O desenho** são formas lisas escritas como dados e desenhadas por um só intérprete (`ShapeArt`), à espera de arte.

## Alternativas consideradas
- **Um mundo infinito, como o Minecraft.** Rejeitado. O dono pediu um limite, e o Kingdom acaba cada ilha. Um mundo
  sem fim também tiraria o sentido à bifurcação e à marcha.
- **Gerar o mundo inteiro no primeiro dia.** Rejeitado: é o que o pedido diz que não quer (*«conforme a pessoa
  anda»*). Como os sorteios estão presos ao sítio, gerar de uma vez ou ao andar dá o mesmo mundo, e o teste prova-o.
- **Não gravar os segmentos e voltar a gerá-los pela semente.** Rejeitado. O mundo mudaria de cada vez que o gerador
  ou o `segments.csv` mudasse, e o pedido é que *«fique salvo daquele jeito»*. O Minecraft grava o chunk pela mesma
  razão.
- **Uma travessia em ecrã à parte entre regiões.** Rejeitado. É o *«pular de um ponto a outro»* de que o dono se
  queixou.

## Consequências
- O mundo da semente 20260930 tem 54 272 px de beira a beira. Do núcleo à borda de leste são seis minutos a andar.
- A vistoria passa a medir o mundo de beira a beira, e não só a região.
- O piloto só vai buscar as moedas da faixa em que está: as da masmorra estão lá em baixo.
- Os bichos do cenário nascem e andam só entre as beiras.
- Continua por decidir o que o jogo faz nas terras, e fica nas Q-174 a Q-180:
  - obras nas terras;
  - uma tabela de segmentos por povo;
  - o que há numa masmorra;
  - o soldo dos mercenários;
  - o que o rei pode fazer na terra de outro povo;
  - de onde vem a noite, agora que o mundo tem pontas;
  - o mapa revelado do §16.
