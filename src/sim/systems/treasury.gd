class_name Treasury
extends RefCounted

var chests: Dictionary = {}


func open(key: String, initial: int) -> void:
	if not chests.has(key):
		chests[key] = maxi(0, initial)


func amount(key: String) -> int:
	return int(chests.get(key, 0))


func deposit(key: String, coins: int) -> int:
	var taken := maxi(0, coins)
	chests[key] = amount(key) + taken
	return taken


func withdraw(key: String, capacity: int) -> int:
	var taken := clampi(capacity, 0, amount(key))
	chests[key] = amount(key) - taken
	return taken


func steal(key: String, capacity: int) -> int:
	return withdraw(key, capacity)


func to_dict() -> Dictionary:
	return {&"chests": chests.duplicate()}


func from_dict(saved: Dictionary) -> void:
	chests = (saved.get(&"chests", {}) as Dictionary).duplicate()
