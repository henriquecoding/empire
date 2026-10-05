# src/sim/data/under_rules.gd — o contrato de area util do subsolo e os limites dos
# sitios opcionais (ADR 0072). Gerado de data/source/underground.csv, chave/valor.
class_name UnderRules
extends Resource

@export var generator_version: int = 2
@export var arrival_px: float = 64.0
@export var clear_px: float = 48.0
@export var bay_px: float = 128.0
@export var margin_px: float = 32.0
@export var cellar_base_px: float = 288.0
@export var chest_px: float = 32.0
@export var optional_max: int = 3
@export var optional_spacing_px: float = 1920.0
@export var thief_carry: int = 5
