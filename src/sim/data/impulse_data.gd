# src/sim/data/impulse_data.gd — §15, §57: "o efeito e um Resource, nao um match".
# Gerado de data/source/impulses.csv. Um impulso por dia, pela roda do rei.
class_name ImpulseData
extends Resource

@export var id: StringName
@export var display_key: String
@export var icon: StringName
@export var coin_cost: int = 0
@export var benefit: StringName
@export var benefit_value: float = 0.0
@export var drawback: StringName
@export var drawback_value: float = 0.0
@export var drawback_days: int = 0
