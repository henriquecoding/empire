extends GdUnitTestSuite


func test_own_wall_and_near_cut_end_camp_but_foreign_wall_does_not() -> void:
	var life := CampLife.new()
	var wall := BuildSlot.new()
	wall.blocks = true
	wall.state = BuildSlot.State.DONE
	wall.x = 1000.0
	wall.territory = 9
	var builds := BuildSystem.new()
	builds.post(wall)
	assert_bool(life.close(800.0, 500.0, builds, PackedFloat32Array(), 120.0)).is_false()
	wall.territory = 0
	assert_bool(life.close(800.0, 500.0, builds, PackedFloat32Array(), 120.0)).is_true()
	assert_bool(life.active(800.0)).is_false()
	assert_bool(life.close(-500.0, 500.0, builds, PackedFloat32Array([-450.0]), 120.0)).is_true()
	var copy := CampLife.new()
	copy.from_dict(life.to_dict())
	assert_bool(copy.active(-500.0)).is_false()


func test_mercenary_camp_remembers_three_hires() -> void:
	var life := CampLife.new()
	life.hired(900.0)
	life.hired(900.0)
	assert_bool(life.available(900.0, 3)).is_true()
	life.hired(900.0)
	assert_bool(life.available(900.0, 3)).is_false()


func test_decay_retains_levels_paths_and_rebuild_price() -> void:
	var builds := BuildSystem.new()
	var slot := BuildSlot.new()
	slot.kind = &"farm"
	slot.costs = PackedInt32Array([4])
	slot.works = PackedFloat32Array([8.0])
	slot.healths = PackedInt32Array([32])
	slot.level = 1
	slot.state = BuildSlot.State.DONE
	slot.variant = 1
	builds.post(slot)
	var legacy := Legacy.of(GameState.new(), builds, 0.0, 0.5)
	Legacy.apply(legacy, GameState.new(), builds)
	assert_bool(slot.foundation).is_true()
	assert_int(slot.repair_cost()).is_equal(2)
	assert_int(slot.variant).is_equal(1)
	slot.mending = true
	RepairWork.tick(slot, 8.0)
	assert_bool(slot.standing()).is_true()
	assert_bool(slot.foundation).is_false()
