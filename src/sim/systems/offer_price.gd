# src/sim/systems/offer_price.gd — se o preco de uma oferta caiu no prato (§75).
#
# Quatro precos tem hoje onde pegar, e sao os quatro gestos do Verbo 1 que o
# jogo ja tem: moedas largadas no prato; uma tropa ferida levada ate ele; uma
# tropa com nome levada ate ele; e, na decima segunda, uma com nome que leva
# todas as outras. Os outros oito precisam de sistemas que ainda nao ha (Q-091).
#
# Sem meias-aceitacoes: ou o preco inteiro esta no prato neste tick e sai tudo
# de uma vez, ou nao sai nada. O que caiu e nao chegou fica no chao, onde caiu.
class_name OfferPrice
extends RefCounted


## O que o preco levou, ou vazio se ainda nao esta pago.
static func pay(
	oferta: OfferData,
	prato: OfferSystem,
	moedas: CoinSystem,
	unidades: UnitSystem,
	titulos: Dictionary,
	tropas: Dictionary
) -> Dictionary:
	match oferta.price_kind:
		&"coins":
			return _moedas(oferta, prato, moedas)
		&"troops_below_health":
			var feridos := _tuas(
				unidades,
				tropas,
				func(i: int) -> bool: return _ferido(unidades, i, oferta.price_amount)
			)
			return _levar(prato, unidades, feridos)
		&"named_troop":
			var nomeadas := _tuas(
				unidades, tropas, func(i: int) -> bool: return titulos.has(unidades.ids[i])
			)
			var no_prato := _no_prato(prato, unidades, nomeadas)
			return _sair(unidades, no_prato.slice(0, 1)) if not no_prato.is_empty() else {}
		&"everything_named":
			var todas := _tuas(
				unidades, tropas, func(i: int) -> bool: return titulos.has(unidades.ids[i])
			)
			return _levar(prato, unidades, todas)
	return {}


## Moedas pousadas no prato, por id crescente, ate somar o preco.
static func _moedas(oferta: OfferData, prato: OfferSystem, moedas: CoinSystem) -> Dictionary:
	var ids := PackedInt32Array()
	for c in moedas.count():
		if moedas.settled[c] != 0 and prato.in_plate(moedas.xs[c], moedas.bands[c]):
			ids.append(moedas.ids[c])
	ids.sort()
	var soma := 0
	var levar := PackedInt32Array()
	for coin_id in ids:
		if soma >= int(oferta.price_amount):
			break
		soma += moedas.amounts[moedas.index_of(coin_id)]
		levar.append(coin_id)
	if soma < int(oferta.price_amount):
		return {}
	for coin_id in levar:
		moedas.remove(coin_id)
	return {OfferSystem.SAEM: PackedInt32Array(), OfferSystem.MOEDAS: soma}


## Basta UMA das do preco estar no prato para o preco inteiro sair.
static func _levar(prato: OfferSystem, unidades: UnitSystem, preco: PackedInt32Array) -> Dictionary:
	if _no_prato(prato, unidades, preco).is_empty():
		return {}
	return _sair(unidades, preco)


static func _sair(unidades: UnitSystem, quem: PackedInt32Array) -> Dictionary:
	for unit_id in quem:
		unidades.remove(unit_id)
	return {OfferSystem.SAEM: quem, OfferSystem.MOEDAS: 0}


## As tuas tropas vivas, sem o monarca, que cumprem `filtro`, por id crescente.
static func _tuas(unidades: UnitSystem, tropas: Dictionary, filtro: Callable) -> PackedInt32Array:
	var ids := PackedInt32Array()
	for i in unidades.count():
		if not unidades.alive(i) or unidades.owners[i] == RecruitSystem.SEM_DONO:
			continue
		var dados: UnitData = tropas.get(unidades.data_ids[i])
		if dados != null and dados.tags.has(OfferSystem.REI):
			continue
		if filtro.call(i):
			ids.append(unidades.ids[i])
	ids.sort()
	return ids


static func _no_prato(
	prato: OfferSystem, unidades: UnitSystem, ids: PackedInt32Array
) -> PackedInt32Array:
	var dentro := PackedInt32Array()
	for unit_id in ids:
		var i := unidades.index_of(unit_id)
		if prato.in_plate(unidades.xs[i], unidades.bands[i]):
			dentro.append(unit_id)
	return dentro


static func _ferido(unidades: UnitSystem, i: int, racio: float) -> bool:
	return float(unidades.healths[i]) < float(unidades.max_healths[i]) * racio
