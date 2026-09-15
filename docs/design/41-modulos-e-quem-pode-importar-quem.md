# 41 — Arquitetura · Módulos, e quem pode importar quem

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Quatro camadas. As setas só apontam para baixo. Uma seta para cima é um erro de compilação conceptual, e o CI trata-a como tal.

> **Correção da v5.1 — a consequência que faltava tirar**
>
> Se as setas só descem e src/sim/ é o fundo, então tudo o que a simulação lê tem de viver na simulação — incluindo o Band, que o §47 e o §65 punham em core/. A §70 resolve esta e mais cinco divergências do mesmo tipo, e dá a tabela canónica de caminhos.

## A árvore completa

```gdscript
res://
├─ data/                  # .tres gerados a partir de data/source/*.csv (§44)
│  ├─ source/             # CSV — a FONTE ÚNICA dos números
│  ├─ units/ creatures/ buildings/ walls/ peoples/ classes/
│  ├─ crafts/ mounts/ biomes/ segments/ economy/ rot/
├─ src/
│  ├─ core/               # autoloads — ver §46 e §48
│  │  ├─ event_bus.gd     # o catálogo do §46, e nada mais
│  │  ├─ game_clock.gd    # fase do dia, tick fixo
│  │  ├─ rng_service.gd   # fluxos nomeados (§42)
│  │  ├─ registry.gd      # .tres carregados por StringName
│  │  └─ save_service.gd
│  ├─ sim/
│  │  ├─ state/           # GameState, KingdomState, UnitRec…
│  │  ├─ systems/         # economy, combat, rot, jobs, build, debt…
│  │  ├─ ai/              # unit_fsm.gd, enemy_king_ai.gd
│  │  └─ worldgen/
│  ├─ actors/             # UnitView, KingView, CreatureView, MountView
│  ├─ world/              # WorldRoot, ParallaxStack, BandLayers, CameraRig
│  ├─ ui/  net/
├─ scenes/
│  ├─ boot.tscn  game.tscn  segments/  tests/
├─ art/
│  ├─ source/             # .aseprite (Git LFS)
│  └─ export/             # .png + .json gerados (NÃO versionar)
├─ shaders/  audio/
├─ tools/                 # csv_to_tres.gd, lint_sim.gd, greybox_gen.gd
└─ tests/                 # gdUnit4
```

> **A pasta que o §19 não tinha**
>
> tools/ e data/source/. São a resposta à base de dados de conteúdo: os números escrevem-se uma vez num CSV, e csv_to_tres.gd gera os .tres. Balanceias numa folha de cálculo, corres a ferramenta, e o jogo tem os números novos. Sem isto, a tabela mestra de unidades do §07 existe em três sítios e diverge no mês quatro.
