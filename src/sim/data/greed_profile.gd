# src/sim/data/greed_profile.gd — os quatro perfis de ganancia (§15).
# Gerado de data/source/greed_profiles.csv. Serve o teu imperio e os inimigos (§20).
class_name GreedProfile
extends Resource

@export var id: StringName
@export var display_key: String
@export var greed_range: Vector2i = Vector2i()
@export_group("No teu imperio")
@export var elite_morale_mod: float = 0.0
@export var free_elite_every_days: int = 0
@export var impulse_cost_mult: float = 1.0
@export_group("Num rei inimigo")
@export var enemy_wall_bias: float = 0.0
@export var enemy_elite_bias: float = 0.0
@export var enemy_attack_unit: StringName = &""
@export var enemy_attack_timing: StringName = &""
