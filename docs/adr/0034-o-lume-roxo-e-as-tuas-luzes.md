# ADR 0034 — O Lume roxo fica na base, e as tuas luzes afastam a Podridão

- Estado: aceite
- Data: 2026-09-29
- Secção do dossiê: §74, §80, §73, §05, §83
- Actualiza: ADR 0011 (a regra das duas exceções)

## Contexto
O §74 punha a candeia no meio da mancha, a atravessar o campo: "a coisa que te vem matar é a única que traz luz".
Copiava a lanterna da Besta ao pé da letra e deitava fora o que *Over the Garden Wall* diz dela — que a lanterna é a
vida da Besta, que arde com o que ela tira às vítimas, e que é a luz que decide o fim. O dono (29/09/2026): *"em Over
the Garden Wall o inimigo foge da luz, os meus personagens deveriam levar coisas que emitem luz para afastar ou
atrasar a podridão"*; e depois: *"como a Besta perante a lanterna apagada […] dependendo do tipo de construção e do
nível do inimigo recua, mas se for muito forte só abranda; essa lanterna que contém a podridão fica na base onde
costumam nascer, similar a Kingdom; tudo aquilo que a podridão consome alimenta ela, mas a luz dela é em roxo […] só
aquele fogo consegue aquecer eles"*.

## Decisão
1. **O Lume fica na base.** A candeia passa a chamar-se Lume e arde na borda de onde a mancha nasce (`trail_from`),
   como os portais do Kingdom. Não se mexe. A mancha que atravessa o campo é escuridão. O raio (150 + 4 × dia, teto
   260) e o mostrador da Dívida (§75) ficam iguais.
2. **O Lume é roxo; o teu fogo é âmbar.** As três paragens do §80 passam a violeta (`lantern_tint*`: `#E9D5FF`,
   `#C084FC`, `#8B5CF6`); o âmbar antigo fica para as tuas luzes (`fire_tint*`). A regra das duas exceções (ADR
   0011) passa a ler-se "roxo é dela, âmbar é teu". O Lume continua a dominar o ecrã (Q-078, `candeia_test`).
3. **O que ela consome alimenta o Lume.** Moedas e sacrifícios dados, o que os Ladrões roubam: cada unidade é
   combustível (`DebtLedger.lume_fuel`, gravado) e vale `lume_mass_per_fuel` (0,25) de massa nas noites seguintes.
   Alimentá-la compra esta noite e paga-se depois — o preço da Besta.
4. **As tuas luzes fazem recuar ou abrandar, conforme a obra e o nível.** Cada luz de pé na superfície guarda um
   troço de chão com `repel_mass` (a massa da criatura mais cara que faz recuar) e `rot_slow` (quanto abranda as
   outras). O nível de uma criatura é a massa dela. Fogueira: recua até 8, abranda 25%. Farol: recua até 30,
   abranda 30%. Archote do rei: recua até 8 (`torch_repel_mass`). Quem recua anda para trás `light_recoil_s` (3 s) e
   volta a tentar. `LightWard`, `CreatureSystem.set_lights()`.
5. **Apagar o Lume é o fim do ciclo, e fica em aberto** (Q-156). Nada no jogo o faz ainda.

## Alternativas consideradas
Pôr o Lume no meio da mancha e só mudar-lhe a cor: continuava a ser ela a trazer a luz. Fazer a luz afastar tudo por
igual: um farol tornava as noites inteiras triviais, e o dono pediu que o forte só abrande.

## Consequências
Os números novos são proposta (`_proposed`). O aviso da tarde (Q-125) continua a acender-se no horizonte da borda
anunciada — agora é, literalmente, o Lume a acender-se. Uma criatura só se vê dentro de uma luz: as tuas ou o Lume.
