class_name CampLife
extends RefCounted

var ruined := PackedFloat32Array()
var waiting: Dictionary = {}
var hires: Dictionary = {}


func active(x: float) -> bool:
	return not ruined.has(x)


func close(
	x: float, core: float, builds: BuildSystem, cuts: PackedFloat32Array, radius: float
) -> bool:
	if not active(x):
		return false
	var enclosed := false
	for wall in builds.standing():
		if wall.territory == 0 and wall.blocks and (wall.x - x) * (x - core) >= 0.0:
			enclosed = true
	for cut in cuts:
		enclosed = enclosed or absf(cut - x) <= radius
	if enclosed:
		ruined.append(x)
	return enclosed


func hired(x: float) -> void:
	hires[x] = int(hires.get(x, 0)) + 1
	waiting.erase(x)


func available(x: float, limit: int) -> bool:
	return active(x) and int(hires.get(x, 0)) < limit


func to_dict() -> Dictionary:
	return {&"ruined": ruined, &"waiting": waiting.duplicate(), &"hires": hires.duplicate()}


func from_dict(saved: Dictionary) -> void:
	ruined = saved.get(&"ruined", PackedFloat32Array())
	waiting = saved.get(&"waiting", {}).duplicate()
	hires = saved.get(&"hires", {}).duplicate()
