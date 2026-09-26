class_name GameplayGuide
extends RefCounted

const HALF := 0.5
const CEM := 100.0


static func goal() -> String:
	if SimLoop.night.rot.active():
		return _tr(&"HUD_GOAL_NIGHT")
	var worker := false
	var hunter := false
	for i in SimLoop.units.count():
		if not SimLoop.units.alive(i) or SimLoop.units.owners[i] == RecruitSystem.SEM_DONO:
			continue
		var data := Registry.entry(&"units", SimLoop.units.data_ids[i]) as UnitData
		worker = worker or data.tags.has(&"worker")
		hunter = hunter or data.tags.has(&"hunter")
	if not worker:
		return _tr(&"GUIDE_WORKER")
	for site in SimLoop.builds.slots:
		if site.blocks and not site.mending and site.repair_cost() > 0:
			return _tr(&"GUIDE_REPAIR")
	if not hunter:
		return _tr(&"GUIDE_HUNTER")
	var production := false
	var wall := false
	for site in SimLoop.builds.standing():
		production = production or site.yield_per_day > 0
		wall = wall or site.two_paths()
	if not production:
		return _tr(&"GUIDE_FARM")
	return _tr(&"GUIDE_EXPLORE" if wall else &"GUIDE_WALL")


## As tropas que o painel conta: quem e teu e esta vivo, sem o monarca — ele e
## quem as tem, e "TROPAS 01" com o rei sozinho em campo dizia que havia uma.
static func troops() -> int:
	var total := 0
	for i in SimLoop.units.count():
		if not SimLoop.units.alive(i) or SimLoop.units.ids[i] == SimLoop.king_id:
			continue
		if SimLoop.units.owners[i] != RecruitSystem.SEM_DONO:
			total += 1
	return total


static func context(device: Glyphs.Device) -> String:
	var units := SimLoop.units
	var king := units.index_of(SimLoop.king_id)
	if king < 0:
		return ""
	var buttons: Array = Glyphs.BOTOES[device]
	var values := {"drop": _button(buttons[1]), "assume": _button(buttons[2])}
	if Verbs.destination(units, SimLoop.king_id, SimLoop.passages) != Verbs.NENHUMA:
		return _tr(&"CONTEXT_PASSAGE").format(values)
	for site in SimLoop.builds.slots:
		if site.band != units.bands[king] or absf(site.x - units.xs[king]) > site.width * HALF:
			continue
		if site.kind == BuildSlot.NUCLEO:
			continue
		values["name"] = _building_name(site)
		values["cost"] = PriceTag.owed_by(site)
		if site.state in [BuildSlot.State.SCAFFOLD, BuildSlot.State.BUILDING]:
			return _tr(&"CONTEXT_BUILDING").format(values)
		if site.mending:
			return _tr(&"CONTEXT_REPAIRING").format(values)
		if site.state in [BuildSlot.State.DAMAGED, BuildSlot.State.RUIN] and values.cost > 0:
			return _tr(&"CONTEXT_REPAIR").format(values)
		if Verbs.wall_choice_open(site):
			values["path"] = _tr(
				&"PATH_GARRISON" if site.path == BuildSlot.Path.GUARNICAO else &"PATH_FORTIFY"
			)
			return _tr(&"CONTEXT_WALL").format(values)
		if values.cost > 0:
			if not SimLoop.builds.can_climb(site, SimLoop.state, SimLoop.night.amargueiros):
				return _tr(&"CONTEXT_LOCKED").format(values)
			return _tr(&"CONTEXT_BUILD").format(values)
		return _training(site, values)
	var nearest := -1
	var distance := SimFactory.curve().recruit_notice_px
	for i in units.count():
		if units.owners[i] != RecruitSystem.SEM_DONO or not units.alive(i):
			continue
		var gap := absf(units.xs[i] - units.xs[king])
		if units.bands[i] == units.bands[king] and gap < distance:
			distance = gap
			nearest = i
	if nearest >= 0:
		var data := Registry.entry(&"units", units.data_ids[nearest]) as UnitData
		values["name"] = _tr(data.display_key)
		values["cost"] = PriceTag.owed_by_unit(units, nearest)
		return _tr(&"CONTEXT_RECRUIT").format(values)
	return ""


static func _building_name(site: BuildSlot) -> String:
	if site.two_paths():
		return _tr(&"CONTEXT_WALL_NAME")
	var data := Registry.entry(&"buildings", site.kind) as BuildingData
	return _tr(data.display_key) if data != null else _tr(&"CONTEXT_SITE")


static func _button(button: Variant) -> String:
	return _tr(button) if button is StringName else String(button)


static func _tr(key: StringName) -> String:
	return TranslationServer.translate(key)


## Uma obra de pe: se forma um oficio (§09), diz o preco do treino, quem esta
## la dentro, ou que falta um trabalhador teu para mandar; senao, funciona.
static func _training(site: BuildSlot, values: Dictionary) -> String:
	if SimLoop.field.conversion.craft_of(site) != null and site.standing():
		return _conversion(site, values)
	var treino := SimLoop.field.training
	var oficio := treino.craft_of(site)
	if oficio == null or not site.standing():
		return _tr(&"CONTEXT_DONE").format(values)
	values["craft"] = _tr(oficio.display_key)
	for quem in treino.trainees:
		if treino.trainees[quem][0] == site.id:
			return _tr(&"CONTEXT_TRAINING").format(values)
	values["cost"] = treino.owed(site, SimLoop.units)
	if values.cost <= 0:
		return _tr(&"CONTEXT_TRAIN_NOBODY").format(values)
	return _tr(&"CONTEXT_TRAIN").format(values)


## Uma casa de conversao (§06, circuito 2): o que faz agora, e o que a moeda
## largada nela faria — vender, ou mandar o oficio dar a capacidade (Q-112).
static func _conversion(site: BuildSlot, values: Dictionary) -> String:
	var conversao := SimLoop.field.conversion
	var conv := conversao.craft_of(site)
	var oficio := Registry.entry(&"units", conv.capacity_craft) as UnitData
	values["material"] = _tr(conv.display_key)
	values["bonus"] = roundi((conv.coin_multiplier - 1.0) * CEM)
	values["craft"] = _tr(oficio.display_key) if oficio != null else ""
	values["effect"] = _tr(&"CAPACITY_" + String(conv.capacity_kind).to_upper()).format(
		{"pct": roundi(absf(conv.magnitude) * CEM)}
	)
	var chave := conversion_key(conversao.status(site), conversao.has_craft(conv.capacity_craft))
	return _tr(chave).format(values)


## A frase de uma casa de conversao. O modo guardado nao chega: a capacidade
## escolhida sem o oficio vende, e com ele so da efeito depois de uma fase com
## materia — o que se diz e o estado efectivo (planejamento 26/09, §7).
static func conversion_key(estado: ConversionSystem.Status, tem_oficio: bool) -> StringName:
	match estado:
		ConversionSystem.Status.ACTIVE:
			return &"CONTEXT_CONVERT_CAPACITY"
		ConversionSystem.Status.WAITING:
			return &"CONTEXT_CONVERT_WAITING"
		ConversionSystem.Status.WANTS_CRAFT:
			return &"CONTEXT_CONVERT_WANTS_CRAFT"
	return &"CONTEXT_CONVERT_COIN" if tem_oficio else &"CONTEXT_CONVERT_NOBODY"
