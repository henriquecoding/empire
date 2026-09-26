# src/sim/systems/economy_system.gd — tres circuitos, uma passagem por fase
# (§49, §06, §29 prompt 3).
#
# Duas metades, e as duas sao precisas:
#
# A CURVA — daily_income, upkeep, greed_cut, night_cost, suffocation_day. Nao
# corre no jogo: e o modelo que diz se a economia esta afinada. O dia da asfixia
# entre 9 e 14 e "o teste mais importante do projeto" (§29) e corre no CI sobre
# estas funcoes. Tem de bater com tests/support/reference_model.gd numero a
# numero — o F1-10 escreve isso, e a divergencia vai a ADR.
#
# A PASSAGEM — on_phase(), o passo 7 do §43. Uma vez por transicao de fase, e
# nunca por frame. A regra que o §49 mais defende e uma negativa: NUNCA escreve
# um inventario do jogador. Nao existe inventario. A materia vive no edificio
# que a produziu e sai de la como moeda no chao — e e isso que mantem os dois
# verbos intactos.
#
# Puro e determinista, sem RNG nenhum.
#
# Duas diferencas de forma face ao §29, e so de forma: o prompt escreve
# `daily_income(sources: Array[SourceData], ...)` e nao existe SourceData em
# lado nenhum da §44 — o que ha e a contagem de fontes do EconomyProfile, e e
# ela que entra. E a conversao de materia em moeda e 1:1 enquanto nao houver
# oficios (F1-11): o circuito 2 do §06 e Fase 2, e inventar-lhe uma taxa agora
# era escrever balanceamento em codigo. Ver docs/QUESTIONS.md, Q-065.
class_name EconomySystem
extends RefCounted

## A escala de uma percentagem. Nao e balanceamento: e a unidade da ganancia.
const PERCENTAGEM := 100.0

## Nenhuma asfixia dentro do horizonte que se olhou.
const NUNCA := 0

const EV_MOEDA := 0
const EV_ARRASADA := 1

const CHAVE := &"kind"
const VAGA := &"slot"
const QUANTO := &"amount"
const ONDE := &"x"
const FAIXA := &"band"

## Os impulsos reais (§15) e o dia em que se esta: a Colheita Forcada e a Chamada
## as Armas mexem no que cada obra rende hoje. Sem coroa, rende o que rendia.
var crown: CrownSystem
var today := 1

var _curva: EconomyCurve
var _fases: int


func _init(curva: EconomyCurve, fases: int) -> void:
	assert(curva != null, "o EconomySystem precisa de um EconomyCurve")
	assert(fases > 0, "o dia tem fases (§48)")
	_curva = curva
	_fases = fases


## Producao: a base construida a crescer a income_growth por dia (§06).
func daily_income(sources: int, day: int) -> float:
	var base := _curva.curve_income_flat + sources * _curva.curve_income_per_source
	return base * pow(_curva.income_growth, day - 1)


## Quantas fontes de producao estao de pe. E o `sources` do simulador do §06,
## lido do mundo em vez de vindo de um slider — a resposta de codigo a Q-033.
func sources(obras: BuildSystem) -> int:
	var quantas := 0
	for vaga in obras.standing():
		if vaga.yield_per_day > 0.0:
			quantas += 1
	return quantas


## O rendimento dos edificios REAIS, a crescer ao mesmo income_growth. O
## daily_income() acima e o modelo abstrato do §06 — 3 + 2,6 por fonte — e os
## dois nao dao o mesmo numero com os edificios de hoje: ver Q-033.
func built_income(obras: BuildSystem, day: int) -> float:
	var bruto := 0.0
	for vaga in obras.standing():
		bruto += vaga.yield_per_day
	return bruto * pow(_curva.income_growth, day - 1)


## Comercio, com efeito de rede a partir da segunda rota (§06, §29). Sem rotas e
## zero em qualquer dia, e nao um minimo simbolico.
func trade_income(routes: int, day: int) -> float:
	var rede := 1.0 + _curva.trade_network_bonus * maxi(0, routes - 1)
	return routes * _curva.trade_route_income * pow(_curva.trade_growth, day - 1) * rede


## Sorvedouro 1 (§06): tres escaloes, e os dois primeiros sao de graca ate ao
## oitavo soldado. Os numeros sao da curva; os do §29 sao o que o teste confere.
func upkeep(troop_count: int) -> float:
	if troop_count <= _curva.upkeep_free_troops:
		return 0.0
	var escalao1 := mini(troop_count, _curva.upkeep_tier1_limit) - _curva.upkeep_free_troops
	var escalao2 := maxi(0, troop_count - _curva.upkeep_tier1_limit)
	return escalao1 * _curva.upkeep_tier1_rate + escalao2 * _curva.upkeep_tier2_rate


## O que o rei leva antes de o reino ver a moeda (§15).
func greed_cut(gross: float, greed: int) -> float:
	return gross * greed / PERCENTAGEM


func net_income(sources: int, routes: int, troops: int, greed: int, day: int) -> float:
	var bruto := daily_income(sources, day) + trade_income(routes, day)
	return bruto - greed_cut(bruto, greed) - upkeep(troops)


## O que custa sobreviver a noite, a crescer a 1,22 por dia (§06, correcao v3).
func night_cost(day: int) -> float:
	return _curva.night_cost_base * pow(_curva.night_cost_growth, day - 1)


## O primeiro dia em que sobreviver custa mais do que se produz, ou NUNCA dentro
## de `dias`. E a pressao que faz do §06 uma economia e nao uma contabilidade.
func suffocation_day(perfil: EconomyProfile, dias: int) -> int:
	for d in range(1, dias + 1):
		if (
			night_cost(d)
			> net_income(perfil.sources, perfil.routes, perfil.troops, perfil.greed, d)
		):
			return d
	return NUNCA


## Passo 7 do §43: uma vez por transicao de fase. `rasto` sao os intervalos em x
## por onde a Podridao ja passou.
##
## Ordem por id da obra (§42, I2): duas conversoes a competir pela mesma materia
## resolvem-se sempre da mesma maneira, e o jogador aprende a ordem.
func on_phase(obras: BuildSystem, _fase: int, rasto: Array[Vector2]) -> Array[Dictionary]:
	var eventos: Array[Dictionary] = []
	for vaga in obras.standing():
		if vaga.yield_per_day <= 0.0:
			continue
		if _no_rasto(vaga.x, rasto):
			_queimar(vaga, eventos)
			continue
		var fator := crown.yield_mult(today, vaga.kind) if crown != null else 1.0
		vaga.stock += vaga.yield_per_day / _fases * fator
		var moedas := int(floorf(vaga.stock))
		if moedas <= 0:
			continue
		vaga.stock -= moedas
		eventos.append(
			{CHAVE: EV_MOEDA, VAGA: vaga, QUANTO: moedas, ONDE: vaga.x, FAIXA: int(vaga.band)}
		)
	return eventos


## §49: a plantacao no rasto e destruida; as outras so param. A distincao esta
## no BuildingData e nao num `if` por tipo — aqui so se le a bandeira.
func _queimar(vaga: BuildSlot, eventos: Array[Dictionary]) -> void:
	vaga.stock = 0.0
	if vaga.razed_by_rot:
		eventos.append({CHAVE: EV_ARRASADA, VAGA: vaga})


func _no_rasto(x: float, rasto: Array[Vector2]) -> bool:
	for faixa in rasto:
		if x >= faixa.x and x <= faixa.y:
			return true
	return false
