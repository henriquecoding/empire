class_name CampWatch
extends RefCounted
const HOUSE := &"citizen_house"


static func tick(field: FieldWork) -> void:
	var life := field.camp_life
	var units := SimLoop.units
	for x: float in life.waiting.keys():
		var i := units.index_of(int(life.waiting[x]))
		if i >= 0 and units.alive(i) and units.owners[i] != RecruitSystem.SEM_DONO:
			life.hired(x)
	SettlementWatch.exhaust(field)
	var cuts := PackedFloat32Array()
	for slot in SimLoop.builds.slots:
		if slot.kind == AmargueiroSystem.CORTE and slot.state == BuildSlot.State.DONE:
			cuts.append(slot.x)
	for x in field.camps:
		if life.close(x, SimLoop.core_x, SimLoop.builds, cuts, RulesFactory.rules().camp_tree_px):
			WorldWorks.post(HOUSE, x)


static func active(field: FieldWork) -> PackedFloat32Array:
	var camps := PackedFloat32Array()
	for x in field.camps:
		if field.camp_life.active(x):
			camps.append(x)
	return camps


static func dawn(_field: FieldWork) -> void:
	var rules := RulesFactory.rules()
	var units := SimLoop.units
	for slot in SimLoop.builds.standing():
		if slot.kind != HOUSE:
			continue
		var count := 0
		for i in units.count():
			if (
				units.alive(i)
				and units.owners[i] == RecruitSystem.SEM_DONO
				and absf(units.xs[i] - slot.x) <= slot.width
			):
				count += 1
		if count < rules.citizen_cap:
			var id := units.spawn(
				SimLoop.state, Registry.entry(&"units", &"vagrant"), RecruitSystem.SEM_DONO, slot.x
			)
			units.recruit_costs[units.index_of(id)] = rules.citizen_price
			EventBus.queue(&"unit_spawned", [id, &"vagrant", slot.x, int(Band.Kind.SURFACE)])
