class_name RealmSiteData
extends Resource

@export var id: StringName
## camp, starter, protected, frontier, wall, wilderness ou native.
@export var placement: StringName = &"protected"
@export var wall_level: int = 0
## Basta uma destas fontes estar de pe para justificar a oficina.
@export var requires_any: Array[StringName] = []
