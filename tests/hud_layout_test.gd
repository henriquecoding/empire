extends GdUnitTestSuite


func test_header_cards_fit_without_overlap_on_phone_deck_and_wide_canvas() -> void:
	for width: float in [568.0, 667.0, 844.0, 1280.0, 1600.0]:
		var area := Vector2(width, 720.0)
		var cards := HudLayout.header(area)
		for key: StringName in cards:
			var box: Rect2 = cards[key]
			if not box.has_area():
				continue
			assert_bool(Rect2(Vector2.ZERO, area).encloses(box)).is_true()
			for other: StringName in cards:
				if other != key:
					assert_bool(box.intersects(cards[other])).is_false()


func test_small_phone_uses_context_for_goal_instead_of_squeezing_text() -> void:
	assert_bool(HudLayout.header(Vector2(667, 375))[&"goal"].has_area()).is_false()
	assert_bool(HudLayout.header(Vector2(844, 390))[&"goal"].has_area()).is_true()


func test_context_expands_for_consequences_and_stays_centred() -> void:
	for width: float in [568.0, 844.0, 1280.0, 1600.0]:
		var area := Vector2(width, 720)
		var short_box := HudLayout.context(area, 24.0)
		var long_box := HudLayout.context(area, 110.0)
		assert_float(long_box.size.y).is_greater(short_box.size.y)
		assert_float(long_box.get_center().x).is_equal_approx(width / 2.0, 0.1)
		assert_float(long_box.position.y).is_greater(HudLayout.HEADER_BOTTOM)
		assert_bool(Rect2(Vector2.ZERO, area).encloses(long_box)).is_true()


func test_touch_pause_uses_header_corner_and_has_room_for_the_finger() -> void:
	var layout := TouchLayout.new()
	var pause := layout.centre(TouchLayout.Role.PAUSE)
	assert_float(pause.y).is_less(GameHud.FAIXA_TOPO)
	assert_int(layout.role_at(pause)).is_equal(TouchLayout.Role.PAUSE)
	assert_float(layout.reach(TouchLayout.Role.PAUSE)).is_greater_equal(22.0)


func test_touch_actions_leave_more_of_the_world_free() -> void:
	var layout := TouchLayout.new()
	for role: TouchLayout.Role in TouchLayout.BOTOES:
		var left_edge := layout.centre(role).x - layout.radius(role)
		assert_float(left_edge).is_greater(900.0)
