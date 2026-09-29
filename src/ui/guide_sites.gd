# src/ui/guide_sites.gd — o que o guia diz nalguns sitios: a boca de uma passagem,
# a casa do herdeiro e a bifurcacao. Tirado do GameplayGuide, que chegou as 250
# linhas do §28.
class_name GuideSites
extends RefCounted


## A boca de uma passagem: descer, ou escora-la enquanto a escora esta por pagar
## (Q-132). A escora a meio ou de pe ja nao se oferece.
static func passage(king: int, values: Dictionary) -> String:
	for site in SimLoop.builds.slots:
		if site.kind != Passages.ESCORA or site.band != SimLoop.units.bands[king]:
			continue
		if absf(site.x - SimLoop.units.xs[king]) > site.width * GameplayGuide.HALF:
			continue
		values["cost"] = PriceTag.owed_by(site)
		if site.state == BuildSlot.State.EMPTY and values.cost > 0:
			return TranslationServer.translate(&"CONTEXT_PASSAGE_SEAL").format(values)
	return TranslationServer.translate(&"CONTEXT_PASSAGE").format(values)


## A casa do herdeiro de pe: quantos dias de treino, e o que custa cada um (§15).
static func heir(values: Dictionary) -> String:
	var herdeiro := SimLoop.field.succession
	if herdeiro.ready():
		return TranslationServer.translate(&"CONTEXT_HEIR_READY").format(values)
	var curva := SimFactory.curve()
	values["days"] = herdeiro.days
	values["total"] = curva.heir_training_days
	values["cost"] = curva.heir_cost_per_day
	return TranslationServer.translate(&"CONTEXT_HEIR").format(values)


## A bifurcacao com a marcha pronta: o reconhecimento do §13 (Q-166). O povo da
## fortaleza seguinte, a firmeza que lhe sobra de marchas anteriores e o que os que
## estao perto do rei lhe tirariam agora.
static func march(values: Dictionary) -> String:
	var reino := SimLoop.field.realm
	var visto := reino.scouted(SimLoop.state)
	var povo := Registry.entry(&"peoples", reino.next_people(SimLoop.state)) as PeopleData
	values["people"] = TranslationServer.translate(povo.display_key) if povo != null else ""
	values["left"] = visto.x
	values["full"] = visto.y
	values["hit"] = reino.blow(SimLoop.units, SimLoop.king_id)
	return TranslationServer.translate(&"CONTEXT_CROSS").format(values)
