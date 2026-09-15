# ADR 0003 — Balanceamento em CSV, gerado para `.tres`

- Estado: aceite
- Data: 2026-09-11
- Secção do dossiê: §40 (I4), §41, §44

## Contexto
Sem uma fonte única, a tabela mestra do §07 existe em três sítios e diverge no mês quatro (§41).

## Decisão
Os números escrevem-se uma vez em `data/source/*.csv`; `tools/csv_to_tres.gd` gera os `.tres`; o código só lê
`Resource`s. O registo das tabelas é `data/source/_tables.csv`. Convenções em
`docs/content/CONTENT_DATABASE.md` (ADR 0008).

## Alternativas consideradas
Editar `.tres` no editor do Godot: sem *diff* legível, sem folha de cálculo, sem verificação contra o dossiê.

## Consequências
Balancear é editar uma folha. O CI verifica a sincronia CSV ↔ `.tres` e os números contra o dossiê.
