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
