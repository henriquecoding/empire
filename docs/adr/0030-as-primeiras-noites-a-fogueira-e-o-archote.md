# ADR 0030 — As primeiras noites em rampa, a fogueira e o archote

- Estado: aceite
- Data: 2026-09-28
- Secção do dossiê: §05, §07, §25, §74, §80

## Contexto
O §25 diz *"Noite 1: três Rastejantes"* e a massa da §74 dava sete (Q-068); o dono confirmou os três e pediu que o
jogo *"comece com algo leve e vá intensificando"* (Q-017) e *"seja cadenciado como o Kingdom: New Lands, que não
acabe cedo"* (Q-047). Aprovou a fogueira como edifício de 3 moedas com o abrandamento do barril, e acrescentou um
item que se leva para explorar, com limite de uso, sem o qual a noite fora das muralhas é muito perigosa (Q-029).

## Decisão
1. **A massa do calendário tem rampa**: a noite 1 vale `opening_mass` (24, os três Rastejantes) e sobe em linha
   recta até à fórmula da §74, que manda por inteiro a partir da noite `ramp_nights` (5). O resto dos termos (árvores,
   recusas, fortalezas, o ritmo da Q-126) fica como estava. `RotProfile.calendar_mass()`.
2. **Os postos de muro disparam com a certeza da torre** (a segunda metade da Q-017).
3. **A fogueira** (`campfire`) abranda a mancha como o barril, e a luz dela é mais fraca do que a candeia. Fogueiras
   e barris passam mesmo a abrandar a Podridão (`FireZones`) — o §05 dizia-o e nada o fazia.
4. **O archote**: compra-se numa fogueira com o Verbo 1, levam-se dois, acende-se sozinho quando o rei entra no
   escuro de noite e arde 60 s. No escuro — fora do núcleo, das muralhas de pé e da luz das tuas obras — e sem
   archote, de 8 em 8 s nasce um Rastejante ao lado do rei, até seis por noite. `Torchlight`, `DarkWatch`.

## Alternativas consideradas
Descer a `mass_base` da §74: mudava todas as noites, e o dono só pediu leveza no princípio. Um teto de três
criaturas na noite 1: resolvia a noite 1 e deixava o salto para sete na noite 2.

## Consequências
Os números novos estão em `_proposed` no `rot.csv`. A noite 5 do §07 ganha-se sem mortes com a torre — as 1–2 mortes
que o §07 pede ficaram na Q-151.
