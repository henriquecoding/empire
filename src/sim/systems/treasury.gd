class_name Treasury
extends RefCounted

var chests: Dictionary = {}
## O que cada ladrao leva de um bau, pelo id dele: valor que saiu do bau e ainda existe
## (cai onde ele morrer). So se perde se ele sair vivo (ADR 0072, §9.6).
var carried: Dictionary = {}


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


func carried_by(thief: int) -> int:
	return int(carried.get(thief, 0))


func carry(thief: int, coins: int) -> void:
	carried[thief] = carried_by(thief) + maxi(0, coins)


func to_dict() -> Dictionary:
	return {&"chests": chests.duplicate(), &"carried": carried.duplicate()}


func from_dict(saved: Dictionary) -> void:
	chests = (saved.get(&"chests", {}) as Dictionary).duplicate()
	carried = (saved.get(&"carried", {}) as Dictionary).duplicate()
