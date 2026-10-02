class_name GuideGoal
extends RefCounted
const HALF := 0.5


static func goal() -> String:
	if CrownWatch.waiting():
		return _tr(&"GUIDE_CROWN")  # a coroa no chao, ate a alvorada (Q-167)
	if Defeat.king_fell() and SimLoop.field.succession.possible(SimLoop.builds):
		return _tr(&"GUIDE_HEIR")  # §16: o herdeiro assume ao amanhecer
	var rot := SimLoop.night.rot
	var tarde := ClockService.clock.current_phase() >= GameClock.Phase.AFTERNOON
	if _rei_em_baixo() and (tarde or rot.active()):
		return _tr(&"GUIDE_CLIMB")  # P-I: o subsolo e de dia
	if rot.active():
		if _rei_na_mancha():
			return _tr(&"GUIDE_ROT_FED")
		return _tr(&"HUD_GOAL_NIGHT")
	if rot.announced != 0:
		var lado := {"side": _tr(&"SIDE_EAST" if rot.announced > 0 else &"SIDE_WEST")}
		var funda := rot.deep(ClockService.clock.day)
		return _tr(&"GUIDE_ROT_COMING_DEEP" if funda else &"GUIDE_ROT_COMING").format(lado)
	if SimLoop.field.seasons.at(ClockService.clock.day) == Seasons.WINTER:
		return _tr(&"GUIDE_WINTER")
	if TravelWatch.at_gate():
		return _tr(&"GUIDE_TRAVEL")
	if ClockService.clock.day >= SimFactory.curve().crossing_day:
		return _tr(&"GUIDE_CROSS")  # a marcha pode sair (Q-146)
	var worker := false
	var hunter := false
	for i in SimLoop.units.count():
		if (
			not SimLoop.units.alive(i)
			or (
				SimLoop.units.owners[i]
				!= SimLoop.units.owners[SimLoop.units.index_of(SimLoop.king_id)]
			)
		):
			continue
		var data := Registry.entry(&"units", SimLoop.units.data_ids[i]) as UnitData
		worker = worker or data.tags.has(&"worker")
		hunter = hunter or data.tags.has(&"hunter")
	if not worker:
		return _tr(&"GUIDE_WORKER")
	var aljavas := SimLoop.field.supply.short(SimLoop.units, SimLoop.king_id) > 0
	if aljavas and not Supply.depot(SimLoop.builds, RulesFactory.rules().ammo_depot):
		return _tr(&"GUIDE_ARROWS")  # as flechas das tropas, a repor (Q-163)
	for site in SimLoop.builds.slots:
		if site.territory != 0:
			continue
		if site.blocks and not site.mending and site.repair_cost() > 0:
			return _tr(&"GUIDE_REPAIR")
	if not hunter:
		return _tr(&"GUIDE_HUNTER")
	var production := false
	var wall := false
	for site in SimLoop.builds.standing():
		if site.territory != 0:
			continue
		production = production or site.yield_per_day > 0
		wall = wall or site.two_paths()
	if not production:
		return _tr(&"GUIDE_FARM")
	return _tr(&"GUIDE_EXPLORE" if wall else &"GUIDE_WALL")


static func _rei_em_baixo() -> bool:
	var i := SimLoop.units.index_of(SimLoop.king_id)
	return i >= 0 and SimLoop.units.bands[i] == int(Band.Kind.UNDERGROUND)


static func _rei_na_mancha() -> bool:
	var i := SimLoop.units.index_of(SimLoop.king_id)
	if i < 0 or SimLoop.units.carried_coins[i] <= 0:
		return false
	var rot := SimLoop.night.rot
	return absf(SimLoop.units.xs[i] - rot.position_x()) <= rot.state.width * HALF


static func _tr(key: StringName) -> String:
	return TranslationServer.translate(key)
