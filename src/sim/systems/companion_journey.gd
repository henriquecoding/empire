class_name CompanionJourney
extends RefCounted

var paid := 0
var worker := -1
var battles := PackedInt32Array()


func pay(amount: int, cost: int) -> int:
	var taken := clampi(cost - paid, 0, amount)
	paid += taken
	return taken


func ready(cost: int) -> bool:
	return cost > 0 and paid >= cost


func enroll(who: int, cost: int) -> bool:
	if worker >= 0 or who < 0 or not ready(cost):
		return false
	worker = who
	return true


func finish() -> void:
	paid = 0
	worker = -1


func victory(foe: int, together: bool) -> bool:
	if not together or foe in battles:
		return false
	battles.append(foe)
	return true


func to_dict() -> Dictionary:
	return {&"paid": paid, &"worker": worker, &"battles": battles}


func from_dict(saved: Dictionary) -> void:
	paid = int(saved.get(&"paid", 0))
	worker = int(saved.get(&"worker", -1))
	battles = PackedInt32Array(saved.get(&"battles", []))
