class_name SaveIntegrity
extends RefCounted

const MAX_DEPTH := 64  # limite estrutural do ficheiro, nao um valor de balanceamento
const DICTIONARIES := [
	"units",
	"creatures",
	"coins",
	"rot",
	"other_rot",
	"amargueiros",
	"offers",
	"titles",
	"harvest",
	"torch",
	"staffing",
	"settlements",
	"underground_sight",
	"under",
	"camp_life",
	"seasons",
	"hunting",
	"training",
	"crown",
	"conversion",
	"classes",
	"hero_progress",
	"focus",
	"song",
	"upkeep",
	"succession",
	"realm",
	"spirit",
	"wilds",
	"roster",
	"crown_drop",
	"supply",
	"mount",
	"monarchy",
	"bleeding",
	"stamina",
	"woodland",
	"seat",
	"arrival",
	"companion_journey",
	"treasury",
]


## Antes das migracoes: nenhum cast nem indice de coluna le dados mal formados.
static func structure(world: Dictionary) -> bool:
	for key: StringName in [&"king_id", &"pilot"]:
		if world.has(key) and not world[key] is int:
			return false
	for key: String in DICTIONARIES:
		if world.has(key) and not world[key] is Dictionary:
			return false
	if world.has(&"builds"):
		if not world[&"builds"] is Array:
			return false
		for slot: Variant in world[&"builds"]:
			if not slot is Dictionary:
				return false
	return (
		_columns(UnitSystem.new(), world.get(&"units", {}))
		and _columns(
			CreatureSystem.new(), world.get(&"creatures", {}), ["loot_slots", "masses", "recoils"]
		)
		and _columns(
			CoinSystem.new(SimFactory.curve()), world.get(&"coins", {}), ["from_king", "targets"]
		)
		and _finite(world)
	)


## Um candidato completo e validado antes de alterar o SimLoop, RNG ou cenario.
static func playable(frame: Dictionary) -> bool:
	var state: Variant = frame.get(&"state")
	var world: Variant = frame.get(&"world")
	if not state is Dictionary or not world is Dictionary or not structure(world):
		return false
	var defaults := GameState.new().to_dict()
	for key: StringName in defaults:
		if state.has(key) and not _same_type(defaults[key], state[key]):
			return false
	if not _finite(state):
		return false
	if state.get(&"day", 1) < 1 or state.get(&"tick", 0) < 0:
		return false
	if state.get(&"clock_elapsed", 0.0) < 0 or state.get(&"day_seconds", 0.0) < 0:
		return false
	var clock := Registry.entry(&"economy", &"clock") as ClockData
	var duration := float(state.get(&"day_seconds", 0.0))
	if duration == 0.0:
		duration = clock.day_seconds
	if float(state.get(&"clock_elapsed", 0.0)) >= duration:
		return false
	var units: Dictionary = world.get(&"units", {})
	var ids: PackedInt32Array = units.get(&"ids", PackedInt32Array())
	if ids.is_empty() or not ids.has(world.get(&"king_id", UnitSystem.NENHUM)):
		return false
	var pilot: Variant = world.get(&"pilot", UnitSystem.NENHUM)
	if not pilot is int or (pilot != UnitSystem.NENHUM and not ids.has(pilot)):
		return false
	var seen := {}
	for key: StringName in [&"units", &"creatures", &"coins"]:
		for id: int in world.get(key, {}).get(&"ids", PackedInt32Array()):
			if id <= 0 or seen.has(id) or id >= state.get(&"next_id", 1):
				return false
			seen[id] = true
	return _bodies(units) and _bodies(world.get(&"creatures", {}))


static func _columns(model: Object, saved: Dictionary, optional: Array[String] = []) -> bool:
	var ids: Variant = saved.get(&"ids", PackedInt32Array())
	if not ids is PackedInt32Array:
		return false
	for name: String in Columns.names(model):
		if not saved.has(name):
			if ids.size() > 0 and not optional.has(name):
				return false
			continue
		var value: Variant = saved[name]
		var expected: Variant = model.get(name)
		var kind := TYPE_PACKED_STRING_ARRAY if expected is Array else typeof(expected)
		if typeof(value) != kind or value.size() != ids.size():
			return false
	return true


static func _bodies(saved: Dictionary) -> bool:
	var ids: PackedInt32Array = saved.get(&"ids", PackedInt32Array())
	for i in ids.size():
		if saved[&"bands"][i] > int(Band.Kind.UNDERGROUND):
			return false
		if saved[&"healths"][i] < 0 or saved[&"healths"][i] > saved[&"max_healths"][i]:
			return false
		if saved.has(&"states") and saved[&"states"][i] > int(UnitFsm.State.DEAD):
			return false
	return true


static func _same_type(expected: Variant, value: Variant) -> bool:
	return typeof(expected) == typeof(value) or (expected is float and value is int)


static func _finite(value: Variant, depth: int = 0) -> bool:
	if depth > MAX_DEPTH:
		return false
	if value is float:
		return is_finite(value)
	if value is Vector2 or value is Vector3 or value is Vector4:
		return value.is_finite()
	if value is Dictionary:
		for item: Variant in value.values():
			if not _finite(item, depth + 1):
				return false
	elif value is Array or value is PackedFloat32Array or value is PackedFloat64Array:
		for item: Variant in value:
			if not _finite(item, depth + 1):
				return false
	return true
