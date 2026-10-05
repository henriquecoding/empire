# ADR 0071 — A noite que se aprende: a estreia, a rampa inteira e o escuro que se paga

- **Estado:** aceite, reversível (o dono, 05/10/2026: *«isso tem que ser balanceado»*); os três números novos são
  propostas (`_proposed` no `rot.csv`) e a curva das noites 2 a 6 fica por decidir (Q-242, Q-243).
- **Data:** 2026-10-05
- **Secção do dossiê:** §05, §25, §51, §74; Q-017, Q-029, Q-068, Q-126, Q-151, Q-157
- **Relatório:** `docs/recovery/PESQUISA-INIMIGOS-2026-10-05.md` (pesquisa, medição antes e depois, fontes)

## Contexto

O dono jogou e escreveu: *«na primeira noite está aparecendo diversos inimigos e inimigos muito fortes, isso tem que
ser balanceado, analise profundamente o que já existe e como pode refinar isso»*, e pediu que a dificuldade fosse
*«natural e faça sentido»*.

A sonda das noites (`tools/noites.gd`, nova) correu a partida pilotada e mediu três defeitos de regra, e não de número:

1. **O escuro não pagava.** O `DarkWatch` (Q-029) trazia um Rastejante de 8 em 8 s, até seis por noite, a 90 px do
   rei, **sem tirar nada à massa** e **desde a noite 1**. Medido na `main` em `417369e` (com a Última Carroça da
   ADR 0065): com o rei no escuro, a noite 1 tinha nove Rastejantes em vez dos três do §25. É a única porta de
   criaturas que não passava pela regra da §05: *«a Podridão é a única fonte de criaturas, e gasta um orçamento»*.
2. **A rampa só valia para o calendário.** A Q-017 e a Q-068 puseram as primeiras noites em rampa, e o dono pediu na
   Q-151 *«mais brando até a noite 5»* (Q-157: *«as cinco primeiras noites brandas»*). Mas as árvores (+22), as recusas
   (+8) e o Lume entravam inteiros desde a primeira noite: medido, uma árvore e uma recusa levavam a noite 3 de 59 a
   89.
   É retroação positiva no pior momento — quem perde gente na noite 2 tem uma noite 3 mais pesada.
3. **Uma espécie nova chegava em monocultura.** «A mais cara que cabe» (§51) é uma boa regra de orçamento e uma má
   regra de apresentação: na noite em que o Alado abre, a massa inteira vira Alados (noite 4: nove, e nenhum
   Rastejante); na do Bruto, Brutos (noite 7: sete); na do Ariete, sete Arietes (noite 14). O rei e os lanceiros não
   chegam ao ar: medido, os Alados da noite 4 matavam o rei em quatro de cinco partidas pilotadas.

A pesquisa (Kingdom, o AI Director do Left 4 Dead, as vagas do Mindustry e do Dome Keeper, o equilíbrio de *tower
defense*) concorda nos três pontos: começar com poucos, introduzir uma criatura nova em pequeno número antes de a
multiplicar, e nunca fazer nascer nada à vista e colado a quem joga.

## Decisão

**Tudo o que a Podridão traz paga-se pela mesma regra, num sítio só; uma espécie estreia com poucos; e as primeiras
noites são brandas por inteiro.**

1. **A estreia (Q-240, `debut_step`).** Numa noite, uma espécie que abriu na noite `abre` vem no máximo
   `debut_step × (dia − abre + 1)` vezes; com `debut_step = 1` são 1, 2, 3… A espécie da noite 1 não estreia. O Cavador
   chamado pelo poço (Q-131) estreia na noite em que o poço o chama. A massa que a estreia não deixa gastar paga as
   mais baratas: a noite não fica mais leve, fica **misturada**. A contagem é por noite e vai no save (`RotState.came`).
2. **A regra num sítio (`RotPick`).** A escolha do §51 e a estreia vivem no `RotPick` (puro). A mancha usa-o para
   invocar; o `RotSystem.afford` usa-o para pagar o que não invoca; e a `NightWatch.pay` é a única porta por onde o
   bicho que ela levanta (`HuntWatch`) e quem o escuro traz (`DarkWatch`) saem da massa.
3. **A rampa pesa a noite inteira (Q-239, `ramp_written`).** As árvores, as recusas e o Lume entram na massa com o mesmo
   `t` da rampa do calendário (`RotProfile.written_weight`): nada na noite 1, metade na 3, inteiro a partir da
   `ramp_nights`. A tabela da §74 (noites 5, 10 e 20) e o teto das recusas (D-04) não mudam. A noite saltada (Q-040)
   continua a vir inteira: é uma dívida, e não uma coisa que se escreveu.
4. **O escuro paga-se e espera (Q-241, `dark_from_night`, `dark_ambush_px`).** Antes da noite 3 o escuro não traz
   ninguém. Depois traz, e a Podridão paga-o da massa: explorar de noite deixa de acrescentar criaturas e passa a
   puxá-las para o rei. Se a mancha já gastou o que tinha, o escuro chama e ninguém vem. A emboscada nasce a 180 px e
   não a 90, que era dentro do corpo de um Rastejante (Q-219).
5. **O ritmo vive no perfil.** O `RotProfile.rhythm` passa a ter a regra da Q-126, ao lado do `calendar_mass`; o
   `RotSystem.rhythm` chama-o. Nada muda no que devolve: foi o que fez o `RotSystem` caber nas 250 linhas.
6. **O instrumento.** A `tools/noites.gd` (`make noites`) fica como mesa de afinação, e o `ROT_BY_DAY.md` diz o que
   cada noite paga, espécie a espécie.

## Alternativas consideradas

- **Mexer no `mass_base`, no `mass_per_day` ou na `ramp_nights`.** São números do dossiê (§74) e decisões do dono
  (Q-157). E não corrigiam nenhum dos três defeitos: o escuro continuava de graça, a retroação continuava inteira, e a
  noite 4 continuava a ser só Alados. A curva das noites 2 a 6 fica como pergunta, com medição (Q-242).
- **Trocar «a mais cara que cabe» por um sorteio ponderado (Dome Keeper).** Mistura bem, mas tira à §51 a
  previsibilidade que o dossiê defende («a noite funda sabe-se de véspera») e gasta o fluxo `rot` em cada invocação.
  A estreia mistura sem sorteio.
- **Um teto às árvores (por exemplo, metade do calendário).** Fecharia a espiral, mas tira à §74 o que ela quer —
  *«paga-se todas as noites, para sempre»* — e enfraquece o D-02 (dez vagabundos sacrificados têm de pesar). A rampa só
  dá a janela de aprendizagem, e a partir da noite 5 a árvore pesa como a §74 diz.
- **Tirar o escuro.** O dono pediu-o (Q-029: *«podem aparecer inimigos de qualquer lugar»*). Fica, com orçamento e
  sem morder antes de se poder aprender.

## Consequências

- A noite 1 é sempre a do §25 (três Rastejantes), esteja o rei onde estiver: `tests/escuro_pago_test.gd` corre a
  partida inteira com o rei no escuro e conta.
- O primeiro Alado e o primeiro Bruto vêm sozinhos; a composição de cada noite lê-se no `ROT_BY_DAY.md`.
- As noites 4 a 6 passam a ter mais Rastejantes e menos Alados. Antes, os nove Alados da noite 4 eram uma noite que só
  os arqueiros jogavam; agora a massa é combate para o reino inteiro — e a curva dessas noites pesa mais contra uma
  defesa fraca. É a Q-242.
- Um save de antes não traz `came`: a noite em curso conta do zero, e só se grava de dia (Q-119).
- **Para reverter os números:** `debut_step = 0`, `ramp_written = false`, `dark_from_night = 0` e
  `dark_ambush_px = 90` no `rot.csv`; com eles o `RotPick` escolhe como o `_escolher` de antes. O escuro continua a
  pagar-se da massa: voltar a tê-lo de graça é tirar a chamada à `NightWatch.pay` no `DarkWatch.tick`.
