# src/ui/class_guide.gd — o que o guia diz do companheiro do monarca e da evolucao dele
# (§08, §24; Q-114, Q-199, Q-200; ADR 0052). Tirado do GameplayGuide, que chegou as 250
# linhas do §28.
#
# Ate a ADR 0052 era aqui que o guia dizia "assumir" ao pe de uma tropa de classe, e a
# trela do rei. As duas sairam: so imperadores se jogam, e todos exploram.
class_name ClassGuide
extends RefCounted


## O companheiro a mao do monarca, e o que o Verbo 2 lhe compra: o escudo do escudeiro, o
## orcamento do Bardo, as flechas do escudeiro do Arqueiro. "" se nao ha que dizer.
static func companion(values: Dictionary) -> String:
	var units := SimLoop.units
	var rei := SimLoop.king_id
	var r := units.index_of(rei)
	match MonarchWatch.data().service:
		MonarchWatch.ESCUDO:
			var classes := SimLoop.field.classes
			if not KingVerbs.squire_wants(units, rei, classes):
				return ""
			values["shield"] = classes.squire.shield
			values["max"] = classes.squire.shield_cap()
			return _tr(&"CONTEXT_SQUIRE").format(values)
		MonarchWatch.CANTO:
			var b := MonarchWatch.at_hand(units, rei)
			if b < 0 or r < 0:
				return ""
			var corpo := Registry.entry(&"units", units.data_ids[b]) as UnitData
			values["budget"] = SimLoop.field.monarchy.budget_of(units.ids[b])
			values["max"] = int(corpo.ability_params.get(&"budget_cap", 0))
			if int(values["budget"]) >= int(values["max"]) or units.carried_coins[r] <= 0:
				return ""
			return _tr(&"CONTEXT_BARD").format(values)
		MonarchWatch.FLECHAS:
			return _quiver(units, r, values)
	return ""


## O estado da evolucao do monarca que nao e o Rei: a classe do perfil, a fase e o feito.
static func status() -> String:
	var id := HeroWatch.current()
	if id not in [&"archer", &"bard"]:
		return ""
	var data := Registry.entry(&"classes", id) as ClassData
	var progress := SimLoop.field.hero_progress
	var nome := data.display_key
	if id == MonarchWatch.skill_class():
		nome = MonarchWatch.data().display_key
	return _tr(&"CLASS_STATUS").format(
		{
			"name": _tr(StringName(nome)),
			"phase": progress.phase_of(id),
			"feat": progress.feat_of(id),
			"goal": data.evolve_condition_value,
			"action": _tr(&"HINT_CHARM" if id == &"bard" else &"HINT_MARK")
		}
	)


## O escudeiro do Arqueiro a mao: compra um lote por uma moeda da bolsa do imperador — ou
## diz que sem moedas nao ha flechas novas (Q-200). Com a aljava cheia, nada.
static func _quiver(units: UnitSystem, r: int, values: Dictionary) -> String:
	if r < 0 or MonarchWatch.at_hand(units, SimLoop.king_id) < 0:
		return ""
	var corpo := Registry.entry(&"units", units.data_ids[r]) as UnitData
	values["left"] = SimLoop.field.supply.left(units, r, corpo)
	values["max"] = corpo.ammo
	values["lot"] = RulesFactory.rules().arrows_per_coin
	if int(values["left"]) >= corpo.ammo:
		return ""
	var credito := int(SimLoop.field.supply.credit.get(units.ids[r], 0))
	if units.carried_coins[r] <= 0 and credito <= 0:
		return _tr(&"CONTEXT_QUIVER_NO_COINS").format(values)
	return _tr(&"CONTEXT_QUIVER").format(values)


static func _tr(chave: StringName) -> String:
	return TranslationServer.translate(chave)
