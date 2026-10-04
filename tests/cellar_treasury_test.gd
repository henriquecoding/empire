extends GdUnitTestSuite


func test_excavation_adds_room_without_replacing_existing_rooms() -> void:
	var sites := UndergroundSites.new()
	var spec := UnderWatch.spec(UndergroundSites.HATCH, 0.0, [])
	spec[UndergroundSites.EXTRA] = 0
	sites.post("hatch", UndergroundSites.HATCH, 100.0, Vector2(100, 100), Vector2(52, 148), spec)
	sites.generate(0, PackedFloat32Array())
	var first := sites.rooms(0).duplicate(true)
	assert_bool(sites.excavate(0, Vector2(52, 244))).is_true()
	assert_array(sites.rooms(0).slice(0, first.size())).is_equal(first)
	assert_float(sites.span(0).y).is_equal(244.0)
	assert_bool(sites.excavate(0, Vector2(52, 244))).is_false()
	var restored := UndergroundSites.new()
	restored.post("hatch", UndergroundSites.HATCH, 100.0, Vector2(100, 100), Vector2(52, 244), spec)
	restored.from_dict(sites.to_dict())
	assert_vector(restored.span(0)).is_equal(sites.span(0))


func test_player_chest_starts_empty_and_is_a_conserved_reserve() -> void:
	var treasury := Treasury.new()
	treasury.open("home", 0)
	assert_int(treasury.amount("home")).is_equal(0)
	assert_int(treasury.deposit("home", 4)).is_equal(4)
	assert_int(treasury.withdraw("home", 2)).is_equal(2)
	assert_int(treasury.amount("home")).is_equal(2)
	var restored := Treasury.new()
	restored.from_dict(treasury.to_dict())
	restored.open("home", 8)
	assert_int(restored.amount("home")).is_equal(2)
	assert_int(restored.steal("home", 9)).is_equal(2)
	assert_int(restored.amount("home")).is_equal(0)


func test_foreign_chest_is_seeded_once() -> void:
	var treasury := Treasury.new()
	treasury.open("foreign", 6)
	assert_int(treasury.withdraw("foreign", 6)).is_equal(6)
	treasury.open("foreign", 6)
	assert_int(treasury.amount("foreign")).is_equal(0)
