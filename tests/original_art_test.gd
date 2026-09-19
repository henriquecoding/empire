extends GdUnitTestSuite


func test_original_idle_preserves_the_long_fifth_frame() -> void:
	var art := OriginalArt.new()
	assert_int(art.frame_at(&"knight", 0.499)).is_equal(4)
	assert_int(art.frame_at(&"knight", 0.549)).is_equal(4)
	assert_int(art.frame_at(&"knight", 0.550)).is_equal(5)
	assert_int(art.frame_at(&"knight", 0.650)).is_equal(0)


func test_originals_have_native_dimensions_and_a_stable_foot() -> void:
	var art := OriginalArt.new()
	var troop := art.entry(&"knight")
	assert_array(troop.size).is_equal([49.0, 54.0])
	assert_array(troop.foot).is_equal([18.0, 53.0])
	assert_array(troop.layers).is_equal([1.0, 2.0, 3.0, 4.0, 5.0])
	assert_int(art.texture(&"knight").get_width()).is_equal(294)
	assert_int(art.texture(&"monarch").get_height()).is_equal(94)
