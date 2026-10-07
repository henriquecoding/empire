# src/sim/data/territory_rules.gd — o alcance das fontes do territorio (ADR 0077). Gerado
# de data/source/territory.csv, chave/valor.
class_name TerritoryRules
extends Resource

@export var water_half_px: float = 96.0
@export var wild_water_half_px: float = 128.0
@export var water_reach_px: float = 64.0
@export var forest_reach_px: float = 160.0
@export var forest_min: int = 3
@export var rock_reach_px: float = 0.0
