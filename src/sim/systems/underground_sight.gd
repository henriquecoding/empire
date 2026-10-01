class_name UndergroundSight
extends RefCounted
var visited := PackedFloat32Array()


func visit(x: float) -> void:
	if not visited.has(x):
		visited.append(x)


func windows(
	mouths: PackedFloat32Array, creatures: CreatureSystem, viewer: float, rules: RulesCurve
) -> PackedVector4Array:
	var result := PackedVector4Array()
	for mouth in mouths:
		if absf(mouth - viewer) > rules.und_notice_px:
			continue
		if visited.has(mouth):
			result.append(Vector4(mouth, rules.und_visited_px, 0.0, 0.0))
		for i in creatures.count():
			if creatures.healths[i] <= 0 or creatures.bands[i] != Band.Kind.UNDERGROUND:
				continue
			if absf(creatures.xs[i] - mouth) <= rules.und_notice_px:
				var window := Vector4(creatures.xs[i], rules.und_creature_px, 0.0, 0.0)
				if not result.has(window):
					result.append(window)
	return result


func to_dict() -> Dictionary:
	return {&"visited": visited}


func from_dict(saved: Dictionary) -> void:
	visited = saved.get(&"visited", PackedFloat32Array())
