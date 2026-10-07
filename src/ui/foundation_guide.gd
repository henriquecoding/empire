# src/ui/foundation_guide.gd — o que a fundacao aqui leva e o que deixa (ADR 0066, 0070).
#
# Parado num sitio livre, a ficha do sitio (UX-08, ADR 0078) diz as consequencias daquele
# sitio, contadas e nao inventadas: as arvores que a clareira tira (sem madeira), se isso
# tira o apoio do bosque a coleta ou o abrigo da toca do veado, e o que fica dentro da
# clareira porque nunca se limpa — a estatua, as raizes da Podridao, a passagem. E o que
# o territorio ali permite e o que falta (ADR 0077): a mesma conta que a confirmacao faz,
# e nao um indice de "qualidade". Uma fonte so: a ficha e os testes leem estas secoes.
class_name FoundationGuide
extends RefCounted

const FONTES := {
	&"water": &"TERRAIN_SOURCE_WATER",
	&"forest": &"TERRAIN_SOURCE_FOREST",
	&"rock": &"TERRAIN_SOURCE_ROCK",
}
## As tres secoes da ficha: o que a clareira leva, o que fica, e o que o territorio permite.
const CLEARS := &"clears"
const KEEPS := &"keeps"
const TERRITORY := &"territory"


## As linhas de cada secao de fundar em `x`, cada uma vazia se nao ha nada a dizer.
static func sections(x: float) -> Dictionary:
	var partes := {
		CLEARS: PackedStringArray(), KEEPS: PackedStringArray(), TERRITORY: PackedStringArray()
	}
	if SimLoop.field == null:
		return partes
	var raio := LastCartWatch.rules().foundation_clear_radius
	var w := SimLoop.field.woodland
	var leva := PackedStringArray()
	var arvores := 0
	for i in w.count():
		if w.standing(i) and absf(w.xs[i] - x) <= raio:
			arvores += 1
	if arvores > 0:
		leva.append(_tr(&"FOUNDATION_CLEARS_TREES").format({"trees": arvores}))
	if _loses(x, raio, SimLoop.arrival.cache_x, Influence.FORAGE):
		leva.append(_tr(&"FOUNDATION_GROVE_LOST"))
	var tocas := SimLoop.field.hunting.burrows
	for k in tocas.xs.size():
		if tocas.kinds[k] == String(ForestWatch.ARVORE):
			if _loses(x, raio, tocas.xs[k], Influence.SHELTER):
				leva.append(_tr(&"FOUNDATION_SHELTER_LOST"))
				break
	partes[CLEARS] = leva
	var ficam := _kept(x, raio)
	if not ficam.is_empty():
		partes[KEEPS] = PackedStringArray(
			[_tr(&"FOUNDATION_KEEPS").format({"kept": ", ".join(ficam)})]
		)
	partes[TERRITORY] = territory_rows(x)
	return partes


## As linhas do territorio de `x`, juntas: o que a previsao da confirmacao diz.
static func territory(x: float) -> String:
	return "\n".join(territory_rows(x))


## Por obra que precisa de uma fonte (e que ja se sabe fazer): se a tem ao alcance aqui.
static func territory_rows(x: float) -> PackedStringArray:
	var respostas: Dictionary = TerritoryWatch.preview(x)[TerritoryProfile.SITES]
	var contas := {}
	for vaga in SimLoop.builds.slots:
		if not respostas.has(vaga.id) or not Discoveries.known(SimLoop.state, vaga.kind):
			continue
		var conta: Vector2i = contas.get(vaga.kind, Vector2i.ZERO)
		conta += Vector2i(1 if respostas[vaga.id][PlacementRules.ALLOWED] else 0, 1)
		contas[vaga.kind] = conta
	var linhas := PackedStringArray()
	for kind: StringName in contas:
		var dados := Registry.entry(&"buildings", kind) as BuildingData
		var conta: Vector2i = contas[kind]
		var chave := &"TERRAIN_SITE_SOME"
		if conta.x == conta.y:
			chave = &"TERRAIN_SITE_OK"
		elif conta.x == 0:
			chave = &"TERRAIN_SITE_NONE"
		var valores := {
			"name": _tr(dados.display_key),
			"source": _tr(FONTES.get(dados.requires_biome_feature, &"TERRAIN_SOURCE_WATER")),
			"ok": conta.x,
			"all": conta.y,
		}
		linhas.append(_tr(chave).format(valores))
	return linhas


## Se limpar `raio` a volta de `x` deixa o destino em `alvo` abaixo do minimo da regra `tag`.
static func _loses(x: float, raio: float, alvo: float, tag: StringName) -> bool:
	var regras := ForestWatch.rules()
	var forage := tag == Influence.FORAGE
	var alcance := regras.grove_feeds_radius if forage else regras.shelter_radius
	var minimo := regras.grove_feeds_min if forage else regras.shelter_min
	var kinds := Influence.kinds(ForestWatch.flora(), tag)
	var w := SimLoop.field.woodland
	var antes := w.count_near(alvo, alcance, kinds)
	var depois := 0
	for i in w.count():
		var conta := w.standing(i) and kinds.has(StringName(w.species[i]))
		if conta and absf(w.xs[i] - alvo) <= alcance and absf(w.xs[i] - x) > raio:
			depois += 1
	return antes >= minimo and depois < minimo


## O que fica dentro da clareira porque nunca se limpa.
static func _kept(x: float, raio: float) -> Array[String]:
	var ficam: Array[String] = []
	for at in SimLoop.secrets.xs:
		if absf(at - x) <= raio:
			ficam.append(_tr(&"FOUNDATION_NEAR_STATUE"))
			break
	for at in SimLoop.night.amargueiros.xs:
		if absf(at - x) <= raio:
			ficam.append(_tr(&"FOUNDATION_NEAR_ROOTS"))
			break
	for at in SimLoop.passages:
		if absf(at - x) <= raio:
			ficam.append(_tr(&"FOUNDATION_NEAR_PASSAGE"))
			break
	return ficam


static func _tr(key: StringName) -> String:
	return TranslationServer.translate(key)
