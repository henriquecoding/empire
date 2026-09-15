# ADR 0018 — Três epílogos, avaliados por precedência escrita

- Estado: aceite
- Data: 2026-09-14
- Secção do dossiê: §15, §17, §18, §45, §75, §78, §79

## Contexto
A §17 prometia dois epílogos e não dizia como se escolhem. A Parte XIII dá-lhes duas entradas — a Dívida da Candeia
(§75) e as seis decisões da Colheita (§78) — e três condições que se podem sobrepor. Sem uma ordem escrita, dois
programadores dão dois finais diferentes ao mesmo estado.

## Decisão
Avalia-se de cima para baixo e para na primeira que bater:

1. `debt >= 12` → **Domínio**. A dívida manda sobre tudo o resto, mesmo com os seis povos soltos.
2. `peoples_kept >= 4` → **Domínio**.
3. `debt <= 3` e `peoples_released >= 4` → **União**.
4. tudo o resto → **O Turno**.

O Turno não é o final de consolação: é o estado mais provável de uma primeira campanha, e a campanha seguinte começa
com a Dívida como termo permanente na massa e com as seis decisões como estado inicial do mundo (Q-046).
Por baixo dos três está a alteração de lore: A Podridão não é o que sobra das seis partes separadas — é o zelador
que ficou de turno demasiado tempo, com uma candeia que tem de arder. A Dívida é a candidatura ao lugar, e o
jogador esteve a preenchê-la desde o dia 3. Dito uma vez, no diário 12, e nunca repetido nem explicado.

## Alternativas consideradas
Dois epílogos só, como a §17: o estado mais provável de uma primeira campanha não batia em nenhum dos dois, e o
jogo teria de forçar um. Rejeitado.
Ordem por "condição mais específica primeiro": não é ordem nenhuma — é uma regra que cada leitor interpreta.

## Consequências
Quatro limiares em `rot.csv` (`union_debt_max`, `union_peoples_released`, `dominion_debt_min`,
`dominion_peoples_kept`) e três contadores no estado autoritativo (§45): `debt_lantern`, `peoples_released`,
`peoples_kept`. `journals.csv` ganha ato, origem, objeto físico e o que cada diário deixa perceber.
Os testes D-12 e D-13 guardam a alcançabilidade dos doze diários em mil sementes e o determinismo da precedência.
Reverter obriga a reescrever a §79 inteira e a decidir o que fazer com o estado guardado d'O Turno.
