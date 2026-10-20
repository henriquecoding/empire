extends GdUnitTestSuite


func test_exploration_has_only_compact_header_instruments() -> void:
	var cards := HudLayout.header(Vector2(1280, 720))
	assert_float((cards[&"purse"] as Rect2).size.y).is_less_equal(44.0)
	assert_float((cards[&"clock"] as Rect2).size.y).is_less_equal(44.0)
	assert_bool((cards[&"goal"] as Rect2).has_area()).is_false()


func test_royal_wheel_does_not_open_the_debug_overlay() -> void:
	var inspector: Inspector = auto_free(Inspector.new())
	add_child(inspector)
	var event := InputEventKey.new()
	event.physical_keycode = KEY_TAB
	event.pressed = true
	inspector._unhandled_input(event)
	assert_bool(inspector.visible).is_false()


func test_pause_home_keeps_management_in_secondary_pages() -> void:
	var menu: PauseMenu = auto_free(PauseMenu.new())
	add_child(menu)
	menu.open(false)
	assert_bool(menu._controls_button.is_visible_in_tree()).is_false()
	assert_bool(menu._export_button.is_visible_in_tree()).is_false()
	assert_bool(menu._zero._abrir.is_visible_in_tree()).is_false()
	assert_object(menu.get_viewport().gui_get_focus_owner()).is_same(menu._retomar)
	menu.show_options()
	assert_bool(menu._controls_button.is_visible_in_tree()).is_true()
	assert_bool(menu._zero._abrir.is_visible_in_tree()).is_true()
