extends GdUnitTestSuite

const STEP := 1.0 / 60.0
const R := TouchLayout.Role

var _touch: TouchControls
var _combat: CombatInput
var _router: InputRouter
var _mouse_emulation := false
var _touch_emulation := false
var _active := false
var _window_size := Vector2i.ZERO


func before_test() -> void:
	_mouse_emulation = Input.is_emulating_mouse_from_touch()
	_touch_emulation = Input.is_emulating_touch_from_mouse()
	_active = TouchControls.active
	_window_size = get_tree().root.size
	get_tree().root.size = Vector2i(1280, 720)
	Input.set_emulate_mouse_from_touch(true)
	Input.set_emulate_touch_from_mouse(false)
	SimLoop.autosave_enabled = false
	SimLoop.set_physics_process(false)
	EventBus.reset()
	SimLoop.start(20261008)
	Greybox.build()
	MonarchWatch.begin(&"archer_emperor")
	HeroWatch.tick(0.0)
	_router = auto_free(InputRouter.new())
	add_child(_router)
	_router.set_process(false)
	_combat = auto_free(CombatInput.new())
	add_child(_combat)
	_combat.set_process(false)
	_touch = auto_free(TouchControls.new())
	add_child(_touch)
	_touch.set_process(false)
	TouchControls.active = true
	WideTouch.apply(get_tree().root, true)
	_touch._medir()
	SimLoop.intents.clear()


func after_test() -> void:
	_touch._largar_tudo()
	for action: StringName in TouchPad.ACCOES.values() + TouchPad.ANDAR + [&"pause"]:
		Input.action_release(action)
	Input.flush_buffered_events()
	Input.set_emulate_mouse_from_touch(_mouse_emulation)
	Input.set_emulate_touch_from_mouse(_touch_emulation)
	TouchControls.active = _active
	get_tree().root.size = _window_size
	SimLoop.stop()
	SimLoop.set_physics_process(true)
	SimLoop.autosave_enabled = true


func _finger(index: int, position: Vector2, pressed: bool, canceled: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = get_viewport().get_final_transform() * position
	event.pressed = pressed
	event.canceled = canceled
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _drag(index: int, position: Vector2, relative: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = get_viewport().get_final_transform() * position
	event.relative = get_viewport().get_final_transform().basis_xform(relative)
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _frame() -> void:
	_touch._process(STEP)
	Input.flush_buffered_events()
	_combat._process(STEP)


func test_lifting_the_movement_finger_does_not_release_a_held_attack() -> void:
	var stick := _touch.pad.layout.stick_home()
	var attack := _touch.pad.layout.centre(R.ATTACK)
	_finger(0, stick, true)
	_drag(0, stick + Vector2(50, 0), Vector2(50, 0))
	_frame()
	_finger(1, attack, true)
	_frame()
	assert_bool(_combat._attack_held).is_true()
	SimLoop.intents.clear()
	_finger(0, stick, false)
	_frame()
	assert_bool(_touch.pad.holds(R.ATTACK)).is_true()
	assert_bool(_combat._attack_held).is_true()
	assert_bool(Input.is_action_pressed(&"attack")).is_true()
	assert_int(SimLoop.intents.pending()).is_greater(0)
	_finger(1, attack, false)
	_frame()
	assert_bool(_combat._attack_held).is_false()


func test_attack_works_while_moving_immediately_after_resuming() -> void:
	SimLoop.set_paused(true)
	SimLoop.set_paused(false)
	var stick := _touch.pad.layout.stick_home()
	_finger(0, stick, true)
	_drag(0, stick + Vector2(50, 0), Vector2(50, 0))
	_frame()
	var attack := _touch.pad.layout.centre(R.ATTACK)
	_finger(1, attack, true)
	_frame()
	assert_bool(_combat._attack_held).is_true()
	assert_int(SimLoop.intents.pending()).is_greater(0)
	_finger(1, attack, false)
	_finger(0, stick, false)
	_frame()


func test_a_canceled_pause_touch_does_not_open_the_menu() -> void:
	var pause := _touch.pad.layout.centre(R.PAUSE)
	_finger(0, pause, true)
	_finger(0, pause, false, true)
	_frame()
	assert_bool(SimLoop.running()).is_true()


func test_a_second_finger_cannot_take_over_the_movement_stick() -> void:
	var stick := _touch.pad.layout.stick_home()
	_finger(0, stick, true)
	_drag(0, stick + Vector2(50, 0), Vector2(50, 0))
	_frame()
	_finger(1, stick + Vector2(150, -60), true)
	_frame()
	assert_bool(Input.is_action_pressed(&"move_right")).is_true()
	_drag(1, stick - Vector2(100, 0), Vector2(-250, 60))
	_frame()
	assert_bool(Input.is_action_pressed(&"move_right")).is_true()
	_finger(0, stick, false)
	_frame()
	assert_bool(Input.is_action_pressed(&"move_right")).is_false()
	assert_bool(Input.is_action_pressed(&"move_left")).is_false()
	_finger(1, stick, false)


func test_a_canceled_fast_attack_does_not_fire() -> void:
	var attack := _touch.pad.layout.centre(R.ATTACK)
	_finger(0, attack, true)
	_finger(0, attack, false, true)
	_frame()
	assert_int(SimLoop.intents.pending()).is_equal(0)
	assert_bool(Input.is_action_pressed(&"attack")).is_false()


func test_canceling_another_finger_keeps_the_completed_coin_tap() -> void:
	var coin := _touch.pad.layout.centre(R.DROP)
	_finger(0, coin, true)
	_finger(0, coin, false)
	_finger(1, coin, true)
	_finger(1, coin, false, true)
	_frame()
	assert_bool(Input.is_action_pressed(&"verb_drop")).is_true()
	_frame()
	assert_bool(Input.is_action_pressed(&"verb_drop")).is_false()


func test_mouse_touch_emulation_does_not_activate_hud_buttons() -> void:
	var event := InputEventScreenTouch.new()
	event.device = InputEvent.DEVICE_ID_EMULATION
	event.position = _touch.pad.layout.centre(R.DROP)
	event.pressed = true
	_touch._input(event)
	_frame()
	assert_bool(_touch.pad.holds(R.DROP)).is_false()
	assert_bool(Input.is_action_pressed(&"verb_drop")).is_false()


func test_touching_pause_and_resume_accepts_new_hud_commands() -> void:
	var menu: PauseMenu = auto_free(PauseMenu.new())
	add_child(menu)
	var pause := _touch.pad.layout.centre(R.PAUSE)
	_finger(0, pause, true)
	_finger(0, pause, false)
	_frame()
	assert_bool(menu.visible).is_true()
	assert_bool(SimLoop.running()).is_false()
	assert_bool(Input.is_emulating_touch_from_mouse()).is_false()
	await get_tree().process_frame
	await get_tree().process_frame
	var resume := menu._retomar.get_global_rect().get_center()
	_finger(0, resume, true)
	_finger(0, resume, false)
	_frame()
	assert_bool(SimLoop.running()).is_true()
	assert_bool(menu.visible).is_false()
	var attack := _touch.pad.layout.centre(R.ATTACK)
	_finger(0, attack, true)
	_frame()
	assert_bool(_combat._attack_held).is_true()
	_finger(0, attack, false)
	_frame()


func test_opening_pause_releases_even_unbuffered_actions() -> void:
	var accumulated := Input.is_using_accumulated_input()
	Input.set_use_accumulated_input(false)
	_touch._emitir(&"pause", true)
	assert_bool(SimLoop.running()).is_false()
	assert_bool(_touch._premidas.get(&"pause", false)).is_false()
	assert_bool(Input.is_action_pressed(&"pause")).is_false()
	Input.set_use_accumulated_input(accumulated)
