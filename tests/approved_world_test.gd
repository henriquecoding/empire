extends GdUnitTestSuite


func before_test() -> void:
	EventBus.reset()
	SimLoop.autosave_enabled = false
	SimLoop.start(20260930)
	Greybox.build()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func test_dynamic_house_foundation_survives_decay_and_rebuild() -> void:
	var slot := WorldWorks.post(&"citizen_house", -4000.0)
	slot.level = 1
	slot.state = BuildSlot.State.DONE
	slot.health = slot.max_health()
	var legacy := DecayWork.of()
	SimLoop.start(20260930)
	Greybox.build()
	DecayWork.restore(legacy)
	Legacy.apply(legacy, SimLoop.state, SimLoop.builds)
	var found: BuildSlot = null
	for s in SimLoop.builds.slots:
		if s.kind == &"citizen_house":
			found = s
	assert_object(found).is_not_null()
	assert_bool(found.foundation).is_true()
	assert_int(found.repair_cost()).is_equal(4)


func test_two_cuts_same_position_and_next_house_keep_their_ids() -> void:
	var woods := SimLoop.night.amargueiros
	for k in 2:
		var tree := woods.plant(-4000.0, Band.Kind.SURFACE, 1, 1, "")
		woods.slot_ids[tree] = SimLoop.builds.post(woods.saw(tree)).id
	var house := WorldWorks.post(&"citizen_house", -4500.0)
	var id := house.id
	house.paid = 2
	var saved := SimLoop.world()
	var count := SimLoop.builds.count()
	SimLoop.start(20260930)
	Greybox.region()
	SimLoop.load_world(saved)
	assert_int(SimLoop.builds.count()).is_equal(count)
	assert_str(String(SimLoop.builds.slots[id].kind)).is_equal("citizen_house")
	assert_int(SimLoop.builds.slots[id].paid).is_equal(2)


func test_new_map_keeps_deserted_extent_without_new_loot_or_recruits() -> void:
	var player := SimLoop.units.index_of(SimLoop.king_id)
	SimLoop.units.xs[player] = SimLoop.world_width + 10000.0
	Frontier.grow(SimLoop.field, SimLoop.units, SimLoop.king_id, SimLoop.world_width)
	var extent := SimLoop.field.wilds.extent(SimLoop.world_width)
	var legacy := DecayWork.of()
	SimLoop.start(20260930)
	Greybox.build()
	var coins := SimLoop.coins.count()
	var units := SimLoop.units.count()
	DecayWork.restore(legacy)
	assert_vector(SimLoop.field.wilds.extent(SimLoop.world_width)).is_equal(extent)
	assert_int(SimLoop.coins.count()).is_equal(coins)
	assert_int(SimLoop.units.count()).is_equal(units)


func test_class_travels_to_conquered_realm_king_stays_and_night_locks_travel() -> void:
	var kingdom := SimLoop.units.index_of(SimLoop.king_id)
	var home := SimLoop.units.xs[kingdom]
	var hero := SimLoop.units.spawn(
		SimLoop.state,
		Registry.entry(&"units", &"archer"),
		SimLoop.units.owners[kingdom],
		SimLoop.secrets.chapters[0]
	)
	SimLoop.units.pilot = hero
	var biome := StringName(SimLoop.state.chapters.regions[1])
	var people := StringName(RulesFactory.biome_peoples()[biome])
	SimLoop.field.realm.vassals.add(people, 4, 100.0, 1)
	assert_bool(TravelWatch.go(1)).is_true()
	assert_float(SimLoop.units.xs[kingdom]).is_equal(home)
	assert_bool(SimLoop.field.settlements.records.has(1)).is_true()
	ClockService.clock.elapsed = ClockService.clock.day_seconds() * 0.9
	assert_bool(TravelWatch.go(0)).is_false()
	ClockService.clock.elapsed = 0.0
	assert_bool(TravelWatch.go(0)).is_true()


func test_local_realm_has_own_workers_defenses_treasury_and_night_attack() -> void:
	Frontier.reveal(SimLoop.field, 1)
	var record: Dictionary = SimLoop.field.settlements.records[1]
	assert_int(record[&"sites"].size()).is_equal(4)
	assert_int(record[&"units"].size()).is_greater(4)
	var before := SimLoop.field.settlements.treasury(1)
	SettlementWatch.dawn(SimLoop.field)
	assert_float(SimLoop.field.settlements.treasury(1)).is_not_equal(before)
	var king := SimLoop.units.index_of(SimLoop.king_id)
	var purse := SimLoop.units.carried_coins[king]
	SimLoop.field.upkeep.dawn(SimLoop.units, SimLoop.king_id, SimLoop.economy, 2)
	assert_int(SimLoop.units.carried_coins[king]).is_equal(purse)
	SettlementWatch.night(SimLoop.field)
	assert_int(record[&"rifts"].size()).is_equal(1)
	var saved := SimLoop.world()
	var treasury := SimLoop.field.settlements.treasury(1)
	SimLoop.start(20260930)
	Greybox.region()
	SimLoop.load_world(saved)
	assert_float(SimLoop.field.settlements.treasury(1)).is_equal(treasury)
	assert_int(SimLoop.field.settlements.records[1][&"sites"].size()).is_equal(4)


func test_mercenary_camp_is_physically_abandoned_after_three_hires() -> void:
	Frontier.reveal(SimLoop.field, 1)
	var entry := SimLoop.field.wilds.at(WorldPlan.LESTE, 0)
	entry[WildSegments.TIPO] = WildSegments.MERCENARIOS
	SettlementWatch.author(SimLoop.field, WorldPlan.LESTE, 0, false)
	var id := SettlementWatch.CAMP_BASE + 1
	var record: Dictionary = SimLoop.field.settlements.records[id]
	var x := float(record[&"camp"])
	for k in 3:
		SimLoop.field.camp_life.hired(x)
	SettlementWatch.exhaust(SimLoop.field)
	assert_bool(record[&"deserted"]).is_true()
	for unit in record[&"units"]:
		assert_int(SimLoop.units.index_of(unit)).is_equal(-1)
	for site in record[&"sites"]:
		assert_bool(SimLoop.builds.slots[SimLoop.builds.index_of(site)].standing()).is_false()
	assert_bool(SimLoop.units.alive(SimLoop.units.index_of(SimLoop.king_id))).is_true()


func test_dungeon_guardian_survives_dawn_and_pays_when_defeated() -> void:
	Frontier.reveal(SimLoop.field, 1)
	var entry: Dictionary = {}
	var side := WorldPlan.LESTE
	var index := -1
	for k in SimLoop.field.wilds.count(side):
		if int(SimLoop.field.wilds.at(side, k).get(WildSegments.PASSAGEM, 0)) > 0:
			entry = SimLoop.field.wilds.at(side, k)
			index = k
	assert_int(index).is_greater_equal(0)
	entry[&"dungeon"] = {&"kind": &"guardian", &"coins": 18, &"bonus": 3}
	DungeonWatch.author(SimLoop.field, side, index, false)
	var guardian := int(entry[&"dungeon"][&"guardian"])
	SimLoop.creatures.dissolve(DungeonWatch.guardians(SimLoop.field))
	assert_int(SimLoop.creatures.index_of(guardian)).is_greater_equal(0)
	assert_int(SimLoop.creatures.coin_drops[SimLoop.creatures.index_of(guardian)]).is_equal(18)
	var saved := SimLoop.world()
	var count := SimLoop.creatures.count()
	SimLoop.start(20260930)
	Greybox.region()
	SimLoop.load_world(saved)
	assert_int(SimLoop.creatures.count()).is_equal(count)
	assert_int(SimLoop.creatures.index_of(guardian)).is_greater_equal(0)

	var i := SimLoop.creatures.index_of(guardian)
	var x := SimLoop.creatures.xs[i]
	SimLoop.creatures.healths[i] = 0.0
	var deaths := SimLoop.combat.resolve(
		SimLoop.units, SimLoop.creatures, SimLoop.builds, func() -> float: return 0.0
	)
	SimLoop._largar(EventRelay.combat(deaths))
	for coin in SimLoop.coins.count():
		SimLoop.coins.vxs[coin] = 0.0
	SimLoop.coins.tick(2.0)
	var collected := SimLoop.coins.collect(x, Band.Kind.UNDERGROUND, 11)
	assert_int(collected.size()).is_equal(11)
	assert_int(SimLoop.coins.collect(x, Band.Kind.UNDERGROUND, 11).size()).is_equal(7)
