# ADR 0001 — Escala `fractional` por omissão, com interruptor para `integer`

- Estado: proposta — fecha no *spike* de duas horas da Fase 0 (§65)
- Data: 2026-09-11
- Secção do dossiê: §19, §38 (decisão 1), §67

## Contexto
A arte é desenhada a 1:1 em 1280 × 720 e perde 6,3% dos píxeis a 640 × 360 (§01). 1080p — o ecrã mais comum — é
1,5× e não é múltiplo inteiro. O Steam Deck (1280 × 800) é 1× com barras de 40 px.

## Decisão
`canvas_items` com escala `fractional` e filtro suave por omissão; nas Opções, "pixels nítidos" passa a `integer`
com barras. A largura visível do mundo fica limitada a 1,25× o rácio 16:9, para ecrãs ultralargos não verem A
Podridão chegar mais cedo. Já está no `project.godot` (valores explícitos, mesmo iguais aos por omissão).

## Alternativas consideradas
`integer` sempre: 1080p ficaria com barras enormes (escala 1×). Baixar a resolução interna para 640 × 360: destrói
a arte, que é o ativo mais difícil de refazer (§22).

## Consequências
A câmara e o enquadramento dependem disto; tomá-la depois custa uma reescrita (§19). **Para aceitar:** correr o
*spike* lado a lado em 1080p e no Deck, com `fractional` e `integer`, e guardar as capturas na PERFORMANCE_MATRIX.
