# ADR 0071 — A noite que se aprende: a estreia, a rampa inteira, a porta e o escuro que se paga

- **Estado:** aceite, reversível (o dono, 05/10/2026: *«isso tem que ser balanceado»*); os três números novos e a
  distância da emboscada são propostas (`_proposed` no `rot.csv`); a curva das noites 2 a 6 fica por decidir (Q-242,
  Q-243).
- **Data:** 2026-10-05
- **Secção do dossiê:** §05, §25, §51, §66, §74; Q-017, Q-029, Q-068, Q-101, Q-126, Q-151, Q-157; ADR 0065, ADR 0070
- **Relatório:** `docs/recovery/PESQUISA-INIMIGOS-2026-10-05.md` (pesquisa, medição antes e depois, fontes)

## Contexto

O dono jogou e escreveu: *«na primeira noite está aparecendo diversos inimigos e inimigos muito fortes, isso tem que
ser balanceado, analise profundamente o que já existe e como pode refinar isso»*, e pediu que a dificuldade fosse
*«natural e faça sentido»*.

A sonda das noites (`tools/noites.gd`, nova) correu a partida pilotada sobre a `main` em `417369e` (com a Última Carroça
da ADR 0065) e mediu quatro defeitos de regra, e não de número:

1. **O escuro não pagava.** O `DarkWatch` (Q-029) trazia um Rastejante de 8 em 8 s, até seis por noite, a 90 px do
   rei, **sem tirar nada à massa** e **desde a noite 1**. Com o rei no escuro, a noite 1 tinha nove Rastejantes em vez
   dos três do §25. Era a única porta de criaturas fora da regra da §05: *«a Podridão é a única fonte de criaturas, e
   gasta um orçamento»*.
2. **A rampa só valia para o calendário.** A Q-017 e a Q-068 puseram as primeiras noites em rampa, e o dono pediu na
   Q-151 *«mais brando até a noite 5»* (Q-157: *«as cinco primeiras noites brandas»*). Mas as árvores (+22), as recusas
   (+8) e o Lume entravam inteiros desde a primeira noite: medido, uma árvore e uma recusa levavam a noite 3 de 59 a
   89. É retroação positiva no pior momento — quem perde gente na noite 2 tem uma noite 3 mais pesada.
3. **Uma espécie nova chegava em monocultura.** «A mais cara que cabe» (§51) é uma boa regra de orçamento e uma má
   regra de apresentação: na noite em que uma espécie abre, a massa inteira vira essa espécie — noite 4 só Alados,
   noite 7 Brutos, noite 10 sete Cavadores, noite 14 sete Arietes. O rei e os lanceiros não chegam ao ar: os seis ou
   sete Alados da noite 4 matavam o rei em quatro de cinco partidas pilotadas com ele à porta do núcleo.
4. **A mancha invocava dentro das muralhas.** A mancha atravessa o campo (§51) e invoca onde está. Numa noite longa,
   com massa ainda por gastar, passa por cima da muralha e faz nascer criaturas à volta do núcleo. Com as monoculturas
   de antes a massa acabava cedo e isto quase não se via; com a noite misturada (mais invocações baratas) a defesa do
   décimo dia do §66 perdia o castelo para Rastejantes nascidos dentro dos muros. Contradiz a ADR 0070: *a noite vem
   de fora do reino*.

A pesquisa (Kingdom, o AI Director do Left 4 Dead, as vagas do Mindustry e do Dome Keeper, o equilíbrio de *tower
defense*) concorda: começar com poucos, introduzir uma criatura nova em pequeno número antes de a multiplicar, fazer
nascer o inimigo de sítios que se conhecem, e nunca à vista e colado a quem joga.

## Decisão

**Tudo o que a Podridão traz paga-se pela mesma regra, num sítio só, e nasce fora do reino; uma espécie estreia como o
Rastejante estreou na noite 1; e as primeiras noites são brandas por inteiro.**

1. **A estreia (Q-240, `debut_step = 3`).** Numa noite, uma espécie que abriu na noite `abre` vem no máximo
   `debut_step × (dia − abre + 1)` vezes: três na primeira noite dela, seis na segunda, nove na terceira. A espécie da
   noite 1 não estreia. O Cavador chamado pelo poço (Q-131) estreia na noite em que o poço o chama. A massa que a
   estreia não deixa gastar paga as mais baratas: a noite não fica mais leve, fica **misturada**. A contagem é por
   noite e vai no save (`RotState.came`).
   - **Porquê três:** é como o Rastejante estreia na noite 1 (§25), e é o passo mais pequeno que mantém os cinco testes
     de desenho do §66. Com 1 ou 2, a noite 10 deixava de ser nove Cavadores a passar por baixo das muralhas e recusar
     todas as ofertas já não derrubava a defesa do décimo dia — a regra do dono na Q-101 (*«há sempre consequências»*).
2. **A regra num sítio (`RotPick`).** A escolha do §51, a estreia e a porta vivem no `RotPick` (puro). A mancha usa-o
   para invocar; o `RotSystem.afford(dados, dia)` usa-o para pagar o que não invoca, no dia do relógio; e a
   `NightWatch.pay` é a única porta por onde o bicho que ela levanta (`HuntWatch`) e quem o escuro traz (`DarkWatch`)
   saem da massa.
3. **A porta (`RotPick.door`, `NightWatch.door`).** Quem a mancha invoca depois de passar por cima da muralha mais
   exterior do lado dela nasce à porta dessa muralha, do lado de fora. A massa gasta-se igual; só o sítio muda. Uma
   muralha caída deixa de ser porta, e o subsolo não tem as muralhas da superfície. Vale para as duas manchas.
4. **A rampa pesa a noite inteira (Q-239, `ramp_written`).** As árvores, as recusas e o Lume entram na massa com o
   mesmo `t` da rampa do calendário (`RotProfile.written_weight`): nada na noite 1, metade na 3, inteiro a partir da
   `ramp_nights`. A tabela da §74 (noites 5, 10 e 20) e o teto das recusas (D-04) não mudam. A noite saltada (Q-040)
   continua a vir inteira: é uma dívida, e não uma coisa que se escreveu.
5. **O escuro paga-se e espera (Q-241, `dark_from_night = 3`, `dark_ambush_px = 180`).** Antes da noite 3 o escuro
   não traz ninguém. Depois traz, e a Podridão paga-o da massa: explorar de noite deixa de acrescentar criaturas e passa
   a puxá-las para o rei. Se a mancha já gastou o que tinha, o escuro chama e ninguém vem. A emboscada nasce a 180 px
   e não a 90, que era dentro do corpo de um Rastejante (Q-219).
6. **O ritmo vive no perfil.** O `RotProfile.rhythm` passa a ter a regra da Q-126, ao lado do `calendar_mass`; o
   `RotSystem.rhythm` chama-o. Nada muda no que devolve: foi o que fez o `RotSystem` caber nas 250 linhas.
7. **O instrumento.** A `tools/noites.gd` (`make noites`) fica como mesa de afinação, e o `ROT_BY_DAY.md` diz o que
   cada noite paga, espécie a espécie.

## Alternativas consideradas

- **Mexer no `mass_base`, no `mass_per_day` ou na `ramp_nights`.** São números do dossiê (§74) e decisões do dono
  (Q-157), e não corrigiam nenhum dos quatro defeitos. Medido (15 partidas pilotadas por variante), alongar a rampa até à
  noite 7 ou 9 quase não muda o dia em que a partida acaba: 3,8 dias em média, 3,9 e 4,0. O piloto perde porque a
  defesa dele não cresce na abertura nova, e não pela rampa. A curva das noites 2 a 6 fica como
  pergunta, com medição (Q-242).
- **`debut_step` 1 ou 2.** Misturam mais cedo, mas partem a Q-101 no §66 (ver acima).
- **Trocar «a mais cara que cabe» por um sorteio ponderado (Dome Keeper).** Mistura bem, mas tira à §51 a
  previsibilidade que o dossiê defende («a noite funda sabe-se de véspera») e gasta o fluxo `rot` em cada invocação.
  A estreia mistura sem sorteio.
- **Parar a mancha à porta.** Mudava o rasto da §49 (o que ela atravessa não produz) e a escuridão que ela traz; a
  porta só muda onde nasce quem ela invoca.
- **Um teto às árvores (por exemplo, metade do calendário).** Fecharia a espiral, mas tira à §74 o que ela quer —
  *«paga-se todas as noites, para sempre»* — e enfraquece o D-02 (dez vagabundos sacrificados têm de pesar). A rampa só
  dá a janela de aprendizagem.
- **Tirar o escuro.** O dono pediu-o (Q-029: *«podem aparecer inimigos de qualquer lugar»*). Fica, com orçamento e
  sem morder antes de se poder aprender.

## Consequências

- A noite 1 é sempre a do §25 (três Rastejantes), esteja o rei onde estiver: `tests/escuro_pago_test.gd` corre a
  partida inteira com o rei no escuro e conta (na `main`, nove).
- Os primeiros três de cada espécie vêm misturados com o que já se conhece; a composição lê-se no `ROT_BY_DAY.md`.
- Ninguém nasce dentro das muralhas de pé (`tests/porta_da_noite_test.gd`); os cinco testes do §66 continuam verdes.
- As noites 4 a 6 trazem metade dos Alados e o resto em Rastejantes, que todos podem bater.
- Um save de antes não traz `came`: a noite em curso conta do zero, e só se grava de dia (Q-119).
- **Para reverter os números:** `debut_step = 0`, `ramp_written = false`, `dark_from_night = 0` e
  `dark_ambush_px = 90` no `rot.csv`; com eles o `RotPick` escolhe como o `_escolher` de antes. O escuro continua a
  pagar-se da massa, e a porta continua: voltar atrás nelas é tirar a chamada à `NightWatch.pay` no `DarkWatch.tick`
  e à `NightWatch.door` no `_invocar` e no `RiftWatch.tick`.
