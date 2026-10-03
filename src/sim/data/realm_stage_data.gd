# src/sim/data/realm_stage_data.gd — ADR 0059. Gerado de data/source/realm_stages.csv.
# Um estagio da sede: da Clareira a Fortaleza. Cada um e um degrau do nucleo, pago e
# levantado como os do muro, e abre as obras da coluna `unlocks`.
class_name RealmStageData
extends Resource

@export var id: StringName
@export var display_key: String
## A posicao na escada: 0 e a Clareira, por fundar.
@export var order: int = 0
## O que custa chegar a este estagio a partir do anterior.
@export var cost: int = 0
@export var build_work: float = 0.0
@export var max_health: int = 0
@export var width_px: int = 0
@export var contact_slots: int = 0
## As obras (buildings.csv) e os niveis de muro (walls.csv) que este estagio abre.
@export var unlocks: Array[StringName] = []
