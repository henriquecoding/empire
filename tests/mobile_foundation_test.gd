extends GdUnitTestSuite


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20261005)
	Greybox.build()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func test_caravan_follows_in_both_directions_without_making_professions() -> void:
	var o := SimLoop.arrival
	var u := SimLoop.units
	var king := u.index_of(SimLoop.king_id)
	var count := u.count()
	assert_int(o.citizens.size()).is_equal(3)
	u.set_target_x(SimLoop.king_id, u.xs[king] + 400.0)
	var before := SimLoop.seat.cart_x
	for tick in 60:
		SimLoop.step(1.0 / 30.0)
	assert_float(SimLoop.seat.cart_x).is_greater(before)
	for id in o.citizens:
		assert_str(String(u.data_ids[u.index_of(id)])).is_equal("vagrant")
	u.set_target_x(SimLoop.king_id, u.xs[king] - 1000.0)
	for tick in 300:
		SimLoop.step(1.0 / 30.0)
	assert_float(SimLoop.seat.cart_x).is_less(before)
	assert_int(u.count()).is_equal(count)
	assert_bool(FoundationChoice.ready()).is_false()


func test_priority_interaction_and_motion_block_foundation() -> void:
	var u := SimLoop.units
	var king := u.index_of(SimLoop.king_id)
	u.xs[king] = SimLoop.arrival.cache_x
	u.clear_target(SimLoop.king_id)
	SimLoop.step(1.0)
	assert_bool(FoundationChoice.ready()).is_false()
	assert_bool(FoundationChoice.claim(u.xs[king])).is_false()
	u.xs[king] = SimLoop.arrival.origin + 83.0
	u.set_target_x(SimLoop.king_id, u.xs[king] + 100.0)
	assert_bool(FoundationChoice.ready()).is_false()


func test_free_foundation_revalidates_is_once_and_preserves_protected_terrain() -> void:
	assert_int(RealmLadder.seat(SimLoop.builds).costs[0]).is_equal(0)
	var u := SimLoop.units
	var king := u.index_of(SimLoop.king_id)
	var x := SimLoop.arrival.origin - 83.0
	u.xs[king] = x
	u.clear_target(SimLoop.king_id)
	SimLoop.step(1.0)
	var passages := SimLoop.passages.duplicate()
	var secrets := SimLoop.secrets.xs.duplicate()
	var money := SimLoop.seat.cart_coins + SimLoop.arrival.cache_coins
	assert_bool(FoundationChoice.claim(x + 1.0)).is_false()
	assert_bool(FoundationChoice.claim(x)).is_true()
	assert_bool(FoundationChoice.claim(x)).is_false()
	assert_float(SimLoop.core_x).is_equal(x)
	assert_array(SimLoop.passages).is_equal(passages)
	assert_array(SimLoop.secrets.xs).is_equal(secrets)
	assert_int(SimLoop.seat.cart_coins + SimLoop.arrival.cache_coins).is_equal(money)
	for id in SimLoop.arrival.citizens:
		assert_int(u.owners[u.index_of(id)]).is_equal(u.owners[king])
	var saved := SimLoop.world()
	var signature := SimLoop.arrival.site_signature.duplicate(true)
	for reload in 2:
		SimLoop.resume(SimLoop.state, RngService.snapshot())
		Greybox.region()
		SimLoop.load_world(saved)
	assert_float(SimLoop.core_x).is_equal(x)
	assert_dict(SimLoop.arrival.site_signature).is_equal(signature)
	assert_array(SimLoop.arrival.clear_manifest).has_size(1)
	assert_array(SimLoop.passages).is_equal(passages)


func test_v10_migration_keeps_reserves_and_never_clears_an_old_realm() -> void:
	var old := {&"save_version": 10, &"world": SimLoop.world()}
	old[&"world"][&"arrival"][&"choice"] = &"grove"
	old[&"world"][&"arrival"].erase(&"site_signature")
	old[&"world"][&"arrival"].erase(&"clear_manifest")
	var saved := SaveMigrations.migrate(old)
	assert_array(saved[&"world"][&"arrival"][&"clear_manifest"]).is_empty()
	assert_str(String(saved[&"world"][&"arrival"][&"site_signature"][&"provenance"])).is_equal(
		"LEGACY_INFERRED"
	)
	assert_int(saved[&"world"][&"seat"][&"cart_coins"]).is_equal(SimLoop.seat.cart_coins)
	assert_int(old[&"save_version"]).is_equal(10)
