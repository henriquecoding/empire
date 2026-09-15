# src/sim/data/wall_data.gd — §44. Gerado de data/source/walls.csv (§10).
class_name WallData
extends Resource

@export var id: StringName
@export var display_key: String
@export var level: int = 0
@export var cost: int = 0
@export var max_health_b: int = 0  # Caminho B — Fortificacao (§10, coluna "Vida (B)")
@export var guard_posts_a: int = 0  # Caminho A — Guarnicao (§10, coluna "Postos (A)")
@export var contact_slots: int = 0  # §07: so N atacantes engajam
@export var material_by_people: Dictionary = {}  # people -> material (§10)
@export var pieces: Array[StringName] = [&"segment", &"cap", &"gate"]  # §22

@export_group("v5.2")
@export var max_health_a: int = 0  # o §10 so da a vida do Caminho B
@export var guard_posts_b: int = 0
@export var unique_per_kingdom: bool = false  # Bastiao: "unico por imperio"
@export var requires_conquest: StringName = &""  # Muralha de ferro: fornalha
@export var shadow_width: int = 0
