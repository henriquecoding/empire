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


## UX-06: o iPhone da tres pixeis por ponto; a interface conta pontos, e nao pixeis.
func test_interface_counts_points_not_pixels_on_dense_screens() -> void:
	var iphone := HudLayout.zoom_for(1170.0 / 720.0, 3.0)
	assert_float(iphone).is_equal_approx(HudLayout.zoom_for(390.0 / 720.0, 1.0), 0.001)
	assert_float(iphone * 1170.0 / 720.0 / 3.0).is_equal_approx(1.0, 0.001)
	assert_float(HudLayout.zoom_for(1.0, 1.0)).is_equal(1.0)
	assert_float(HudLayout.zoom_for(2.5, 2.0)).is_equal(1.0)
	assert_float(HudLayout.zoom_for(2.0, 0.0)).is_equal(1.0)


## UX-06: no toque o contexto, os avisos e as legendas ficam entre os controlos.
func test_touch_panels_stay_between_the_controls() -> void:
	var antes := TouchLayout.span
	TouchControls.active = true
	TouchLayout.span = Vector2(320.0, 1040.0)
	var faixa := HudLayout.band(1558.0, 2.12, 480.0)
	assert_float(faixa.x).is_greater_equal(320.0)
	assert_float(faixa.x + faixa.y * 2.12).is_less_equal(1040.0)
	TouchControls.active = false
	var largo := HudLayout.band(1558.0, 2.12, 480.0)
	assert_float(largo.y).is_equal(480.0)
	TouchLayout.span = antes
