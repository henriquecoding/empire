class_name Treasury
extends RefCounted

var chests: Dictionary = {}
## O que cada ladrao leva de um bau, pelo id dele: valor que saiu do bau e ainda existe
## (cai onde ele morrer). So se perde se ele sair vivo (ADR 0072, §9.6).
var carried: Dictionary = {}
## Ultima alvorada: origem, destino, valor pago e falta. Totais persistem sem duplicar.
var payments: Dictionary = {}
var payment_day := 0


func pay(key: String, coins: int, purpose: StringName, day: int) -> bool:
	if coins < 0:
		return false
	if payment_day != day:
		payments.clear()
		payment_day = day
	var paid := coins if amount(key) >= coins else 0
	var record: Dictionary = payments.get(purpose, {&"source": key, &"paid": 0, &"unpaid": 0})
	record[&"paid"] += paid
	record[&"unpaid"] += coins - paid
	payments[purpose] = record
	if paid != coins:
		return false
	withdraw(key, paid)
	return true


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
	return {
		&"chests": chests.duplicate(),
		&"carried": carried.duplicate(),
		&"payments": payments.duplicate(true),
		&"payment_day": payment_day
	}


func from_dict(saved: Dictionary) -> void:
	chests = (saved.get(&"chests", {}) as Dictionary).duplicate()
	carried = (saved.get(&"carried", {}) as Dictionary).duplicate()
	payments = (saved.get(&"payments", {}) as Dictionary).duplicate(true)
	payment_day = int(saved.get(&"payment_day", 0))
