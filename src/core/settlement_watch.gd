class_name SettlementWatch
extends RefCounted
const OWNER_BASE := 100
const CAMP_BASE := 10000
const NIGHT_OFFSET := 360.0
const SAL := 211


static func author(
	field: FieldWork, side: int, k: int, restoring: bool, seed_world: WildSegments = null
) -> void:
	if field.settlements.awake_day <= 0:
		return
	var world := field.wilds if seed_world == null else seed_world
	var entry := world.at(side, k)
	var merc: bool = entry[WildSegments.TIPO] == WildSegments.MERCENARIOS
	if not merc and int(entry[WildSegments.ZONA]) != WorldPlan.Zone.FORTRESS:
		return
	var id := CAMP_BASE + k * 2 + (1 if side > 0 else 0) if merc else int(entry[WildSegments.POVO])
	if field.settlements.records.has(id):
		return
	var rules := RulesFactory.rules()
	var people := (
		&"mercenary"
		if merc
		else StringName(RulesFactory.biome_peoples().get(entry[WildSegments.PARA], &"enramados"))
	)
	var x := world.subject_x(side, k, SimLoop.world_width)
	var record := field.settlements.add(id, people, x, rules.realm_start_coins)
	if not restoring:
		record[&"born_day"] = field.settlements.awake_day
	record[&"deserted"] = entry.get(&"deserted", false)
	if merc:
		record[&"camp"] = x
	var sites := [
		[&"house", x],
		[&"work", x - rules.realm_work_offset],
		[&"defense", x - rules.realm_wall_offset],
		[&"defense", x + rules.realm_wall_offset]
	]
	for site in sites:
		var slot := WorldWorks.post(
			StringName(String(people) + "_" + String(site[0])), float(site[1]), id
		)
		slot.level = 1 if restoring or record[&"deserted"] else 0
		slot.state = (
			BuildSlot.State.RUIN
			if record[&"deserted"]
			else BuildSlot.State.DONE if restoring else BuildSlot.State.EMPTY
		)
		slot.builder_work = true
		slot.health = 0 if record[&"deserted"] else slot.max_health()
		record[&"sites"].append(slot.id)
	if restoring or record[&"deserted"]:
		return
	for index in rules.realm_citizen_count:
		_spawn(
			record, id, &"vagrant", x + Retinue.spot(index) * SimFactory.curve().follow_spacing_px
		)
	_spawn(record, id, &"builder", x)


static func plan(field: FieldWork) -> void:
	var units := SimLoop.units
	var ids := field.settlements.records.keys()
	ids.sort()
	for id: int in ids:
		var record: Dictionary = field.settlements.records[id]
		SimLoop.builds.work_owners[id] = OWNER_BASE + id
		CellarWatch.foreign(field, id, record)
		for k in (record[&"units"] as PackedInt32Array).size():
			var unit := int(record[&"units"][k])
			var i := units.index_of(unit)
			if i < 0 or not units.alive(i):
				continue
			SimLoop.jobs.territories[unit] = id
			field.local_homes[unit] = float(record[&"x"])
			if units.job_ids[i] == UnitSystem.NENHUM and units.states[i] != UnitFsm.State.FIGHT:
				units.set_target_x(
					unit,
					float(record[&"x"]) + Retinue.spot(k) * SimFactory.curve().follow_spacing_px
				)


static func dawn(field: FieldWork) -> void:
	SocialWatch.awaken(field, SimLoop.state.day)
	var rules := RulesFactory.rules()
	var ids := field.settlements.records.keys()
	ids.sort()
	for id: int in ids:
		var record: Dictionary = field.settlements.records[id]
		record[&"rifts"] = PackedFloat32Array()
		if record[&"deserted"]:
			continue
		SocialWatch.develop(field, id, record)
		var guards := 0
		for unit in record[&"units"]:
			var i := SimLoop.units.index_of(unit)
			if i < 0 or not SimLoop.units.alive(i):
				continue
			var data := Registry.entry(&"units", SimLoop.units.data_ids[i]) as UnitData
			if data.damage > 0:
				guards += 1
				var wage := (
					float(rules.mercenary_daily_wage)
					if data.id == &"mercenary"
					else rules.realm_guard_wage
				)
				if field.settlements.spend(id, wage):
					field.supply.spent.erase(unit)
		for site in record[&"sites"]:
			var slot := SimLoop.builds.slots[SimLoop.builds.index_of(site)]
			if slot.standing() and not slot.mending and slot.rest_day != SimLoop.state.day:
				field.settlements.earn(
					id, slot.yield_per_day * field.seasons.yield_mult(SimLoop.state.day, slot.kind)
				)
			if (
				slot.level > 0
				and slot.health < slot.max_health()
				and not slot.mending
				and field.settlements.spend(id, maxi(1, slot.repair_cost()))
			):
				slot.mending = true
				slot.progress = 0.0
				if slot.state == BuildSlot.State.RUIN:
					slot.state = BuildSlot.State.SCAFFOLD
		if (
			guards < rules.realm_guard_count
			and SimLoop.builds.slots[SimLoop.builds.index_of(record[&"sites"][1])].standing()
			and field.settlements.spend(id, rules.realm_guard_price)
		):
			var kind := &"mercenary" if record.has(&"camp") else &"archer"
			if not record.has(&"camp") and not record.get(&"unique_recruited", false):
				kind = (Registry.entry(&"peoples", record[&"people"]) as PeopleData).unique_unit
				record[&"unique_recruited"] = true
			_spawn(record, id, kind, float(record[&"x"]))


static func night(field: FieldWork) -> void:
	if field.settlements.first_night_day == 0 and SimLoop.builds.foundation_committed:
		field.settlements.first_night_day = SimLoop.state.day
	var rules := RulesFactory.rules()
	var ids := field.settlements.records.keys()
	ids.sort()
	for id: int in ids:
		var record: Dictionary = field.settlements.records[id]
		if record[&"deserted"]:
			continue
		var roll := RngService.scatter(hash([SAL, id, SimLoop.state.day]), 1)[0]
		var side := 1 if roll >= BuildSystem.METADE else -1
		var x := float(record[&"x"]) + side * NIGHT_OFFSET
		record[&"rifts"] = PackedFloat32Array([x])
		var rot := SimFactory.rot()
		rot.spawn(SimLoop.state.day, side, SimLoop.world_width)
		var remaining := floori(rot.mass() * rules.realm_night_share)
		var data := Registry.entry(&"creatures", &"crawler") as CreatureData
		for k in mini(rules.realm_night_cap, remaining / maxi(1, data.mass_cost)):
			var creature := SimLoop.creatures.spawn(SimLoop.state, data, x, float(record[&"x"]))
			EventBus.queue(&"rot_summoned", [data.id, x, int(data.band), remaining])
			remaining -= data.mass_cost
			SimLoop.creatures.goal_xs[SimLoop.creatures.index_of(creature)] = float(record[&"x"])


static func exhaust(field: FieldWork) -> void:
	var rules := RulesFactory.rules()
	for id: int in field.settlements.records:
		var record: Dictionary = field.settlements.records[id]
		if (
			not record.has(&"camp")
			or record[&"deserted"]
			or field.camp_life.available(float(record[&"camp"]), rules.mercenary_camp_hires)
		):
			continue
		record[&"deserted"] = true
		for unit in record[&"units"]:
			SimLoop.units.remove(unit)
		for site in record[&"sites"]:
			var slot := SimLoop.builds.slots[SimLoop.builds.index_of(site)]
			slot.state = BuildSlot.State.RUIN
			slot.health = 0


static func _spawn(record: Dictionary, id: int, kind: StringName, x: float) -> void:
	var unit := SimLoop.units.spawn(
		SimLoop.state, Registry.entry(&"units", kind), OWNER_BASE + id, x
	)
	record[&"units"].append(unit)
	SimLoop.jobs.territories[unit] = id
	SimLoop.field.local_homes[unit] = float(record[&"x"])
	EventBus.queue(&"unit_spawned", [unit, kind, x, int(Band.Kind.SURFACE)])
