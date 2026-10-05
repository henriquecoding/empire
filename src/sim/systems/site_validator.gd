class_name SiteValidator
extends RefCounted

const PLANT_STRIDE := 4


static func valid(x: float, radius: float, bounds: Vector2, protected: Array[Vector2]) -> bool:
	if not is_finite(x) or not is_finite(radius) or radius <= 0.0:
		return false
	if x - radius < bounds.x or x + radius > bounds.y:
		return false
	for span in protected:
		if x + radius >= span.x and x - radius <= span.y:
			return false
	return true


static func flora(plants: PackedFloat32Array, cleared: Array[Vector2]) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	for i in range(0, plants.size(), PLANT_STRIDE):
		var removed := false
		for span in cleared:
			if plants[i + 1] >= span.x and plants[i + 1] <= span.y:
				removed = true
				break
		if not removed:
			result.append_array(plants.slice(i, i + PLANT_STRIDE))
	return result
