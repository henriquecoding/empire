# src/sim/systems/harvest_system.gd — a Colheita, e as duas maneiras de acabar
# com um povo (§78).
#
# Conquistar deixa de dar edificios: da uma divida de trabalho. Um povo tomado
# trabalha para ti a 140% durante C = 6 + 2 x povos ja detidos dias (metade,
# arredondada para cima, por assimilacao), fora das tuas muralhas. Uma Colheita
# de cada vez — a seguinte espera em fila, a 100%. Se a aldeia cair a noite,
# perde-se o povo sem escolha. No fim, uma decisao: soltar ou ficar.
#
# Soltar da uma voz ao coro (§81); ficar da +80% de producao e poe o marco deles
# a criar raiz — um Amargueiro que nao se corta, +22 por noite (§74). Nenhuma e
# o final bom: as duas listas sao o epilogo (§79).
#
# Puro. Os campos do save sao os da §84. O que comeca uma Colheita e a conquista
# (§13), que ainda nao existe; o gesto da decisao e o Verbo 1 no nucleo deles,
# que ainda nao tem aldeia onde cair (Q-095).
class_name HarvestSystem
extends RefCounted

enum Choice { NONE, RELEASE, KEEP }

const EV_COMECA := 0
const EV_DECIDIR := 1
const EV_DECIDIDO := 2
const EV_PERDIDO := 3

const CHAVE := &"kind"
const POVO := &"people"

var people: String = ""
var days_left: int = 0
var assimilated: bool = false
var queue: PackedStringArray = PackedStringArray()
## Em paralelo com a fila: 1 se esse povo foi assimilado e nao tomado.
var queue_assimilated: PackedByteArray = PackedByteArray()
## O povo cuja Colheita acabou e espera pela decisao. Ninguem decide por ti.
var deciding: String = ""
var released: PackedStringArray = PackedStringArray()
var kept: PackedStringArray = PackedStringArray()
var lost: PackedStringArray = PackedStringArray()

var _curva: EconomyCurve


func _init(curva: EconomyCurve) -> void:
	assert(curva != null, "a Colheita precisa do EconomyCurve")
	_curva = curva


## C = base + por_povo x detidos; por assimilacao, factor dela, para cima.
func duration(detidos: int, por_assimilacao: bool) -> int:
	var c := _curva.colheita_base_days + _curva.colheita_per_people * detidos
	if por_assimilacao:
		return ceili(float(c) * _curva.colheita_assimilation_factor)
	return c


## Os povos que ja detens: soltos, ficados, o que esta a ser colhido, o que
## espera pela decisao e os que esperam em fila. Os perdidos ja nao.
func held() -> int:
	var n := released.size() + kept.size() + queue.size()
	return n + (1 if people != "" else 0) + (1 if deciding != "" else 0)


## Um povo tomado ou assimilado. Falso se ja passou por aqui.
func conquer(povo: StringName, por_assimilacao: bool) -> bool:
	var id := String(povo)
	if id == people or id == deciding or queue.has(id):
		return false
	if released.has(id) or kept.has(id) or lost.has(id):
		return false
	queue.append(id)
	queue_assimilated.append(1 if por_assimilacao else 0)
	_seguinte()
	return true


## Cada alvorada e um dia de trabalho. No ultimo, o povo espera pela decisao.
func at_dawn() -> Array[Dictionary]:
	if people == "":
		return []
	days_left -= 1
	if days_left > 0:
		return []
	deciding = people
	people = ""
	return [{CHAVE: EV_DECIDIR, POVO: deciding}]


func decide(escolha: Choice) -> Dictionary:
	if deciding == "" or escolha == Choice.NONE:
		return {}
	if escolha == Choice.RELEASE:
		released.append(deciding)
	else:
		kept.append(deciding)
	var e := {CHAVE: EV_DECIDIDO, POVO: deciding}
	deciding = ""
	_seguinte()
	return e


## A aldeia em Colheita caiu a noite: acaba ali, sem escolha (§78).
func fall() -> Dictionary:
	if people == "":
		return {}
	var e := {CHAVE: EV_PERDIDO, POVO: people}
	lost.append(people)
	people = ""
	days_left = 0
	_seguinte()
	return e


## A producao daquela terra: 140% em Colheita, +80% para sempre se ficou.
func production_mult(povo: StringName) -> float:
	var id := String(povo)
	if id == people:
		return _curva.colheita_production_mult
	if kept.has(id):
		return 1.0 + _curva.keep_production_bonus
	return 1.0


## Os marcos que criaram raiz — um por povo que ficou.
func landmarks() -> int:
	return kept.size()


## As vozes do coro noturno: tantas quantos povos soltos (§78, §81).
func voices() -> int:
	return released.size()


func to_dict() -> Dictionary:
	return {
		&"colheita_people": people,
		&"colheita_days": days_left,
		&"colheita_assimilated": assimilated,
		&"colheita_queue": queue,
		&"colheita_queue_assimilated": queue_assimilated,
		&"colheita_deciding": deciding,
		&"peoples_released": released,
		&"peoples_kept": kept,
		&"peoples_lost": lost,
	}


func from_dict(d: Dictionary) -> void:
	people = d.get(&"colheita_people", people)
	days_left = d.get(&"colheita_days", days_left)
	assimilated = d.get(&"colheita_assimilated", assimilated)
	queue = d.get(&"colheita_queue", queue)
	queue_assimilated = d.get(&"colheita_queue_assimilated", queue_assimilated)
	deciding = d.get(&"colheita_deciding", deciding)
	released = d.get(&"peoples_released", released)
	kept = d.get(&"peoples_kept", kept)
	lost = d.get(&"peoples_lost", lost)
	while queue_assimilated.size() < queue.size():
		queue_assimilated.append(0)


## Comeca a seguinte da fila, se nao ha nenhuma a decorrer nem a decidir. Conta
## os povos ja detidos ANTES dela — "a primeira conquista dura 6 dias".
func _seguinte() -> void:
	if people != "" or deciding != "" or queue.is_empty():
		return
	var id := queue[0]
	var por_assimilacao := queue_assimilated[0] == 1
	queue.remove_at(0)
	queue_assimilated.remove_at(0)
	days_left = duration(held(), por_assimilacao)
	people = id
	assimilated = por_assimilacao
