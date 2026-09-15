# src/sim/state/build_slot.gd — um sitio onde se pode construir (§55, §21).
#
# Os slots sao AUTORADOS na cena do segmento, nao calculados: e a decisao do §21,
# "forcar posicoes arriscadas em vez de deixar amontoar tudo no sitio seguro". O
# gerador escolhe segmentos; o segmento decide onde se pode construir.
#
# A escada de niveis esta aqui e nao no sistema porque e ela que distingue um
# canteiro de um muro: o canteiro tem um degrau, o muro tem os cinco do §10. Um
# `if e_muro` espalhado pelo sistema era a mesma coisa escrita pior.
class_name BuildSlot
extends RefCounted

## Os seis estados do §55, e cada um e um frame de sprite, nao uma cena.
enum State { EMPTY, SCAFFOLD, BUILDING, DONE, DAMAGED, RUIN }

const NENHUM := -1

var id: int = NENHUM
var x: float = 0.0
var band: Band.Kind = Band.Kind.SURFACE

## O que ali se constroi: a chave do BuildingData ou do WallData do nivel 1. Nao
## e texto para o ecra — e o que o build_completed leva.
var kind: StringName = &""

## A escada, um degrau por nivel. O indice 0 e o nivel 1.
var costs: PackedInt32Array = PackedInt32Array()
var works: PackedFloat32Array = PackedFloat32Array()
var healths: PackedInt32Array = PackedInt32Array()

## Largura em px. Manda no raio de apanha da obra e em quem conta como presente.
var width: float = 0.0

## Verdadeiro para o que trava uma criatura a caminho do nucleo: muros e torres.
## Um canteiro nao trava ninguem, e e por isso que o §10 lhe chama outra coisa.
var blocks: bool = false

## O posto que publica quando esta de pe. Vazio = nao publica nenhum.
var job_id: StringName = &""

## Quanto rende por dia (§06, circuito 1). O EconomySystem divide pelas fases —
## o CSV guarda por dia e o sistema reparte (Q-027, fechada).
var yield_per_day: float = 0.0
## Materia acumulada e ainda nao convertida. Float porque uma fase rende menos
## do que uma moeda e a parte de tras nao se perde.
var stock: float = 0.0
## §49: uma plantacao no rasto da Podridao e destruida; as outras so param.
var razed_by_rot: bool = false

var level: int = 0
var state: State = State.EMPTY
## Moedas ja pagas do degrau seguinte. §55: a obra existe quando uma moeda cai.
var paid: int = 0
## Segundos de construtor PRESENTE, e nao tempo decorrido (§55).
var progress: float = 0.0
var health: int = 0


## De pe: ja construida, inteira ou tocada, mas ainda nao ruina.
func standing() -> bool:
	return state == State.DONE or state == State.DAMAGED


## Quanto custa o degrau seguinte, ou NENHUM se ja chegou ao topo.
func next_cost() -> int:
	return costs[level] if level < costs.size() else NENHUM


func max_health() -> int:
	return healths[level - 1] if level > 0 and level <= healths.size() else 0
