class_name BoarWalls
extends RefCounted


static func collide(
	herd: Herd, before: Dictionary, species: Callable, builds: BuildSystem, stun: float, damage: int
) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var homes := before.keys()
	homes.sort()
	for home: float in homes:
		var animal: WildlifeData = species.call(home)
		if animal == null or animal.flees or not herd.provoked.has(home):
			continue
		var previous := float(before[home])
		var current := herd.where(home)
		if is_equal_approx(previous, current):
			continue
		var wall := builds.barrier(previous, current, Band.Kind.SURFACE)
		if wall == null or not wall.two_paths():
			continue
		herd.xs[home] = wall.x
		herd.stunned[home] = stun
		herd.provoked.erase(home)
		events.append_array(builds.damage(wall.id, damage))
	return events
