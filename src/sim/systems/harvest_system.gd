# src/sim/systems/harvest_system.gd — a Colheita, e as duas maneiras de acabar
# com um povo (§78).
#
# Tomar ou assimilar um povo nao da a producao dele: da uma Colheita, uns dias
# em que aquela gente trabalha para ti, a vista de todos, e nao e livre. C = 6 +
# 2 x povos ja detidos; por assimilacao, metade, arredondada para cima. Uma de
# cada vez: a segunda conquista espera em fila. No fim, uma decisao — soltar ou
# ficar — e nenhuma das duas e o final bom. Se a aldeia cair a noite a meio, o
# povo perde-se.
#
# Puro, em colunas, pela ordem das conquistas. Os numeros sao do economy.csv; se
# o marco cria raiz ao ficar e do peoples.csv. O que falta para isto se jogar e
# a conquista (§13, Fase 2) e o gesto de decidir (Q-090).
class_name HarvestSystem
extends RefCounted

enum Estado { EM_FILA, EM_COLHEITA, A_DECIDIR, SOLTO, FICADO, PERDIDO }
enum { EV_COMECA, EV_EM_FILA, EV_DECIDIR, EV_SOLTO, EV_FICADO, EV_PERDIDO }

const CHAVE := &"kind"
const POVO := &"people"
const DIAS := &"days"

var peoples: PackedStringArray = PackedStringArray()
var states: PackedByteArray = PackedByteArray()
var days_left: PackedInt32Array = PackedInt32Array()
var assimilated: PackedByteArray = PackedByteArray()

var _curva: EconomyCurve
var _povos: Dictionary


## `povos` e PeopleData por id: o marco de quem fica cria raiz, ou nao (§78).
func _init(curva: EconomyCurve, povos: Dictionary) -> void:
	_curva = curva
	_povos = povos


func state_of(people_id: StringName) -> int:
	var i := peoples.find(String(people_id))
	return states[i] if i != -1 else -1


## Quantos dias dura a proxima: C = base + por_povo x ja detidos; por
## assimilacao, a fraccao do CSV, arredondada para cima (§78).
func duration(por_assimilacao: bool) -> int:
	var c := _curva.colheita_base_days + _curva.colheita_per_people * held()
	if por_assimilacao:
		return ceili(c * _curva.colheita_assimilation_factor)
	return c


## Os povos ja detidos: soltos, ficados, e o que estiver em Colheita.
func held() -> int:
	var n := 0
	for e in states:
		if e in [Estado.SOLTO, Estado.FICADO, Estado.EM_COLHEITA, Estado.A_DECIDIR]:
			n += 1
	return n


## Conquistar ou assimilar. Com uma Colheita a decorrer, o povo entra em fila:
## "Conquistar um povo com uma Colheita a decorrer nao a duplica" (§78).
func conquer(people_id: StringName, por_assimilacao: bool) -> Dictionary:
	var dias := duration(por_assimilacao)
	var ocupada := _atual() != -1
	peoples.append(String(people_id))
	assimilated.append(int(por_assimilacao))
	states.append(Estado.EM_FILA if ocupada else Estado.EM_COLHEITA)
	days_left.append(0 if ocupada else dias)
	if ocupada:
		return {CHAVE: EV_EM_FILA, POVO: people_id}
	return {CHAVE: EV_COMECA, POVO: people_id, DIAS: dias}


## A alvorada: a Colheita anda um dia; acabada, espera pela decisao.
func at_dawn() -> Array[Dictionary]:
	var i := _atual()
	if i == -1 or states[i] != Estado.EM_COLHEITA:
		return []
	days_left[i] -= 1
	if days_left[i] > 0:
		return []
	states[i] = Estado.A_DECIDIR
	return [{CHAVE: EV_DECIDIR, POVO: StringName(peoples[i])}]


## Soltar ou ficar (§78). So quando a Colheita acabou; e a seguinte da fila
## comeca logo, com a duracao contada nesse momento.
func decide(people_id: StringName, soltar: bool) -> Array[Dictionary]:
	var i := peoples.find(String(people_id))
	if i == -1 or states[i] != Estado.A_DECIDIR:
		return []
	states[i] = Estado.SOLTO if soltar else Estado.FICADO
	var eventos: Array[Dictionary] = [{CHAVE: EV_SOLTO if soltar else EV_FICADO, POVO: people_id}]
	eventos.append_array(_proxima())
	return eventos


## A aldeia caiu a noite a meio da Colheita: perde-se o povo, a decisao e a
## arquitetura. So a que esta em Colheita pode cair assim.
func fall(people_id: StringName) -> Array[Dictionary]:
	var i := peoples.find(String(people_id))
	if i == -1 or states[i] != Estado.EM_COLHEITA:
		return []
	states[i] = Estado.PERDIDO
	var eventos: Array[Dictionary] = [{CHAVE: EV_PERDIDO, POVO: people_id}]
	eventos.append_array(_proxima())
	return eventos


func released() -> int:
	return states.count(Estado.SOLTO)


func kept() -> int:
	return states.count(Estado.FICADO)


## A producao daquela terra, em multiplo: 140% em Colheita, +80% para sempre se
## ficaste; soltos e em fila produzem o normal (§78).
func production_mult(people_id: StringName) -> float:
	match state_of(people_id):
		Estado.EM_COLHEITA, Estado.A_DECIDIR:
			return _curva.colheita_production_mult
		Estado.FICADO:
			return 1.0 + _curva.keep_production_bonus
	return 1.0


## A massa dos marcos que criaram raiz: cada povo ficado cujo marco enraiza pesa
## keep_landmark_mass todas as noites, e nao se corta (§78).
func landmark_mass() -> float:
	var n := 0
	for i in peoples.size():
		var povo := _povos.get(StringName(peoples[i])) as PeopleData
		if states[i] == Estado.FICADO and povo != null and povo.landmark_roots:
			n += 1
	return n * _curva.keep_landmark_mass


func to_dict() -> Dictionary:
	return Columns.to_dict(self)


func from_dict(d: Dictionary) -> void:
	Columns.from_dict(self, d)


## A que esta a decorrer ou a espera de decisao, ou -1.
func _atual() -> int:
	for i in states.size():
		if states[i] == Estado.EM_COLHEITA or states[i] == Estado.A_DECIDIR:
			return i
	return -1


func _proxima() -> Array[Dictionary]:
	var i := states.find(Estado.EM_FILA)
	if i == -1:
		return []
	var dias := duration(bool(assimilated[i]))  # antes de contar: nao se detem a si proprio
	states[i] = Estado.EM_COLHEITA
	days_left[i] = dias
	return [{CHAVE: EV_COMECA, POVO: StringName(peoples[i]), DIAS: days_left[i]}]
