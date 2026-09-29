# ADR 0031 — Dois povos novos: o gelo e o pântano

- Estado: aceite (fora da campanha até à Q-152)
- Data: 2026-09-28
- Secção do dossiê: §04, §10, §12

## Contexto
A Q-010 propunha tirar a *"paliçada de gelo"* do §10, porque nenhum povo é de gelo; a Q-013, que a libélula da
*"Fortaleza do pântano"* viesse da Horta. O dono respondeu às duas com povos: *"gosto da ideia de ter um povo do gelo
com características únicas"* e *"quero que haja também a população do pântano"*.

## Decisão
**Entram nos dados dois povos, a Geada (gelo, bioma `glacier`) e o Paul (pântano, bioma `marsh`)**, com arquitectura,
marco, material de muralha, unidade própria, canção e modificadores propostos (tudo em `_proposed`):
- Geada — o frio guarda (nada estraga, `spoil_mult` 0), o chão gelado abranda a Podridão 15%; a Guarda do Gelo
  abranda quem golpeia. A paliçada de gelo do §10 é deles.
- Paul — o lodo prende (`mire`), as montarias recuperam ao dobro; o Caçador do Caniçal atira de zarabatana e chega
  às libélulas. A libélula-montaria vem deles.
**Ficam fora da campanha** (`biomes.csv`, `in_campaign` falso) até o dono decidir como a campanha cresce (Q-152).

## Alternativas consideradas
Pô-los já na campanha: passava a oito regiões e mudava os limiares da União e do Domínio (4 de 6) e a conta dos
capítulos sem ninguém o ter decidido.

## Consequências
A classe de cada um é provisória. Os modificadores não têm sistema que os leia até à Fase 7, como os dos outros
seis povos.
