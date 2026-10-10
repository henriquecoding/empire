extends GdUnitTestSuite

const Sede := preload("res://tests/support/sede.gd")


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func test_tres_imperadores_contratam_diplomata_sem_conquista_ou_semente() -> void:
	for profile in [&"monarch", &"archer_emperor", &"nia"]:
		SimLoop.autosave_enabled = false
		SimLoop.start(20261007)
		Greybox.build()
		MonarchWatch.begin(profile)
		Sede.erguer(1)
		FoundationWatch.founded_tools()
		var desk: BuildSlot
		for slot in SimLoop.builds.slots:
			if slot.kind == &"emissary_stand":
				desk = slot
		assert_object(desk).is_not_null()
		if desk == null:
			return
		assert_bool(desk.standing()).is_true()
		assert_bool(SimLoop.state.conquests.is_empty()).is_true()
		SimLoop.state.royal_seeds = 0
		var u := SimLoop.units
		var owner := u.owners[u.index_of(SimLoop.king_id)]
		var person := u.spawn(SimLoop.state, Registry.entry(&"units", &"vagrant"), owner, desk.x)
		var craft := Registry.entry(&"units", &"diplomat") as UnitData
		var coin := SimLoop.coins.drop(SimLoop.state, desk.x, desk.band, craft.recruit_cost, 0.0)
		SimLoop.coins.targets[SimLoop.coins.index_of(coin)] = desk.id
		SimLoop.coins.settled[SimLoop.coins.index_of(coin)] = 1
		SimLoop.field.training.absorb(SimLoop.coins, SimLoop.builds, u)
		SimLoop.field.training.tick(1.0, u, SimLoop.builds, ClockService.clock.day_seconds())
		assert_str(String(u.data_ids[u.index_of(person)])).is_equal("diplomat")
		assert_int(SimLoop.state.royal_seeds).is_zero()
		assert_int(u.pilot).is_equal(UnitSystem.NENHUM)
		var count := SimLoop.builds.count()
		var saved := SimLoop.world()
		for reload in 2:
			SimLoop.load_world(saved)
			assert_int(SimLoop.builds.count()).is_equal(count)
