# src/sim/data/wildlife_data.gd — fauna cacavel (§06 "Caca", §25 o coelho do minuto 1:10).
# Gerado de data/source/wildlife.csv. Acrescentado na v5.2: a §44 nao tinha onde
# guardar a caca, e os arqueiros cacam de dia desde a Fase 1 (§07).
class_name WildlifeData
extends Resource

@export var id: StringName
@export var display_key: String
@export var max_health: int = 0
@export var move_speed: float = 0.0
@export var coin_yield: int = 0
@export var flees: bool = true
@export var damage: int = 0
@export var biomes: Array[StringName] = []
@export var per_segment_max: int = 0
@export var shadow_width: int = 0
