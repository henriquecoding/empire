# src/sim/data/companion_data.gd — o companheiro do trono (§08). Um por partida.
# Gerado de data/source/companions.csv. Nao combate: altera uma regra.
class_name CompanionData
extends Resource

@export var id: StringName
@export var display_key: String
@export var rule: StringName  # a regra que altera
@export var rule_params: Dictionary = {}
@export var heal_per_day: float = 0.0  # §08: a cura tambem vem do companheiro
@export var growth_stages: int = 0
@export var food: Array[StringName] = []
