extends GdUnitTestSuite


func test_seven_coins_train_one_recruited_worker_without_creating_a_person() -> void:
	var journey := CompanionJourney.new()
	assert_int(journey.pay(4, 7)).is_equal(4)
	assert_bool(journey.ready(7)).is_false()
	assert_int(journey.pay(8, 7)).is_equal(3)
	assert_bool(journey.ready(7)).is_true()
	assert_bool(journey.enroll(3, 7)).is_true()
	assert_bool(journey.enroll(4, 7)).is_false()
	var restored := CompanionJourney.new()
	restored.from_dict(journey.to_dict())
	assert_int(restored.worker).is_equal(3)
	restored.finish()
	assert_int(restored.paid).is_equal(0)
	assert_int(restored.worker).is_equal(-1)


func test_battle_growth_requires_both_people_and_a_new_defeated_foe() -> void:
	var journey := CompanionJourney.new()
	assert_bool(journey.victory(21, false)).is_false()
	assert_bool(journey.victory(21, true)).is_true()
	assert_bool(journey.victory(21, true)).is_false()
	assert_int(journey.battles.size()).is_equal(1)
	var restored := CompanionJourney.new()
	restored.from_dict(journey.to_dict())
	assert_bool(restored.victory(21, true)).is_false()
	assert_bool(restored.victory(22, true)).is_true()
