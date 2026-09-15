# ADR 0002 — Três faixas com camadas de física separadas desde a primeira entidade

- Estado: aceite
- Data: 2026-09-11
- Secção do dossiê: §11, §40 (I3), §47, §53, §70

## Contexto
O §11 chama-lhe a decisão arquitetónica mais importante do projeto: acrescentar faixas no dia 200 é reescrever o
jogo.

## Decisão
Toda a entidade tem `band: Band.Kind` desde a criação; `Band` vive em `src/sim/band.gd` (§70); as colisões usam as
camadas `L_AERIAL`, `L_SURFACE`, `L_UNDER`, `L_TERRAIN`, `L_BUILDING`, `L_COIN` (§53), já nomeadas no
`project.godot`. A matriz de colisão é a do §53.

## Alternativas consideradas
Câmara que se divide ao descer (§11, opção A): mais código, mais *bugs* de câmara, e o jogador perde a superfície
de vista quando mais precisa dela.

## Consequências
`test_band_vive_na_simulacao` guarda o caminho. Um sistema que precise de saber a faixa lê o campo; nunca a deduz
da posição Y (Y é derivado, §45).
