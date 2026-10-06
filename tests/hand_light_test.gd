# tests/hand_light_test.gd — a tocha da mao, quando ha pouca luz (UX-07).
extends GdUnitTestSuite


func test_burns_at_dawn_dusk_and_night_but_not_by_day() -> void:
	var clock := load("res://data/economy/clock.tres") as ClockData
	var escuro := func(fase: GameClock.Phase, progresso: float) -> float:
		return Lighting.darkness(clock, BandLight.seen(clock, fase, progresso))
	assert_bool(HandLight.carried(escuro.call(GameClock.Phase.DAWN, 0.0), false)).is_true()
	assert_bool(HandLight.carried(escuro.call(GameClock.Phase.DUSK, 0.5), false)).is_true()
	assert_bool(HandLight.carried(escuro.call(GameClock.Phase.NIGHT, 0.5), false)).is_true()
	assert_bool(HandLight.carried(escuro.call(GameClock.Phase.NOON, 0.5), false)).is_false()
	assert_bool(HandLight.carried(escuro.call(GameClock.Phase.MORNING, 0.5), false)).is_false()


func test_the_bought_torch_takes_its_place() -> void:
	assert_bool(HandLight.carried(1.0, true)).is_false()


func test_gives_less_light_than_the_bought_torch() -> void:
	assert_float(HandLight.LUZ.raio).is_less(1.0)
	assert_float(HandLight.LUZ.forca).is_less(WorldLight.MEIA)
