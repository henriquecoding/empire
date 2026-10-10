class_name Settlements
extends RefCounted
var records: Dictionary = {}
var first_night_day := 0
var awake_day := 0


func add(id: int, people: StringName, x: float, coins: int) -> Dictionary:
	if not records.has(id):
		records[id] = {
			&"people": people,
			&"x": x,
			&"treasury": float(coins),
			&"units": PackedInt32Array(),
			&"sites": PackedInt32Array(),
			&"deserted": false,
			&"rifts": PackedFloat32Array()
		}
	return records[id]


func treasury(id: int) -> float:
	return float(records.get(id, {}).get(&"treasury", 0.0))


func spend(id: int, amount: float) -> bool:
	if not records.has(id) or amount < 0.0 or treasury(id) < amount:
		return false
	records[id][&"treasury"] = treasury(id) - amount
	return true


func earn(id: int, amount: float) -> void:
	if records.has(id):
		records[id][&"treasury"] = treasury(id) + maxf(0.0, amount)


func to_dict() -> Dictionary:
	return {
		&"records": records.duplicate(true),
		&"first_night_day": first_night_day,
		&"awake_day": awake_day
	}


func from_dict(saved: Dictionary) -> void:
	records = saved.get(&"records", {}).duplicate(true)
	first_night_day = int(saved.get(&"first_night_day", 0))
	awake_day = int(saved.get(&"awake_day", 0 if records.is_empty() else 1))
