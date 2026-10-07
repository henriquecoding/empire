# src/sim/systems/territory_profile.gd — o que um territorio permite (o relatorio de
# 06/10/2026, §7.2; ADR 0077).
#
# Para cada sitio de obra que precisa de uma fonte, a resposta do PlacementRules; e, por
# necessidade, quantos cabem de quantos. E derivado: as fontes e os sitios chegam de
# fora, e as mesmas fontes dao sempre o mesmo perfil. A fotografia da fundacao guarda-o
# uma vez; o perfil vivo recalcula-se quando o mundo muda (cortar, fundar, gerar).
class_name TerritoryProfile
extends RefCounted

## As chaves de um sitio.
const ID := &"id"
const X := &"x"
const REACH := &"reach"
const MINIMUM := &"minimum"
## As chaves do perfil: a resposta por id de sitio, e Vector2i(cabem, total) por necessidade.
const SITES := &"sites"
const NEEDS := &"needs"


## Um sitio que precisa de `need`, onde ficaria (`x`, `band`) e o alcance que a regra lhe da.
static func site(
	id: int, need: StringName, x: float, band: int, reach: float, minimum := 1
) -> Dictionary:
	return {
		ID: id,
		PlacementRules.NEED: need,
		X: x,
		PlacementRules.BAND: band,
		REACH: reach,
		MINIMUM: minimum,
	}


static func of(sites: Array, sources: Array) -> Dictionary:
	var respostas := {}
	var contas := {}
	for s: Dictionary in sites:
		var need: StringName = s[PlacementRules.NEED]
		var r := PlacementRules.evaluate(
			need, s[X], int(s[PlacementRules.BAND]), sources, s[REACH], int(s[MINIMUM])
		)
		respostas[int(s[ID])] = r
		var conta: Vector2i = contas.get(need, Vector2i.ZERO)
		conta.y += 1
		if r[PlacementRules.ALLOWED]:
			conta.x += 1
		contas[need] = conta
	return {SITES: respostas, NEEDS: contas}


## Os ids dos sitios que o perfil recusa, por ordem.
static func barred(perfil: Dictionary) -> Array[int]:
	var ids: Array[int] = []
	var respostas: Dictionary = perfil[SITES]
	for id: int in respostas:
		if not respostas[id][PlacementRules.ALLOWED]:
			ids.append(id)
	ids.sort()
	return ids
