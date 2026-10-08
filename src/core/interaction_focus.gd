class_name InteractionFocus
extends RefCounted


static func still() -> bool:
	if SimLoop.state == null or not SimLoop.running():
		return false
	var id := Assume.driven()
	var i := SimLoop.units.index_of(id)
	if i < 0 or not SimLoop.units.alive(i):
		return false
	if not Input.is_action_pressed(&"king_wheel"):
		if not is_zero_approx(Input.get_axis(&"move_left", &"move_right")):
			return false
	return not SimLoop.units.walking(i, id)
