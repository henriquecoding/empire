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
## Quantas tocas deste bicho tem uma regiao, e a que distancia de um Amargueiro
## uma toca se perde (Q-106). Zero: este bicho nao sai de tocas.
@export var burrows_per_region: int = 0
@export var burrow_wither_px: float = 0.0
## De onde sai (Q-150): &"bush" | &"hole" | &"rock" | &"tree" | &"lake".
@export var sources: Array[StringName] = []
## A caca viva (ADR 0057): pasta a `graze_speed` ate `roam_px` da toca; quem chega a
## `notice_px` faz-o fugir ate `flee_px` da toca, ou carregar, se nao foge.
@export var graze_speed: float = 0.0
@export var roam_px: float = 0.0
@export var notice_px: float = 0.0
@export var flee_px: float = 0.0
## O bicho que carrega bate `damage` a `reach_px`, a cada `attack_interval`.
@export var reach_px: float = 0.0
@export var attack_interval: float = 0.0
## O raro: sai, com `rare_chance`, de uma toca do bicho `rare_of`, no lugar dele.
@export var rare_of: StringName = &""
@export var rare_chance: float = 0.0
## A criatura da Podridao em que o bicho se levanta, se uma o apanhar de noite.
@export var rots_into: StringName = &""
## Os segundos de luz entre dois bichos da mesma toca (Q-217): o bicho volta varias
## vezes por dia. Zero: a toca segue o periodo da caca media (hunt_yield, Q-106).
@export var respawn_s: float = 0.0
