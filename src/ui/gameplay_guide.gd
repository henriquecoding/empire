class_name GameplayGuide
extends RefCounted

const HALF := 0.5


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
		if site.two_paths() and site.level <= 1 and site.paid == 0:
			values["path"] = _tr(
				&"PATH_GARRISON" if site.path == BuildSlot.Path.GUARNICAO else &"PATH_FORTIFY"
			)
			return _tr(&"CONTEXT_WALL").format(values)
		if values.cost > 0:
			if not SimLoop.builds.can_climb(site, SimLoop.state, SimLoop.night.amargueiros):
				return _tr(&"CONTEXT_LOCKED").format(values)
			return _tr(&"CONTEXT_BUILD").format(values)
		return _tr(&"CONTEXT_DONE").format(values)
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
