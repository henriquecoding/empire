# ADR 0007 — O save nunca usa `load()`: só tipos base, validados campo a campo

- Estado: aceite (corrigida na v5.2 — Q-036)
- Data: 2026-09-11
- Secção do dossiê: §19, §40 (I6), §62

## Contexto
Um `.tres` arbitrário pode conter *script* embutido: carregar um save com `load()` é execução remota de código
disfarçada. É a falha de segurança clássica dos jogos em Godot (§62).

## Decisão
O save é um dicionário de tipos base (`save_version`, `worldgen_version`, `seed`, `rng_states`, `state`…, §62),
escrito com `FileAccess.store_var` e lido com `FileAccess.get_var(false)` — `allow_objects` desligado, que é o
valor por omissão — e **validado à mão, campo a campo**. Nunca `load()` nem `ResourceLoader.load` num save: são a
mesma função, e `CACHE_MODE_IGNORE` só mexe na *cache*, não impede um `.tres` de trazer *script* (v5.2, Q-036). Campos
desconhecidos ignoram-se (degrada em vez de recusar). Escrita para ficheiro temporário e só depois `rename`; três
*slots* em rotação; `save_version` desde a 1, com uma migração por alteração, no mesmo *commit*.

## Alternativas consideradas
`ResourceSaver`/`load()` de um `Resource` com o estado: é exatamente a vulnerabilidade. `ResourceLoader.load` com
`CACHE_MODE_IGNORE`, como o §62 do dossiê escreve: a mesma vulnerabilidade, porque o modo de *cache* não desliga a
execução de *scripts* embutidos. JSON: também seguro, mas perde `int` contra `float` e obriga a converter
`Vector2`; o `store_var` guarda os tipos base do Godot tal e qual. Um *add-on* que inspeciona o `.tres` antes de o
carregar: resolve, mas é uma dependência a manter para um problema que o `get_var(false)` não tem.

## Consequências
Esta ADR é citada como regra absoluta no `AGENTS.md`. Revisão obrigatória em qualquer *diff* que toque em
`save_service.gd`.
