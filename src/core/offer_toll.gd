# src/core/offer_toll.gd — o que uma oferta leva e da quando o preco nao cabe no
# prato (§75; Q-099, o dono a 29/09/2026: "consultar as mudancas da candeia e
# corrigir").
#
# O OfferPrice diz que se pagou (a moeda do rei no prato e o sim); isto leva o
# resto do mundo — o herdeiro em treino, um Marco consagrado, uma escora, a
# evolucao da classe — e da o que so existe fora da mancha: a Semente, a ganancia
# a zero. Vive fora do OfferWatch, que chegou perto das 250 linhas do §28.
class_name OfferToll
extends RefCounted


## Leva o preco `preco` do mundo. Devolve falso se ja nao havia o que levar.
static func take(preco: StringName) -> bool:
	match preco:
		&"successor":
			SimLoop.field.succession.days = 0
		&"marker":
			var arvores := SimLoop.night.amargueiros
			var k := arvores.fates.find(AmargueiroSystem.Fate.MARKER)
			if k < 0:
				return false
			arvores.fates[k] = AmargueiroSystem.Fate.STANDING  # volta a ser dela
		&"sealed_passage":
			var escora := sealed()
			if escora == null:
				return false
			escora.state = BuildSlot.State.RUIN  # a passagem abre
			escora.health = 0
		&"playable_class":
			SimLoop.field.classes.surrender()
	return true


## A primeira escora de pe, ou null.
static func sealed() -> BuildSlot:
	for obra in SimLoop.builds.standing():
		if obra.kind == Passages.ESCORA:
			return obra
	return null


## Os factos da §75 que vem de fora da mancha: o saco do rei (a tesouraria que ha,
## §02), os povos que ficaram, o herdeiro em treino, o bioma da regiao, as escoras.
static func facts() -> Dictionary:
	var saco := 0
	var i := SimLoop.units.index_of(SimLoop.king_id)
	if i != UnitSystem.NENHUM:
		saco = SimLoop.units.carried_coins[i]
	var regioes := SimLoop.state.chapters.regions
	var regiao := SimLoop.state.region
	var escoras := 0
	for obra in SimLoop.builds.standing():
		escoras += 1 if obra.kind == Passages.ESCORA else 0
	return {
		&"treasury": saco,
		&"peoples": SimLoop.night.harvest.kept.size(),
		&"successor": 1 if SimLoop.field.succession.days > 0 else 0,
		&"biome": StringName(regioes[regiao]) if regiao < regioes.size() else &"",
		&"sealed": escoras,
	}
