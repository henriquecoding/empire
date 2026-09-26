# src/sim/systems/upkeep_system.gd — a manutencao do exercito, paga a alvorada
# (§06, sorvedouro 1).
#
# O §06 da-lhe tres escaloes — de graca ate a oitava tropa, 0,5 por tropa ate a
# vigesima, 1,5 dai para cima — e ate a auditoria de 26/09 so o modelo a cobrava
# (D7): a partida nao tinha sorvedouro nenhum alem das obras, e depois de o reino
# render nao havia pergunta sobre quantos soldados sustentar.
#
# Paga-se do saco do rei, a alvorada (§02: nao ha inventario). A fracao que um
# dia nao fecha passa ao seguinte. Sem moedas para a parte inteira, a divida do
# dia perdoa-se e UMA tropa vai-se embora — a mais barata que nao esta num posto,
# e so se nao houver, a mais barata de todas. Deixa de ser tua; fica com a classe
# e com o que leva no saco, e pode voltar a ser recrutada (§25). Q-124.
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

## O que ficou por pagar e ainda nao chega a uma moeda.
var owed := 0.0

var _dados: Dictionary


## `dados` e UnitData por id: quem acompanha o rei (o escudeiro) nao conta.
func _init(dados: Dictionary) -> void:
	_dados = dados


## As tropas que a manutencao conta: tuas, vivas, sem o rei e sem quem so o
## acompanha (a tag `follows_king`).
func troops(unidades: UnitSystem, rei: int) -> int:
	var n := 0
	for i in unidades.count():
		if _conta(unidades, i, rei):
			n += 1
	return n


## A alvorada: cobra o dia que acabou.
func dawn(unidades: UnitSystem, rei: int, economia: EconomySystem) -> Array[Dictionary]:
	var eventos: Array[Dictionary] = []
	var r := unidades.index_of(rei)
	if r == NENHUM or not unidades.alive(r):
		return eventos
	owed += economia.upkeep(troops(unidades, rei))
	var devido := int(floorf(owed + FOLGA))
	var pago := mini(devido, unidades.carried_coins[r])
	if pago > 0:
		unidades.carried_coins[r] -= pago
		owed -= pago
		eventos.append({CHAVE: EV_PAGA, QUANTO: pago})
	if pago < devido:
		owed -= devido - pago
		var quem := _quem_vai(unidades, rei)
		if quem != NENHUM:
			var i := unidades.index_of(quem)
			unidades.owners[i] = RecruitSystem.SEM_DONO
			unidades.job_ids[i] = UnitSystem.NENHUM
			eventos.append({CHAVE: EV_FOI, UNIDADE: quem})
	return eventos


func to_dict() -> Dictionary:
	return {&"owed": owed}


func from_dict(guardado: Dictionary) -> void:
	owed = guardado.get(&"owed", 0.0)


func _conta(unidades: UnitSystem, i: int, rei: int) -> bool:
	if unidades.ids[i] == rei or unidades.owners[i] == RecruitSystem.SEM_DONO:
		return false
	if not unidades.alive(i) or unidades.healths[i] <= 0:
		return false
	var dados: UnitData = _dados.get(unidades.data_ids[i])
	return dados == null or not dados.tags.has(&"follows_king")


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
