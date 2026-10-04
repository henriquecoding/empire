extends GdUnitTestSuite


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20261004)
	Greybox.build()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func test_banner_starts_free_camp_and_opens_existing_reserve() -> void:
	var r := SimLoop.units.index_of(SimLoop.king_id)
	var money := SimLoop.units.carried_coins[r]
	SimLoop.step(10.0)
	assert_float(ClockService.clock.elapsed).is_equal(0.0)
	SimLoop.units.xs[r] = SimLoop.arrival.origin - 256.0
	SimLoop.units.target_xs[r] = SimLoop.units.xs[r]
	SimLoop.intents.queue(IntentQueue.Kind.ASSUME, {})
	SimLoop.step(5.0)
	assert_str(String(SimLoop.arrival.choice)).is_equal("grove")
	assert_int(RealmLadder.stage(SimLoop.builds)).is_equal(1)
	assert_bool(SimLoop.seat.cart_open).is_true()
	assert_int(SimLoop.units.carried_coins[r]).is_equal(money)
	assert_int(SimLoop.seat.cart_coins + SimLoop.arrival.cache_coins).is_equal(8)
	assert_bool(CompanionWatch.site().standing()).is_true()


func test_foundation_offset_survives_reload_without_moving_authored_ids() -> void:
	var original := SimLoop.core_x
	LastCartWatch.claim(&"grove")
	var before := SimLoop.builds.to_dict()
	var saved := SimLoop.world()
	var state := SimLoop.state
	var rng := RngService.snapshot()
	SimLoop.resume(state, rng)
	Greybox.region()
	SimLoop.load_world(saved)
	assert_float(SimLoop.core_x).is_equal(original - 256.0)
	for i in before.size():
		assert_float(SimLoop.builds.slots[i].x).is_equal(float(before[i][&"x"]))
	assert_int(SimLoop.seat.cart_coins + SimLoop.arrival.cache_coins).is_equal(8)
	assert_bool(SimLoop.seat.cart_open).is_false()


func test_labor_requires_a_recruited_person_and_presence() -> void:
	LastCartWatch.claim(&"road")
	assert_bool(ArrivalLabor.assign(LastCart.FORAGE)).is_false()
	var u := SimLoop.units
	u.owners[1] = u.owners[0]
	assert_bool(ArrivalLabor.assign(LastCart.FORAGE)).is_true()
	var worker := u.index_of(SimLoop.arrival.worker)
	u.xs[worker] = SimLoop.core_x
	ArrivalLabor.tick(30.0, GameClock.Phase.MORNING)
	assert_int(SimLoop.arrival.earned).is_equal(0)
	u.xs[worker] = SimLoop.arrival.cache_x
	ArrivalLabor.tick(30.0, GameClock.Phase.MORNING)
	assert_int(SimLoop.arrival.earned).is_equal(1)
	assert_int(SimLoop.coins.count()).is_equal(1)


func test_supply_rescue_and_scouting_use_the_same_worker() -> void:
	LastCartWatch.claim(&"road")
	var u := SimLoop.units
	u.owners[1] = u.owners[0]
	ArrivalLabor.assign(LastCart.RESCUE)
	var worker := u.index_of(SimLoop.arrival.worker)
	u.xs[worker] = SimLoop.arrival.cache_x
	ArrivalLabor.tick(30.0, GameClock.Phase.MORNING)
	assert_int(SimLoop.arrival.cache_coins).is_equal(3)
	u.xs[worker] = SimLoop.seat.cart_x
	ArrivalLabor.tick(1.0, GameClock.Phase.MORNING)
	assert_int(SimLoop.arrival.cache_coins).is_equal(0)
	assert_int(SimLoop.seat.cart_coins).is_equal(8)
	ArrivalLabor.assign(LastCart.SCOUT)
	u.xs[worker] = SimLoop.core_x + Greybox.PASSAGENS_X[0]
	ArrivalLabor.tick(30.0, GameClock.Phase.MORNING)
	assert_bool(SimLoop.arrival.scouted).is_true()
	assert_int(SimLoop.arrival.worker).is_equal(-1)


func test_companion_requires_payment_and_arrival_for_each_monarch() -> void:
	MonarchWatch.begin(&"archer_emperor")
	LastCartWatch.claim(&"road")
	RealmLadder.seat(SimLoop.builds).raise_to(1)
	FoundationWatch.founded_tools()
	var u := SimLoop.units
	u.owners[1] = u.owners[0]
	var post := CompanionWatch.site()
	var offer := {
		EventRelay.ONDE: post.x, EventRelay.FAIXA: Band.Kind.SURFACE, EventRelay.QUANTO: 7
	}
	assert_bool(CompanionWatch.pay(offer)).is_true()
	var people := u.count()
	CompanionWatch.plan()
	assert_bool(CompanionWatch.available()).is_true()
	u.xs[1] = post.x
	CompanionWatch.plan()
	assert_bool(CompanionWatch.available()).is_false()
	assert_int(u.count()).is_equal(people)
	assert_str(String(u.data_ids[1])).is_equal(String(MonarchWatch.data().companion))


func test_companion_training_takes_the_worker_out_of_existing_labor() -> void:
	LastCartWatch.claim(&"road")
	RealmLadder.seat(SimLoop.builds).raise_to(1)
	FoundationWatch.founded_tools()
	var u := SimLoop.units
	u.owners[1] = u.owners[0]
	assert_bool(ArrivalLabor.assign(LastCart.FORAGE)).is_true()
	var worker := SimLoop.arrival.worker
	var post := CompanionWatch.site()
	var offer := {EventRelay.ONDE: post.x, EventRelay.FAIXA: post.band, EventRelay.QUANTO: 6}
	CompanionWatch.pay(offer)
	assert_int(SimLoop.arrival.worker).is_equal(worker)
	assert_str(String(SimLoop.arrival.task)).is_equal("forage")
	offer[EventRelay.QUANTO] = 1
	CompanionWatch.pay(offer)
	assert_int(SimLoop.companion.worker).is_equal(worker)
	assert_int(SimLoop.arrival.worker).is_equal(LastCart.NONE)
	assert_str(String(SimLoop.arrival.task)).is_equal("")
	ArrivalLabor.reserve()
	assert_bool(SimLoop.jobs.excluded.has(worker)).is_true()
	u.xs[u.index_of(worker)] = SimLoop.arrival.cache_x
	ArrivalLabor.tick(30.0, GameClock.Phase.MORNING)
	assert_int(SimLoop.arrival.earned).is_equal(0)
	assert_int(SimLoop.coins.count()).is_equal(0)


func test_save_v9_preserves_legacy_campaign_and_never_replays_arrival() -> void:
	var save := {&"save_version": 9, &"world": {&"seat": {&"cart_coins": 5}}}
	var migrated := SaveMigrations.migrate(save)
	assert_bool(migrated[&"world"][&"arrival"][&"active"]).is_false()
	assert_bool(migrated[&"world"][&"seat"][&"cart_open"]).is_true()
	assert_int(save[&"save_version"]).is_equal(9)
