# tests/unit_fsm_test.gd — a maquina de cinco estados, o fatiamento e o §63.
#
# Separado do unit_system_test porque a regra das 250 linhas do §28 tambem
# vale para os testes — e porque sao duas perguntas diferentes: uma e sobre
# como as tropas sao guardadas, a outra e sobre como decidem e quanto custam.
extends GdUnitTestSuite

const TROPAS := 300
const PASSO := 1.0 / 30.0

## §63: "UnitSystem (FSM) | 0,8 ms | Marcador dedicado". O orcamento e do Steam
## Deck; esta medicao corre onde correr, e por isso o teste guarda uma margem
## larga e o numero exato fica escrito no registo, para ser comparado la.
const ORCAMENTO_FSM_US := 800
const ORCAMENTO_MOVIMENTO_US := 1000


func _estado() -> GameState:
	var e := GameState.new()
	e.seed = 20260915
	return e


func _vagabundo() -> UnitData:
	return Registry.entry(&"units", &"vagrant")


func _povoar(sistema: UnitSystem, estado: GameState, quantos: int) -> void:
	var dados := _vagabundo()
	for i in quantos:
		var unit_id := sistema.spawn(estado, dados, 0, float(i))
		sistema.set_target_x(unit_id, float(i) + 1000.0)


# ─── O fatiamento ────────────────────────────────────────────────────────────


func test_so_um_sexto_decide_por_tick() -> void:
	# §52: u.id % 6 == s.tick % 6.
	var decidiram := 0
	for unit_id in range(1, 601):
		if UnitFsm.decides(unit_id, 0):
			decidiram += 1
	assert_int(decidiram).is_equal(600 / UnitFsm.AI_SLICE)


func test_em_seis_ticks_todas_decidem_exatamente_uma_vez() -> void:
	# O que faz o fatiamento ser fatiamento e nao esquecimento.
	for unit_id in range(1, 60):
		var vezes := 0
		for tick in UnitFsm.AI_SLICE:
			if UnitFsm.decides(unit_id, tick):
				vezes += 1
		var porque := "unidade %d decidiu %d vezes" % [unit_id, vezes]
		assert_int(vezes).override_failure_message(porque).is_equal(1)


# ─── A maquina de estados ────────────────────────────────────────────────────


func test_vida_a_zero_e_sempre_morte_venha_de_onde_vier() -> void:
	for estado in [UnitFsm.State.GOTO, UnitFsm.State.WORK, UnitFsm.State.FIGHT, UnitFsm.State.FLEE]:
		assert_int(UnitFsm.next(estado, 0, true, false)).is_equal(UnitFsm.State.DEAD)
		assert_int(UnitFsm.next(estado, -5, true, false)).is_equal(UnitFsm.State.DEAD)


func test_de_morto_nao_se_sai_por_decisao() -> void:
	# Ressuscitar e repor a vida, e isso e do ClassSystem — nao e uma transicao
	# que a FSM possa tomar sozinha.
	assert_int(UnitFsm.next(UnitFsm.State.DEAD, 10, true, true)).is_equal(UnitFsm.State.DEAD)


func test_com_alvo_longe_vai_com_alvo_perto_trabalha() -> void:
	assert_int(UnitFsm.next(UnitFsm.State.WORK, 10, true, false)).is_equal(UnitFsm.State.GOTO)
	assert_int(UnitFsm.next(UnitFsm.State.GOTO, 10, true, true)).is_equal(UnitFsm.State.WORK)
	assert_int(UnitFsm.next(UnitFsm.State.GOTO, 10, false, false)).is_equal(UnitFsm.State.WORK)


func test_a_unidade_anda_ate_ao_alvo_e_para_la_exatamente() -> void:
	var sistema := UnitSystem.new()
	var estado := _estado()
	var unit_id := sistema.spawn(estado, _vagabundo(), 0, 0.0)
	sistema.set_target_x(unit_id, 26.0)  # um segundo a velocidade de vagabundo
	var i := sistema.index_of(unit_id)

	for _t in 60:
		sistema.tick_movement(PASSO)

	# Aterra EXATAMENTE no alvo, e e por isso que a FSM nao precisa de
	# tolerancia nenhuma para saber que chegou.
	assert_float(sistema.xs[i]).is_equal(26.0)
	var chegou := is_equal_approx(sistema.xs[i], 26.0)
	assert_int(UnitFsm.next(UnitFsm.State.GOTO, 10, true, chegou)).is_equal(UnitFsm.State.WORK)


func test_a_morte_e_imediata_e_nao_espera_pela_fatia() -> void:
	# Uma unidade com vida a zero que continue a agir durante ate seis ticks e
	# o defeito que o §43 descreve. A morte nao e uma decisao.
	var sistema := UnitSystem.new()
	var estado := _estado()
	var unit_id := sistema.spawn(estado, _vagabundo(), 0, 0.0)
	var i := sistema.index_of(unit_id)
	# Um tick em que esta unidade NAO decide, de proposito.
	var tick := 0
	while UnitFsm.decides(unit_id, tick):
		tick += 1

	sistema.damage(unit_id, 999)
	var mudancas := sistema.tick_decisions(tick)

	assert_int(sistema.states[i]).is_equal(UnitFsm.State.DEAD)
	assert_int(mudancas.size()).is_equal(1)
	assert_int(mudancas[0][&"to"]).is_equal(UnitFsm.State.DEAD)
	# E nao volta a anunciar a morte em cada tick seguinte.
	assert_int(sistema.tick_decisions(tick + 1).size()).is_equal(0)


func test_um_morto_nao_anda() -> void:
	var sistema := UnitSystem.new()
	var estado := _estado()
	var unit_id := sistema.spawn(estado, _vagabundo(), 0, 0.0)
	sistema.set_target_x(unit_id, 500.0)
	sistema.damage(unit_id, 999)
	sistema.tick_decisions(0)

	var i := sistema.index_of(unit_id)
	assert_int(sistema.states[i]).is_equal(UnitFsm.State.DEAD)
	for _t in 30:
		sistema.tick_movement(PASSO)
	assert_float(sistema.xs[i]).is_equal(0.0)


# ─── O orcamento do §63 ──────────────────────────────────────────────────────


func test_trezentas_unidades_cabem_no_orcamento_da_passagem() -> void:
	var sistema := UnitSystem.new()
	var estado := _estado()
	_povoar(sistema, estado, TROPAS)
	assert_int(sistema.count()).is_equal(TROPAS)

	# Aquece: a primeira passagem paga alocacoes que as seguintes nao pagam.
	for t in UnitFsm.AI_SLICE:
		sistema.tick_decisions(t)
		sistema.tick_movement(PASSO)

	var voltas := 60
	var t0 := Time.get_ticks_usec()
	for t in voltas:
		sistema.tick_decisions(t)
	var fsm_us := float(Time.get_ticks_usec() - t0) / float(voltas)

	t0 = Time.get_ticks_usec()
	for _t in voltas:
		sistema.tick_movement(PASSO)
	var mov_us := float(Time.get_ticks_usec() - t0) / float(voltas)

	# O numero fica no registo do CI, que e onde serve de comparacao futura.
	prints(
		(
			"§63 com %d unidades: FSM %.1f us (orcamento %d) · movimento %.1f us (orcamento %d)"
			% [TROPAS, fsm_us, ORCAMENTO_FSM_US, mov_us, ORCAMENTO_MOVIMENTO_US]
		)
	)

	var porque_fsm := "FSM: %.1f us contra o orcamento de %d us" % [fsm_us, ORCAMENTO_FSM_US]
	assert_bool(fsm_us < ORCAMENTO_FSM_US).override_failure_message(porque_fsm).is_true()
	var porque_mov := "movimento: %.1f us contra %d us" % [mov_us, ORCAMENTO_MOVIMENTO_US]
	assert_bool(mov_us < ORCAMENTO_MOVIMENTO_US).override_failure_message(porque_mov).is_true()


func test_o_fatiamento_e_o_que_paga_o_orcamento() -> void:
	# Sem fatiar, a FSM custaria seis vezes mais. E o teste que justifica o
	# AI_SLICE existir, e o que a §63 manda mexer PRIMEIRO se o orcamento
	# estourar — antes de tocar em codigo.
	var sistema := UnitSystem.new()
	_povoar(sistema, _estado(), TROPAS)

	var decidem := 0
	for i in sistema.count():
		if UnitFsm.decides(sistema.ids[i], 0):
			decidem += 1

	assert_int(decidem).is_less_equal(TROPAS / UnitFsm.AI_SLICE + 1)
