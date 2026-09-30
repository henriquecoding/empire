# src/sim/systems/upkeep_system.gd — a manutencao do exercito, paga a alvorada
# (§06, sorvedouro 1).
#
# O §06 da-lhe tres escaloes — de graca ate a oitava tropa, 0,5 por tropa ate a
# vigesima, 1,5 dai para cima — e ate a auditoria de 26/09 so o modelo a cobrava
# (D7): a partida nao tinha sorvedouro nenhum alem das obras, e depois de o reino
# render nao havia pergunta sobre quantos soldados sustentar.
#
# Paga-se do saco do rei, a alvorada (§02: nao ha inventario). A fracao que um
# dia nao fecha passa ao seguinte. O que nao se paga fica em atraso (Q-144, o dono
# a 29/09/2026: "elabore um planeamento completo"): o atraso paga-se primeiro, nas
# alvoradas seguintes, e as tropas aguentam `wage_grace_days` dias de soldo por
# pagar. Para la disso vao-se embora tantas quantas o excesso paga, a um soldo por
# cabeca — as mais baratas sem posto primeiro —, e quem se vai leva a parte dela
# do atraso e so volta a poder ser recrutada `deserter_rest_days` dias depois. A
# deserção e proporcional ao defice e nao uma por dia: 13,5 de soldo por pagar ja
# nao se trocam por uma tropa de 1 moeda (auditoria de 27/09, N6). E a espiral
# (desercao -> menos renda -> mais desercao) trava-se na tolerancia: um dia mau
# nao leva ninguem.
#
# Puro: recebe a economia (que sabe a tabela de escaloes) e os UnitData.
class_name UpkeepSystem
extends RefCounted

const NENHUM := -1
const FOLGA := 0.0001

const EV_PAGA := 0
const EV_FOI := 1

const CHAVE := &"kind"
const QUANTO := &"amount"
const UNIDADE := &"unit"

## O soldo por pagar, fracao incluida: o atraso de dias anteriores e o que ainda
## nao chega a uma moeda (Q-124, Q-144).
var owed := 0.0
## Quem desertou: id -> dia em que volta a poder ser recrutado (RecruitSystem).
var resting: Dictionary = {}
## Dias de soldo que as tropas aguentam por pagar, e dias de quem desertou (Q-144).
var grace_days := 1.0
var rest_days := 2

var _dados: Dictionary


## `dados` e UnitData por id: quem acompanha o rei (o escudeiro) nao conta.
func _init(dados: Dictionary, curva: EconomyCurve = null) -> void:
	_dados = dados
	if curva != null:
		grace_days = curva.wage_grace_days
		rest_days = curva.deserter_rest_days


## As tropas que a manutencao conta: tuas, vivas, sem o rei, sem quem so o acompanha
## (a tag `follows_king`) e sem os corpos das classes jogaveis, que nao sao tropa (Q-162).
func troops(unidades: UnitSystem, rei: int) -> int:
	var n := 0
	for i in unidades.count():
		if _conta(unidades, i, rei):
			n += 1
	return n


## A alvorada: cobra o dia que acabou, e o atraso primeiro. `dia` e o que comeca.
func dawn(
	unidades: UnitSystem, rei: int, economia: EconomySystem, dia: int = 0
) -> Array[Dictionary]:
	var eventos: Array[Dictionary] = []
	var r := unidades.index_of(rei)
	if r == NENHUM or not unidades.alive(r):
		return eventos
	var tropas := troops(unidades, rei)
	var conta := economia.upkeep(tropas)
	owed += conta
	var pago := mini(int(floorf(owed + FOLGA)), unidades.carried_coins[r])
	if pago > 0:
		unidades.carried_coins[r] -= pago
		owed -= pago
		eventos.append({CHAVE: EV_PAGA, QUANTO: pago})
	# Para la da tolerancia, vai-se quem o excesso paga: cada um leva o soldo que
	# custava — o que a conta desce sem ele.
	while owed > conta * grace_days + 1.0 - FOLGA and tropas > 0:
		var cabeca := economia.upkeep(tropas) - economia.upkeep(tropas - 1)
		var quem := _quem_vai(unidades, rei)
		if cabeca <= 0.0 or quem == NENHUM:
			break
		var i := unidades.index_of(quem)
		unidades.owners[i] = RecruitSystem.SEM_DONO
		unidades.job_ids[i] = UnitSystem.NENHUM
		resting[quem] = dia + rest_days
		owed = maxf(0.0, owed - cabeca)
		tropas -= 1
		eventos.append({CHAVE: EV_FOI, UNIDADE: quem})
	return eventos


## O soldo inteiro em atraso, em moedas.
func arrears() -> int:
	return int(floorf(owed + FOLGA))


func to_dict() -> Dictionary:
	return {&"owed": owed, &"resting": resting.duplicate()}


func from_dict(guardado: Dictionary) -> void:
	owed = guardado.get(&"owed", 0.0)
	resting.clear()  # o mesmo dicionario que o RecruitSystem le
	resting.merge(guardado.get(&"resting", {}))


func _conta(unidades: UnitSystem, i: int, rei: int) -> bool:
	if unidades.ids[i] == rei or unidades.owners[i] == RecruitSystem.SEM_DONO:
		return false
	if not unidades.alive(i) or unidades.healths[i] <= 0:
		return false
	var dados: UnitData = _dados.get(unidades.data_ids[i])
	return dados == null or not (dados.tags.has(&"follows_king") or dados.tags.has(&"playable"))


## A tropa mais barata sem posto; sem nenhuma, a mais barata. Empate pelo id.
func _quem_vai(unidades: UnitSystem, rei: int) -> int:
	var melhor := NENHUM
	var chave := [1, INF, INF]
	for i in unidades.count():
		if not _conta(unidades, i, rei):
			continue
		var candidato := [
			0 if unidades.job_ids[i] == UnitSystem.NENHUM else 1,
			unidades.recruit_costs[i],
			unidades.ids[i],
		]
		if melhor == NENHUM or _antes(candidato, chave):
			melhor = unidades.ids[i]
			chave = candidato
	return melhor


func _antes(a: Array, b: Array) -> bool:
	for k in a.size():
		if a[k] != b[k]:
			return a[k] < b[k]
	return false
