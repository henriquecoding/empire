# ADR 0058 — Os bichos de todos os dias: o ritmo de cada bicho, a caça das terras, o tamanho e o fôlego

- **Estado:** aceite, reversível (03/10/2026)
- **Contexto:** o dono jogou e escreveu: *«O rei está cansando extremamente rápido, deve demorar e se recuperar um
  pouco mais rápido, além disso não aparece criatura e animal nenhum, eles devem spawnar logo ao lado do meu império dos
  dois lados e depois de forma mais orgânica e aleatoriamente pelo mundo. Analise profundamente como Kingdom faz»*.
  E depois: *«À noite os bichos não nascem, só ficam os que já estavam fugindo da Podridão, mas os que já haviam
  deveriam estar a aparecer de forma consistente e que faça sentido»* e *«as criaturas e animais para caçar e farmar
  dinheiro devem aparecer todos os dias, várias vezes ao dia. Como espera que o jogador consiga dinheiro se isso não é
  bem feito?»*.

## O que estava, medido

Uma partida nova, simulada sem ninguém a jogar: em toda a região de casa (3840 px) havia **um a três bichos de cada
vez**. Cada toca dava um bicho a cada `HuntWatch.period` segundos de luz, e esse período reparte a caça média do
`hunt_yield` (6 moedas por dia) pelas 22 moedas que as tocas valem juntas: **825 s de luz, quase quatro dias** por bicho
e por toca. A primeira espera de cada toca era sorteada nesse período, e por isso no primeiro dia saíam dois ou três
bichos. O bicho que a Podridão apanhava de noite, ou que um arqueiro abatia, só voltava dias depois. E as terras
geradas ao andar (Q-173) não tinham caça nenhuma: só a região de casa tinha tocas.

## A pesquisa (Kingdom: Two Crowns, New Lands, Classic)

- **O fôlego.** O cavalo de base galopa uns 13 a 15 s; esgotado, anda até recuperar todo. Parado, recupera muito mais
  depressa do que a andar, e a pastar quase de imediato (wiki *Mounts*, guias do Steam). A queixa mais repetida dos
  jogadores é o cansaço que chega cedo demais (a montaria de guerra, o urso de Two Crowns: «cansado ao fim de 3 s»).
- **A caça.** Os coelhos saem dos arbustos de erva alta, nas planícies para lá das tuas muralhas: o arbusto some se a
  muralha o fecha e a erva não cresce por baixo das obras. Os veados vivem nas florestas, até 7 por ilha, e fogem do
  monarca. O javali-mãe sai de um arbusto no inverno. A disposição é sorteada com a ilha: a praça tem uns tufos de erva
  e cada ponta tem a sua planície. A caça vive **fora** do reino e rareia à medida que ele cresce; os arqueiros sem torre
  caçam o que lhes passa perto. O Greed não caça bichos (aqui a Podridão caça, ADR 0057).

## Decisão

1. **Cada bicho tem o seu ritmo (`respawn_s`, wildlife.csv).** A toca vazia volta a dar o seu bicho `respawn_s`
   segundos de luz depois de ele sair — abatido, apanhado pela Podridão ou perdido —, e nunca de noite (o dono: *«à
   noite os bichos não nascem»*). Coelho 60 s (quase quatro vezes por dia de luz), faisão 75 s, raposa 90 s, veado
   112 s (duas vezes), javali 200 s (uma vez). Num dia mais longo ou mais curto (§26) o ritmo escala com o dia, como
   o período escalava. A primeira espera de cada toca de casa sorteia-se no ritmo do bicho, e não nos quatro dias: logo
   na primeira manhã há bichos dos dois lados do castelo. O `HuntWatch.period` (o `hunt_yield`) fica como o ritmo de
   quem não tem `respawn_s`.
2. **As terras geradas têm caça (`WildBurrows`, `WildHunt`).** Cada segmento de trilho que nasce ao andar ganha até
   `per_segment_max` tocas de cada bicho do bioma dele (a coluna existia e não era usada), nos sítios que o tipo de
   segmento tem: o campo tem arbustos, rochas e buracos; a floresta árvores, arbustos e buracos; a água o lago; a ruína
   rochas e buracos; os acampamentos arbustos. Os povos, as fortalezas, os limiares e as bordas não têm caça. O sorteio
   é o `RngService.scatter` com o sítio (lado e índice), como o resto do segmento: o mesmo segmento dá as mesmas tocas
   venha o rei quando vier. As tocas ficam afastadas umas das outras (96 px, Q-218) e do assunto do segmento (72 px). A metade
   de perto de um trilho tem os bichos do povo de onde se vem; a de longe, os do outro.
3. **Logo ao lado do império, dos dois lados.** O primeiro segmento de cada lado tem sempre pelo menos uma toca de cada
   bicho que lá cabe, mesmo que o sorteio diga nenhuma. Os seguintes são o sorteio: uns cheios, outros vazios.
4. **Os bichos das terras já lá estão.** Quando um segmento nasce, o bicho de cada toca está à porta: não nasce à
   frente do rei. A partir daí segue o ritmo do ponto 1.
5. **Os caçadores de casa ficam em casa (`HuntingSystem.home`).** O arqueiro, o lanceiro e os outros `hunter` vão
   atrás da caça só dentro da região de casa; os bichos das terras são do imperador que lá passa (ADR 0057, a caça dele
   cai no chão) e de quem o acompanha. Sem isto, um arqueiro de casa atravessava o mundo atrás de um coelho.
6. **Q-216 — o fôlego.** `king_run_stamina_s` passa de 8 s a 14 s (o galope do cavalo de base do Kingdom),
   `king_run_refill_s` de 10 s a 8 s e `king_run_rest_refill_s` de 4 s a 3 s. Corre-se mais tempo do que se leva a
   recuperar a andar; o evoluído corre 21 s. As regras da Q-193 e da Q-208 não mudam.

7. **Q-218 — os bichos do tamanho certo.** O dono: *«as criaturas estão microscópicas, têm que ser pelo menos 2 ou 3
   vezes o tamanho, com base em 64x64 pixels de sprite, para fazerem sentido em imagem e dar para bater»*.
   - **O tamanho.** O coelho, o faisão, a raposa e o javali desenham-se a 3× (`sprite_scale`, wildlife.csv); o veado e o
     cervo branco a 2×, porque já são altos. Cada bicho fica entre meio sprite de 64 px e dois.
   - **As tocas e a sombra.** As tocas desenham-se ao dobro, e cada bicho tem a sua sombra de contacto (`shadow_width`, à
     escala).
   - **O golpe.** Acerta no corpo e não só no meio dele: até meia sombra para lá do alcance e para trás de quem bate
     (`RoyalHunt`).
   - **O pastar.** `roam_px` e `graze_speed` dobram com o corpo, e o vaivém leva o mesmo tempo.
   - **As tocas de casa.** Com o chão que as tocas grandes pedem, a região de casa só tem lugar para oito sem pisar uma
     obra (Q-207): quatro à porta do castelo, como os tufos de erva da praça do Kingdom, e quatro nos chãos livres. O
     veado fica com uma toca em casa (eram duas), e as tocas das terras ficam a 96 px umas das outras.

## O que mudou na economia (medido)

Numa partida simulada com três arqueiros e dois lanceiros teus, sem mais ninguém a jogar, e com as oito tocas de casa
da Q-218: saem **cerca de 23 bichos por dia** na região de casa e a caça rende **27 a 28 moedas por dia**, contra as 6 do
`hunt_yield`. O dono pediu-o: a caça passa a ser uma fonte de dinheiro a sério, como no Kingdom. O modelo de
economia da §06 (o dia da asfixia, `economia_jogada_test`) continua a contar a caça pelo `hunt_yield`; se o modelo deve
passar a contar a caça nova, é a Q-217. As terras geradas acrescentam, por cima, o que o imperador lá caçar.

## Consequências

- Mais fácil: há caça em casa todos os dias, várias vezes ao dia, e o mundo tem bichos para lá das muralhas.
- O save não muda de versão: as tocas das terras vão nas tocas que já se gravavam. Um save de antes ganha-as ao
  carregar (o `Frontier.reapply` passa pelo `WildHunt.author`, que só acrescenta as que faltam).
- O `HuntView` desenha só o que está no ecrã (ADR 0055): o mundo inteiro tem caça. O `Herd` ordena quem assusta os
  bichos uma vez por passo, e não uma vez por bicho.
- O `_rare` do `HuntingSystem` passou para o `Herd.rare`, para o `HuntingSystem` caber nas 250 linhas.
- Reverter: `sprite_scale` a 1 e o `shadow_width` de antes voltam ao tamanho de antes; `respawn_s` a 0 no
  wildlife.csv volta ao período do `hunt_yield`; `per_segment_max` a 0 tira a caça das
  terras; os três números do fôlego voltam a 8, 10 e 4 no economy.csv.
