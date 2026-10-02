class_name WorldWorks
extends RefCounted


static func slot(data: BuildingData, x: float, territory := 0) -> BuildSlot:
	var result := BuildSlot.new()
	result.kind = data.id
	result.x = x
	result.territory = territory
	result.costs = PackedInt32Array([data.cost])
	result.works = PackedFloat32Array([data.build_work])
	result.healths = PackedInt32Array([data.max_health])
	result.contacts = PackedInt32Array([data.contact_slots])
	result.width = data.width_px
	result.blocks = data.category == &"defense"
	result.job_id = (
		&"wall" if result.blocks else &"farm" if data.material == &"grain" else data.craft
	)
	result.job_slots = data.job_slots
	result.yield_per_day = data.yield_per_day
	result.effects = data.effect_params.duplicate()
	result.razed_by_rot = data.destroyed_by_rot_trail
	return result


static func post(kind: StringName, x: float, territory := 0) -> BuildSlot:
	for existing in SimLoop.builds.slots:
		if existing.kind == kind and is_equal_approx(existing.x, x):
			return existing
	return SimLoop.builds.post(slot(Registry.entry(&"buildings", kind), x, territory))


static func restore(saved: Array) -> void:
	for record: Dictionary in saved:
		var id := int(record.get(&"id", -1))
		if SimLoop.builds.index_of(id) >= 0:
			continue
		var kind := StringName(record.get(&"kind", &""))
		var result: BuildSlot
		if kind == AmargueiroSystem.CORTE:
			result = BuildSlot.new()
			result.kind = kind
			result.x = float(record.get(&"x", 0.0))
		elif Registry.has_entry(&"buildings", kind):
			result = slot(Registry.entry(&"buildings", kind), float(record.get(&"x", 0.0)))
		else:
			continue
		result.band = int(record.get(&"band", int(Band.Kind.SURFACE))) as Band.Kind
		SimLoop.builds.post(result)
