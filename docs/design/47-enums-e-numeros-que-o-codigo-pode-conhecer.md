# 47 — Constantes · Enums e números que o código pode conhecer

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

A invariante I4 diz que balanceamento vive em .tres. Isto é o complemento: o que não é balanceamento e pode, por isso, ser constante de código. A distinção é simples — se afinares isto num playtest, está no sítio errado.

```gdscript
# src/sim/band.gd  — corrigido na v5.1, ver §70
class_name Band
enum Kind { AERIAL = 0, SURFACE = 1, UNDERGROUND = 2 }

# Planos de imagem — §11. Fixados na Fase 0 e nunca mexidos.
const SKY_TOP        := 0
const HORIZON        := 420    # onde as camadas distantes se encontram
const GROUND_LINE    := 517    # onde as tropas pisam
const SCREEN_BOTTOM  := 720
const AERIAL_BOTTOM  := 200
const SOIL_CUT       := SCREEN_BOTTOM - GROUND_LINE   # 203

# Camadas de física — uma por faixa, mais estáticos
# v5.2: uma constante por linha — o GDScript não aceita várias numa só (C-01, §72)
const L_AERIAL   := 1
const L_SURFACE  := 2
const L_UNDER    := 4
const L_TERRAIN  := 8
const L_BUILDING := 16
const L_COIN     := 32
```

| Constante | Valor | De onde vem | Afina-se em playtest? |
| --- | --- | --- | --- |
| TICK_HZ | 30 | §19 | Não |
| DAY_SECONDS | 360 | §05 | Sim → vai para ClockData (v5.2, ADR 0006) |
| GROUND_LINE | 517 | §11, fixado na Fase 0 | Não — meia dúzia de sistemas dependem dele |
| SEGMENT_WIDTH | 640 | §21 | Não |
| TILE | 32 | §22 | Não |
| AI_SLICE | 6 | 1/6 das unidades decide por tick | Não — é desempenho |
| SLOT_REPLACE_TIME | 0,4 s | §07 | Sim → EconomyCurve |
| EVENT_LOG_SIZE | 600 | ≈ 20 s de história para depuração | Não |


> **O teste que mantém isto honesto**
>
> test_sem_literais_de_balanceamento percorre src/ à procura de literais numéricos fora de uma lista de exceções (0, 1, -1, e as constantes acima). Encontrar 26.0 escrito à mão dentro de um sistema é um chumbo. É rude, e é exatamente por isso que funciona quando o código não é escrito por ti.
