extends GdUnitTestSuite

var _was_touch := false
var _emulated := false


func before_test() -> void:
	_was_touch = TouchControls.active
	_emulated = Input.is_emulating_touch_from_mouse()
	TouchControls.active = true
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20261008)
	Greybox.build()
	SimLoop.set_paused(true)


func after_test() -> void:
	TouchControls.active = _was_touch
	Input.set_emulate_touch_from_mouse(_emulated)
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _menu() -> PauseMenu:
	var menu: PauseMenu = auto_free(PauseMenu.new())
	add_child(menu)
	menu.open(false)
	return menu


func test_the_pause_does_not_change_global_input_emulation() -> void:
	Input.set_emulate_touch_from_mouse(false)
	var menu := _menu()
	assert_bool(Input.is_emulating_touch_from_mouse()).is_false()
	menu._fechar()
	assert_bool(Input.is_emulating_touch_from_mouse()).is_false()


func test_dragging_over_a_button_does_not_move_keyboard_focus() -> void:
	var menu := _menu()
	var motion := InputEventMouseMotion.new()
	motion.device = InputEvent.DEVICE_ID_EMULATION
	motion.relative = Vector2(0, -40)
	menu._options_button.gui_input.emit(motion)
	assert_object(menu.get_viewport().gui_get_focus_owner()).is_same(menu._retomar)


func test_options_can_receive_swipes_over_their_interactive_children() -> void:
	var menu := _menu()
	assert_int(menu._options_button.mouse_filter).is_equal(Control.MOUSE_FILTER_PASS)
	menu.show_options()
	assert_int(menu._opcoes._tremor.mouse_filter).is_equal(Control.MOUSE_FILTER_PASS)
	assert_int(menu._opcoes._contraste.mouse_filter).is_equal(Control.MOUSE_FILTER_PASS)
	assert_int(menu._opcoes._daltonismo.mouse_filter).is_equal(Control.MOUSE_FILTER_PASS)


func test_losing_focus_releases_the_scroll_finger() -> void:
	var viewport: SubViewport = auto_free(SubViewport.new())
	viewport.size = Vector2i(844, 390)
	add_child(viewport)
	var menu := PauseMenu.new()
	viewport.add_child(menu)
	menu.open(false)
	await get_tree().process_frame
	await get_tree().process_frame
	var area := menu._frame.home as TouchScroll
	var press := InputEventScreenTouch.new()
	press.position = area.get_global_rect().get_center()
	press.pressed = true
	viewport.push_input(press, true)
	area._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_int(area._finger).is_equal(-1)
	await _swipe(viewport, press.position, 1)
	assert_int(area.scroll_vertical).is_greater(0)


func test_swiping_the_home_moves_the_list_without_activating_a_button() -> void:
	var viewport: SubViewport = auto_free(SubViewport.new())
	viewport.size = Vector2i(844, 390)
	add_child(viewport)
	var menu := PauseMenu.new()
	viewport.add_child(menu)
	menu.open(false)
	await get_tree().process_frame
	await get_tree().process_frame
	var area := menu._frame.home
	var start := area.get_global_rect().get_center()
	await _swipe(viewport, start)
	assert_int(area.scroll_vertical).is_greater(0)
	assert_bool(menu.visible).is_true()
	assert_int(menu._page).is_equal(PauseMenu.Page.HOME)
	assert_bool(SimLoop.running()).is_false()


func test_swiping_over_an_option_scrolls_without_changing_the_setting() -> void:
	var viewport: SubViewport = auto_free(SubViewport.new())
	viewport.size = Vector2i(844, 390)
	add_child(viewport)
	var menu := PauseMenu.new()
	viewport.add_child(menu)
	menu.open(false)
	menu.show_options()
	await get_tree().process_frame
	await get_tree().process_frame
	var area := menu._pages.options.get_child(1).get_child(0) as ScrollContainer
	var toggle := menu._opcoes._tremor
	var value := toggle.button_pressed
	await _swipe(viewport, toggle.get_global_rect().get_center())
	assert_int(area.scroll_vertical).is_greater(0)
	assert_bool(toggle.button_pressed).is_equal(value)
	assert_int(menu._page).is_equal(PauseMenu.Page.OPTIONS)


func _swipe(viewport: SubViewport, start: Vector2, index := 0) -> void:
	var mouse := InputEventMouseButton.new()
	mouse.device = InputEvent.DEVICE_ID_EMULATION
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.position = start
	mouse.pressed = true
	viewport.push_input(mouse, true)
	var press := InputEventScreenTouch.new()
	press.index = index
	press.position = start
	press.pressed = true
	viewport.push_input(press, true)
	for n in 10:
		var motion := InputEventMouseMotion.new()
		motion.device = InputEvent.DEVICE_ID_EMULATION
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		motion.position = start - Vector2(0, (n + 1) * 12)
		motion.relative = Vector2(0, -12)
		viewport.push_input(motion, true)
		var drag := InputEventScreenDrag.new()
		drag.index = index
		drag.position = start - Vector2(0, (n + 1) * 12)
		drag.relative = Vector2(0, -12)
		viewport.push_input(drag, true)
		await get_tree().process_frame
	press.pressed = false
	press.position = start - Vector2(0, 120)
	mouse.pressed = false
	mouse.position = press.position
	viewport.push_input(mouse, true)
	viewport.push_input(press, true)
