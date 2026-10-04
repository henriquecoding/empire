class_name RealmMilestones
extends RefCounted


static func missing() -> StringName:
	var seat := RealmLadder.seat(SimLoop.builds)
	if not SimLoop.arrival.active or seat == null:
		return &""
	var next := RulesFactory.realm_stage(seat.level + 1)
	if next == null:
		return &""
	var production := SimLoop.economy.sources(SimLoop.builds) > 0
	var people := 0
	for i in SimLoop.units.count():
		if SimLoop.units.alive(i) and SimLoop.units.owners[i] == SimLoop.builds.crew_owner:
			people += 1
	var west := false
	var east := false
	var current := RulesFactory.realm_stage(seat.level)
	var required := 1 if current == null else current.wall_rings
	var left := 0
	var right := 0
	for wall in SimLoop.builds.standing():
		if not wall.two_paths() or wall.territory != 0:
			continue
		left += 1 if wall.x < seat.x else 0
		right += 1 if wall.x > seat.x else 0
	west = left >= required
	east = right >= required
	return (
		RealmMaturity
		. missing(
			next,
			{
				&"night": SimLoop.arrival.survived,
				&"income": SimLoop.arrival.events.has(&"first_income") or production,
				&"walls": west and east,
				&"people": people >= LastCartWatch.rules().maturity_people,
				&"production": production,
				&"subsoil": not SimLoop.field.under.layouts.is_empty(),
			}
		)
	)


static func sync() -> void:
	SimLoop.builds.maturity_ready = missing() == &""
