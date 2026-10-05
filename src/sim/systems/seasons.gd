class_name Seasons
extends RefCounted

enum { SPRING, SUMMER, AUTUMN, WINTER }
const COUNT := 4
var reserves: Dictionary = {}
var _rules: RulesCurve


func _init(rules: RulesCurve) -> void:
	_rules = rules


func at(day: int) -> int:
	return (maxi(1, day) - 1) / maxi(1, _rules.season_days) % COUNT


func left(day: int) -> int:
	return maxi(1, _rules.season_days) - (maxi(1, day) - 1) % maxi(1, _rules.season_days)


func yield_mult(day: int, kind: StringName) -> float:
	return 0.0 if at(day) == WINTER and kind in [&"farm", &"horta_work"] else 1.0


func hunt_mult(day: int) -> float:
	return _rules.winter_hunt_mult if at(day) == WINTER else 1.0


## A parte da colheita que fica para o inverno, pelos celeiros proprios de pe, por ordem
## de id: um celeiro cheio passa o resto ao seguinte em vez de o deitar fora (SUB-14).
func store(day: int, kind: StringName, produced: float, builds: BuildSystem) -> float:
	if at(day) == WINTER or kind != &"farm" or produced <= 0.0:
		return produced
	var falta := produced * _rules.granary_reserve_frac
	var celeiros := builds.standing().filter(
		func(s: BuildSlot) -> bool: return s.kind == &"granary" and s.territory == 0
	)
	celeiros.sort_custom(func(a: BuildSlot, b: BuildSlot) -> bool: return a.id < b.id)
	var guardado := 0.0
	for slot: BuildSlot in celeiros:
		var held := float(reserves.get(slot.id, 0.0))
		var amount := minf(falta - guardado, maxf(0.0, _rules.granary_reserve_cap - held))
		if amount <= 0.0:
			continue
		reserves[slot.id] = held + amount
		guardado += amount
	return produced - guardado


func release(day: int, slot: BuildSlot) -> int:
	if at(day) != WINTER or not slot.standing() or slot.kind != &"granary":
		return 0
	var amount := mini(_rules.granary_release_daily, floori(float(reserves.get(slot.id, 0.0))))
	reserves[slot.id] = float(reserves.get(slot.id, 0.0)) - amount
	return amount


func to_dict() -> Dictionary:
	return {&"reserves": reserves.duplicate()}


func from_dict(saved: Dictionary) -> void:
	reserves = saved.get(&"reserves", {}).duplicate()
