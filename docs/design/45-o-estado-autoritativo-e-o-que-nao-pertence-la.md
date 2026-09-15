# 45 — Estado · O estado autoritativo, e o que não pertence lá

_Gerado de dossie.html — nao editar a mao; edita o dossie e volta a correr._

Uma regra simples: se está aqui, é guardado no save e é determinista. Se está num nó, é derivado e descartável. A fronteira entre os dois é o que torna o save trivial.

```gdscript
# src/sim/state/game_state.gd
class_name GameState extends RefCounted

var seed: int
var tick: int = 0                              # passos desde o início
var day: int = 1
var phase: GameClock.Phase = GameClock.Phase.DAWN
var phase_elapsed: float = 0.0

var player: KingdomState                        # o teu império
var kingdoms: Array[KingdomState] = []          # impérios inimigos, ordenados por id

var units: Array[UnitRec] = []                  # ordenado por id, sempre
var creatures: Array[CreatureRec] = []
var buildings: Array[BuildingRec] = []
var coins_on_ground: Array[CoinRec] = []
var corpses: Array[CorpseRec] = []              # ressuscitáveis até ao amanhecer

var rot: RotState                               # posição, largura, massa, ativo
var world: WorldState                            # segmentos, cavidades, passagens, terreno apodrecido
var debt: DebtState
var next_id: int = 1                             # contador único e monotónico
```

```gdscript
# src/sim/state/unit_rec.gd — uma tropa é uma linha de dados, não um nó
class_name UnitRec extends RefCounted

var id: int
var data_id: StringName          # chave para UnitData no Registry
var owner: int                   # 0 = jogador, 1..n = impérios
var x: float
var band: Band.Kind
var health: int
var state: UnitFsm.State         # IR_PARA, TRABALHAR, COMBATER, FUGIR, MORTO
var job_id: int = -1
var target_id: int = -1
var attack_cooldown: float = 0.0
var carried_coins: int = 0
var slots: Dictionary = {}       # body/head/face/weapon/overlay -> StringName
var loyalty: float = 1.0         # mercenários e encantados (§14)
```

## O que fica de fora, e porquê

**Posição em Y** — Derivada da faixa e da linha do solo. Guardar Y seria guardar duas vezes a mesma informação e abrir a porta a que divirjam.

Derivado de state. O UnitView escolhe a tag. Carregar um save e ver toda a gente no frame 0 de idle não é um bug.

Preferência de sessão, não estado de jogo. Vai para user://settings.cfg.

Consequências de eventos. Um save a meio de uma explosão carrega sem explosão. Correto.
