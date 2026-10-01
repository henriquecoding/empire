class_name TravelWatch
extends RefCounted
const GATE_PX := 96.0
const TRAVEL := &"travel"


static func daylight() -> bool:
	return ClockService.clock != null and ClockService.clock.current_phase() < GameClock.Phase.DUSK


static func at_gate() -> bool:
	if Assume.king() or SimLoop.state == null:
		return false
	var units := SimLoop.units
	var i := units.index_of(Assume.driven())
	if i < 0 or not units.alive(i) or units.bands[i] != Band.Kind.SURFACE:
		return false
	var x := units.xs[i]
	for fork in SimLoop.secrets.chapters:
		if absf(x - fork) <= GATE_PX:
			return true
	for id: int in SimLoop.field.settlements.records:
		var record: Dictionary = SimLoop.field.settlements.records[id]
		if id < SettlementWatch.CAMP_BASE and safe(id) and absf(x - float(record[&"x"])) <= GATE_PX:
			return true
	return false


static func destinations() -> PackedInt32Array:
	var result := PackedInt32Array([0])
	var regions := SimLoop.state.chapters.regions
	for id in range(1, regions.size()):
		var people := StringName(RulesFactory.biome_peoples().get(StringName(regions[id]), &""))
		if SimLoop.field.realm.vassals.has(people):
			if not SimLoop.field.settlements.records.has(id) or safe(id):
				result.append(id)
	return result


static func safe(id: int) -> bool:
	if id == 0:
		return true
	var record: Dictionary = SimLoop.field.settlements.records.get(id, {})
	if (
		record.is_empty()
		or record[&"deserted"]
		or not SimLoop.field.realm.vassals.has(record[&"people"])
	):
		return false
	for site in record[&"sites"]:
		var i := SimLoop.builds.index_of(site)
		if i >= 0 and SimLoop.builds.slots[i].blocks and SimLoop.builds.slots[i].holds():
			return true
	return false


static func go(id: int) -> bool:
	if not daylight() or not at_gate() or not destinations().has(id):
		return false
	if id != 0:
		Frontier.reveal(SimLoop.field, id)
		if not safe(id):
			return false
	var x := (
		SimLoop.secrets.chapters[0]
		if id == 0
		else float(SimLoop.field.settlements.records[id][&"x"])
	)
	var units := SimLoop.units
	var hero := Assume.driven()
	units.xs[units.index_of(hero)] = x
	units.clear_target(hero)
	EventBus.queue(&"segment_entered", [StringName(SimLoop.state.chapters.regions[id]), TRAVEL])
	return true
