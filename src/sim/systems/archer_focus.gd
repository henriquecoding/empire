class_name ArcherFocus
extends RefCounted

var targets: Dictionary = {}
var remaining: Dictionary = {}
var piercing := PackedInt32Array()
var allies: Dictionary = {}
var inheritance := 1.0
var _class: ClassData
var _units: Dictionary


func _init(data: ClassData, units: Dictionary) -> void:
	_class = data
	_units = units


func aim(
	units: UnitSystem, creatures: CreatureSystem, hero: int, x: float, phase: int
) -> Array[int]:
	var hits: Array[int] = []
	var i := units.index_of(hero)
	if i < 0 or not units.alive(i) or units.healths[i] <= 0:
		return hits
	var body: UnitData = _units.get(units.data_ids[i])
	if body == null or absf(x - units.xs[i]) > body.range_px:
		return hits
	var best := -1
	var gap := INF
	for id in TargetPicker.ids_por_ordem(creatures.ids):
		var c := creatures.index_of(id)
		if allies.has(id) or not creatures.alive(c) or creatures.bands[c] != units.bands[i]:
			continue
		if absf(creatures.xs[c] - units.xs[i]) > body.range_px:
			continue
		var distance := absf(creatures.xs[c] - x)
		if distance < gap:
			best = id
			gap = distance
	if best < 0:
		return hits
	var center := creatures.xs[creatures.index_of(best)]
	var radius := float(_class.phase2_params.get(&"mark_radius", 0.0)) if phase > 1 else 0.0
	for id in TargetPicker.ids_por_ordem(creatures.ids):
		var c := creatures.index_of(id)
		if not allies.has(id) and creatures.alive(c) and creatures.bands[c] == units.bands[i]:
			if absf(creatures.xs[c] - center) <= radius:
				hits.append(id)
	targets[units.owners[i]] = PackedInt32Array(hits)
	remaining[units.owners[i]] = float(_class.phase1_params.get(&"duration", 0.0)) * inheritance
	return hits


func tick(delta: float, creatures: CreatureSystem) -> void:
	for owner: int in targets.keys():
		remaining[owner] = maxf(0.0, float(remaining.get(owner, 0.0)) - delta)
		var live := PackedInt32Array()
		for id in targets[owner]:
			var c := creatures.index_of(id)
			if c >= 0 and creatures.alive(c) and not allies.has(id):
				live.append(id)
		if remaining[owner] <= 0.0 or live.is_empty():
			targets.erase(owner)
			remaining.erase(owner)
		else:
			targets[owner] = live


func marked(creature: int, owner: int) -> bool:
	return (targets.get(owner, PackedInt32Array()) as PackedInt32Array).has(creature)


func pierced(units: UnitSystem, creatures: CreatureSystem, hero: int, target: int) -> Array[int]:
	var hits: Array[int] = []
	var i := units.index_of(hero)
	var t := creatures.index_of(target)
	if i < 0 or t < 0:
		return hits
	var body: UnitData = _units.get(units.data_ids[i])
	if body == null:
		return hits
	var direction := signf(creatures.xs[t] - units.xs[i])
	if is_zero_approx(direction):
		return [target]
	for id in TargetPicker.ids_por_ordem(creatures.ids):
		var c := creatures.index_of(id)
		var distance := (creatures.xs[c] - units.xs[i]) * direction
		if not allies.has(id) and creatures.alive(c) and creatures.bands[c] == units.bands[i]:
			if distance >= 0.0 and distance <= body.range_px:
				hits.append(id)
	return hits


func to_dict() -> Dictionary:
	return {&"targets": targets.duplicate(true), &"remaining": remaining.duplicate()}


func from_dict(data: Dictionary) -> void:
	targets = data.get(&"targets", {}).duplicate(true)
	remaining = data.get(&"remaining", {}).duplicate()
