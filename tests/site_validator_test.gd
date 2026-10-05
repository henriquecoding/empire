extends GdUnitTestSuite


func test_continuous_sites_respect_edges_and_protected_footprints() -> void:
	var protected: Array[Vector2] = [Vector2(800.0, 900.0)]
	assert_bool(SiteValidator.valid(433.0, 100.0, Vector2(0.0, 1000.0), protected)).is_true()
	assert_bool(SiteValidator.valid(50.0, 100.0, Vector2(0.0, 1000.0), protected)).is_false()
	assert_bool(SiteValidator.valid(750.0, 100.0, Vector2(0.0, 1000.0), protected)).is_false()
	assert_bool(SiteValidator.valid(NAN, 100.0, Vector2(0.0, 1000.0), protected)).is_false()


func test_flora_manifest_preserves_the_boundary_and_survives_reload() -> void:
	var cart := LastCart.new()
	cart.begin(0.0, -500.0, 3)
	cart.clear_manifest = [Vector2(200.0, 300.0)]
	var saved := LastCart.new()
	saved.from_dict(cart.to_dict())
	var flora := PackedFloat32Array([4, 199, 0, 0, 4, 250, 0, 0, 6, 301, 0, 0])
	var expected := PackedFloat32Array([4, 199, 0, 0, 6, 301, 0, 0])
	assert_array(SiteValidator.flora(flora, saved.clear_manifest)).is_equal(expected)
	assert_array(SiteValidator.flora(expected, saved.clear_manifest)).is_equal(expected)
