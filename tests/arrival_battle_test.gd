extends GdUnitTestSuite


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func test_every_monarch_and_paid_companion_evolve_only_after_distinct_shared_battles() -> void:
	SimLoop.autosave_enabled = false
	for profile in Registry.ids(&"monarchs"):
		EventBus.reset()
		SimLoop.start(20261004)
		Greybox.build()
		MonarchWatch.begin(profile)
		LastCartWatch.claim(&"road")
		RealmLadder.seat(SimLoop.builds).raise_to(1)
		FoundationWatch.founded_tools()
		var u := SimLoop.units
		u.owners[1] = u.owners[0]
		var post := CompanionWatch.site()
		var drop := {EventRelay.ONDE: post.x, EventRelay.FAIXA: post.band, EventRelay.QUANTO: 7}
		assert_bool(CompanionWatch.pay(drop)).is_true()
		u.xs[1] = post.x
		CompanionWatch.plan()
		var c := SimLoop.field.monarchy.companion_index(u, SimLoop.king_id)
		var health := u.max_healths[c]
		u.xs[c] = u.xs[0] + 500.0
		var converted := _kill()
		SimLoop.field.song.allies[int(converted[CombatSystem.DE])] = {}
		u.xs[c] = u.xs[0]
		CompanionWatch.battles([converted])
		assert_int(SimLoop.companion.battles.size()).is_equal(0)
		u.xs[c] = u.xs[0] + 500.0
		var first := _kill()
		CompanionWatch.battles([first])
		assert_bool(MonarchWatch.evolved(SimLoop.field)).is_false()
		u.xs[c] = u.xs[0]
		CompanionWatch.battles([first, first])
		assert_int(SimLoop.companion.battles.size()).is_equal(1)
		for _k in LastCartWatch.rules().battle_evolve_count - 1:
			CompanionWatch.battles([_kill()])
		assert_bool(MonarchWatch.evolved(SimLoop.field)).is_true()
		assert_int(u.max_healths[c]).is_greater(health)
		SimLoop.load_world(SimLoop.world())
		assert_bool(MonarchWatch.evolved(SimLoop.field)).is_true()
		assert_int(u.max_healths[c]).is_greater(health)
		assert_int(SimLoop.companion.battles.size()).is_equal(
			LastCartWatch.rules().battle_evolve_count
		)


func _kill() -> Dictionary:
	var foe := SimLoop.creatures.spawn(
		SimLoop.state,
		Registry.entry(&"creatures", &"crawler"),
		SimLoop.units.xs[0] + 20.0,
		SimLoop.core_x
	)
	return {
		CombatSystem.CHAVE: CombatSystem.EV_MORTE, CombatSystem.DE: foe, CombatSystem.CRIATURA: true
	}


func test_seat_health_and_defense_increase_with_real_stages() -> void:
	var seat := SeatSite.slot(0.0)
	var previous_damage := 100
	var previous_health := 0
	for level in range(1, seat.costs.size() + 1):
		seat.raise_to(level)
		assert_int(seat.max_health()).is_greater(previous_health)
		assert_int(seat.soak(100, 0.0)).is_less(previous_damage)
		previous_health = seat.max_health()
		previous_damage = seat.soak(100, 0.0)


func test_tower_preview_uses_the_same_range_before_and_after_building_and_variant() -> void:
	var tower := Greybox.slot_of(Registry.entry(&"buildings", &"archer_tower"), 0.0)
	var before := TowerPreview.range_of(tower)
	tower.raise_to(1)
	assert_float(TowerPreview.range_of(tower)).is_equal(before)
	tower.variant = 1
	assert_float(TowerPreview.range_of(tower)).is_less(before)
