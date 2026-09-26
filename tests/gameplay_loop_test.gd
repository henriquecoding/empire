extends GdUnitTestSuite

const STEP := 1.0 / 30.0


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20260926)
	Greybox.build()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _run(seconds: float) -> void:
	for tick in int(seconds / STEP):
		SimLoop.step(STEP)


func test_paid_farm_completes_with_worker_while_the_king_explores() -> void:
	var site: BuildSlot
	for candidate in SimLoop.builds.slots:
		if candidate.kind == &"farm":
			site = candidate
			break
	# Isolate the complete payment -> assignment -> walking -> building flow.
	for id in SimLoop.units.ids.duplicate():
		SimLoop.units.remove(id)
	var king := SimLoop.units.spawn(SimLoop.state, Registry.entry(&"units", &"monarch"), 1, site.x)
	SimLoop.king_id = king
	var worker := SimLoop.units.spawn(
		SimLoop.state, Registry.entry(&"units", &"vagrant"), 1, site.x - 200.0
	)
	SimLoop.units.carried_coins[0] = site.next_cost()
	SimLoop.intents.queue(
		IntentQueue.Kind.DROP_COIN,
		{
			&"x": site.x,
			&"band": Band.Kind.SURFACE,
			&"amount": site.next_cost(),
			&"source": Verbs.JOGADOR
		}
	)
	SimLoop.units.set_target_x(king, site.x + 400.0)
	_run(20.0)
	assert_int(site.state).is_equal(BuildSlot.State.DONE)
	assert_int(SimLoop.units.job_ids[SimLoop.units.index_of(worker)]).is_not_equal(-1)
	assert_float(SimLoop.units.xs[0]).is_equal(site.x + 400.0)


func test_recruitment_reassigns_in_the_same_phase_and_band_changes_invalidate() -> void:
	var site := SimLoop.builds.slots[1]
	site.level = 1
	site.state = BuildSlot.State.DONE
	SimLoop.step(STEP)
	var archer := SimLoop.units.spawn(SimLoop.state, Registry.entry(&"units", &"archer"), 0, site.x)
	var i := SimLoop.units.index_of(archer)
	SimLoop.units.owners[i] = 1
	SimLoop.step(STEP)
	assert_int(SimLoop.units.job_ids[i]).is_not_equal(-1)
	SimLoop.units.bands[i] = Band.Kind.UNDERGROUND
	SimLoop.step(STEP)
	assert_int(SimLoop.units.job_ids[i]).is_equal(-1)


func test_wall_path_can_be_chosen_with_the_real_intent_and_is_saved() -> void:
	var site := SimLoop.builds.slots[1]
	var i := SimLoop.units.index_of(SimLoop.king_id)
	SimLoop.units.xs[i] = site.x
	SimLoop.intents.queue(IntentQueue.Kind.ASSUME)
	SimLoop.step(STEP)
	assert_int(site.path).is_equal(BuildSlot.Path.GUARNICAO)
	var saved := SimLoop.world()
	site.path = BuildSlot.Path.FORTIFICACAO
	SimLoop.load_world(saved)
	assert_int(site.path).is_equal(BuildSlot.Path.GUARNICAO)
	assert_dict(SimLoop.hunting.to_dict()).is_equal(saved[&"hunting"])


func test_the_context_only_offers_the_wall_path_the_verb_accepts() -> void:
	var site := SimLoop.builds.slots[1]
	var i := SimLoop.units.index_of(SimLoop.king_id)
	var paths := [
		TranslationServer.translate(&"PATH_GARRISON"), TranslationServer.translate(&"PATH_FORTIFY")
	]
	SimLoop.units.xs[i] = site.x
	site.level = 1
	site.state = BuildSlot.State.DAMAGED
	var before := site.path
	var hint := GameplayGuide.context(Glyphs.Device.KEYBOARD)
	for path in paths:
		assert_str(hint).not_contains(path)
	SimLoop.intents.queue(IntentQueue.Kind.ASSUME)
	SimLoop.step(STEP)
	assert_int(site.path).is_equal(before)
	site.state = BuildSlot.State.DONE
	SimLoop.units.xs[i] = site.x
	var offered := GameplayGuide.context(Glyphs.Device.KEYBOARD)
	assert_bool(offered.contains(paths[0]) or offered.contains(paths[1])).is_true()
	SimLoop.intents.queue(IntentQueue.Kind.ASSUME)
	SimLoop.step(STEP)
	assert_int(site.path).is_not_equal(before)


func test_the_coin_toast_is_the_kings_and_troops_do_not_count_him() -> void:
	var hud: GameHud = auto_free(GameHud.new())
	add_child(hud)
	assert_int(GameplayGuide.troops()).is_equal(0)
	var archer := SimLoop.units.index_of(7)
	SimLoop.units.owners[archer] = SimLoop.units.owners[SimLoop.units.index_of(SimLoop.king_id)]
	assert_int(GameplayGuide.troops()).is_equal(1)
	EventBus.coin_collected.emit(SimLoop.units.ids[archer], 1)
	assert_str(hud._aviso.text).is_empty()
	EventBus.coin_collected.emit(SimLoop.king_id, 1)
	assert_str(hud._aviso.text).is_equal(HudText.coins(1))
