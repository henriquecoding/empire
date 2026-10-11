extends GdUnitTestSuite


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20261007)
	Greybox.build()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func test_explorar_o_dia_um_nao_cria_sociedades_organizadas() -> void:
	var u := SimLoop.units
	u.xs[u.index_of(SimLoop.king_id)] = SimLoop.world_width + 22000.0
	Frontier.grow(SimLoop.field, u, SimLoop.king_id, SimLoop.world_width)
	assert_int(SimLoop.state.day).is_equal(1)
	assert_bool(SimLoop.builds.foundation_committed).is_false()
	assert_dict(SimLoop.field.settlements.records).is_empty()


func test_nasce_na_alvorada_seguinte_e_persiste_sem_depender_de_visitas() -> void:
	var field := SimLoop.field
	SocialWatch.awaken(field, 1)
	assert_dict(field.settlements.records).is_empty()
	SimLoop.builds.foundation_committed = true
	SettlementWatch.night(field)
	SocialWatch.awaken(field, 1)
	assert_dict(field.settlements.records).is_empty()
	SocialWatch.awaken(field, 2)
	assert_int(field.settlements.awake_day).is_equal(2)
	assert_int(field.settlements.records.size()).is_greater(0)
	var snapshot := field.settlements.to_dict()
	for record: Dictionary in field.settlements.records.values():
		assert_int(record[&"born_day"]).is_equal(2)
		for site in record[&"sites"]:
			assert_int(SimLoop.builds.slots[SimLoop.builds.index_of(site)].level).is_zero()
	var saved := SimLoop.world()
	for reload in 2:
		SimLoop.load_world(saved)
		assert_dict(SimLoop.field.settlements.to_dict()).is_equal(snapshot)
		SocialWatch.awaken(SimLoop.field, 3)
		assert_dict(SimLoop.field.settlements.to_dict()).is_equal(snapshot)


func test_ordem_de_exploracao_nao_altera_sociedades_ou_o_rng() -> void:
	var first := _born_after_visit(22000.0)
	before_test()
	var second := _born_after_visit(-22000.0)
	assert_dict(first).is_equal(second)


func _born_after_visit(x: float) -> Dictionary:
	var u := SimLoop.units
	u.xs[u.index_of(SimLoop.king_id)] = x
	Frontier.grow(SimLoop.field, u, SimLoop.king_id, SimLoop.world_width)
	SimLoop.field.settlements.first_night_day = 1
	var rng := RngService.snapshot()
	SocialWatch.awaken(SimLoop.field, 2)
	assert_dict(RngService.snapshot()).is_equal(rng)
	var result := SimLoop.field.settlements.to_dict()
	for record: Dictionary in result[&"records"].values():
		record.erase(&"units")
		record.erase(&"sites")
	return result


func test_sociedade_paga_e_constroi_com_trabalho_sem_o_rei_visitar() -> void:
	SimLoop.field.settlements.first_night_day = 1
	SocialWatch.awaken(SimLoop.field, 2)
	SettlementWatch.dawn(SimLoop.field)
	var record: Dictionary = SimLoop.field.settlements.records[1]
	var house := SimLoop.builds.slots[SimLoop.builds.index_of(record[&"sites"][0])]
	assert_bool(house.standing()).is_false()
	assert_float(SimLoop.field.settlements.treasury(1)).is_less(
		float(RulesFactory.rules().realm_start_coins)
	)
	for tick in 900:
		SimLoop.step(1.0 / 30.0)
	assert_bool(house.standing()).is_true()
	assert_int(house.level).is_equal(1)
