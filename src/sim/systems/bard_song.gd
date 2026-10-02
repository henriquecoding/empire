class_name BardSong
extends RefCounted

var allies: Dictionary = {}
var cooldowns: Dictionary = {}
var _converted := PackedInt32Array()
var _class: ClassData
var _units: Dictionary
var _creatures: Dictionary


func _init(data: ClassData, units: Dictionary, creatures: Dictionary) -> void:
	_class = data
	_units = units
	_creatures = creatures


func cast(units: UnitSystem, creatures: CreatureSystem, bard: int, x: float, phase: int) -> int:
	var i := units.index_of(bard)
	if (
		i < 0
		or not units.alive(i)
		or units.healths[i] <= 0
		or float(cooldowns.get(bard, 0.0)) > 0.0
	):
		return -1
	var body: UnitData = _units.get(units.data_ids[i])
	if body == null:
		return -1
	var radius := float(body.ability_params.get(&"radius", 0.0))
	if absf(x - units.xs[i]) > radius:
		return -1
	var best := -1
	var gap := INF
	for id in TargetPicker.ids_por_ordem(creatures.ids):
		var c := creatures.index_of(id)
		var data: CreatureData = _creatures.get(creatures.data_ids[c])
		if allies.has(id) or not creatures.alive(c) or data == null or not data.can_be_killed:
			continue
		if phase == 1 and data.max_health > int(_class.phase1_params.get(&"max_target_health", 0)):
			continue
		if creatures.bands[c] != units.bands[i] or absf(creatures.xs[c] - units.xs[i]) > radius:
			continue
		var distance := absf(creatures.xs[c] - x)
		if distance < gap:
			best = id
			gap = distance
	if best < 0:
		return -1
	allies[best] = {
		&"owner": units.owners[i],
		&"bard": bard,
		&"anchor": units.xs[i],
		&"permanent": phase > 1,
		&"remaining": float(_class.phase1_params.get(&"duration", 0.0))
	}
	creatures.allies = allies
	cooldowns[bard] = body.attack_interval
	if not _converted.has(best):
		_converted.append(best)
	var c := creatures.index_of(best)
	creatures.target_ids[c] = -1
	creatures.target_slots[c] = -1
	creatures.loot_slots[c] = -1
	return best


func credited(id: int) -> bool:
	return _converted.has(id)


func conversions() -> int:
	return _converted.size()


func tick(delta: float, creatures: CreatureSystem) -> void:
	for bard: int in cooldowns.keys():
		cooldowns[bard] = maxf(0.0, float(cooldowns[bard]) - delta)
		if is_zero_approx(float(cooldowns[bard])):
			cooldowns.erase(bard)
	for id: int in allies.keys():
		var c := creatures.index_of(id)
		if c < 0 or not creatures.alive(c):
			allies.erase(id)
			continue
		if bool(allies[id][&"permanent"]):
			continue
		allies[id][&"remaining"] = maxf(0.0, float(allies[id][&"remaining"]) - delta)
		if float(allies[id][&"remaining"]) <= 0.0:
			allies.erase(id)
			creatures.target_ids[c] = -1
			creatures.target_slots[c] = -1
			creatures.target_xs[c] = creatures.goal_xs[c]


func permanent() -> PackedInt32Array:
	var ids := PackedInt32Array()
	for id: int in allies:
		if bool(allies[id][&"permanent"]):
			ids.append(id)
	ids.sort()
	return ids


func pace(phase: int) -> float:
	return 1.0 + float(_class.phase1_params.get(&"speed_boost", 0.0)) if phase > 0 else 1.0


func plan(units: UnitSystem, creatures: CreatureSystem) -> void:
	for id in TargetPicker.ids_por_ordem(creatures.ids):
		if not allies.has(id):
			continue
		var c := creatures.index_of(id)
		var data: CreatureData = _creatures.get(creatures.data_ids[c])
		creatures.target_ids[c] = -1
		creatures.target_slots[c] = -1
		if data == null or not creatures.alive(c):
			continue
		var bard := units.index_of(int(allies[id][&"bard"]))
		var body: UnitData = _units.get(units.data_ids[bard]) if bard >= 0 else null
		var sight: float = (
			float(body.ability_params.get(&"radius", 0.0)) if body != null else data.range_px
		)
		var best := -1
		var gap := INF
		for target in TargetPicker.ids_por_ordem(creatures.ids):
			var t := creatures.index_of(target)
			if (
				allies.has(target)
				or not creatures.alive(t)
				or creatures.bands[t] != creatures.bands[c]
			):
				continue
			var distance := absf(creatures.xs[t] - creatures.xs[c])
			if distance <= sight and distance < gap:
				best = target
				gap = distance
		var home := float(allies[id][&"anchor"])
		if bard >= 0 and units.alive(bard) and units.bands[bard] == creatures.bands[c]:
			home = units.xs[bard]
		creatures.target_xs[c] = creatures.xs[creatures.index_of(best)] if best >= 0 else home
		if best >= 0 and gap <= data.range_px:
			creatures.target_ids[c] = best


func defender(
	creatures: CreatureSystem,
	c: int,
	data: CreatureData,
	current: int,
	gap: float,
	wall: BuildSlot = null
) -> int:
	var best := current
	for id in TargetPicker.ids_por_ordem(creatures.ids):
		var a := creatures.index_of(id)
		if not allies.has(id) or not creatures.alive(a):
			continue
		if wall != null and (creatures.xs[a] - wall.x) * (creatures.xs[c] - wall.x) < 0.0:
			continue
		if not Passages.reaches(data, int(creatures.bands[c]), int(creatures.bands[a])):
			continue
		var distance := absf(creatures.xs[a] - creatures.xs[c])
		if distance <= data.range_px and distance < gap:
			best = id
			gap = distance
	return best


func to_dict() -> Dictionary:
	return {
		&"allies": allies.duplicate(true),
		&"converted": _converted.duplicate(),
		&"cooldowns": cooldowns.duplicate()
	}


func from_dict(data: Dictionary) -> void:
	allies = data.get(&"allies", {}).duplicate(true)
	_converted = PackedInt32Array(data.get(&"converted", PackedInt32Array()))
	cooldowns = data.get(&"cooldowns", {}).duplicate()
