class_name HeroProgress
extends RefCounted

var phases: Dictionary = {}
var feats: Dictionary = {}
var locked: Dictionary = {}
var _classes: Dictionary


func _init(classes: Dictionary = {}) -> void:
	_classes = classes


func phase_of(id: StringName) -> int:
	return int(phases.get(id, 1))


func feat_of(id: StringName) -> int:
	return int(feats.get(id, 0))


func record(id: StringName) -> void:
	if _classes.has(id):
		feats[id] = feat_of(id) + 1


func can_evolve(id: StringName, seeds: int) -> bool:
	var data: ClassData = _classes.get(id)
	return (
		data != null
		and not bool(locked.get(id, false))
		and phase_of(id) < data.phase_count
		and seeds >= data.evolve_seed_cost
		and feat_of(id) >= data.evolve_condition_value
	)


func evolve(id: StringName, state: GameState) -> bool:
	if not can_evolve(id, state.royal_seeds):
		return false
	state.royal_seeds -= (_classes[id] as ClassData).evolve_seed_cost
	phases[id] = phase_of(id) + 1
	return true


func to_dict() -> Dictionary:
	return {
		&"phases": phases.duplicate(), &"feats": feats.duplicate(), &"locked": locked.duplicate()
	}


func from_dict(data: Dictionary) -> void:
	phases = data.get(&"phases", {}).duplicate()
	feats = data.get(&"feats", {}).duplicate()
	locked = data.get(&"locked", {}).duplicate()
