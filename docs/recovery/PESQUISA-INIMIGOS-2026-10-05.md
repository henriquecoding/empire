# Os inimigos e a curva da noite — pesquisa, medição e desenho (ADR 0071)

_5 de outubro de 2026. Pedido do dono: «Quero que faça uma densa pesquisa na web e no meu projeto atual para tornar os
inimigos e os sistemas de inimigos bem mais fundamentados e bem implementados no meu jogo, que a dificuldade seja natural
e faça sentido, na primeira noite está aparecendo diversos inimigos e inimigos muito fortes, isso tem que ser
balanceado, analise profundamente o que já existe e como pode refinar isso»._

**Rótulos de evidência** (os das auditorias anteriores): **Medido** (a sonda ou a suíte correu), **Confirmado no
código** (caminho rastreado, sem execução), **Proposta** (precisa de decisão do dono).

## 1. A resposta curta

A noite 1 não trazia os três Rastejantes do §25 a quem saía da luz: trazia **nove** (medido na `main` em `417369e`,
com a Última Carroça da ADR 0065). Seis vinham do escuro, **de graça e colados ao rei**; com o rei a 400 px do núcleo
a partida chegava a acabar na noite 2. E o «inimigo muito forte» também tem nome: na noite 4 a massa inteira virava
Alados, que o rei e os lanceiros não conseguem bater, e matavam o rei em quatro de cinco partidas pilotadas.

Eram quatro regras, e não números, a empurrar a curva contra quem está a aprender:

- **O escuro não pagava.** Era a única porta de criaturas fora da massa da Podridão, e abria logo na noite 1.
- **O que se escreve de dia pesava inteiro desde a primeira noite.** A rampa das primeiras noites só valia para o
  calendário.
- **Uma espécie nova vinha toda de uma vez.** «A mais cara que cabe» fazia de cada noite de estreia uma monocultura:
  Alados na 4, Brutos na 7, Cavadores na 10, Arietes na 14.
- **A mancha invocava dentro das muralhas.** Atravessa o campo e invoca onde está — também por cima da Bastião.

A ADR 0071 corrige as quatro com regras que o jogo já tinha (a §05, a Q-151, a §51 e a ADR 0070), e os cinco testes de
desenho do §66 continuam verdes. Fica uma pergunta maior, que é tua: a curva das noites 2 a 6 foi afinada (Q-157,
30/09) quando o reino começava num castelo de pé, antes da Clareira (ADR 0059) e da Última Carroça (ADR 0065). A
medição diz que o piloto morre cedo com ou sem rampa longa, porque a defesa dele não cresce — por isso a afinação da
curva pede o RG-06 ou o teu *playtest* (secção 7, Q-242).

## 2. O que existe: todas as portas por onde entra uma criatura

**Confirmado no código.** A §05 e a §51 dizem que a Podridão é a *única* fonte de criaturas e que gasta um orçamento
(a massa). Na `main` havia seis portas:

| Porta | Onde | Paga da massa? | Desde | Notas |
|---|---|---|---|---|
| A mancha invoca | `RotSystem.tick` | sim | noite 1 | «a mais cara que cabe», a cada 4–7 s, **onde a mancha estiver — também dentro dos muros** |
| O bicho apanhado levanta-se | `HuntWatch._paid` | sim | noite 1 | coelho, faisão e raposa → Rastejante; veado, javali e cervo → Bruto (dia 7) |
| **O escuro à volta do rei** | `DarkWatch.tick` | **não** | **noite 1** | de 8 em 8 s, até 6 por noite, a **90 px** do rei |
| A segunda mancha | `RiftWatch` | sim (metade) | noite 12 | metade da massa vai para o outro lado |
| A noite de um povoado das terras | `SettlementWatch.night` | outra mancha, só para ele | noite 1 | Rastejantes a 360 px do povoado, até 6, só contra ele |
| O guardião de masmorra | `DungeonWatch.author` | não | quando o segmento nasce | um Cavador parado no subsolo, guarda o saque |

E a massa de cada noite (§74) é o calendário (com a rampa da Q-017 nas cinco primeiras) **mais** o que se escreve de
dia: +22 por árvore de pé (+45 se nomeada), +8 por recusa nas últimas cinco noites (até +40), e o que o Lume comeu.

## 3. A medição: a sonda das noites

**Medido.** A `tools/noites.gd` (nova; `make noites`) corre a partida inteira com o piloto da vistoria e diz, noite a
noite, a defesa ao crepúsculo, quantas criaturas vieram, de que espécie e por que porta, a massa com que a noite
nasceu, o pico de criaturas vivas, o dano no rei e as baixas. O rei passa a noite onde a política manda: `casa` (na
borda do núcleo, do lado da mancha), `cauteloso` (do outro lado), `fora` (a 400 px, como quem defende a estacaria ou
explora) e `longe` (1400 px). Fora, o rei bate no que lhe chega perto, como quem joga.

### Antes (a `main` em `417369e`)

Rei `fora` — o escuro na noite 1:

| semente | noite | defesa | massa | da mancha | do escuro | dano no rei |
|---|---|---|---|---|---|---|
| 7 | 1 | 2 arq. · 3 lanç. · 2 muros | 24 | Rastejante 3 | **Rastejante 6** | 16 |
| 7 | 2 | 2 · 3 · 1 | 38 | Rastejante 2 | **Rastejante 4** | **44 — o rei cai** |
| 1234 | 1 | 4 · 0 · 0 | 24 | Rastejante 3 | **Rastejante 6** | **40 de 60** |

Rei em `casa` — a noite 4:

| semente | noite | defesa | massa | da mancha | dano no rei |
|---|---|---|---|---|---|
| 20260916 | 4 | 2 arq. · 0 lanç. · 1 muro | 106 | Rastejante 1 · **Alado 7** | **60 — o rei cai** |
| 11 | 4 | 2 · 3 · 3 | 92 | **Alado 6** | **65 — o rei cai** |

Na `main` anterior (`247d5a0`, ainda sem a Última Carroça), com o piloto a deixar mortos lá fora e a recusar ofertas,
a noite 3 pesava **89** contra 59 do calendário, e a composição era 11 Rastejantes, depois 9 Alados, 13, 19, 7 Brutos,
12 Brutos.

O que se lê:

- **O escuro triplica a noite 1** e mata o rei na 2 a quem explora.
- **A noite em que uma espécie abre é essa espécie, toda.** Os Alados da noite 4 voam por cima das muralhas e só os
  arqueiros lhes chegam.
- **A defesa do piloto não cresce** na abertura nova: 2 arqueiros e 1–2 muros do dia 1 ao 4.

## 4. A pesquisa

| Fonte | O que faz | O que serve aqui |
|---|---|---|
| **Kingdom Two Crowns** (wiki e Steam) | A primeira vaga de retaliação tem sempre só uns poucos Greedlings. A Greed nasce **só dos portais**, à vista e de lados conhecidos. Os tipos novos entram aos poucos: a 1.ª Lua de Sangue só traz Greedlings, a 3.ª traz Floaters, a 5.ª Breeders e Crown Stealers. A força cresce com o dia global e com os portais destruídos. | Começar com poucos; uma criatura nova entra em pequeno número; as criaturas vêm de onde se sabe. |
| **Left 4 Dead — AI Director** (Mike Booth, GDC 2009) | Mede a intensidade de cada sobrevivente. Ciclo *Build Up* → *Sustain Peak* (3–5 s) → *Peak Fade* → *Relax* (30–45 s, sem vagas nem especiais). Os errantes de uma área **zeram-se quando ela fica à vista**: nunca nasce nada à frente do jogador. Os bosses ficam fora da modulação. | A emboscada não pode nascer colada a quem joga. A noite funda precisa de uma calma depois (o jogo já a tem, Q-126). |
| **Mindustry** (`Waves.java`) | Cada espécie entra com **uma unidade** na primeira vaga dela (`unitAmount = f == start ? 1 : …`) e cresce a partir daí. Os níveis espaçam-se 8–16 vagas, com um grupo de transição que se sobrepõe. | A estreia: uma espécie nova vem em pequeno número (três, como o Rastejante na noite 1) e cresce a partir daí. |
| **Dome Keeper** (wiki, notas de versão) | A força da vaga é um peso (ciclo, recursos minados, dificuldade). Cada monstro tem um peso mínimo para aparecer, e o gerador escolhe **ao acaso** até a soma chegar perto do peso da vaga. | Orçamento por massa (o que a Podridão já é), com mistura em vez de «tudo do mais caro». |
| **Equilíbrio de *tower defense*** (Game Developer, *Balance in TD games*) | A primeira vaga tem de caber no que as primeiras torres matam (`(8+N)·L ≥ h·N`, N < 8 na vaga 1). O que se ganha numa vaga tem de pagar a defesa da seguinte. A vida cresce uns 8–12% por vaga e o número mais devagar. | A ameaça de uma noite mede-se contra a defesa que o jogador pode ter nessa noite, e não contra a de outro jogo. |
| **Curva em dente de serra** (DEV, *Curves are the real game design language*; Joys of Small Game Development) | A dificuldade sobe, alivia quando entra uma mecânica nova, e volta a subir mais alto. Crescimento suave (raiz quadrada) depois de um começo. | Quando uma espécie abre, a noite não deve dar um salto: a estreia é o dente. |
| **Introduzir em isolamento** (Game Developer, *Pacing and sequencing combat encounters*; GDKeys) | O inimigo novo aparece sozinho antes de vir em grupo e misturado. | Os primeiros Alados e os primeiros Brutos vêm em pequeno número, misturados com o que já se conhece. |
| ***Feedback loops*** (Bugnet, GameDev Gems, Randy Gaul) | A retroação positiva sem travão faz a espiral da morte: quem perde passa a perder mais. A negativa (o *rubber banding*) dá folga a quem vai atrás. | As árvores dos mortos são retroação positiva (morrer → mais massa → morrer mais). Precisa de uma janela de aprendizagem. |
| **They Are Billions** (Steam) | A queixa mais repetida é o salto da última vaga (5, 12, 18, 24, 30, **140**). | Evitar degraus: uma noite não deve valer o dobro da anterior sem aviso. |

## 5. O diagnóstico

| # | O problema | Evidência | Princípio que fere |
|---|---|---|---|
| P1 | O escuro traz até seis Rastejantes **de graça** e **colados ao rei** desde a noite 1 | Medido: 9 em vez de 3 na noite 1 | §05/§51 (a Podridão é a única fonte, com orçamento); §25 (a noite 1 «é ganha de certeza»); L4D (nunca nascer à vista) |
| P2 | O que se escreve de dia pesa inteiro desde a noite 1 | Medido: a noite 3 a 89 em vez de 59 | Q-151 e Q-157 do dono: «mais brando até a noite 5»; retroação positiva |
| P3 | Uma espécie nova chega em monocultura | Medido: noite 4 só Alados; ROT_BY_DAY: 7 Cavadores na 10, 7 Arietes na 14 | Introduzir em isolamento; a estreia do Mindustry e do Kingdom |
| P4 | O Alado não se deixa bater pelo rei nem pelos lanceiros | Confirmado nos dados: o monarca e o lanceiro não têm `AERIAL` em `targets_bands`; medido: o rei cai na noite 4 | Com seis ou sete, a noite 4 é uma noite que só os arqueiros podem jogar |
| P5 | A mancha invoca por cima das muralhas | Medido no cenário do §66: Rastejantes nascidos a 1700–2160 px, à volta do núcleo em 1920 | ADR 0070 (a noite vem de fora do reino); Kingdom (a Greed nasce dos portais) |
| P6 | A curva das noites 2 a 6 cresce ~50% por noite | O calendário: 24, 37, 59, 90, 130, 192 (funda) | TD: 8–12% por vaga; o reino começa numa Clareira (ADR 0059) com a Última Carroça (ADR 0065) |
| P7 | A primeira noite funda (×1,3) é a 6, logo a seguir ao fim da rampa | Q-126 | L4D: o pico vem depois de um *build up*; a 1.ª Lua de Sangue do Kingdom só vem semanas depois |

## 6. O que foi feito (ADR 0071)

1. **A estreia (Q-240, `debut_step = 3`).** Numa noite, uma espécie que abriu vem no máximo `debut_step × n` vezes,
   sendo n a noite dela: três, seis, nove — como o Rastejante estreia na noite 1. A da noite 1 não estreia. A massa que
   sobra paga as mais baratas, por isso a noite não fica mais leve: fica **misturada**. Três é o passo mais pequeno que
   mantém os cinco testes do §66: com 1 ou 2, recusar todas as ofertas já não derrubava a defesa do décimo dia (a Q-101).
2. **A regra num sítio só (`RotPick`).** A escolha, a estreia e a porta; o `RotSystem.afford(dados, dia)` e a
   `NightWatch.pay` pagam o bicho que a Podridão levanta e quem o escuro traz pelas mesmas regras.
3. **A porta.** Quem a mancha invoca depois de passar a muralha mais exterior do lado dela nasce à porta dessa muralha,
   do lado de fora. A massa gasta-se igual.
4. **A rampa pesa a noite inteira (Q-239).** As árvores, as recusas e o Lume entram com o `t` da rampa: nada na noite
   1, um quarto na 2, metade na 3, três quartos na 4, inteiro da 5 em diante. A tabela da §74 não muda.
5. **O escuro paga-se e espera (Q-241).** Quem o escuro traz sai da massa da mancha — explorar de noite deixa de
   **acrescentar** criaturas e passa a **puxá-las** para o rei; antes da noite 3 não traz ninguém; e nasce a 180 px, e
   não a 90, que era dentro do corpo de um Rastejante (112 px, Q-219).
6. **O instrumento.** A `tools/noites.gd` (`make noites`) e o `ROT_BY_DAY.md`, que diz **o que** cada noite paga.

### A composição, noite a noite (o piso da §74, sem árvores nem recusas)

| noite | massa | antes | depois |
|---|---|---|---|
| 1 | 24 | Rastejante 3 | Rastejante 3 |
| 3 | 59 | Rastejante 7 | Rastejante 7 |
| 4 | 90 | **Alado 6** | Alado 3 · Rastejante 6 |
| 5 | 130 | **Alado 9** | Alado 6 · Rastejante 5 |
| 6 (funda) | 192 | Rastejante 1 · **Alado 13** | Alado 9 · Rastejante 8 |
| 7 (calma) | 100 | Rastejante 1 · **Bruto 4** | Bruto 3 · Alado 2 |
| 8 | 184 | Rastejante 1 · **Bruto 8** | Bruto 6 · Alado 3 · Rastejante 1 |
| 10 | 220 | Rastejante 1 · **Cavador 7** | Cavador 3 · Bruto 5 · Alado 1 |
| 14 | 369 | Cavador 1 · **Ariete 7** | Ariete 3 · Cavador 7 · Alado 1 |

## 7. Depois (medido)

- **A noite 1 é a do §25, esteja o rei onde estiver.** `tests/escuro_pago_test.gd` corre a partida inteira com o rei
  no escuro: na `main`, **nove** criaturas; agora, **três**.
- **Ninguém nasce dentro das muralhas de pé** (`tests/porta_da_noite_test.gd`), e os cinco testes do §66 passam: a
  defesa do décimo dia aguenta dez noites com o castelo inteiro; recusar todas as ofertas derruba-a; a receita do §07
  cai; sem torres cai; o núcleo pode ser atacado.
- **O piloto, 15 partidas de 12 dias** (cinco sementes × `casa`, `cauteloso`, `fora`): ver a tabela abaixo. Com o rei
  `fora`, a partida dura mais (o escuro já não o mata na noite 2); com o rei à porta do núcleo, a noite 4 continua a
  matá-lo, agora com Rastejantes. Em todas as variantes o piloto acaba entre o dia 2 e o 5, porque a defesa dele não
  cresce — a mesma conclusão com a rampa até à noite 7 (média 3,9 dias) ou 9 (4,0).

## 8. O que fica para decidires

- **Q-242 — a curva das noites 2 a 6.** A proposta, se o teu *playtest* o pedir, é `ramp_nights` 5 → 7. Muda uma frase
  e uma linha da tabela da §74; não foi aplicada.
- **Q-243 — a primeira noite funda.** Proposta: a primeira na noite 12, e daí de seis em seis.
- **Fora desta tarefa, e anotado:** o rei não chega aos Alados (P4) — é uma escolha de arquétipo (§08); o guardião de
  masmorra é um Cavador desde o dia 1 para quem desce; e a noite de cada povoado das terras é uma mancha à parte, só
  contra ele.

## Fontes

- [Greedling — Kingdom Wiki](https://kingdomthegame.fandom.com/wiki/Greedling) · [Counterattack wave](https://kingdomthegame.fandom.com/wiki/Counterattack_wave) · [Blood Moon](https://kingdomthegame.fandom.com/wiki/Blood_Moon) · [Waves](https://kingdomthegame.fandom.com/wiki/Waves) · [Portal](https://kingdomthegame.fandom.com/wiki/Portal) · [Breeder](https://kingdomthegame.fandom.com/wiki/Breeder)
- [Day count and difficulty in the main campaign — Kingdom Two Crowns, Steam](https://steamcommunity.com/app/701160/discussions/0/4477100383818435568/)
- [The AI Systems of Left 4 Dead — Michael Booth, Valve, GDC 2009](https://steamcdn-a.akamaihd.net/apps/valve/2009/ai_systems_of_l4d_mike_booth.pdf) · [The Director — Left 4 Dead Wiki](https://left4dead.fandom.com/wiki/The_Director)
- [Mindustry — `Waves.java`](https://github.com/Anuken/Mindustry/blob/master/core/src/mindustry/game/Waves.java)
- [Version History — Dome Keeper Wiki](https://domekeeper.wiki.gg/wiki/Version_History) · [Relic Hunt — Dome Keeper Wiki](https://domekeeper.wiki.gg/wiki/Relic_Hunt)
- [Balance in TD games — Game Developer](https://www.gamedeveloper.com/design/balance-in-td-games)
- [Curves are the real game design language — DEV Community](https://dev.to/sam_novak_574b07811e18495/curves-are-the-real-game-design-language-and-most-broken-games-got-the-curve-wrong-4dg1) · [Rising Difficulty Curve — Joys of Small Game Development](https://abagames.github.io/joys-of-small-game-development-en/difficulty/curve.html)
- [The Art and Science of Pacing and Sequencing Combat Encounters — Game Developer](https://www.gamedeveloper.com/design/the-art-and-science-of-pacing-and-sequencing-combat-encounters) · [Keys to Rational Enemy Design — GDKeys](https://gdkeys.com/keys-to-rational-enemy-design/)
- [Positive and Negative Feedback Loops in Game Design — Bugnet](https://bugnet.io/blog/positive-and-negative-feedback-loops-in-game-design) · [Why You NEED To Understand Feedback Loops — GameDev Gems](https://gamedevgems.com/why-you-need-to-understand-feedback-loops/)
- [Why final wave so inbalanced? — They Are Billions, Steam](https://steamcommunity.com/app/644930/discussions/0/1620599015905340861/)
- [Thronefall — Gameluster review](https://gameluster.com/thronefall-review-holding-on-for-one-last-night/) · [How to git gud at Thronefall — Steam guide](https://steamcommunity.com/sharedfiles/filedetails/?id=3109796946)
