class_name SaveMigrationsV11
extends RefCounted


static func apply(save: Dictionary) -> void:
	var world: Variant = save.get(&"world", {})
	if not world is Dictionary or world.is_empty():
		return
	var arrival: Variant = world.get(&"arrival", {})
	if not arrival is Dictionary:
		return
	if not arrival.has(&"site_signature"):
		arrival[&"site_signature"] = {&"provenance": &"LEGACY_INFERRED"}
	if not arrival.has(&"clear_manifest"):
		arrival[&"clear_manifest"] = []
	if not arrival.has(&"citizens"):
		var units: Variant = world.get(&"units", {})
		var citizens := PackedInt32Array()
		if (
			arrival.get(&"active", false)
			and arrival.get(&"choice", &"") == &""
			and units is Dictionary
		):
			var data: Array = Array(units.get(&"data_ids", []))
			var xs: Array = Array(units.get(&"xs", []))
			var ids: Array = Array(units.get(&"ids", []))
			var origin := float(arrival.get(&"origin", 0.0))
			for i in mini(data.size(), mini(xs.size(), ids.size())):
				if data[i] == &"vagrant" and absf(float(xs[i]) - origin) < LastCartWatch.NEARBY_PX:
					citizens.append(int(ids[i]))
		arrival[&"citizens"] = citizens
	world[&"arrival"] = arrival
