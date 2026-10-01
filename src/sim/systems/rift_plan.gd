class_name RiftPlan
extends RefCounted


static func two(day: int, roll: float, rules: RulesCurve, from_day: int) -> bool:
	return day >= from_day and roll < rules.rift_both_chance


static func shares(mass: float, both: bool) -> Vector2:
	var second := mass * BuildSystem.METADE if both else 0.0
	return Vector2(mass - second, second)
