# src/sim/data/craft_data.gd — §06 (circuito 2), §44, §49.
# Uma conversao: materia -> moeda agora OU capacidade depois. Nunca as duas.
class_name CraftData
extends Resource

enum Mode { COIN, CAPACITY }  # §49: c.mode == CraftData.Mode.COIN

@export var id: StringName
@export var display_key: String
@export var material: StringName  # materia consumida
@export var house: StringName  # edificio-alvo (BuildingData id)
@export var cost: int = 0  # §49: materia consumida por conversao
@export var coin_multiplier: float = 1.0  # §06: "+50% do valor de venda"
@export var capacity_craft: StringName  # oficio que da a capacidade
@export var capacity_kind: StringName
@export var magnitude: float = 0.0
@export var duration: float = 0.0  # segundos; 0 = permanente
