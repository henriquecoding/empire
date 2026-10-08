extends GdUnitTestSuite

var _memory: HintMemory
var _locale: String


func before_test() -> void:
	_memory = HintMemory.new("user://test_hints.cfg")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_memory.path))
	_memory = HintMemory.new(_memory.path)
	HintMemory.set_shared(_memory)
	_locale = TranslationServer.get_locale()
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20261008)
	Greybox.build()
	SimLoop.step(1.0 / 60.0)


func after_test() -> void:
	Input.action_release(&"move_right")
	TouchControls.active = false
	HintMemory.set_shared(null)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_memory.path))
	TranslationServer.set_locale(_locale)
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func test_movement_hides_the_context_on_the_same_frame() -> void:
	var panel: ContextPanel = auto_free(ContextPanel.new())
	add_child(panel)
	panel._process(1.0)
	assert_bool(panel.visible).is_true()
	Input.action_press(&"move_right")
	panel._process(0.0)
	assert_bool(panel.visible).is_false()


func test_an_interrupted_hint_can_be_read_after_stopping() -> void:
	var hint := HintCue.new()
	assert_bool(hint.present(&"CONTEXT_BUILD", true, 1.0)).is_true()
	assert_bool(hint.present(&"CONTEXT_BUILD", false, 10.0)).is_false()
	assert_bool(_memory.seen(&"CONTEXT_BUILD")).is_false()
	assert_bool(hint.present(&"CONTEXT_BUILD", true, 1.0)).is_true()


func test_a_read_hint_does_not_repeat_after_reloading() -> void:
	var hint := HintCue.new()
	hint.present(&"CONTEXT_BUILD", true, HintCue.STOP_SECONDS)
	hint.present(&"CONTEXT_BUILD", true, HintCue.READ_SECONDS)
	assert_bool(hint.present(&"CONTEXT_BUILD", true, 1.0)).is_false()
	assert_bool(HintMemory.new(_memory.path).seen(&"CONTEXT_BUILD")).is_true()
	assert_bool(HintCue.new().present(&"CONTEXT_BUILD", true, 1.0)).is_false()
	assert_bool(HintCue.new().present(&"CONTEXT_REPAIR", true, 1.0)).is_true()


func test_hint_identity_survives_a_price_or_language_change() -> void:
	SimLoop.arrival.active = false
	var site := RealmLadder.seat(SimLoop.builds)
	var king := SimLoop.units.index_of(SimLoop.king_id)
	SimLoop.units.xs[king] = site.x
	SimLoop.units.has_targets[king] = 0
	var first := GuideHints.context(Glyphs.Device.KEYBOARD)
	TranslationServer.set_locale("en" if _locale != "en" else "pt_PT")
	site.paid += 1
	var second := GuideHints.context(Glyphs.Device.KEYBOARD)
	assert_str(first.key).is_not_empty()
	assert_str(second.key).is_equal(first.key)
	assert_str(second.text).is_not_equal(first.text)
	MonarchWatch.begin(&"nia")
	SimLoop.units.xs[king] = 1000000.0
	var status := GuideHints.context(Glyphs.Device.KEYBOARD)
	assert_str(status.text).is_not_empty()
	assert_str(status.key).is_equal("CLASS_STATUS")


func test_coin_slots_show_payments_instead_of_the_purse_balance() -> void:
	assert_array(PriceTag.payment_slots(3, 2, 1)).contains_exactly([2, 2, 1, 0, 0])
	assert_array(PriceTag.payment_slots(3, 0, 8)).contains_exactly([1, 1, 1])


func test_moving_hides_objectives_and_control_instructions() -> void:
	var hud: GameHud = auto_free(GameHud.new())
	add_child(hud)
	hud._process(1.0)
	hud._ribbon._process(1.0)
	Input.action_press(&"move_right")
	hud._process(0.0)
	hud._ribbon._process(0.0)
	assert_bool(hud._dica.visible).is_false()
	assert_bool(hud._ribbon._goal.visible).is_false()


func test_collecting_coins_uses_the_counter_without_a_repeated_notice() -> void:
	var hud: GameHud = auto_free(GameHud.new())
	add_child(hud)
	EventBus.coin_collected.emit(SimLoop.king_id, 1)
	hud._process(0.0)
	assert_bool(hud._aviso.visible).is_false()


func test_an_objective_that_does_not_fit_is_not_counted_as_read() -> void:
	var viewport: SubViewport = auto_free(SubViewport.new())
	viewport.size = Vector2i(844, 390)
	add_child(viewport)
	TouchControls.active = true
	var ribbon := HudRibbon.new()
	viewport.add_child(ribbon)
	ribbon.refresh()
	ribbon._process(HintCue.READ_SECONDS + HintCue.STOP_SECONDS)
	assert_bool(ribbon._goal.visible).is_false()
	assert_bool(_memory.seen(ribbon._goal_key)).is_false()
