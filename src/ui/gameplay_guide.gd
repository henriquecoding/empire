class_name GameplayGuide
extends RefCounted

const CEM := 100.0


static func goal() -> String:
	return GuideGoal.goal()


static func troops() -> int:
	var total := 0
	for i in SimLoop.units.count():
		if (
			not SimLoop.units.alive(i)
			or SimLoop.units.ids[i] == SimLoop.king_id
			or (
				SimLoop.units.owners[i]
				!= SimLoop.units.owners[SimLoop.units.index_of(SimLoop.king_id)]
			)
		):
			continue
		var dados := Registry.entry(&"units", SimLoop.units.data_ids[i]) as UnitData
		if dados.tags.has(&"follows_king"):  # o companheiro do monarca nao e tropa
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
	if not Assume.king():  # so o titular da coroa gere (§08, ADR 0052)
		return ""
	var abertas := Passages.open(SimLoop.passages, SimLoop.builds)
	if Verbs.destination(units, SimLoop.king_id, abertas) != Verbs.NENHUMA:
		return GuideSites.passage(king, values)
	if units.bands[king] == int(Band.Kind.SURFACE) and Verbs.at_fork(units.xs[king]):
		if Verbs.crossing_open(units, SimLoop.king_id):
			var falta := SimLoop.field.realm.refusal(units, SimLoop.king_id, SimLoop.state)
			return GuideSites.march(values) if falta.is_empty() else _tr(falta).format(values)
		values["day"] = SimFactory.curve().crossing_day
		return _tr(&"CONTEXT_CROSS_LOCKED").format(values)
	if units.bands[king] == int(Band.Kind.SURFACE) and Lume.at_base(units.xs[king]):
		var falta := Lume.refusal(units, SimLoop.king_id)  # o fim pela luz (Q-156)
		return _tr(&"CONTEXT_LUME" if falta.is_empty() else falta).format(values)
	for site in SimLoop.builds.slots:
		if site.band != units.bands[king] or absf(site.x - units.xs[king]) > site.catch_half():
			continue
		if site.kind == BuildSlot.NUCLEO:  # fundar, melhorar, ou o monarca (ADR 0059)
			return SeatGuide.context(site, values)
		values["name"] = _building_name(site)
		if site.kind == Succession.CASA and site.standing():
			return GuideSites.heir(values)
		values["cost"] = PriceTag.owed_by(site)
		if site.state in [BuildSlot.State.SCAFFOLD, BuildSlot.State.BUILDING]:
			return _tr(&"CONTEXT_BUILDING").format(values)
		if site.mending:
			return _tr(&"CONTEXT_REPAIRING").format(values)
		if site.state in [BuildSlot.State.DAMAGED, BuildSlot.State.RUIN] and values.cost > 0:
			return _tr(&"CONTEXT_REPAIR").format(values)
		if values.cost > 0 and not RealmLadder.allows(SimLoop.builds, site):
			return SeatGuide.locked(site, values)  # o estagio da sede que a abre (ADR 0059)
		if KingVerbs.wall_choice_open(site):
			values["path"] = _tr(
				&"PATH_GARRISON" if site.path == BuildSlot.Path.GUARNICAO else &"PATH_FORTIFY"
			)
			return _tr(&"CONTEXT_WALL").format(values)
		if SlotVariant.open(site):  # P-N: a variante escolhe-se antes da moeda (Q-136)
			var chave := "VARIANT_%s_%s" % [String(site.kind).to_upper(), "AB"[site.variant]]
			values["variant"] = _tr(StringName(chave))
			return _tr(&"CONTEXT_VARIANT").format(values)
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
		values["cost"] = PriceTag.owed_by_unit(
			units, nearest, SimLoop.recruits.price(units, nearest)
		)
		return _tr(&"CONTEXT_RECRUIT").format(values)
	var companhia := ClassGuide.companion(values)  # pagar ao companheiro (ADR 0052)
	if not companhia.is_empty() or units.bands[king] != int(Band.Kind.SURFACE):
		return companhia
	var terras := GuideSites.wilds(units.xs[king], values)
	return terras if not terras.is_empty() else ClassGuide.status()


## O monarca a evoluir no nucleo: o Rei pela classe, a Nia e o Arqueiro pelo perfil.
static func evolve(site: BuildSlot, values: Dictionary) -> String:
	var classe := Registry.entry(&"classes", MonarchWatch.skill_class()) as ClassData
	values["name"] = SeatGuide.stage_name(site.level)
	if classe.id != Monarchy.REI:  # a Nia e o Arqueiro evoluem pela classe do perfil
		values["monarch"] = TranslationServer.translate(MonarchWatch.data().display_key)
		values["seeds"] = classe.evolve_seed_cost
		return _tr(&"CONTEXT_MONARCH_EVOLVE").format(values)
	values["pct"] = roundi(float(classe.phase2_params.get(ClassSystem.DEFESA, 0.0)) * CEM)
	values["seeds"] = classe.evolve_seed_cost
	return _tr(&"CONTEXT_EVOLVE").format(values)


static func _building_name(site: BuildSlot) -> String:
	if site.two_paths():
		return _tr(&"CONTEXT_WALL_NAME")
	var data := Registry.entry(&"buildings", site.kind) as BuildingData
	return _tr(data.display_key) if data != null else _tr(&"CONTEXT_SITE")


static func _button(button: Variant) -> String:
	return _tr(button) if button is StringName else String(button)


static func _tr(key: StringName) -> String:
	return TranslationServer.translate(key)


static func _training(site: BuildSlot, values: Dictionary) -> String:
	if SimLoop.field.conversion.craft_of(site) != null and site.standing():
		return _conversion(site, values)
	if site.kind == Passages.ESCORA and site.standing():  # abre-se outra vez (Q-138)
		return _tr(&"CONTEXT_SEALED").format(values)
	if site.kind == Ward.SINO and site.standing():  # a carga do sino (Q-100)
		values["charge"] = floori(site.charge)
		values["max"] = floori(Ward.cap(site))
		return _tr(&"CONTEXT_WARD").format(values)
	var treino := SimLoop.field.training
	var oficio := treino.craft_of(site)
	if oficio == null or not site.standing():
		var paga := ClassGuide.companion(values)  # o Verbo 2 aqui paga ao companheiro
		return paga if not paga.is_empty() else _tr(&"CONTEXT_DONE").format(values)
	values["craft"] = _tr(oficio.display_key)
	for quem in treino.trainees:
		if treino.trainees[quem][0] == site.id:
			return _tr(&"CONTEXT_TRAINING").format(values)
	values["cost"] = treino.owed(site, SimLoop.units)
	if values.cost <= 0:
		return _tr(&"CONTEXT_TRAIN_NOBODY").format(values)
	return _tr(&"CONTEXT_TRAIN").format(values)


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


static func conversion_key(estado: ConversionSystem.Status, tem_oficio: bool) -> StringName:
	match estado:
		ConversionSystem.Status.ACTIVE:
			return &"CONTEXT_CONVERT_CAPACITY"
		ConversionSystem.Status.WAITING:
			return &"CONTEXT_CONVERT_WAITING"
		ConversionSystem.Status.WANTS_CRAFT:
			return &"CONTEXT_CONVERT_WANTS_CRAFT"
	return &"CONTEXT_CONVERT_COIN" if tem_oficio else &"CONTEXT_CONVERT_NOBODY"
