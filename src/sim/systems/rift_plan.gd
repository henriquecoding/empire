class_name RiftPlan
extends RefCounted


static func two(day: int, roll: float, rules: RulesCurve, from_day: int) -> bool:
	return day >= from_day and roll < rules.rift_both_chance


static func shares(mass: int, both: bool) -> Vector2i:
	var second := mass / 2 if both else 0
	return Vector2i(mass - second, second)
