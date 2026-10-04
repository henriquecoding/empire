extends GdUnitTestSuite


func test_wealth_alone_does_not_satisfy_settlement_maturity() -> void:
	var stage := RealmStageData.new()
	stage.maturity = [&"night", &"income", &"walls"]
	var facts := {&"night": false, &"income": true, &"walls": false}
	assert_str(String(RealmMaturity.missing(stage, facts))).is_equal("night")
	facts[&"night"] = true
	assert_str(String(RealmMaturity.missing(stage, facts))).is_equal("walls")
	facts[&"walls"] = true
	assert_str(String(RealmMaturity.missing(stage, facts))).is_empty()


func test_unconfigured_stage_keeps_legacy_progression() -> void:
	assert_str(String(RealmMaturity.missing(RealmStageData.new(), {}))).is_empty()
