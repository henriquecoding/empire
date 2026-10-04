extends GdUnitTestSuite


func test_claim_is_once_and_does_not_mint_reserves() -> void:
	var cart := LastCart.new()
	cart.begin(1920.0, 852.0, 3)
	assert_bool(cart.claim(&"grove", -256.0)).is_true()
	assert_bool(cart.claim(&"road", 0.0)).is_false()
	assert_int(cart.cache_coins).is_equal(3)
	cart.record(&"foundation_choice_committed", &"road")
	assert_str(String(cart.events[&"foundation_choice_committed"][&"value"])).is_equal("grove")


func test_switching_work_starts_a_new_physical_task() -> void:
	var cart := LastCart.new()
	cart.assign(3, LastCart.FORAGE)
	assert_bool(cart.work(4.0, 8.0)).is_false()
	cart.assign(3, LastCart.SCOUT)
	assert_float(cart.progress).is_equal(0.0)
	assert_bool(cart.work(8.0, 8.0)).is_true()
	cart.assign(LastCart.NONE, &"")
	assert_bool(cart.work(8.0, 8.0)).is_false()


func test_consequence_and_telemetry_survive_save_without_replaying() -> void:
	var cart := LastCart.new()
	cart.begin(1920.0, 852.0, 3)
	cart.claim(&"road", 0.0)
	cart.assign(3, LastCart.RESCUE)
	cart.seconds = 60.0
	assert_int(cart.spoil()).is_equal(3)
	var restored := LastCart.new()
	restored.from_dict(cart.to_dict())
	assert_bool(restored.scar).is_true()
	assert_int(restored.spoil()).is_equal(0)
	assert_int(restored.worker).is_equal(3)
	assert_float(restored.seconds).is_equal(60.0)
	assert_str(String(restored.choice)).is_equal("road")
	assert_int(restored.events.size()).is_equal(cart.events.size())


func test_old_save_has_no_prologue_and_no_free_cache() -> void:
	var cart := LastCart.new()
	cart.from_dict({})
	assert_bool(cart.active).is_false()
	assert_int(cart.cache_coins).is_equal(0)
