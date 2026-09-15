# ADR 0015 — Ninguém tem nome até merecer um, e o império segura nove

- Estado: aceite
- Data: 2026-09-14
- Secção do dossiê: §04, §07, §16, §50, §52, §58, §76, §81

## Contexto
A §04 promete desde a v3: "não são unidade tipo 3 — são razões para doer quando morrem, e a tua morte é
permanente." Nada no dossiê implementava isso. Cinquenta lanceiros iguais a morrer não doem; o que dói é aquele
lanceiro, e a diferença entre um e outro não é arte nem IA.

## Decisão
Um nome ganha-se por feito registado, nunca por sobrevivência sozinha e nunca por escolha do jogador. São nove
feitos (`titles.csv`), todos medidos por condições que o `CombatSystem` e o `UnitSystem` já observam (§50, §52).
A nomeação acontece na alvorada. O império segura nove nomes ao mesmo tempo: cumprido um décimo feito, a tropa fica
à espera, um passo à frente das outras, até abrir vaga. Um título é único enquanto o dono viver; morto o dono, fica
de luto três dias e volta com ordinal — O Segundo Que Ficou, depois o Terceiro.
A cerimónia é a encomendação das almas: duas vozes, sem instrumentos, oito segundos, na alvorada, e a mesma melodia
para quem foi nomeado e para quem criou raiz. O jogo não distingue celebração de luto.

## Alternativas consideradas
Teto que cresce com o império (Q-041): o nome deixa de significar alguma coisa. Rejeitado — a escassez é o valor.
Nome escolhido pelo jogador: transforma o sistema num editor de personagens e apaga o registo de feitos.

## Consequências
`titles.csv` com nove linhas, um campo `title_id` no estado da unidade, um sprite de fita por cor no slot *overlay*
que a §58 já tem — zero sprites novos de corpo. Um Amargueiro nomeado passa a valer 45 de massa em vez de 22, rende
5 Lenhos em vez de 1 a 3, e serrá-lo custa 1 ponto de moral durante 2 dias: ter nomes é ficar mais forte e mais
frágil ao mesmo tempo. Os testes D-07 e D-08 guardam o teto e o luto.
Nenhuma outra secção da Parte XIII depende desta — se o calendário apertar, entra na Fase 4 sem partir nada.
