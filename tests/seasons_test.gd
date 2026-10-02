extends GdUnitTestSuite


func test_winter_starts_on_day_49_and_has_viable_sources() -> void:
	var s := Seasons.new(RulesFactory.rules())
	assert_int(s.at(1)).is_equal(Seasons.SPRING)
	assert_int(s.at(49)).is_equal(Seasons.WINTER)
	assert_float(s.yield_mult(49, &"farm")).is_equal(0.0)
	assert_float(s.yield_mult(49, &"fishing_pier")).is_equal(1.0)
	assert_float(s.hunt_mult(49)).is_greater(0.0)
	assert_int(s.left(64)).is_equal(1)


func test_only_new_grain_is_reserved_and_round_trips() -> void:
	var s := Seasons.new(RulesFactory.rules())
	var builds := BuildSystem.new()
	var granary := BuildSlot.new()
	granary.kind = &"granary"
	granary.state = BuildSlot.State.DONE
	builds.post(granary)
	assert_float(s.store(1, &"farm", 2.0, builds)).is_equal(1.5)
	assert_float(s.store(49, &"farm", 0.0, builds)).is_equal(0.0)
	var copy := Seasons.new(RulesFactory.rules())
	copy.from_dict(s.to_dict())
	assert_float(float(copy.reserves[granary.id])).is_equal(0.5)
	assert_int(copy.release(49, granary)).is_equal(0)
	s.store(1, &"farm", 30.0, builds)
	assert_int(s.release(49, granary)).is_equal(4)
