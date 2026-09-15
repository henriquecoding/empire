# tests/game_clock_test.gd — os cinco testes do prompt 1 da §29, e a fronteira.
#
# Os numeros estao escritos no proprio prompt, calculados a mao: (75-15)/85 =
# 0,706 e 15+85+40+85+30 = 255. Dar o numero calculado ao agente e o que impede
# uma implementacao que passa nos testes por acidente (§29).
extends GdUnitTestSuite

const CLOCK_DATA := "res://data/economy/clock.tres"
const TOLERANCIA := 0.0005


func _relogio() -> GameClock:
	return GameClock.new(load(CLOCK_DATA) as ClockData)


func test_um_tick_de_360_avanca_exatamente_um_dia() -> void:
	var relogio := _relogio()
	var eventos := relogio.tick(relogio.day_seconds())

	assert_int(relogio.day).is_equal(2)
	assert_float(relogio.elapsed).is_equal_approx(0.0, TOLERANCIA)
	assert_int(eventos.size()).is_equal(1)
	assert_str(eventos[0][GameClock.EVENTO]).is_equal(GameClock.EVENTO_DIA)
	assert_int(eventos[0][GameClock.CAMPO_DIA]).is_equal(2)
	# Comeca e acaba em DAWN, por isso NAO ha transicao de fase neste passo.
	assert_int(relogio.current_phase()).is_equal(GameClock.Phase.DAWN)


func test_aos_75_segundos_a_fase_e_morning_e_o_progresso_e_0706() -> void:
	var relogio := _relogio()
	relogio.tick(75.0)

	assert_int(relogio.current_phase()).is_equal(GameClock.Phase.MORNING)
	assert_float(relogio.phase_progress()).is_equal_approx((75.0 - 15.0) / 85.0, TOLERANCIA)


func test_aos_15_exatos_ja_e_morning_a_fronteira_e_fechada_a_esquerda() -> void:
	var relogio := _relogio()
	relogio.tick(15.0)

	# Se fosse <=, o instante 15,0 pertencia a DAWN e a MORNING ao mesmo tempo.
	assert_int(relogio.current_phase()).is_equal(GameClock.Phase.MORNING)
	assert_float(relogio.phase_progress()).is_equal_approx(0.0, TOLERANCIA)


func test_seconds_until_night_no_instante_zero_e_255() -> void:
	var relogio := _relogio()
	# 15 + 85 + 40 + 85 + 30 = 255 (§29)
	assert_float(relogio.seconds_until(GameClock.Phase.NIGHT)).is_equal_approx(255.0, TOLERANCIA)


func test_mudar_o_dia_para_180_mantem_as_proporcoes() -> void:
	var relogio := _relogio()
	var antes := relogio.phase_duration(GameClock.Phase.MORNING) / relogio.day_seconds()

	relogio.set_day_seconds(180.0)

	assert_float(relogio.day_seconds()).is_equal_approx(180.0, TOLERANCIA)
	var depois := relogio.phase_duration(GameClock.Phase.MORNING) / relogio.day_seconds()
	assert_float(depois).is_equal_approx(antes, TOLERANCIA)
	# A noite continua a ser a fase mais longa, e o dia continua a somar certo.
	assert_float(relogio.phase_duration(GameClock.Phase.DAWN)).is_equal_approx(7.5, TOLERANCIA)
	assert_float(relogio.seconds_until(GameClock.Phase.NIGHT)).is_equal_approx(127.5, TOLERANCIA)


func test_mudar_o_dia_a_meio_nao_faz_a_fase_saltar() -> void:
	var relogio := _relogio()
	relogio.tick(75.0)
	var progresso := relogio.phase_progress()

	relogio.set_day_seconds(540.0)

	assert_int(relogio.current_phase()).is_equal(GameClock.Phase.MORNING)
	assert_float(relogio.phase_progress()).is_equal_approx(progresso, TOLERANCIA)


func test_as_seis_fases_saem_por_ordem_e_o_dia_vira_no_fim() -> void:
	var relogio := _relogio()
	var vistas: Array[int] = []
	var dias: Array[int] = []
	# 1/30 s, o passo fixo do §19 — o mesmo delta que o ClockService usa.
	var passo := 1.0 / float((load(CLOCK_DATA) as ClockData).tick_hz)

	for _i in int(relogio.day_seconds() / passo) + 1:
		for evento in relogio.tick(passo):
			if evento[GameClock.EVENTO] == GameClock.EVENTO_FASE:
				vistas.append(evento[GameClock.CAMPO_PARA])
			else:
				dias.append(evento[GameClock.CAMPO_DIA])

	var esperadas: Array[int] = [
		GameClock.Phase.MORNING,
		GameClock.Phase.NOON,
		GameClock.Phase.AFTERNOON,
		GameClock.Phase.DUSK,
		GameClock.Phase.NIGHT,
		GameClock.Phase.DAWN,
	]
	assert_array(vistas).is_equal(esperadas)
	assert_array(dias).is_equal([2])


func test_seconds_until_de_uma_fase_ja_passada_conta_pela_volta() -> void:
	var relogio := _relogio()
	relogio.tick(100.0)  # NOON

	assert_int(relogio.current_phase()).is_equal(GameClock.Phase.NOON)
	# DAWN comeca aos 0 s; faltam 360 - 100 = 260 para a proxima.
	assert_float(relogio.seconds_until(GameClock.Phase.DAWN)).is_equal_approx(260.0, TOLERANCIA)


func test_o_relogio_nao_inventa_numeros_le_os_do_tres() -> void:
	var dados: ClockData = load(CLOCK_DATA)
	var relogio := _relogio()

	assert_float(relogio.day_seconds()).is_equal_approx(dados.day_seconds, TOLERANCIA)
	for i in dados.phase_durations.size():
		assert_float(relogio.phase_duration(i as GameClock.Phase)).is_equal_approx(
			dados.phase_durations[i], TOLERANCIA
		)
