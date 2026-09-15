# ADR 0019 — Nenhum sistema da Parte XIII entra sem o teste que o guarda

- Estado: aceite
- Data: 2026-09-14
- Secção do dossiê: §31, §37, §84

## Contexto
A §31 diz porque é que os testes existem neste projeto: sem eles não se consegue rever o que a IA escreve, e ao fim
de duas semanas deixa-se de tentar. Nove sistemas novos sem testes de design são nove sistemas que se desafinam
sozinhos no mês oito e ninguém dá por isso.

## Decisão
Catorze testes de design (D-01 a D-14), em `tests/parte_xiii_rot_test.gd` (§74, §75) e
`tests/parte_xiii_mundo_test.gd` (§76, §77, §79, §84), cada um agarrado à regra que guarda e à secção de onde ela
vem. São dois ficheiros e não um porque o portão das 250 linhas do §28 vale também para os testes. Os que se podem medir só com os dados correm já contra `data/source/` e `data/**/*.tres`; os que
precisam de sistemas que ainda não existem ficam saltados **com a razão escrita no próprio teste** e o nome do
sistema que falta — nunca comentados, nunca apagados.
Seis linhas novas entram no registo de risco da §37, cada uma com sinal de alarme e plano B.
O save dos sistemas novos só contém tipos base, como a ADR 0007 exige: `int`, `PackedInt32Array`,
`PackedFloat32Array`, `PackedStringArray` e `Dictionary` de `String` para `int`. Nada de `Resource`, nada de
caminhos que o motor possa carregar. Cabe em cerca de dois quilobytes.

## Alternativas consideradas
Escrever os testes depois dos sistemas: é exatamente o que a §31 diz que não acontece nunca. Rejeitado.
Apagar os testes que ainda não correm: perde-se a lista, e a lista é metade do valor — um teste saltado com razão
escrita é documentação executável do que falta.

## Consequências
A suite da Parte XIII entra no `run_tests.sh` com as outras — 43 casos no total, 37 a correr e 6 saltados. O D-12 é o único caro — mil sementes
a correr só o gerador de mundo e a atribuição de diários, sem simulação e sem cenas — e é a única maneira honesta
de afirmar que uma partida vê sempre os doze diários.
Fica escrito o que nenhum teste apanha: prosa morna. Doze diários de setenta palavras, doze frases de oferta de
oito, nove títulos e dez leis. O único controlo é o espécime do diário 9 na §79.
