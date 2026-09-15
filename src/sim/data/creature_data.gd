# src/sim/data/creature_data.gd — §44. Gerado de data/source/creatures.csv.
# As criaturas so existem como invocacoes da Podridao (§51).
class_name CreatureData
extends Resource

@export var id: StringName
@export var display_key: String

@export_group("Podridao")
@export var mass_cost: int = 0  # §30: RotSystem compara com a massa
@export var min_day: int = 0  # §51: so e escolhida a partir deste dia

@export_group("Combate")
@export var max_health: int = 0
@export var damage: int = 0
@export var attack_interval: float = 0.0
@export var range_px: int = 0
@export var accuracy: float = 0.0
## &"nearest" | &"walls_only" | &"structures_first" — "alvo preferido" da §44.
@export var target_priority: StringName = &"nearest"
@export var targets_bands: Array[int] = [1]

@export_group("Mundo")
@export var band: Band.Kind = Band.Kind.SURFACE
@export var move_speed: float = 0.0  # px/s
@export var can_change_band: bool = false
@export var scale_tier: int = 0

@export_group("Arte")
@export var sprite_frames: SpriteFrames
@export var layer_slots: Array[StringName] = [&"body", &"face"]
@export var shadow_width: int = 0

@export_group("v5.2")
@export var drops_on_death: Array[StringName] = [&"coins"]
@export var coin_drop: int = 0  # §25: "uma moeda no chao onde morreu um Rastejante"
@export var tags: Array[StringName] = []

@export_group("v6 · o Zelador (§75)")
## Aparece com a Divida da Candeia a partir deste valor. 0 = nao depende dela.
@export var from_debt: int = 0
## O Zelador nao ataca, nao morre e olha para o teu nucleo. Afasta-se.
@export var can_be_killed: bool = true
@export var pushable: bool = false
## Se chegar ao nucleo, leva uma tropa nomeada (§75, §76).
@export var steals_named: bool = false
