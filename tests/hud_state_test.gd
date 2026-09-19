extends GdUnitTestSuite


func before_test() -> void:
	Registry.load_all()
	SimLoop.start(20260919)
	SimLoop.autosave_enabled = false
	Greybox.build()


func after_test() -> void:
	SimLoop.stop()


func test_core_defeat_is_not_pause_and_has_no_resume() -> void:
	SimLoop.set_paused(true)
	assert_str(HudState.mode()).is_equal("paused")
	for slot in SimLoop.builds.slots:
		if slot.kind == BuildSlot.NUCLEO:
			slot.state = BuildSlot.State.RUIN
	assert_str(HudState.mode()).is_equal("defeat")


func test_passage_hint_uses_the_same_reach_as_the_simulation() -> void:
	var i := SimLoop.units.index_of(SimLoop.king_id)
	SimLoop.units.xs[i] = SimLoop.passages[0] + Band.PASSAGE_PX
	assert_str(HudState.context_key()).is_equal("HUD_PASSAGE")
	SimLoop.units.xs[i] += 1.0
	assert_str(HudState.context_key()).is_not_equal("HUD_PASSAGE")
