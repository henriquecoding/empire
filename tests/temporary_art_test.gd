extends GdUnitTestSuite


func test_temporary_combatants_replace_proxies_but_keep_author_originals() -> void:
	assert_str(String(OriginalArt.unit_profile(&"archer"))).is_equal("temp_archer")
	assert_str(String(OriginalArt.unit_profile(&"spearman"))).is_equal("temp_spearman")
	assert_str(String(OriginalArt.unit_profile(&"archer_hero"))).is_equal("temp_archer_hero")
	assert_str(String(OriginalArt.unit_profile(&"monarch"))).is_equal("monarch")
	assert_str(String(OriginalArt.unit_profile(&"cook"))).is_equal("cook")
	assert_str(String(OriginalArt.unit_profile(&"vagrant"))).is_equal("vagrant")


func test_imported_combatants_have_actions_and_frames_inside_their_texture() -> void:
	var art := OriginalArt.new()
	for id in [&"temp_archer", &"temp_spearman", &"temp_archer_hero", &"temp_crawler"]:
		var item := art.entry(id)
		assert_bool(item.is_empty()).is_false()
		if item.is_empty():
			continue
		for action in [&"idle", &"walk", &"attack", &"die"]:
			assert_bool(art.has_action(id, action)).is_true()
		var bounds := Rect2(Vector2.ZERO, art.texture(id).get_size())
		for origin: Array in item.frame_origins:
			var region := Rect2(Vector2(origin[0], origin[1]), Vector2(item.size[0], item.size[1]))
			assert_bool(bounds.encloses(region)).is_true()
		var tag: Dictionary = item.tags.get("die", {})
		if tag.is_empty():
			continue
		assert_int(art.frame_at(id, 100.0, &"die", false)).is_equal(int(tag.to_frame))


func test_playable_archer_is_larger_than_troop_and_smaller_than_monarch() -> void:
	var art := OriginalArt.new()
	var troop := art.entry(&"temp_archer")
	var hero := art.entry(&"temp_archer_hero")
	assert_bool(troop.is_empty()).is_false()
	assert_bool(hero.is_empty()).is_false()
	if troop.is_empty() or hero.is_empty():
		return
	var king := art.body_box(&"monarch", Vector2.ZERO)
	assert_float(art.body_box(&"temp_archer", Vector2.ZERO).size.y).is_less(
		art.body_box(&"temp_archer_hero", Vector2.ZERO).size.y
	)
	assert_float(art.body_box(&"temp_archer_hero", Vector2.ZERO).size.y).is_less(king.size.y)
