extends GdUnitTestSuite


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20261004)
	Greybox.build()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func test_the_warning_stops_exposed_income_before_any_creature_exists() -> void:
	LastCartWatch.claim(&"road")
	var u := SimLoop.units
	u.owners[1] = u.owners[0]
	ArrivalLabor.assign(LastCart.FORAGE)
	u.xs[1] = SimLoop.arrival.cache_x
	LastCartWatch.tick(0.0, GameClock.Phase.AFTERNOON, true)
	ArrivalLabor.tick(30.0, GameClock.Phase.AFTERNOON)
	assert_bool(SimLoop.arrival.tainted).is_true()
	assert_int(SimLoop.arrival.earned).is_equal(0)
	assert_int(SimLoop.creatures.count()).is_equal(0)
	assert_bool(SimLoop.arrival.events.has(&"rot_first_noticed")).is_false()
	u.xs[0] = SimLoop.arrival.cache_x
	LastCartWatch.use()
	assert_bool(SimLoop.arrival.events.has(&"rot_first_noticed")).is_true()


func test_the_visible_old_roots_can_be_inspected_before_the_banner_or_any_payment() -> void:
	var trees := SimLoop.night.amargueiros
	var inspected := false
	for k in trees.count():
		if trees.fates[k] != AmargueiroSystem.Fate.OLD:
			continue
		SimLoop.units.xs[0] = trees.xs[k]
		var purse := SimLoop.units.carried_coins[0]
		SimLoop.intents.queue(IntentQueue.Kind.ASSUME, {})
		SimLoop.step(1.0 / 30.0)
		assert_str(String(SimLoop.arrival.events[&"first_landmark_inspected"][&"value"])).is_equal(
			"black_roots"
		)
		assert_bool(SimLoop.arrival.events.has(&"rot_first_noticed")).is_true()
		assert_int(SimLoop.units.carried_coins[0]).is_equal(purse)
		assert_bool(SimLoop.arrival.choice == &"").is_true()
		inspected = true
	assert_bool(inspected).is_true()


func test_the_first_night_leaves_a_saved_scar_or_preserves_the_protected_reserve() -> void:
	LastCartWatch.claim(&"road")
	var rot := SimLoop.night.rot
	rot.spawn(1, -1, SimLoop.world_width)
	rot.state.trail_from = 0.0
	rot.state.trail_to = SimLoop.arrival.cache_x + 100.0
	LastCartWatch.tick(0.0, GameClock.Phase.NIGHT, false)
	assert_bool(SimLoop.arrival.scar).is_true()
	assert_int(SimLoop.arrival.cache_coins).is_equal(0)
	var saved := SimLoop.world()
	SimLoop.load_world(saved)
	assert_bool(SimLoop.arrival.scar).is_true()
	LastCartWatch.tick(0.0, GameClock.Phase.DAWN, true)
	assert_str(String(SimLoop.arrival.events[&"night_one_loss_type"][&"value"])).is_equal(
		"provisions"
	)
	SimLoop.arrival.scar = false
	SimLoop.arrival.survived = false
	SimLoop.arrival.cache_coins = 3
	for wall in SimLoop.builds.slots:
		if wall.two_paths() and is_equal_approx(wall.x, SimLoop.core_x - 680.0):
			wall.raise_to(1)
	LastCartWatch.tick(0.0, GameClock.Phase.NIGHT, false)
	assert_int(SimLoop.arrival.cache_coins).is_equal(3)
	assert_bool(SimLoop.arrival.scar).is_false()


func test_grove_and_road_preserve_geography_but_enclose_different_habitat() -> void:
	var habitat := SimLoop.core_x - 830.0
	LastCartWatch.claim(&"grove")
	WildHunt.prepare(SimLoop.field, 1, SimLoop.core_x, SimLoop.world_width, 0)
	assert_bool(SimLoop.hunting.burrows.xs.has(habitat)).is_true()
	var saved := SimLoop.world()
	var core := SimLoop.core_x
	SimLoop.load_world(saved)
	SimLoop.load_world(saved)
	assert_float(SimLoop.core_x).is_equal(core)
	for wall in SimLoop.builds.slots:
		if wall.two_paths() and is_equal_approx(wall.x, core - 680.0):
			wall.raise_to(1)
	WildHunt.prepare(SimLoop.field, 1, core, SimLoop.world_width, 0)
	var k := SimLoop.hunting.burrows.xs.find(habitat)
	assert_int(SimLoop.hunting.burrows.alive[k]).is_equal(0)


func test_foreign_chest_uses_existing_wealth_and_player_chest_starts_empty() -> void:
	LastCartWatch.claim(&"road")
	var under := SimLoop.field.under
	var own := under.find(SimLoop.core_x, INF)
	for k in under.count():
		if under.key_of(k) == UnderWatch.HATCH_KEY:
			own = k
	var mouth := under.mouth_of(own)
	UnderWatch.enter(mouth, Band.PASSAGE_PX)
	assert_int(SimLoop.treasury.amount(UnderWatch.HATCH_KEY)).is_equal(0)
	var record := SimLoop.field.settlements.add(2, &"portuarios", 5000.0, 10)
	CellarWatch.foreign(SimLoop.field, 2, record)
	assert_int(SimLoop.treasury.amount("realm_hatch_2")).is_equal(5)
	assert_float(SimLoop.field.settlements.treasury(2)).is_equal(5.0)
	CellarWatch.foreign(SimLoop.field, 2, record)
	assert_float(SimLoop.field.settlements.treasury(2)).is_equal(5.0)
	var r := SimLoop.units.index_of(SimLoop.king_id)
	var chest := UnderReserve.chest_x(under, own)  # na baia, longe da subida (ADR 0072)
	SimLoop.units.bands[r] = Band.Kind.UNDERGROUND
	SimLoop.units.xs[r] = chest
	SimLoop.units.clear_target(SimLoop.king_id)
	var purse := SimLoop.units.carried_coins[r]
	SimLoop.intents.queue(
		IntentQueue.Kind.DROP_COIN,
		{&"x": chest, &"band": Band.Kind.UNDERGROUND, &"amount": 2, &"source": Verbs.JOGADOR}
	)
	SimLoop.step(1.0 / 30.0)
	assert_int(SimLoop.treasury.amount(UnderWatch.HATCH_KEY)).is_equal(2)
	assert_int(SimLoop.units.carried_coins[r]).is_equal(purse - 2)
	SimLoop.intents.queue(IntentQueue.Kind.ASSUME, {})
	SimLoop.step(1.0 / 30.0)
	assert_int(SimLoop.units.carried_coins[r]).is_equal(purse)
	SimLoop.treasury.deposit(UnderWatch.HATCH_KEY, 3)
	var foe := SimLoop.creatures.spawn(
		SimLoop.state, Registry.entry(&"creatures", &"burrower"), chest, chest
	)
	SimLoop.creatures.bands[SimLoop.creatures.index_of(foe)] = Band.Kind.UNDERGROUND
	CellarWatch.steal()
	assert_int(SimLoop.treasury.amount(UnderWatch.HATCH_KEY)).is_equal(0)
	assert_int(SimLoop.treasury.carried_by(foe)).is_equal(3)
	SimLoop.load_world(SimLoop.world())
	assert_int(SimLoop.treasury.amount(UnderWatch.HATCH_KEY)).is_equal(0)


func test_new_services_preserve_twenty_four_pixels_between_every_ground_footprint() -> void:
	var seat := RealmLadder.seat(SimLoop.builds)
	for post in SimLoop.builds.slots:
		if post.kind not in [CompanionWatch.POST, CellarWatch.EXCAVATION]:
			continue
		for other in SimLoop.builds.slots:
			if other == post or other.band != post.band:
				continue
			var width := seat.widths[-1] if other == seat else other.width
			var gap := absf(post.x - other.x) - (post.width + width) * 0.5
			assert_float(gap).override_failure_message(String(other.kind)).is_greater_equal(24.0)


func test_the_cart_and_exposed_supplies_have_clear_ground_for_both_foundations() -> void:
	# Carroca de 72 px (ASSETS_TODO), carga com a caixa usada pelo proprio desenho.
	var half_widths := (72.0 + ArrivalView.SUPPLIES.size.x) / 2.0
	var cache := SimLoop.arrival.cache_x
	assert_float(absf(SimLoop.seat.cart_x - cache) - half_widths).is_greater_equal(24.0)
	for offset: float in LastCartWatch.CHOICES.values():
		var parked := SimLoop.arrival.origin + offset + LastCartWatch.CART_X
		assert_float(absf(parked - cache) - half_widths).is_greater_equal(24.0)


func test_excavation_needs_paid_work_on_site_and_respects_the_seat_stage() -> void:
	LastCartWatch.claim(&"road")
	RealmLadder.seat(SimLoop.builds).raise_to(1)
	SimLoop.builds.crew_owner = 1
	var excavation: BuildSlot
	for slot in SimLoop.builds.slots:
		if slot.kind == CellarWatch.EXCAVATION:
			excavation = slot
	(
		assert_bool(SimLoop.builds.can_climb(excavation, SimLoop.state, SimLoop.night.amargueiros))
		. is_false()
	)
	var builder := SimLoop.units.spawn(
		SimLoop.state, Registry.entry(&"units", &"builder"), 1, excavation.x + 100.0
	)
	(
		assert_bool(SimLoop.builds.can_climb(excavation, SimLoop.state, SimLoop.night.amargueiros))
		. is_true()
	)
	var under := SimLoop.field.under
	var hatch := under.find(SimLoop.core_x, INF)
	for k in under.count():
		if under.key_of(k) == UnderWatch.HATCH_KEY:
			hatch = k
	UnderWatch.enter(under.mouth_of(hatch), Band.PASSAGE_PX)
	var before := under.span(hatch)
	SimLoop.coins.drop(SimLoop.state, excavation.x, excavation.band, 3, 0.0)
	for c in SimLoop.coins.count():
		SimLoop.coins.settled[c] = 1
	SimLoop.builds.absorb(SimLoop.coins, SimLoop.state, SimLoop.night.amargueiros)
	SimLoop.builds.tick(8.0, SimLoop.units)
	assert_int(excavation.level).is_equal(0)
	SimLoop.units.xs[SimLoop.units.index_of(builder)] = excavation.x
	SimLoop.builds.tick(8.0, SimLoop.units)
	CellarWatch.sync()
	assert_int(excavation.level).is_equal(1)
	assert_float(under.span(hatch).y).is_greater(before.y)
	(
		assert_bool(SimLoop.builds.can_climb(excavation, SimLoop.state, SimLoop.night.amargueiros))
		. is_false()
	)
