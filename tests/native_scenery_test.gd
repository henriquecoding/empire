extends GdUnitTestSuite


func test_production_catalog_has_all_views_and_native_anchors() -> void:
	var data := NativeSceneryCatalog.manifest()
	assert_bool(data.is_empty()).is_false()
	assert_int(data.get("families", {}).size()).is_equal(13)
	assert_int(data.get("variants", {}).size()).is_equal(24)
	assert_float(float(data.get("surface_y", -1))).is_equal(517.0)
	assert_float(float(data.get("underground_y", -1))).is_equal(618.5)
	assert_array(data.get("playable_frame", [])).is_equal([64, 64])
	assert_array(data.get("worker_frame", [])).is_equal([32, 32])


func test_every_dry_lower_bank_has_a_reachable_passage() -> void:
	for id: String in NativeSceneryCatalog.manifest().get("families", {}):
		var family := NativeSceneryCatalog.family(id)
		for span: Array in family.lower_spans:
			var accessible := false
			for mouth: float in family.passages:
				accessible = accessible or (
					mouth >= float(span[0]) + 32.0 and mouth <= float(span[1]) - 32.0
				)
			assert_bool(accessible).override_failure_message(id).is_true()


func test_water_gaps_do_not_support_lower_walking() -> void:
	for id in ["bruma", "fenda", "lago", "rio", "enramados_bruma", "fenda_geada"]:
		assert_bool(NativeSceneryCatalog.supports(id, 640.0, Band.Kind.UNDERGROUND)).is_false()
		assert_bool(NativeSceneryCatalog.supports(id, 640.0, Band.Kind.SURFACE)).is_true()


func test_actual_actor_bounds_fit_the_native_frames() -> void:
	var king := NativeActorFit.bounds(&"royal_king", true, Vector2(640.0, 517.0))
	var worker := NativeActorFit.bounds(&"royal_citizen", false, Vector2(320.0, 618.5))
	assert_float(maxf(king.size.x, king.size.y)).is_equal_approx(64.0, 0.01)
	assert_float(maxf(worker.size.x, worker.size.y)).is_equal_approx(32.0, 0.01)
	assert_float(worker.position.y).is_greater(517.0)
