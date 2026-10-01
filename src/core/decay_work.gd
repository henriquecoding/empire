class_name DecayWork
extends RefCounted


static func of() -> Dictionary:
	var result := Legacy.of(
		SimLoop.state,
		SimLoop.builds,
		SimFactory.curve().decay_structures_kept,
		RulesFactory.rules().decay_rebuild_frac
	)
	var map := SimLoop.field.wilds.to_dict()
	for side in [&"west", &"east"]:
		for entry: Dictionary in map.get(side, []):
			entry[&"deserted"] = true
			entry.erase(&"dungeon")
	result[&"revealed_map"] = map
	result[&"map_seed"] = SimLoop.state.seed
	return result


static func restore(legacy: Dictionary) -> void:
	# Restore the campaign before authoring settlements on the restored map.
	if legacy.has(Legacy.PLANO):
		SimLoop.state.chapters.from_dict(legacy[Legacy.PLANO])
	if legacy.has(&"revealed_map"):
		SimLoop.field.wilds.from_dict(legacy[&"revealed_map"])
		Frontier.reapply(SimLoop.field, SimLoop.world_width)
	for key in [Legacy.OBRAS, &"foundations"]:
		for record: Dictionary in legacy.get(key, []):
			if not record.has(&"kind") or not record.has(&"x"):
				continue
			var kind := StringName(record[&"kind"])
			var x := float(record[&"x"])
			var found: BuildSlot = null
			for slot in SimLoop.builds.slots:
				if slot.territory == 0 and slot.kind == kind and is_equal_approx(slot.x, x):
					found = slot
					break
			if found == null and Registry.has_entry(&"buildings", kind):
				found = WorldWorks.post(kind, x)
			if found != null:
				record[Legacy.ID] = found.id
