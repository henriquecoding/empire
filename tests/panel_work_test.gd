extends GdUnitTestSuite


func test_seat_dawn_repair_needs_a_builder_at_the_worksite() -> void:
	var builds := BuildSystem.new()
	var seat := builds.post(SeatSite.slot(100.0))
	seat.raise_to(1)
	builds.damage(seat.id, 10)
	var before := seat.health
	DawnRepair.plan(builds)
	assert_bool(seat.mending).is_true()
	var units := UnitSystem.new()
	var state := GameState.new()
	units.spawn(state, Registry.entry(&"units", &"vagrant"), 1, seat.x)
	builds.tick(5.0, units)
	assert_int(seat.health).is_equal(before)
	var builder := units.spawn(state, Registry.entry(&"units", &"builder"), 1, seat.x + 500.0)
	builds.tick(5.0, units)
	assert_int(seat.health).is_equal(before)
	units.xs[units.index_of(builder)] = seat.x
	builds.tick(5.0, units)
	assert_int(seat.health).is_equal(seat.max_health())


func test_resting_boosts_only_the_next_run_after_full_recovery() -> void:
	var stamina := Stamina.new()
	stamina.step(true, 30.0, 30.0, 3.0, 1.5)
	stamina.still = true
	stamina.step(false, 2.0, 30.0, 3.0, 1.5)
	assert_bool(stamina.rested).is_false()
	stamina.step(false, 1.0, 30.0, 3.0, 1.5)
	assert_bool(stamina.rested).is_true()
	assert_bool(stamina.step(true, 44.0, 30.0, 3.0, 1.5)).is_true()
	assert_float(stamina.left).is_equal(1.0)
	stamina.step(true, 1.0, 30.0, 3.0, 1.5)
	assert_bool(stamina.tired).is_true()
	stamina.still = false
	stamina.step(false, 3.0, 30.0, 3.0, 1.5)
	assert_bool(stamina.rested).is_false()
	stamina.step(true, 30.0, 30.0, 3.0, 1.5)
	assert_float(stamina.left).is_equal(0.0)


func test_reserved_worker_cannot_work_a_building_simultaneously() -> void:
	var jobs := SimFactory.job_board()
	var units := UnitSystem.new()
	var state := GameState.new()
	var worker := units.spawn(state, Registry.entry(&"units", &"vagrant"), 1, 0.0)
	jobs.post(JobSlot.new(&"farm", 0.0, Band.Kind.SURFACE))
	jobs.excluded = PackedInt32Array([worker])
	assert_bool(jobs.assign(units, GameClock.Phase.MORNING).has(worker)).is_false()
	jobs.excluded = PackedInt32Array()
	assert_bool(jobs.assign(units, GameClock.Phase.MORNING).has(worker)).is_true()


func test_resting_and_boosted_stamina_survive_save_and_report_the_real_ratio() -> void:
	var stamina := Stamina.new()
	stamina.step(true, 30.0, 30.0, 3.0, 1.5)
	stamina.still = true
	stamina.step(false, 3.0, 30.0, 3.0, 1.5)
	var restored := Stamina.new()
	restored.from_dict(stamina.to_dict())
	assert_bool(restored.rested).is_true()
	restored.step(true, 22.5, 30.0, 3.0, 1.5)
	assert_float(restored.ratio(30.0)).is_equal(0.5)
	stamina.from_dict(restored.to_dict())
	assert_float(stamina.left).is_equal(22.5)
	assert_float(stamina.boost).is_equal(1.5)
	stamina.from_dict({})
	assert_float(stamina.ratio(30.0)).is_equal(1.0)


func test_foreign_dawn_repair_is_paid_once_and_waits_for_the_local_builder() -> void:
	SimLoop.autosave_enabled = false
	SimLoop.start(20261004)
	Greybox.build()
	LastCartWatch.claim(&"road")
	var home := SimLoop.core_x + 2000.0
	var record := SimLoop.field.settlements.add(2, &"enramados", home, 30)
	var wall := WorldWorks.post(&"enramados_defense", home - 200.0, 2)
	wall.raise_to(1)
	record[&"sites"].append(wall.id)
	SimLoop.builds.damage(wall.id, 10)
	var before := wall.health
	var builder := SimLoop.units.spawn(
		SimLoop.state, Registry.entry(&"units", &"builder"), SettlementWatch.OWNER_BASE + 2, home
	)
	record[&"units"].append(builder)
	var rules := RulesFactory.rules()
	for _k in rules.realm_guard_count:
		record[&"units"].append(
			SimLoop.units.spawn(
				SimLoop.state,
				Registry.entry(&"units", &"archer"),
				SettlementWatch.OWNER_BASE + 2,
				home
			)
		)
	SimLoop.units.spawn(SimLoop.state, Registry.entry(&"units", &"builder"), 1, wall.x)
	SettlementWatch.plan(SimLoop.field)
	SettlementWatch.dawn(SimLoop.field)
	assert_int(wall.health).is_equal(before)
	assert_bool(wall.mending).is_true()
	var paid := SimLoop.field.settlements.treasury(2)
	SettlementWatch.dawn(SimLoop.field)
	assert_float(SimLoop.field.settlements.treasury(2)).is_equal_approx(
		paid - rules.realm_guard_count * rules.realm_guard_wage, 0.000001
	)
	SimLoop.builds.tick(5.0, SimLoop.units)
	assert_int(wall.health).is_equal(before)
	for _k in 1200:
		if not wall.mending:
			break
		SimLoop.step(1.0 / 30.0)
	assert_int(wall.health).is_equal(wall.max_health())
	assert_float(SimLoop.units.xs[SimLoop.units.index_of(builder)]).is_not_equal(home)
	SimLoop.stop()
	SimLoop.autosave_enabled = true
