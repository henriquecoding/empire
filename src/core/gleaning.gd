# src/core/gleaning.gd — quem pisa uma moeda apanha-a (§02, §08, Q-107, Q-111).
#
# O rei apanha o que pisa; o escudeiro, o que caiu (Q-114). E, desde o painel de
# 29/09/2026, as tuas tropas tambem: "e como em Kingdom — se o jogador nao pega, o
# vagabundo pode pegar e tornar-se tropa, ou a tropa pode pegar e armazenar". A
# tropa guarda a moeda caida no saco dela, ate a capacidade do UnitData (Q-111), e
# entrega-a ao rei quando ele passa — pelo mesmo livro da caca (`guarda`, o
# HuntingSystem.bagged). Nao apanha o que o rei largou: essa moeda tem destino.
#
# Separado do Verbs, que chegou as 250 linhas do §28.
class_name Gleaning
extends RefCounted


## Um tick: cada um dos teus apanha o que tem aos pes. `guarda` e o livro das
## moedas que as tropas levam para o rei (id -> moedas).
static func sweep(
	unidades: UnitSystem, moedas: CoinSystem, king_id: int, guarda: Dictionary
) -> void:
	if moedas.count() == 0:
		return
	var ha_caidas := _ha_caidas(moedas)
	for i in unidades.count():
		if unidades.owners[i] == RecruitSystem.SEM_DONO or not unidades.alive(i):
			continue
		var espaco := unidades.coin_capacities[i] - unidades.carried_coins[i]
		if espaco <= 0:
			continue
		var rei := unidades.ids[i] == king_id
		if not rei and not ha_caidas:
			continue
		var faixa := unidades.bands[i] as Band.Kind
		# So o rei leva as que ele proprio largou; os outros apanham as caidas.
		if rei and awaited(unidades, moedas, i):
			continue
		var levado := Verbs.collect(moedas, unidades.ids[i], unidades.xs[i], faixa, espaco, not rei)
		if levado <= 0:
			continue
		unidades.carried_coins[i] += levado
		if not rei and not _escudeiro(unidades, i):
			guarda[unidades.ids[i]] = int(guarda.get(unidades.ids[i], 0)) + levado


## Se ha, aos pes de quem varre, uma moeda que o rei largou e que alguem por
## recrutar esta a vir buscar (§25, 0:20). O rei nao a leva de volta ao saco
## antes de ele la chegar: largar ao lado de alguem tem de chegar a ele
## (auditoria de 26/09). Afasta-te, ou ele apanha-a, e o chao volta a ser teu.
static func awaited(unidades: UnitSystem, moedas: CoinSystem, i: int) -> bool:
	var curva := SimFactory.curve()
	for c in moedas.count():
		if moedas.from_king[c] == 0 or moedas.settled[c] == 0:
			continue
		if moedas.bands[c] != unidades.bands[i]:
			continue
		if absf(moedas.xs[c] - unidades.xs[i]) > curva.coin_pickup_px:
			continue
		for u in unidades.count():
			if unidades.owners[u] != RecruitSystem.SEM_DONO or not unidades.alive(u):
				continue
			if unidades.bands[u] == moedas.bands[c]:
				if absf(unidades.xs[u] - moedas.xs[c]) <= curva.recruit_notice_px:
					return true
	return false


## O escudeiro guarda o que apanha para ele (Q-114): nao entra no livro do rei.
static func _escudeiro(unidades: UnitSystem, i: int) -> bool:
	var dados := Registry.entry(Verbs.TABELA_TROPAS, unidades.data_ids[i]) as UnitData
	return dados != null and dados.tags.has(&"collects_coins")


static func _ha_caidas(moedas: CoinSystem) -> bool:
	for c in moedas.count():
		if moedas.settled[c] != 0 and moedas.from_king[c] == 0:
			return true
	return false
