# src/sim/data/forest_rules.gd — a floresta como territorio (ADR 0070). Gerado de
# data/source/forest.csv, chave/valor.
class_name ForestRules
extends Resource

@export var generator_version: int = 1
@export var tree_step_px: float = 56.0
@export var reserve_px: float = 56.0
@export var fell_cost: int = 1
@export var tree_reach_px: float = 28.0
@export var flora_clear_px: float = 32.0
@export var grove_feeds_radius: float = 240.0
@export var grove_feeds_min: int = 3
@export var grove_feeds_bonus: int = 1
@export var grove_feeds_cap: int = 1
@export var shelter_radius: float = 200.0
@export var shelter_min: int = 2
