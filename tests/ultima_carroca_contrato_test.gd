extends GdUnitTestSuite


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20261004)
	Greybox.build()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func test_a_chegada_tem_tres_vagabundos_e_nenhuma_companhia_gratis() -> void:
	var proximos := 0
	var companhia := 0
	for i in SimLoop.units.count():
		if SimLoop.units.data_ids[i] == &"vagrant":
			if absf(SimLoop.units.xs[i] - SimLoop.core_x) < 500.0:
				proximos += 1
		var dados := Registry.entry(&"units", SimLoop.units.data_ids[i]) as UnitData
		if dados.tags.has(&"follows_king"):
			companhia += 1
	assert_int(proximos).is_equal(3)
	assert_int(companhia).is_equal(0)


func test_a_carroca_nao_entrega_a_reserva_antes_do_estandarte() -> void:
	var rei := SimLoop.units.index_of(SimLoop.king_id)
	var antes := SimLoop.units.carried_coins[rei]
	SimLoop.units.xs[rei] = SimLoop.seat.cart_x
	FoundationWatch.collect()
	assert_int(SimLoop.units.carried_coins[rei]).is_equal(antes)


func test_o_herdeiro_so_abre_na_fortaleza() -> void:
	var sede := RealmLadder.seat(SimLoop.builds)
	var casa: BuildSlot
	for vaga in SimLoop.builds.slots:
		if vaga.kind == Succession.CASA:
			casa = vaga
	assert_int(RealmLadder.required(casa)).is_equal(sede.costs.size())


func test_o_folego_aprovado_e_de_trinta_e_cinquenta_segundos() -> void:
	var c := SimFactory.curve()
	assert_float(c.king_run_stamina_s).is_equal(30.0)
	assert_float(c.king_run_stamina_s * c.king_run_evolved_mult).is_equal_approx(50.0, 0.001)
