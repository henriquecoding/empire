class_name ArrivalGuide
extends RefCounted


static func goal() -> String:
	var o := SimLoop.arrival
	if not o.active:
		return ""
	if RealmLadder.stage(SimLoop.builds) > RealmLadder.FUNDADO or ClockService.clock.day > 2:
		return ""
	if o.choice == &"":
		return _tr(&"ARRIVAL_GOAL_CHOOSE")
	if not SimLoop.seat.cart_open:
		return _tr(&"ARRIVAL_GOAL_CART")
	if not RealmLadder.founded(SimLoop.builds):
		return _tr(&"ARRIVAL_GOAL_BUILD")
	if not o.survived:
		if ClockService.clock.current_phase() >= GameClock.Phase.AFTERNOON:
			return _tr(&"ARRIVAL_GOAL_THREAT")
		if ArrivalLabor.candidate() < 0 and o.worker < 0:
			return _tr(&"ARRIVAL_GOAL_PEOPLE")
		if not o.events.has(&"first_income"):
			return _tr(&"ARRIVAL_GOAL_LABOR")
		return _tr(&"ARRIVAL_GOAL_PREPARE")
	if not o.scouted and not o.events.has(&"underground_discovered"):
		return _tr(&"ARRIVAL_GOAL_SUBSOIL")
	return ""


static func context(x: float, band: int, values: Dictionary) -> String:
	if band == Band.Kind.UNDERGROUND:
		var key := CellarWatch.chest_at(x)
		if key != "":
			values["coins"] = SimLoop.treasury.amount(key)
			return _tr(&"ARRIVAL_CHEST").format(values)
		return ""
	var o := SimLoop.arrival
	if not o.active:
		return ""
	var choice := LastCartWatch.choice_at(x)
	if choice != &"":
		return _tr(&"ARRIVAL_CHOICE_" + String(choice).to_upper()).format(values)
	var trees := SimLoop.night.amargueiros
	for k in trees.count():
		if trees.fates[k] == AmargueiroSystem.Fate.OLD and absf(x - trees.xs[k]) <= Band.PASSAGE_PX:
			return _tr(&"ARRIVAL_ROOTS_CONTEXT").format(values)
	if absf(x - o.cache_x) <= Band.PASSAGE_PX:
		values["coins"] = o.cache_coins
		return _tr(&"ARRIVAL_SCAR" if o.scar else &"ARRIVAL_CACHE").format(values)
	if absf(x - SimLoop.seat.cart_x) <= Band.PASSAGE_PX:
		if not SimLoop.seat.cart_open:
			return _tr(&"ARRIVAL_CART_CLOSED")
		values["work"] = (
			_tr(&"ARRIVAL_TASK_" + String(o.task).to_upper())
			if o.task != &""
			else _tr(&"ARRIVAL_TASK_NONE")
		)
		return _tr(&"ARRIVAL_CART_WORK").format(values)
	return ""


static func companion(values: Dictionary) -> String:
	values["cost"] = maxi(0, LastCartWatch.rules().companion_cost - SimLoop.companion.paid)
	if not CompanionWatch.available():
		values["wins"] = SimLoop.companion.battles.size()
		values["total"] = LastCartWatch.rules().battle_evolve_count
		return _tr(&"ARRIVAL_COMPANION_PRESENT").format(values)
	if SimLoop.companion.worker >= 0:
		return _tr(&"ARRIVAL_COMPANION_COMING")
	return _tr(&"ARRIVAL_COMPANION_HIRE").format(values)


static func _tr(key: StringName) -> String:
	return TranslationServer.translate(key)
