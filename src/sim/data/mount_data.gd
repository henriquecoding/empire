# src/sim/data/mount_data.gd — §12, §44. Gerado de data/source/mounts.csv. Fase 6.
class_name MountData
extends Resource

@export var id: StringName
@export var display_key: String
@export var speed_multiplier: float = 1.0
@export var coin_capacity_multiplier: float = 1.0
@export var band: Band.Kind = Band.Kind.SURFACE
@export var can_change_band: bool = false
@export var flies: bool = false  # libelula: ignora a faixa de superficie
@export var climbs_walls: bool = false  # lagarto: acesso vertical sem passagem
@export var ignores_rot_trail: bool = false  # alce da Podridao
@export var knocks_down_stakes: bool = false  # javali
## &"start" | &"stable" | &"hunt" | &"secret" | &"fortress" | &"convert"
@export var obtain: StringName = &"start"
@export var obtain_ref: StringName = &""  # bioma, povo ou classe de origem
@export var cost: int = 0
@export var heal_days: int = 0  # §12: ferida recupera no estabulo em 2 dias
