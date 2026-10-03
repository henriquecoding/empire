extends GdUnitTestSuite


func test_dungeon_rewards_have_single_double_triple_and_relic() -> void:
	var rules := RulesFactory.rules()
	assert_int(int(DungeonLoot.draw(rules, 0.0, 0.0, 0.9)[&"bonus"])).is_equal(1)
	assert_int(int(DungeonLoot.draw(rules, 0.0, 0.0, 0.1)[&"bonus"])).is_equal(2)
	assert_int(int(DungeonLoot.draw(rules, 0.0, 0.0, 0.0)[&"bonus"])).is_equal(3)
	assert_str(String(DungeonLoot.draw(rules, 0.99, 0.0, 0.9)[&"kind"])).is_equal("relic")
	assert_str(String(DungeonLoot.draw(rules, 0.7, 0.0, 0.9)[&"kind"])).is_equal("guardian")


func test_two_rifts_conserve_budget_and_leave_early_nights_unchanged() -> void:
	assert_bool(RiftPlan.two(10, 0.0, RulesFactory.rules(), 12)).is_false()
	assert_bool(RiftPlan.two(12, 0.0, RulesFactory.rules(), 12)).is_true()
	var shares := RiftPlan.shares(47, true)
	assert_float(shares.x + shares.y).is_equal(47.0)


func test_visiting_only_opens_local_mouth_and_nearby_creature() -> void:
	var sight := UndergroundSight.new()
	sight.visit(200.0)
	var creatures := CreatureSystem.new()
	var c := creatures.spawn(
		GameState.new(), Registry.entry(&"creatures", &"burrower"), 400.0, 400.0
	)
	creatures.bands[creatures.index_of(c)] = Band.Kind.UNDERGROUND
	var windows := sight.windows(
		PackedFloat32Array([200.0]), creatures, 300.0, RulesFactory.rules()
	)
	assert_int(windows.size()).is_equal(2)
	assert_float(windows[0].y).is_equal(80.0)
	assert_float(windows[1].y).is_equal(160.0)
	(
		assert_int(
			(
				sight
				. windows(PackedFloat32Array([200.0]), creatures, 5000.0, RulesFactory.rules())
				. size()
			)
		)
		. is_equal(0)
	)
	var copy := UndergroundSight.new()
	copy.from_dict(sight.to_dict())
	assert_bool(copy.visited.has(200.0)).is_true()


func test_v5_migration_renames_people_and_nested_ids() -> void:
	var result := SaveMigrations.migrate(
		{
			&"save_version": 5,
			&"state": {&"conquests": PackedStringArray(["paul"])},
			&"world": {&"wilds": {&"east": [{&"id": &"paul_empty_01", &"people": &"paul"}]}}
		}
	)
	assert_int(int(result[&"save_version"])).is_equal(SaveMigrations.CURRENT)
	assert_str(String(result[&"state"][&"conquests"][0])).is_equal("bruma")
	assert_str(String(result[&"world"][&"wilds"][&"east"][0][&"id"])).is_equal("bruma_empty_01")
