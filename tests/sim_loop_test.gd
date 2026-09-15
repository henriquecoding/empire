# tests/sim_loop_test.gd — a ordem do §43, e o dia a passar de facto.
#
# E o teste que separa "tem ficheiros" de "anda": corre um dia inteiro a 30 Hz,
# conta as fases por que passou, e confirma que o mesmo caminho pela mesma
# semente da o mesmo estado.
extends GdUnitTestSuite

const SEMENTE := 20260915
const FASES_POR_DIA := 6


func before_test() -> void:
	SimLoop.autosave_enabled = false
	# O start() ENFILEIRA day_started e dawn_broke; quem os entrega e o primeiro
	# tick (§43 passo 11). Um teste que arranque e nao corra passos deixa-os na
	# fila, e o teste seguinte recebia-os. No jogo isto nao acontece — o
	# _physics_process vem a seguir — mas entre testes tem de se limpar.
	EventBus.reset()
	for slot in SaveService.SLOTS:
		SaveService.delete_slot(slot)


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true
	for slot in SaveService.SLOTS:
		SaveService.delete_slot(slot)


## Corre n segundos de simulacao ao passo fixo, como o _physics_process faria.
func _correr(segundos: float) -> void:
	var passo := 1.0 / 30.0
	for _i in int(segundos / passo):
		SimLoop.step(passo)


func test_arrancar_poe_o_jogo_no_dia_1_ao_amanhecer() -> void:
	SimLoop.start(SEMENTE)

	assert_bool(SimLoop.running()).is_true()
	assert_int(SimLoop.state.day).is_equal(1)
	assert_int(SimLoop.state.seed).is_equal(SEMENTE)
	assert_int(ClockService.clock.current_phase()).is_equal(GameClock.Phase.DAWN)


func test_um_dia_inteiro_passa_pelas_seis_fases_e_vira() -> void:
	SimLoop.start(SEMENTE)
	var fases: Array[int] = []
	var dias: Array[int] = []
	var ouvir_fase := func(_de: int, para: int) -> void: fases.append(para)
	var ouvir_dia := func(dia: int) -> void: dias.append(dia)
	EventBus.phase_changed.connect(ouvir_fase)
	EventBus.day_started.connect(ouvir_dia)

	_correr(ClockService.clock.day_seconds())

	assert_int(fases.size()).is_equal(FASES_POR_DIA)
	assert_int(fases[-1]).is_equal(GameClock.Phase.DAWN)
	assert_array(dias).is_equal([1, 2])  # o 1 sai do start(), o 2 da viragem
	assert_int(SimLoop.state.day).is_equal(2)

	EventBus.phase_changed.disconnect(ouvir_fase)
	EventBus.day_started.disconnect(ouvir_dia)


func test_o_tick_conta_e_o_estado_espelha_o_relogio() -> void:
	SimLoop.start(SEMENTE)
	_correr(100.0)

	assert_int(SimLoop.state.tick).is_equal(int(100.0 * 30.0))
	assert_float(SimLoop.state.clock_elapsed).is_equal_approx(ClockService.clock.elapsed, 0.001)
	assert_int(SimLoop.state.day).is_equal(ClockService.clock.day)


func test_a_fila_de_eventos_fica_sempre_vazia_no_fim_do_tick() -> void:
	# §43 passo 11. Uma fila que nao volta a zero quer dizer que alguem se
	# esqueceu do flush — e os ouvintes passam a reagir um tick atrasados.
	SimLoop.start(SEMENTE)
	for _i in 100:
		SimLoop.step(1.0 / 30.0)
		assert_int(EventBus.pending()).is_equal(0)


func test_o_autosave_acontece_ao_amanhecer_e_nao_no_dia_um() -> void:
	SimLoop.autosave_enabled = true
	SimLoop.start(SEMENTE)

	# O amanhecer do dia 1 e o arranque: gravar ai seria gravar antes de ter
	# acontecido alguma coisa.
	assert_bool(SaveService.has_slot(0)).is_false()

	_correr(ClockService.clock.day_seconds())

	assert_bool(SaveService.has_slot(0)).is_true()
	assert_int(SaveService.restore(0).day).is_equal(2)


func test_retomar_um_save_continua_o_dia_e_a_sequencia() -> void:
	SimLoop.start(SEMENTE)
	_correr(200.0)
	var meio := SimLoop.state
	var fluxos := RngService.snapshot()
	var esperado: Array[int] = []
	for _i in 20:
		esperado.append(RngService.int_range(&"rot", 0, 1000))

	SimLoop.stop()
	SimLoop.resume(meio, fluxos)

	assert_int(ClockService.clock.day).is_equal(meio.day)
	assert_float(ClockService.clock.elapsed).is_equal_approx(meio.clock_elapsed, 0.001)
	var depois: Array[int] = []
	for _i in 20:
		depois.append(RngService.int_range(&"rot", 0, 1000))
	assert_array(depois).is_equal(esperado)


func test_a_mesma_semente_e_o_mesmo_numero_de_passos_dao_o_mesmo_estado() -> void:
	# A promessa do §21, no caminho todo: semente, relogio, tick e estado.
	SimLoop.start(SEMENTE)
	_correr(500.0)
	var primeira := SimLoop.state.to_dict()
	var fluxos_1 := RngService.snapshot()

	SimLoop.start(SEMENTE)
	_correr(500.0)

	assert_dict(SimLoop.state.to_dict()).is_equal(primeira)
	assert_dict(RngService.snapshot()).is_equal(fluxos_1)


func test_parado_nao_anda() -> void:
	SimLoop.start(SEMENTE)
	_correr(50.0)
	var tick := SimLoop.state.tick
	SimLoop.stop()

	# O _physics_process ignora; o step() continua a ser chamavel de proposito,
	# porque e assim que um teste corre um dia em milissegundos.
	assert_bool(SimLoop.running()).is_false()
	assert_int(SimLoop.state.tick).is_equal(tick)


func test_as_tropas_andam_pelo_ciclo_e_nao_por_alguem_as_empurrar() -> void:
	# Os passos 4 e 5 do §43 ligados: o SimLoop e que faz a FSM decidir e o
	# movimento acontecer. Sem isto, o UnitSystem era uma classe que ninguem
	# chamava — e o tipo de coisa de que so se da conta tarde.
	SimLoop.start(SEMENTE)
	var vagabundo: UnitData = Registry.entry(&"units", &"vagrant")
	var unit_id := SimLoop.units.spawn(SimLoop.state, vagabundo, 0, 0.0)
	SimLoop.units.set_target_x(unit_id, 130.0)
	var i := SimLoop.units.index_of(unit_id)

	var estados: Array[int] = []
	var ouvinte := func(quem: int, _de: int, para: int) -> void:
		if quem == unit_id:
			estados.append(para)
	EventBus.unit_state_changed.connect(ouvinte)

	_correr(10.0)  # 130 px a 26 px/s sao cinco segundos; dez chegam e sobram

	assert_float(SimLoop.units.xs[i]).is_equal(130.0)
	# Saiu a andar e acabou a trabalhar, e o EventBus soube das duas coisas.
	assert_array(estados).is_equal([UnitFsm.State.GOTO, UnitFsm.State.WORK])
	EventBus.unit_state_changed.disconnect(ouvinte)


func test_largar_uma_moeda_pelo_ciclo_e_determinista_e_anuncia_se() -> void:
	# O Verbo 1 (§61) inteiro, pelo caminho que o jogo usa: o SimLoop sorteia o
	# desvio do fluxo `economy`, o sistema puro faz a fisica, e o EventBus diz.
	SimLoop.start(SEMENTE)
	var largadas: Array[int] = []
	var ouvinte := func(_x: float, _faixa: int, quanto: int, _origem: StringName) -> void:
		largadas.append(quanto)
	EventBus.coin_dropped.connect(ouvinte)

	SimLoop.drop_coin(100.0, Band.Kind.SURFACE, 1, &"player")
	SimLoop.step(1.0 / 30.0)

	assert_array(largadas).is_equal([1])
	assert_int(SimLoop.coins.count()).is_equal(1)
	EventBus.coin_dropped.disconnect(ouvinte)

	# A mesma semente larga a moeda no mesmo sitio: o desvio sai de um fluxo
	# determinista, e onde a moeda cai afeta o jogo.
	_correr(2.0)
	var onde := SimLoop.coins.xs[0]

	SimLoop.start(SEMENTE)
	SimLoop.drop_coin(100.0, Band.Kind.SURFACE, 1, &"player")
	_correr(2.0)
	assert_float(SimLoop.coins.xs[0]).is_equal(onde)


func test_apanhar_uma_moeda_pelo_ciclo_conta_o_que_apanhou() -> void:
	SimLoop.start(SEMENTE)
	var vagabundo: UnitData = Registry.entry(&"units", &"vagrant")
	SimLoop.drop_coin(0.0, Band.Kind.SURFACE, 1, &"player")
	_correr(2.0)  # deixa assentar

	var apanhado: Array[int] = []
	var ouvinte := func(_quem: int, quanto: int) -> void: apanhado.append(quanto)
	EventBus.coin_collected.connect(ouvinte)

	var x := SimLoop.coins.xs[0]
	var total := SimLoop.collect_coins(7, x, Band.Kind.SURFACE, vagabundo.coin_capacity)
	SimLoop.step(1.0 / 30.0)

	assert_int(total).is_equal(1)
	assert_array(apanhado).is_equal([1])
	assert_int(SimLoop.coins.count()).is_equal(0)
	EventBus.coin_collected.disconnect(ouvinte)
