extends GdUnitTestSuite


func test_interpolation_is_by_id_and_survives_column_reorder() -> void:
	var track := VisualMotion.new()
	track.capture([10, 20], [100.0, 200.0], [1, 1], 1)
	track.capture([20, 10], [202.0, 104.0], [1, 1], 2)
	assert_float(track.x(10, 0.5)).is_equal(102.0)
	assert_float(track.x(20, 0.5)).is_equal(201.0)


func test_spawn_teleport_band_change_and_skipped_ticks_snap() -> void:
	var track := VisualMotion.new()
	track.capture([10], [100.0], [1], 1)
	assert_float(track.x(10, 0.0)).is_equal(100.0)
	track.capture([10], [900.0], [1], 2)
	assert_float(track.x(10, 0.0)).is_equal(900.0)
	track.capture([10], [904.0], [2], 3)
	assert_float(track.x(10, 0.0)).is_equal(904.0)
	track.capture([10], [910.0], [2], 8)
	assert_float(track.x(10, 0.0)).is_equal(910.0)


func test_removed_ids_are_discarded_and_pause_uses_current_position() -> void:
	var track := VisualMotion.new()
	track.capture([10], [100.0], [1], 1)
	track.capture([10], [104.0], [1], 2)
	assert_float(track.x(10, 1.0)).is_equal(104.0)
	track.capture([], [], [], 3)
	assert_bool(track.has(10)).is_false()
