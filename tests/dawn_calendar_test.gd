extends GdUnitTestSuite

const STEP := 1.0 / 30.0


func before_test() -> void:
	EventBus.reset()
	SimLoop.autosave_enabled = false
	SimLoop.start(20261007)
	Greybox.build()
	LastCartWatch.claim(&"road")
	SimLoop.step(STEP)


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _dawn(day: int) -> void:
	var seconds := ClockService.clock.day_seconds()
	ClockService.seek(day, seconds - STEP / 2.0, seconds)
	SimLoop.state.day = day
	SimLoop.state.clock_elapsed = seconds - STEP / 2.0
	SimLoop.field._dia = day
	SimLoop._fase = GameClock.Phase.NIGHT
	SimLoop.step(STEP)


func test_societies_awaken_on_the_first_dawn_after_the_first_night() -> void:
	SimLoop.field.settlements.first_night_day = 1
	_dawn(1)
	assert_int(SimLoop.field.settlements.awake_day).is_equal(2)
	assert_int(SimLoop.field.settlements.records.size()).is_greater(0)
	var societies := SimLoop.field.settlements.records.size()
	SimLoop.step(STEP)
	assert_int(SimLoop.field.settlements.records.size()).is_equal(societies)


func test_greed_returns_on_the_dawn_when_the_offer_expires() -> void:
	SimLoop.state.greed = 0
	SimLoop.night.voice.greed_kept = 12
	SimLoop.night.voice.greed_until = 2
	_dawn(1)
	assert_int(SimLoop.state.greed).is_equal(12)
	assert_int(SimLoop.night.voice.greed_until).is_equal(0)


func test_all_dawn_payments_share_the_same_day_and_survive_a_save() -> void:
	WorldWorks.post(&"heir_house", SimLoop.core_x).raise_to(1)
	WorldWorks.post(RulesFactory.rules().ammo_depot, SimLoop.core_x).raise_to(1)
	var units := SimLoop.units
	var owner := units.owners[units.index_of(SimLoop.king_id)]
	var archer := units.spawn(
		SimLoop.state, Registry.entry(&"units", &"archer"), owner, SimLoop.core_x
	)
	SimLoop.field.supply.spent[archer] = 3
	for _k in 12:
		units.spawn(SimLoop.state, Registry.entry(&"units", &"builder"), owner, SimLoop.core_x)
	SimLoop.treasury.deposit(UnderWatch.HATCH_KEY, 100)
	_dawn(1)
	var treasury := SimLoop.treasury
	assert_int(treasury.payment_day).is_equal(2)
	assert_int(treasury.payments[&"heir"][&"paid"]).is_equal(5)
	assert_int(treasury.payments[&"upkeep"][&"paid"]).is_equal(2)
	assert_int(treasury.payments[&"arrows"][&"paid"]).is_equal(1)
	assert_int(treasury.payments.size()).is_equal(3)
	assert_int(treasury.amount(UnderWatch.HATCH_KEY)).is_equal(92)
	var restored := Treasury.new()
	restored.from_dict(treasury.to_dict())
	assert_dict(restored.payments).is_equal(treasury.payments)
	assert_int(restored.payment_day).is_equal(2)
