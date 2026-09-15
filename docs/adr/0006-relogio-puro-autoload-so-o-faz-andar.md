# ADR 0006 — O relógio é puro; o autoload só o faz andar

- Estado: aceite
- Data: 2026-09-11
- Secção do dossiê: §30, §41, §48, §65, §70

## Contexto
A §30 escreve `src/sim/game_clock.gd` puro (`RefCounted`); a §41 e a §65 punham um `game_clock.gd` em `core/` como
*autoload* — e um *autoload* é um `Node`.

## Decisão
Dois ficheiros: `src/sim/game_clock.gd` é o relógio (dono do estado, testável em milissegundos, recebe um
`ClockData`); `src/core/clock_service.gd` é um *autoload* de trinta linhas que chama `tick(delta)` no
`_physics_process` e traduz o que ele devolve em sinais do `EventBus`. Zero lógica no *autoload*. As durações
vivem em `data/source/clock.csv` → `data/economy/clock.tres`.

## Alternativas consideradas
Relógio como *autoload*: não se testa sem abrir o Godot e viola I1.

## Consequências
O `DAY_SECONDS` que a §47 mandava para a `EconomyCurve` vive no `ClockData` (Q-021).
