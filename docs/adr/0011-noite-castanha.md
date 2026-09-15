# ADR 0011 — A noite é castanha, e o preto entra na paleta

- Estado: aceite
- Data: 2026-09-13
- Secção do dossiê: §05, §11, §22, §80

## Contexto
A §05 mandava "Azul profundo" na luz ambiente da noite. A paleta do projeto (§22) tem 112 cores: 30 de madeira e
terra, 23 neutras, 21 de estuque — e 9 de azul-petróleo. A noite usava a família de que há menos, o que obriga a
inventar cor que não é do projeto. Os cartazes de referência que o autor juntou ao pedido são a composição
contrária: ocre queimado sem gradiente, duas massas pretas sem detalhe, figuras em contraluz, uma luz quente ao
centro, zero azul. A §11 já tinha diagnosticado o problema como "falta de um plano no meio", não falta de talento.

## Decisão
A noite é castanha: matiz 32°, saturação 0,22, valor 0,16, com chão de valor em 0,11. O preto entra na paleta como
cor de preenchimento e não só de contorno, com teto de valores por plano de *parallax*: 1 valor na distância, 2 no
plano médio, 2 no primeiro plano, paleta inteira só no plano de jogo. À noite o ecrã tem exatamente duas cores que
não são terra: violeta (`--rot`) é A Podridão e só A Podridão; âmbar é luz, seja a candeia dela ou uma fogueira tua.

## Alternativas consideradas
Manter o azul e afinar o valor: o azul é frio como o violeta, e as duas coisas fundem-se — a leitura de relance do
ecrã noturno, que é o que a §26 exige para o comando sem rato, deixa de existir. Rejeitado por legibilidade, não
por gosto.

## Consequências
Fecha a Q-037. A tabela de fases da §05 está corrigida; `clock.csv` ganha `phase_tint_hue`, `phase_tint_sat`,
`phase_tint_val` e `night_value_floor`, e deixa de os marcar como proposta. O *parallax* desce de 12 h para 5 h
(§82) porque o teto de valores acaba com a indecisão sobre quanto detalhe pôr. Passa a ser proibido dar contorno a
qualquer coisa dentro do raio de uma luz. O teste das "duas frias" (§80) entra no CI: mais de 0,5% do ecrã em matiz
200°–290° com saturação acima de 0,35, fora da mancha e à noite, chumba.
Reverter isto obriga a redesenhar as camadas de fundo dos seis biomas — é a única dependência dura de calendário da
Parte XIII (§82).
