# src/sim/data/building_data.gd — §44. Gerado de data/source/buildings.csv.
# Inclui producao (§06), casas de conversao (§06), oficios (§09), treino e
# defesas (§10). Estados de construcao sao frames de sprite (§55).
class_name BuildingData
extends Resource

@export var id: StringName
@export var display_key: String
@export var people: StringName = &"neutral"
## &"core" | &"production" | &"conversion" | &"craft" | &"training" | &"defense" | &"special"
@export var category: StringName = &"production"

@export_group("Economia")
@export var cost: int = 0
@export var material: StringName = &""  # materia produzida: grain, fish, animal, wood, ore
## Valor de venda por dia (§06). O §49 le yield_per_phase: o EconomySystem divide
## pelo numero de fases do ClockData.
@export var yield_per_day: float = 0.0
@export var requires_biome_feature: StringName = &""  # water, forest, rock (§06, §21)
@export var destroyed_by_rot_trail: bool = false  # §49: plantacoes destruidas, o resto para
@export var job_slots: int = 0  # postos que publica (§20)
@export var craft: StringName = &""  # oficio que trabalha aqui

@export_group("Construcao")
@export var max_health: int = 0
## §07: "so N atacantes engajam". A coluna que o walls.csv sempre teve e o
## buildings.csv nao tinha: uma obra com zero slots nao recebe atacante
## nenhum, e por isso nao podia ser atacada (Q-075). Zero e "nao trava".
@export var contact_slots: int = 0
@export var build_work: float = 0.0  # segundos de construtor presente (§55)
@export var width_px: int = 0
@export var upgrade_to: StringName = &""
@export var unique_per_kingdom: bool = false
@export
var states: Array[StringName] = [&"empty", &"scaffold", &"building", &"done", &"damaged", &"ruin"]

@export_group("Efeito")
@export var effect_params: Dictionary = {}  # torres e defesas (§10)

@export_group("Arte")
@export var shadow_width: int = 0
@export var tags: Array[StringName] = []
