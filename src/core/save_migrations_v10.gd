class_name SaveMigrationsV10
extends RefCounted


static func apply(save: Dictionary) -> void:
	var world: Variant = save.get(&"world", {})
	if not world is Dictionary or world.is_empty():
		return
	if not world.has(&"arrival"):
		world[&"arrival"] = {&"active": false}
	if not world.has(&"companion_journey"):
		world[&"companion_journey"] = {}
	if not world.has(&"treasury"):
		world[&"treasury"] = {}
	var seat: Variant = world.get(&"seat", {})
	if seat is Dictionary and not seat.has(&"cart_open"):
		seat[&"cart_open"] = true
