extends GdUnitTestSuite

const STEP := 1.0 / 30.0


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20261004)
	SimLoop.king_id = SimLoop.units.spawn(
		SimLoop.state, Registry.entry(&"units", &"monarch"), 1, 500.0
	)


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _vagrant(x: float) -> int:
	return SimLoop.units.spawn(SimLoop.state, Registry.entry(&"units", &"vagrant"), 0, x)


func _coin(x: float) -> int:
	var id := SimLoop.drop_coin(x, Band.Kind.SURFACE, 1, Verbs.JOGADOR)
	SimLoop.coins.settled[SimLoop.coins.index_of(id)] = 1
	return id


func _decide(id: int) -> void:
	SimLoop.recruits.seek_coins(SimLoop.units, SimLoop.coins, id)


func test_o_vagabundo_corre_mais_depressa_que_o_passo_normal() -> void:
	var id := _vagrant(100.0)
	_coin(0.0)
	SimLoop.state.tick = id - 1
	var i := SimLoop.units.index_of(id)
	var speed := SimLoop.units.speeds[i]
	SimLoop.step(STEP)
	assert_float(100.0 - SimLoop.units.xs[i]).is_greater(speed * STEP)
	assert_float(SimLoop.units.speeds[i]).is_equal(speed)


func test_a_moeda_exatamente_no_limite_do_raio_tambem_chama() -> void:
	var id := _vagrant(SimFactory.curve().recruit_notice_px)
	var coin := _coin(0.0)
	_decide(id)
	assert_int(SimLoop.units.target_ids[SimLoop.units.index_of(id)]).is_equal(coin)


func test_a_moeda_de_uma_obra_nao_chama_vagabundos() -> void:
	var id := _vagrant(40.0)
	var coin := _coin(0.0)
	SimLoop.coins.targets[SimLoop.coins.index_of(coin)] = 7
	_decide(id)
	assert_int(SimLoop.units.has_targets[SimLoop.units.index_of(id)]).is_equal(0)


func test_a_corrida_para_quando_outro_apanha_a_moeda() -> void:
	var id := _vagrant(100.0)
	var coin := _coin(0.0)
	_decide(id)
	SimLoop.coins.remove(coin)
	SimLoop.recruits.seek_coins(SimLoop.units, SimLoop.coins, id + 1)
	var i := SimLoop.units.index_of(id)
	assert_int(SimLoop.units.target_ids[i]).is_equal(UnitSystem.NENHUM)
	assert_int(SimLoop.units.has_targets[i]).is_equal(0)


func test_a_moeda_no_ar_ou_noutra_faixa_nao_chama() -> void:
	var id := _vagrant(40.0)
	var coin := _coin(0.0)
	var c := SimLoop.coins.index_of(coin)
	SimLoop.coins.settled[c] = 0
	_decide(id)
	assert_int(SimLoop.units.has_targets[SimLoop.units.index_of(id)]).is_equal(0)
	SimLoop.coins.settled[c] = 1
	SimLoop.coins.bands[c] = int(Band.Kind.UNDERGROUND)
	_decide(id)
	assert_int(SimLoop.units.has_targets[SimLoop.units.index_of(id)]).is_equal(0)


func test_dois_vagabundos_so_contratam_um_com_a_mesma_moeda() -> void:
	var first := _vagrant(40.0)
	var second := _vagrant(50.0)
	_coin(0.0)
	for _tick in 60:
		SimLoop.step(STEP)
	var hired := 0
	for id in [first, second]:
		hired += 1 if SimLoop.units.owners[SimLoop.units.index_of(id)] == 1 else 0
	assert_int(hired).is_equal(1)
	assert_int(SimLoop.coins.count()).is_equal(0)
