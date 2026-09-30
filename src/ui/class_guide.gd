# src/ui/class_guide.gd — o que o guia diz a quem conduz uma classe, e ao rei ao pe de
# quem ele pode assumir (§08, §24; Q-150, Q-162, Q-178). Tirado do GameplayGuide, que
# chegou as 250 linhas do §28.
class_name ClassGuide
extends RefCounted


## Com um corpo de classe assumido: a passagem, o rei ao pe (para voltar a ele) e as
## terras geradas. O corpo nao gere (§08), e por isso as obras nao lhe dizem nada.
static func context(values: Dictionary) -> String:
	var units := SimLoop.units
	var quem := Assume.driven()
	var i := units.index_of(quem)
	if i < 0:
		return ""
	var abertas := Passages.open(SimLoop.passages, SimLoop.builds)
	if Verbs.destination(units, quem, abertas) != Verbs.NENHUMA:
		return GuideSites.passage(i, values)
	var r := units.index_of(SimLoop.king_id)
	if r >= 0 and units.alive(r) and units.bands[r] == units.bands[i]:
		if absf(units.xs[r] - units.xs[i]) <= Assume.reach():
			return _tr(&"CONTEXT_BACK_TO_KING").format(values)
	return GuideSites.wilds(units.xs[i], values)


## O rei ao pe de um corpo ou de uma tropa tua de uma classe desbloqueada: o Verbo 2
## assume-a. "" se nao ha quem.
static func assume_hint(values: Dictionary) -> String:
	var units := SimLoop.units
	var r := units.index_of(SimLoop.king_id)
	if r < 0:
		return ""
	var roster := SimLoop.field.roster
	var desbloqueadas := Assume.unlocked()
	for i in units.count():
		if i == r or not units.alive(i) or units.owners[i] != units.owners[r]:
			continue
		if units.bands[i] != units.bands[r] or absf(units.xs[i] - units.xs[r]) > Assume.reach():
			continue
		var classe := roster.class_of_body(units.data_ids[i])
		if classe == &"":
			classe = roster.class_of_troop(units.data_ids[i])
			if classe != &"" and roster.body(units, classe, units.owners[r]) != UnitSystem.NENHUM:
				continue
		if classe == &"" or classe == Roster.REI or not desbloqueadas.has(String(classe)):
			continue
		var dados := Registry.entry(&"classes", classe) as ClassData
		values["name"] = _tr(dados.display_key)
		return _tr(&"CONTEXT_ASSUME").format(values)
	return ""


## O rei chegou a trela (Q-150): daqui para la vao as classes.
static func leash(values: Dictionary) -> String:
	var units := SimLoop.units
	var r := units.index_of(SimLoop.king_id)
	if r < 0 or not Assume.king():
		return ""
	var limites := Assume.limits(SimLoop.king_id)
	var x := units.xs[r]
	if minf(absf(x - limites.x), absf(x - limites.y)) > Assume.reach():
		return ""
	if Frontier.walk_limits() == limites:
		return ""
	return _tr(&"CONTEXT_KING_LEASH").format(values)


static func _tr(chave: StringName) -> String:
	return TranslationServer.translate(chave)
