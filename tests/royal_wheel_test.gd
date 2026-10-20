extends GdUnitTestSuite

var wheel: RoyalWheel


func before_test() -> void:
	SimLoop.autosave_enabled = false
	SimLoop.set_physics_process(false)
	SimLoop.start(1234)
	Greybox.build()
	MonarchWatch.begin(&"monarch")
	ClassSelection.active = false
	TravelPanel.active = false
	SiteSheet.active = false
	wheel = auto_free(RoyalWheel.new())
	add_child(wheel)
	wheel.set_process(false)
	SimLoop.intents.clear()


func after_test() -> void:
	wheel.close()
	TouchControls.aim = Vector2.ZERO
	Input.action_release(&"king_wheel")
	Input.action_release(&"verb_drop")
	RoyalWheel.release_guard = false
	SimLoop.stop()
	SimLoop.set_physics_process(true)


func test_opening_and_cancelling_spends_nothing() -> void:
	var before := RealmReadout.purse()
	wheel.open()
	assert_bool(RoyalWheel.active).is_true()
	assert_int(wheel.count()).is_equal(6)
	wheel.choose(-1)
	assert_bool(RoyalWheel.active).is_false()
	assert_int(SimLoop.intents.pending()).is_equal(0)
	assert_that(RealmReadout.purse()).is_equal(before)


func test_boost_is_a_separate_deliberate_choice() -> void:
	wheel.open()
	wheel.choose(3)
	assert_bool(wheel.impulses).is_true()
	assert_bool(RoyalWheel.active).is_true()
	assert_int(SimLoop.intents.pending()).is_equal(0)
	wheel.close()
	assert_bool(RoyalWheel.active).is_false()


func test_pause_cancels_selection_and_restores_time() -> void:
	wheel.open()
	wheel.selected = 3
	Pace.scale = 0.5
	SimLoop.set_paused(true)
	assert_bool(RoyalWheel.active).is_false()
	assert_int(wheel.selected).is_equal(-1)
	assert_float(Pace.scale).is_equal(1.0)
	assert_int(SimLoop.intents.pending()).is_equal(0)


func test_window_focus_loss_never_commits_the_selected_command() -> void:
	wheel.open()
	wheel.selected = 3
	wheel._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	assert_bool(RoyalWheel.active).is_false()
	assert_int(SimLoop.intents.pending()).is_equal(0)


func test_other_menus_prevent_opening_the_wheel() -> void:
	SiteSheet.active = true
	wheel.open()
	assert_bool(RoyalWheel.active).is_false()
	SiteSheet.active = false
	TravelPanel.active = true
	wheel.open()
	assert_bool(RoyalWheel.active).is_false()
	TravelPanel.active = false


func test_unaffordable_boost_does_not_enter_the_queue() -> void:
	var index := SimLoop.units.index_of(SimLoop.king_id)
	SimLoop.units.carried_coins[index] = 0
	wheel.open()
	wheel.choose(3)
	wheel.choose(0)
	assert_bool(RoyalWheel.active).is_false()
	assert_int(SimLoop.intents.pending()).is_equal(0)


func test_drag_release_opens_boosts_then_requires_a_second_gesture() -> void:
	RoyalWheel.release_guard = false
	Input.action_press(&"king_wheel")
	TouchControls.aim = Vector2.DOWN
	wheel._process(0.0)
	Input.action_release(&"king_wheel")
	wheel._process(0.0)
	assert_bool(wheel.impulses).is_true()
	assert_bool(RoyalWheel.active).is_true()
	assert_int(SimLoop.intents.pending()).is_equal(0)
	TouchControls.aim = Vector2.ZERO
	wheel._process(0.0)
	assert_bool(RoyalWheel.active).is_true()
	Input.action_press(&"king_wheel")
	TouchControls.aim = Vector2.ZERO
	wheel._process(0.0)
	Input.action_release(&"king_wheel")
	wheel._process(0.0)
	assert_bool(RoyalWheel.active).is_false()
	assert_int(SimLoop.intents.pending()).is_equal(0)


func test_keyboard_selection_never_spills_into_coin_or_attack() -> void:
	wheel.open()
	var key := InputEventKey.new()
	key.physical_keycode = KEY_2
	key.pressed = true
	Input.action_press(&"verb_drop")
	wheel._input(key)
	assert_bool(RoyalWheel.active).is_false()
	assert_bool(RoyalWheel.release_guard).is_true()
	assert_bool(CombatInput.blocked()).is_true()
	assert_int(SimLoop.intents.pending()).is_equal(0)
	Input.action_release(&"verb_drop")
	wheel._process(0.0)
	assert_bool(RoyalWheel.release_guard).is_false()


func test_number_previews_boost_cost_before_enter_confirms() -> void:
	wheel.open()
	wheel.choose(3)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_1
	key.pressed = true
	wheel._input(key)
	assert_bool(RoyalWheel.active).is_true()
	assert_int(wheel.selected).is_equal(0)
	assert_str(wheel._detail.text).is_not_empty()
	assert_int(SimLoop.intents.pending()).is_equal(0)
	wheel._process(0.0)
	assert_int(wheel.selected).is_equal(0)
