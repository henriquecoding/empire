# Os inimigos e a curva da noite — pesquisa, medição e desenho (ADR 0071)

_5 de outubro de 2026. Pedido do dono: «Quero que faça uma densa pesquisa na web e no meu projeto atual para tornar os
inimigos e os sistemas de inimigos bem mais fundamentados e bem implementados no meu jogo, que a dificuldade seja natural
e faça sentido, na primeira noite está aparecendo diversos inimigos e inimigos muito fortes, isso tem que ser
balanceado, analise profundamente o que já existe e como pode refinar isso»._

**Rótulos de evidência** (os das auditorias anteriores): **Medido** (a sonda ou a suíte correu), **Confirmado no
código** (caminho rastreado, sem execução), **Proposta** (precisa de decisão do dono).

## 1. A resposta curta

A noite 1 não trazia os três Rastejantes do §25 a quem saía da luz: trazia **nove** (medido na `main` em `417369e`,
com a Última Carroça da ADR 0065), e com o rei a 400 px do núcleo a partida acabava nessa noite. Seis vinham do escuro, **de graça e colados ao rei**. Além disso, três regras empurravam a curva contra quem
está a aprender:

- **O escuro não pagava.** Era a única porta de criaturas fora da massa da Podridão, e abria logo na noite 1.
- **O que se escreve de dia pesava inteiro desde a primeira noite.** A rampa das primeiras noites só valia para o
  calendário.
- **Uma espécie nova vinha toda de uma vez.** A regra «a mais cara que cabe» fazia a noite 4 ser nove Alados e nenhum
  Rastejante, e a noite 7 sete Brutos.

A ADR 0071 corrige as três com regras que o jogo já tinha (a §05, a Q-151 e a §51), e não com números à mão. Fica uma
pergunta maior, que é tua: a curva das noites 2 a 6 foi afinada (Q-157, 30/09) quando o reino começava num castelo de
pé, antes da Clareira (ADR 0059) e da Última Carroça (ADR 0065), e continua íngreme para o reino que agora se tem
nessas noites (secção 7, Q-242).

## 2. O que existe: todas as portas por onde entra uma criatura

**Confirmado no código.** A §05 e a §51 dizem que a Podridão é a *única* fonte de criaturas e que gasta um orçamento
(a massa). Na `main` havia seis portas:

| Porta | Onde | Paga da massa? | Desde | Notas |
|---|---|---|---|---|
| A mancha invoca | `RotSystem.tick` | sim | noite 1 | «a mais cara que cabe», a cada 4–7 s |
| O bicho apanhado levanta-se | `HuntWatch._paid` | sim | noite 1 | coelho, faisão e raposa → Rastejante; veado, javali e cervo → Bruto (dia 7) |
| **O escuro à volta do rei** | `DarkWatch.tick` | **não** | **noite 1** | de 8 em 8 s, até 6 por noite, a **90 px** do rei |
| A segunda mancha | `RiftWatch` | sim (metade) | noite 12 | metade da massa vai para o outro lado |
| A noite de um povoado das terras | `SettlementWatch.night` | outra mancha, só para ele | noite 1 | Rastejantes a 360 px do povoado, até 6, só contra ele |
| O guardião de masmorra | `DungeonWatch.author` | não | quando o segmento nasce | um Cavador parado no subsolo, guarda o saque |

E a massa de cada noite (§74) é o calendário (com a rampa da Q-017 nas cinco primeiras) **mais** o que se escreve de
dia: +22 por árvore de pé (+45 se nomeada), +8 por recusa nas últimas cinco noites (até +40), e o que o Lume comeu.

## 3. A medição: a sonda das noites

**Medido.** A `tools/noites.gd` (nova; `make noites`) corre a partida inteira com o piloto da vistoria e diz, noite a
noite, quantas criaturas vieram, de que espécie e por que porta, a massa com que a noite nasceu, o pico de criaturas
vivas, o dano no rei e as baixas. O rei passa a noite onde a política manda: `casa` (na borda do núcleo, do lado da
mancha), `cauteloso` (do outro lado), `fora` (a 400 px, como quem defende a estacaria ou explora) e `longe` (1400 px).
Nas políticas `fora` e `longe` o rei bate no que lhe chega perto, como quem joga.

### Antes (a `main` em `247d5a0`)

Semente 20260916, rei `fora`:

| noite | massa | da mancha | do escuro | pico | dano no rei |
|---|---|---|---|---|---|
| 1 | 24 | Rastejante 3 | **Rastejante 6** | 5 | **52 de 60** |

Com o rei `longe`, a mesma noite 1: 3 + 6 = **nove** Rastejantes; perde-se uma tropa e a partida acaba ao dia 2.

Semente 20260916, rei em `casa` (a noite como a §74 a pesa, com o piloto a deixar mortos lá fora e a recusar ofertas):

| noite | massa | calendário | da mancha |
|---|---|---|---|
| 3 | **89** | 59 | Rastejante 11 |
| 4 | 131 | 90 | **Alado 9** |
| 5 | 189 | 130 | **Alado 13** |
| 6 (funda) | 283 | 192 | Rastejante 1 · **Alado 19** |
| 7 (calma) | 162 | 100 | Rastejante 1 · **Bruto 7** |
| 8 | 272 | 184 | **Bruto 12** |

Lê-se assim:

- **A noite 3 já pesava 51% acima do calendário.** Uma árvore (+22) e uma recusa (+8) entram inteiras na noite em que
  o jogador ainda está a aprender o que é uma árvore.
- **Cada espécie nova chega em monocultura.** A noite em que o Alado abre é só Alados; a do Bruto, só Brutos. Nenhuma
  noite ensina uma criatura antes de a multiplicar.

## 4. A pesquisa

| Fonte | O que faz | O que serve aqui |
|---|---|---|
| **Kingdom Two Crowns** (wiki e Steam) | A primeira vaga de retaliação tem sempre só uns poucos Greedlings. A Greed nasce **só dos portais**, à vista e de lados conhecidos. Os tipos novos entram aos poucos: a 1.ª Lua de Sangue só traz Greedlings, a 3.ª traz Floaters, a 5.ª Breeders e Crown Stealers. A força cresce com o dia global e com os portais destruídos. | Começar com poucos; uma criatura nova entra em pequeno número; as criaturas vêm de onde se sabe. |
| **Left 4 Dead — AI Director** (Mike Booth, GDC 2009) | Mede a intensidade de cada sobrevivente. Ciclo *Build Up* → *Sustain Peak* (3–5 s) → *Peak Fade* → *Relax* (30–45 s, sem vagas nem especiais). Os errantes de uma área **zeram-se quando ela fica à vista**: nunca nasce nada à frente do jogador. Os bosses ficam fora da modulação. | A emboscada não pode nascer colada a quem joga. A noite funda precisa de uma calma depois (o jogo já a tem, Q-126). |
| **Mindustry** (`Waves.java`) | Cada espécie entra com **uma unidade** na primeira vaga dela (`unitAmount = f == start ? 1 : …`) e cresce a partir daí. Os níveis espaçam-se 8–16 vagas, com um grupo de transição que se sobrepõe. | A estreia: o primeiro de uma espécie é um, e depois mais um por noite. |
| **Dome Keeper** (wiki, notas de versão) | A força da vaga é um peso (ciclo, recursos minados, dificuldade). Cada monstro tem um peso mínimo para aparecer, e o gerador escolhe **ao acaso** até a soma chegar perto do peso da vaga. | Orçamento por massa (o que a Podridão já é), com mistura em vez de «tudo do mais caro». |
| **Equilíbrio de *tower defense*** (Game Developer, *Balance in TD games*) | A primeira vaga tem de caber no que as primeiras torres matam (`(8+N)·L ≥ h·N`, N < 8 na vaga 1). O que se ganha numa vaga tem de pagar a defesa da seguinte. A vida cresce uns 8–12% por vaga e o número mais devagar. | A ameaça de uma noite mede-se contra a defesa que o jogador pode ter nessa noite, e não contra a de outro jogo. |
| **Curva em dente de serra** (DEV, *Curves are the real game design language*; Joys of Small Game Development) | A dificuldade sobe, alivia quando entra uma mecânica nova, e volta a subir mais alto. Crescimento suave (raiz quadrada) depois de um começo. | Quando uma espécie abre, a noite não deve dar um salto: a estreia é o dente. |
| **Introduzir em isolamento** (Game Developer, *Pacing and sequencing combat encounters*; GDKeys) | O inimigo novo aparece sozinho antes de vir em grupo e misturado. | O primeiro Alado e o primeiro Bruto vêm sozinhos. |
| ***Feedback loops*** (Bugnet, GameDev Gems, Randy Gaul) | A retroação positiva sem travão faz a espiral da morte: quem perde passa a perder mais. A negativa (o *rubber banding*) dá folga a quem vai atrás. | As árvores dos mortos são retroação positiva (morrer → mais massa → morrer mais). Precisa de uma janela de aprendizagem. |
| **They Are Billions** (Steam) | A queixa mais repetida é o salto da última vaga (5, 12, 18, 24, 30, **140**). | Evitar degraus: uma noite não deve valer o dobro da anterior sem aviso. |

## 5. O diagnóstico

| # | O problema | Evidência | Princípio que fere |
|---|---|---|---|
| P1 | O escuro traz até seis Rastejantes **de graça** e **colados ao rei** desde a noite 1 | Medido: 9 em vez de 3 na noite 1; a partida acaba nessa noite | §05/§51 (a Podridão é a única fonte, com orçamento); §25 (a noite 1 «é ganha de certeza»); L4D (nunca nascer à vista) |
| P2 | O que se escreve de dia pesa inteiro desde a noite 1 | Medido: a noite 3 a 89 em vez de 59 | Q-151 e Q-157 do dono: «mais brando até a noite 5»; retroação positiva |
| P3 | Uma espécie nova chega em monocultura | Medido: noite 4 nove Alados, noite 7 sete Brutos | Introduzir em isolamento; a estreia do Mindustry e do Kingdom |
| P4 | O Alado da noite 4 não se deixa bater pelo rei nem pelos lanceiros | Confirmado nos dados: o monarca e o lanceiro não têm `AERIAL` em `targets_bands` | Com nove, a noite 4 era uma noite que só três arqueiros podiam jogar |
| P5 | A curva das noites 2 a 6 cresce ~50% por noite | O calendário: 24, 37, 59, 90, 130, 192 (funda) | TD: 8–12% por vaga; o reino começa numa Clareira (ADR 0059) e com a Última Carroça (ADR 0065) |
| P6 | A primeira noite funda (×1,3) é a 6, logo a seguir ao fim da rampa | Q-126 | L4D: o pico vem depois de um *build up*, e a 1.ª Lua de Sangue do Kingdom só vem semanas depois |

## 6. O que foi feito (ADR 0071)

1. **A estreia (Q-240).** Numa noite, uma espécie que abriu vem no máximo `debut_step × n` vezes, sendo n a noite dela.
   Com `debut_step = 1` são 1, 2, 3… A da noite 1 (o Rastejante) não estreia. A massa que sobra paga as mais baratas,
   por isso a noite não fica mais leve: fica **misturada**. A regra vive num sítio só (`RotPick`) e vale para tudo o que
   a Podridão paga: o que invoca, o bicho que levanta e quem o escuro traz.
2. **A rampa pesa a noite inteira (Q-239).** As árvores, as recusas e o Lume entram na massa com o mesmo `t` da rampa do
   calendário: nada na noite 1, um quarto na 2, metade na 3, três quartos na 4, inteiro da 5 em diante. A tabela da
   §74 (noites 5, 10 e 20) não muda.
3. **O escuro paga-se e espera (Q-241).**
   - Quem o escuro traz sai da massa da mancha (`NightWatch.pay`), como o bicho que ela levanta. Explorar de noite
     deixa de **acrescentar** criaturas e passa a **puxá-las** para o rei.
   - O escuro não traz ninguém antes da noite `dark_from_night` (3). As duas primeiras noites ensinam a noite e o
     archote antes de o escuro morder.
   - A emboscada nasce a `dark_ambush_px` 180 em vez de 90. A 90 px nascia dentro do corpo de um Rastejante (112 px,
     Q-219); a 180 px há três a quatro segundos para reagir.
4. **O instrumento.** A `tools/noites.gd` (`make noites`) fica, como o `night_test`: é a tabela que se olha antes e
   depois de mexer num número do `rot.csv`. O `ROT_BY_DAY.md` passa a dizer **o que** cada noite paga, espécie a
   espécie, e não só quantas.

## 7. Depois (medido)

_Ver a secção 7 do relatório final — preenchida com a comparação._

## 8. O que fica para decidires

Ver as Q-242 e Q-243 em `docs/QUESTIONS.md`.

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
