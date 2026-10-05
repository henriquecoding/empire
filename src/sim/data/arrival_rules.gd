class_name ArrivalRules
extends Resource

@export var cart_speed: float = 48.0
@export var foundation_stop_s: float = 0.35
@export var foundation_clear_radius: float = 240.0
@export var worker_work_s: float = 30.0
@export var forage_daily_cap: int = 3
@export var exposed_provisions: int = 3
@export var companion_cost: int = 7
@export var rested_run_mult: float = 1.5
@export var standing_repair_mult: float = 2.0
@export var boar_stun_s: float = 4.0
@export var boar_wall_damage: int = 6
@export var cellar_cost: int = 3
@export var cellar_work_s: float = 8.0
@export var cellar_step_px: float = 96.0

@export var battle_evolve_count := 5
@export var maturity_people := 4
@export var foreign_chest_coins := 5
@export var companion_evolved_health_mult := 1.5
## Verificacao da fundacao livre (ADR 0070): a carroca que alcanca o monarca.
@export var caravan_catch_up_px := 320.0
@export var caravan_catch_up_mult := 2.0
