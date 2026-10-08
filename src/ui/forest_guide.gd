# src/ui/forest_guide.gd — o que o painel diz ao pe de uma arvore (ADR 0070).
#
# Antes da moeda sair, o painel diz quanto custa abater, o que o tronco da, e a quem a
# arvore serve: a coleta das provisoes e a toca do veado, com quantas arvores cada uma
# tem e quantas precisa. Se esta for a que faz a diferenca, diz o que se perde. Origem,
# alcance e destino escritos, e nao adivinhados (§7.5 do relatorio de vegetacao).
class_name ForestGuide
extends RefCounted


## O texto da arvore ao pe de `x`, ou "" se nao ha arvore de pe ao alcance.
static func context(x: float, values: Dictionary) -> String:
	if SimLoop.field == null:
		return ""
	var w := SimLoop.field.woodland
	var regras := ForestWatch.rules()
	var i := w.nearest(x, regras.tree_reach_px)
	if i < 0:
		return ""
	var especie := Registry.entry(&"flora", StringName(w.species[i])) as FloraData
	values["name"] = _tr(StringName(especie.display_key))
	values["cost"] = regras.fell_cost
	values["coins"] = especie.fell_coins
	values["work"] = roundi(especie.fell_work_s)
	return _tr(_key(w, i)).format(values) + _effects(w, i, values)


## A linha do bosque nas provisoes: quantas arvores apoiam a coleta, e se chegam.
static func grove(values: Dictionary) -> String:
	if SimLoop.field == null or not SimLoop.field.woodland.generated:
		return ""
	var regras := ForestWatch.rules()
	values["have"] = ForestWork.support(
		SimLoop.arrival.cache_x, regras.grove_feeds_radius, Influence.FORAGE
	)
	values["min"] = regras.grove_feeds_min
	values["bonus"] = ForestWork.forage_bonus()
	return "\n" + _tr(&"FOREST_CACHE_GROVE").format(values)


static func _key(w: Woodland, i: int) -> StringName:
	if w.states[i] == Woodland.State.MARKED:
		return &"FOREST_TREE_MARKED"
	if SimLoop.arrival.active and SimLoop.arrival.choice == &"":
		return &"FOREST_TREE_WILD"
	if not WallCrew.available(SimLoop.units, Band.Kind.SURFACE, SimLoop.builds.crew_owner):
		return &"FOREST_TREE_NO_BUILDER"
	return &"FOREST_TREE_CUT"


static func _effects(w: Woodland, i: int, values: Dictionary) -> String:
	var linhas := ""
	var regras := ForestWatch.rules()
	var flora := ForestWatch.flora()
	var o := SimLoop.arrival
	var come := Influence.kinds(flora, Influence.FORAGE)
	if o.active and Influence.would_lose(w, i, o.cache_x, regras.grove_feeds_radius, come) > 0:
		var tem := w.count_near(o.cache_x, regras.grove_feeds_radius, come)
		values["have"] = tem
		values["min"] = regras.grove_feeds_min
		values["bonus"] = regras.grove_feeds_bonus
		linhas += "\n" + _tr(&"FOREST_FEEDS").format(values)
		if tem == regras.grove_feeds_min:
			linhas += " " + _tr(&"FOREST_FEEDS_LOST")
	var abrigo := Influence.kinds(flora, Influence.SHELTER)
	var tocas := SimLoop.field.hunting.burrows
	for k in tocas.xs.size():
		if tocas.kinds[k] != String(ForestWatch.ARVORE):
			continue
		if Influence.would_lose(w, i, tocas.xs[k], regras.shelter_radius, abrigo) == 0:
			continue
		var tem := w.count_near(tocas.xs[k], regras.shelter_radius, abrigo)
		values["have"] = tem
		values["min"] = regras.shelter_min
		linhas += "\n" + _tr(&"FOREST_SHELTERS").format(values)
		if tem == regras.shelter_min:
			linhas += " " + _tr(&"FOREST_SHELTER_LOST")
	return linhas


static func _tr(key: StringName) -> String:
	return GuideHints.translate(key)
