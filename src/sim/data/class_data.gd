# src/sim/data/class_data.gd — §08, §44. Gerado de data/source/classes.csv.
# Classes sao arquetipos: cada povo tem o seu corpo para o mesmo papel (§08).
class_name ClassData
extends Resource

@export var id: StringName
@export var display_key: String
@export var archetype: StringName
@export var base_unit: StringName  # UnitData que se assume com o Verbo 2 (§08)
@export var verb: StringName = &""  # acao propria da classe (§24: arqueiro marca alvo)
@export var fights: bool = true

@export_group("Desbloqueio")
## &"start" | &"royal_seed" | &"conquest" | &"secret"
@export var unlock: StringName = &"start"
@export var unlock_seed_cost: int = 0

@export_group("Fases")
@export var phase_count: int = 2
@export var evolve_seed_cost: int = 0  # §08: 1 Semente Real para a Fase 2
@export var evolve_condition: StringName = &""
@export var evolve_condition_value: int = 0
@export var phase1_ability: StringName = &""
@export var phase1_params: Dictionary = {}
@export var phase2_ability: StringName = &""
@export var phase2_params: Dictionary = {}
