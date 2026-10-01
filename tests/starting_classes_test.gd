extends GdUnitTestSuite


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20261001)
	Greybox.build()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func test_o_arqueiro_escolhido_nasce_jogavel_sem_substituir_o_rei() -> void:
	var roster := SimLoop.field.roster
	var hero: int = roster.call("begin", SimLoop.units, SimLoop.state, SimLoop.king_id, &"archer")
	assert_int(hero).is_not_equal(UnitSystem.NENHUM)
	assert_int(Assume.driven()).is_equal(hero)
	assert_str(String(SimLoop.units.data_ids[SimLoop.units.index_of(hero)])).is_equal("archer_hero")
	assert_str(String(SimLoop.units.data_ids[SimLoop.units.index_of(SimLoop.king_id)])).is_equal(
		"monarch"
	)
	assert_int(SimLoop.units.carried_coins[SimLoop.units.index_of(SimLoop.king_id)]).is_greater(0)


func test_o_bardo_escolhido_nasce_ao_pe_do_rei_e_pode_voltar_a_ele() -> void:
	var roster := SimLoop.field.roster
	var hero: int = roster.call("begin", SimLoop.units, SimLoop.state, SimLoop.king_id, &"bard")
	assert_int(hero).is_not_equal(UnitSystem.NENHUM)
	assert_str(String(SimLoop.units.data_ids[SimLoop.units.index_of(hero)])).is_equal("bard_hero")
	assert_bool(roster.back(SimLoop.units, SimLoop.king_id, Assume.reach())).is_true()
	assert_int(Assume.driven()).is_equal(SimLoop.king_id)


func test_monarca_e_classe_invalida_nao_criam_corpo_extra() -> void:
	var antes := SimLoop.units.count()
	var roster := SimLoop.field.roster
	var hero: int = roster.call("begin", SimLoop.units, SimLoop.state, SimLoop.king_id, &"monarch")
	assert_int(hero).is_equal(SimLoop.king_id)
	assert_int(SimLoop.units.count()).is_equal(antes)
	var invalid: int = roster.call(
		"begin", SimLoop.units, SimLoop.state, SimLoop.king_id, &"diplomat"
	)
	assert_int(invalid).is_equal(UnitSystem.NENHUM)
	assert_int(SimLoop.units.count()).is_equal(antes)


func test_escolha_inicial_persiste_no_save_e_nao_duplica_o_corpo() -> void:
	var roster := SimLoop.field.roster
	var first: int = roster.call("begin", SimLoop.units, SimLoop.state, SimLoop.king_id, &"bard")
	var count := SimLoop.units.count()
	var second: int = roster.call("begin", SimLoop.units, SimLoop.state, SimLoop.king_id, &"bard")
	assert_int(second).is_equal(first)
	assert_int(SimLoop.units.count()).is_equal(count)
	var world := SimLoop.world()
	SimLoop.load_world(world)
	assert_str(String(SimLoop.field.roster.get("starting_class"))).is_equal("bard")
	assert_int(Assume.driven()).is_equal(first)
