# src/core/royal_song.gd — a ordem da Imperatriz Nia ao Bardo dela (ADR 0052, Q-199; o
# dono a 02/10/2026: "um bardo com bandeira nas costas, remunerado para encantar
# inimigos e incentivar aliados").
#
# "Nia nao canta no lugar do bardo. O comando do jogador solicita uma acao do
# companheiro, validando se ele esta vivo, proximo, na faixa apropriada, pronto e
# financiado" (plano §4.2). O alvo diz a acao, como o Maestro ja fazia: um inimigo mais
# perto da mira do que uma tropa tua e encantado (convertido, como Maestro); uma tropa tua
# e promovida (Maestro) ou incentivada. Paga-se do orcamento do Bardo e depois da bolsa
# dela, uma vez, no mesmo tick em que o canto acontece: o que nao aconteceu nao se paga.
class_name RoyalSong
extends RefCounted

const NENHUM := -1
const BARDO := &"bard"


## A habilidade da imperatriz em `x`. Verdadeiro se o Bardo cantou; o porque fica no
## HeroWatch.feedback.
static func order(x: float) -> bool:
	var units := SimLoop.units
	var campo := SimLoop.field
	var b := MonarchWatch.at_hand(units, SimLoop.king_id)
	if b == NENHUM:
		HeroWatch.feedback = &"COMBAT_BARD_AWAY"
		return false
	if float(campo.song.cooldowns.get(units.ids[b], 0.0)) > 0.0:
		HeroWatch.feedback = &"COMBAT_SKILL_RECOVERING"
		return false
	var fase := campo.hero_progress.phase_of(BARDO)
	var inimigo := _inimigo(units, b, x)
	var tropa := _tropa(units, b, x)
	# Como Maestro, uma tropa tua tao perto da mira como o inimigo e promovida primeiro: um
	# empate nao troca a promocao por um encanto sem dizer nada.
	if fase > 1 and tropa <= inimigo and _promover(units, b, x):
		return true
	if inimigo < INF and inimigo <= tropa:
		return _encantar(units, b, x, fase)
	return _incentivar(units, b)


static func _encantar(units: UnitSystem, b: int, x: float, fase: int) -> bool:
	var campo := SimLoop.field
	var p := _params(units, b)
	var bardo := units.ids[b]
	var teto := int(p.get(&"max_permanent_mass" if fase > 1 else &"max_temporary", 0))
	if _encantados(bardo, fase > 1) >= teto:
		HeroWatch.feedback = &"COMBAT_BARD_LIMIT"
		return false
	var preco := int(p.get(&"convert_cost" if fase > 1 else &"charm_cost", 0))
	if not _paga(units, b, preco, false):
		return false
	var antes := campo.song.conversions()
	var alvo := campo.song.cast(units, SimLoop.creatures, bardo, x, fase)
	if alvo < 0:
		return false
	_paga(units, b, preco, true)
	if campo.song.conversions() > antes:
		campo.hero_progress.record(BARDO)  # o feito da Nia: criaturas distintas, com ela
	EventBus.queue(&"target_marked", [alvo, bardo])
	HeroWatch.feedback = &"COMBAT_CHARMED"
	return true


static func _promover(units: UnitSystem, b: int, x: float) -> bool:
	var preco := int(_params(units, b).get(&"promote_cost", 0))
	if not _paga(units, b, preco, false) or not BardPromotion.at(units.ids[b], x, true):
		return false
	_paga(units, b, preco, true)
	HeroWatch.feedback = &"COMBAT_PROMOTED"
	return true


static func _incentivar(units: UnitSystem, b: int) -> bool:
	var p := _params(units, b)
	var preco := int(p.get(&"encourage_cost", 0))
	if not _paga(units, b, preco, false):
		return false
	var raio := float(p.get(&"encourage_radius", 0.0))
	var boost := float(p.get(&"encourage_boost", 0.0)) * ImperialSuccession.bonus()
	var prazo := float(p.get(&"encourage_seconds", 0.0))
	if SimLoop.field.monarchy.encourage(units, b, raio, boost, prazo) <= 0:
		return false
	_paga(units, b, preco, true)
	var corpo := Registry.entry(&"units", units.data_ids[b]) as UnitData
	SimLoop.field.song.cooldowns[units.ids[b]] = corpo.attack_interval
	HeroWatch.feedback = &"COMBAT_ENCOURAGED"
	return true


## A distancia da mira ao inimigo mais perto dela, ao alcance do canto (INF se nenhum).
static func _inimigo(units: UnitSystem, b: int, x: float) -> float:
	var bichos := SimLoop.creatures
	var raio := float(_params(units, b).get(&"radius", 0.0))
	var inimigo := INF
	for c in bichos.count():
		if not bichos.alive(c) or bichos.bands[c] != units.bands[b]:
			continue
		if SimLoop.field.song.allies.has(bichos.ids[c]) or absf(bichos.xs[c] - units.xs[b]) > raio:
			continue
		inimigo = minf(inimigo, absf(bichos.xs[c] - x))
	return inimigo


## A distancia da mira a tropa tua mais perto dela, na faixa do Bardo (INF se nenhuma).
static func _tropa(units: UnitSystem, b: int, x: float) -> float:
	var tropa := INF
	for i in units.count():
		if i == b or units.ids[i] == SimLoop.king_id or not units.alive(i):
			continue
		if units.owners[i] == units.owners[b] and units.bands[i] == units.bands[b]:
			tropa = minf(tropa, absf(units.xs[i] - x))
	return tropa


## Quanto este bardo ja tem encantado: os temporarios contam por cabeca (fase base); os
## convertidos de vez (Maestro) contam pela massa, nao por cabeca (Q-199).
static func _encantados(bardo: int, permanentes: bool) -> int:
	var n := 0
	var aliados := SimLoop.field.song.allies
	var bichos := SimLoop.creatures
	for id: int in aliados:
		if int(aliados[id][&"bard"]) != bardo or bool(aliados[id][&"permanent"]) != permanentes:
			continue
		var c := bichos.index_of(id)
		if not permanentes:
			n += 1
		elif c >= 0:
			n += (Registry.entry(&"creatures", bichos.data_ids[c]) as CreatureData).mass_cost
	return n


## `pagar` falso so confere; verdadeiro debita. Sem moedas, diz porque e nao debita nada.
static func _paga(units: UnitSystem, b: int, preco: int, pagar: bool) -> bool:
	var reino := SimLoop.field.monarchy
	var r := units.index_of(SimLoop.king_id)
	if not pagar:
		var chega := reino.can_pay(units, r, units.ids[b], preco)
		if not chega:
			HeroWatch.feedback = &"COMBAT_BARD_UNPAID"
		return chega
	if preco > 0 and reino.charge(units, r, units.ids[b], preco):
		EventBus.queue(&"coin_spent", [preco, MonarchWatch.BARDO])
	return true


static func _params(units: UnitSystem, b: int) -> Dictionary:
	return (Registry.entry(&"units", units.data_ids[b]) as UnitData).ability_params
