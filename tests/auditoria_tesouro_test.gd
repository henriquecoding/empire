extends GdUnitTestSuite


func test_o_herdeiro_pronto_continua_pago_e_desaparece_sem_fundos() -> void:
	var units := UnitSystem.new()
	var state := GameState.new()
	var king := units.spawn(state, Registry.entry(&"units", &"monarch"), 1, 100.0)
	var builds := BuildSystem.new()
	var house := builds.post(WorldWorks.slot(Registry.entry(&"buildings", &"heir_house"), 100.0))
	house.raise_to(1)
	var heir := Succession.new(2, 5)
	units.carried_coins[0] = 15
	for day in 3:
		assert_int(heir.dawn(builds, units, king)).is_equal(5)
	assert_bool(heir.ready()).is_true()
	assert_int(heir.days).is_equal(2)
	assert_int(heir.dawn(builds, units, king)).is_equal(0)
	assert_bool(heir.ready()).is_false()
	assert_int(heir.days).is_equal(0)
	units.carried_coins[0] = 5
	assert_int(heir.dawn(builds, units, king)).is_equal(5)
	assert_bool(heir.ready()).is_false()


func test_o_tesouro_paga_na_ausencia_sem_tocar_na_bolsa() -> void:
	SimLoop.autosave_enabled = false
	SimLoop.start(20261007)
	Greybox.build()
	var units := SimLoop.units
	var king := units.index_of(SimLoop.king_id)
	var house := WorldWorks.post(&"heir_house", SimLoop.core_x)
	house.raise_to(1)
	units.carried_coins[king] = 9
	units.xs[king] += 20000.0
	SimLoop.treasury.deposit(UnderWatch.HATCH_KEY, 20)
	DawnWork.run(
		SimLoop.field,
		2,
		units,
		SimLoop.state,
		SimLoop.builds,
		SimLoop.economy,
		SimLoop.king_id,
		Vector2(SimLoop.core_x, SimLoop.world_width)
	)
	assert_int(units.carried_coins[king]).is_equal(9)
	assert_int(SimLoop.treasury.amount(UnderWatch.HATCH_KEY)).is_less(20)
	var saved := SimLoop.treasury.to_dict()
	SimLoop.treasury.from_dict(saved)
	SimLoop.treasury.from_dict(saved)
	assert_dict(SimLoop.treasury.to_dict()).is_equal(saved)
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func test_pagamento_local_e_extrato_conservam_moedas_e_limite() -> void:
	var treasury := Treasury.new()
	treasury.deposit("hatch", 7)
	assert_bool(treasury.pay("hatch", -1, &"heir", 2)).is_false()
	assert_bool(treasury.pay("hatch", 5, &"heir", 2)).is_true()
	assert_bool(treasury.pay("hatch", 5, &"heir", 2)).is_false()
	assert_int(treasury.amount("hatch")).is_equal(2)
	assert_int(treasury.payments[&"heir"][&"paid"]).is_equal(5)
	assert_int(treasury.payments[&"heir"][&"unpaid"]).is_equal(5)
	var copy := Treasury.new()
	copy.from_dict(treasury.to_dict())
	assert_dict(copy.to_dict()).is_equal(treasury.to_dict())
	assert_bool(copy.pay("hatch", 1, &"upkeep", 3)).is_true()
	assert_int(copy.payments.size()).is_equal(1)
