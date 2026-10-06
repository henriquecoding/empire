extends GdUnitTestSuite


func test_walk_frames_are_nonempty_aligned_and_inside_the_atlas() -> void:
	var art := OriginalArt.new()
	var profiles: Array = RenewalArt.UNITS.values() + RenewalArt.CREATURES.values()
	for id: StringName in profiles:
		var item := art.entry(id)
		var texture := art.texture(id)
		assert_object(texture).is_not_null()
		var sheet := texture.get_image()
		var frame_size := Vector2i(item.size[0], item.size[1])
		assert_bool(art.has_action(id, &"walk")).is_true()
		assert_int(art.frame_at(id, 0.17, &"walk")).is_equal(1)
		assert_int(art.frame_at(id, 0.65, &"walk")).is_equal(0)
		for origin: Array in item.frame_origins:
			var rect := Rect2i(Vector2i(origin[0], origin[1]), frame_size)
			assert_bool(Rect2i(Vector2i.ZERO, sheet.get_size()).encloses(rect)).is_true()
			var occupied := sheet.get_region(rect).get_used_rect()
			assert_int(occupied.size.y).is_greater(20)
			assert_int(occupied.end.y).is_equal(int(item.foot[1]))
			assert_int(occupied.position.x).is_greater(0)
			assert_int(occupied.end.x).is_less(frame_size.x)


func test_live_cast_keeps_readable_height_hierarchy() -> void:
	var art := OriginalArt.new()
	var citizen := art.body_box(&"royal_citizen", Vector2.ZERO).size.y
	var archer := art.body_box(&"royal_archer", Vector2.ZERO).size.y
	var king := art.body_box(&"royal_king", Vector2.ZERO).size.y
	assert_float(citizen).is_less(archer)
	assert_float(archer).is_less(king)
	assert_str(String(OriginalArt.unit_profile(&"nia"))).is_equal("royal_nia")
	assert_str(String(OriginalArt.unit_profile(&"bard_banner"))).is_equal("royal_bard")
	assert_str(String(OriginalArt.unit_profile(&"quiver_squire"))).is_equal("royal_quiver")


func test_renewed_settlement_preserves_the_unfounded_clearing() -> void:
	var slot := BuildSlot.new()
	slot.kind = BuildSlot.NUCLEO
	assert_str(String(BuildingSkins.profile_at(slot, Silhouette.Form.COPA, 0))).is_equal(
		"seat_clearing"
	)
	for level in range(1, RenewalArt.SEATS.size() + 1):
		var profile := BuildingSkins.profile_at(slot, Silhouette.Form.COPA, level)
		assert_bool(profile in RenewalArt.SEATS).is_true()
		assert_int(BuildingSkins.texture(profile).get_height()).is_greater(80)


func test_rot_has_an_emission_map_for_eyes_and_a_matching_hit_mask() -> void:
	var art := OriginalArt.new()
	for id: StringName in RenewalArt.CREATURES.values():
		var item := art.entry(id)
		var eyes := load(RenewalArt.ROOT + item.eyes_texture) as Texture2D
		var mask := load(RenewalArt.ROOT + item.mask_texture) as Texture2D
		assert_vector(eyes.get_size()).is_equal(mask.get_size())
		var rect := Rect2i(item.atlas_origin[0], item.atlas_origin[1], item.size[0], item.size[1])
		assert_bool(eyes.get_image().get_region(rect).is_invisible()).is_false()
