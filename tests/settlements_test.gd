extends GdUnitTestSuite


func test_local_treasuries_are_independent_and_persist() -> void:
	var realms := Settlements.new()
	realms.add(1, &"geada", 4000.0, 30)
	realms.add(2, &"bruma", 8000.0, 30)
	assert_bool(realms.spend(1, 10.0)).is_true()
	realms.earn(2, 4.0)
	assert_float(realms.treasury(1)).is_equal(20.0)
	assert_bool(realms.spend(1, 99.0)).is_false()
	var copy := Settlements.new()
	copy.from_dict(realms.to_dict())
	assert_float(copy.treasury(2)).is_equal(34.0)
