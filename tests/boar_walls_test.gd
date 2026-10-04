extends GdUnitTestSuite


func test_charging_boar_stops_at_wall_and_needs_builder_repair() -> void:
	var herd := Herd.new()
	herd.arrive(0.0)
	herd.provoked[0.0] = true
	herd.xs[0.0] = 30.0
	var builds := BuildSystem.new()
	var wall := builds.post(WallSite.slot(20.0))
	wall.raise_to(1)
	var before := wall.health
	var species := func(_x: float) -> WildlifeData: return Registry.entry(&"wildlife", &"boar")
	assert_int(BoarWalls.collide(herd, {0.0: 0.0}, species, builds, 4.0, 6).size()).is_equal(1)
	assert_float(herd.where(0.0)).is_equal(20.0)
	assert_float(float(herd.stunned[0.0])).is_equal(4.0)
	assert_int(wall.health).is_equal(before - 6)
	assert_int(wall.repair_cost()).is_greater(0)
	var restored := Herd.new()
	restored.from_dict(herd.to_dict())
	restored.step(1.0, [0.0], species, {1: 80.0})
	assert_float(restored.where(0.0)).is_equal(20.0)
	restored.forget(0.0)
	assert_bool(restored.stunned.is_empty()).is_true()


func test_noncharging_wildlife_does_not_damage_a_wall() -> void:
	var herd := Herd.new()
	herd.arrive(0.0)
	herd.xs[0.0] = 30.0
	var builds := BuildSystem.new()
	var wall := builds.post(WallSite.slot(20.0))
	wall.raise_to(1)
	var species := func(_x: float) -> WildlifeData: return Registry.entry(&"wildlife", &"rabbit")
	assert_array(BoarWalls.collide(herd, {0.0: 0.0}, species, builds, 4.0, 6)).is_empty()
	assert_int(wall.health).is_equal(wall.max_health())
