# src/sim/data/flora_data.gd — uma especie de arvore (ADR 0070). Gerado de
# data/source/flora.csv.
class_name FloraData
extends Resource

@export var id: StringName
@export var display_key: String
## Os biomas onde cresce: e o bioma da posicao que escolhe a especie, nao o contrario.
@export var biomes: Array[StringName] = []
## Perene: nao perde a copa no outono nem no inverno.
@export var evergreen: bool = false
## O que esta arvore faz a quem esta perto: &"shelter" (abriga a caca das arvores) e
## &"forage" (apoia a coleta). E a origem das regras de influencia.
@export var tags: Array[StringName] = []
## A densidade do bosque (0..1) acima da qual esta especie nasce numa celula.
@export var density_min: float = 0.5
## O trabalho do construtor para a abater, e as moedas que o tronco da.
@export var fell_work_s: float = 0.0
@export var fell_coins: int = 0
## A altura do desenho, em px do mundo, e a forma da copa.
@export var height_px: float = 0.0
@export var crown: StringName = &"round"
