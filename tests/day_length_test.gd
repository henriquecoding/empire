# tests/day_length_test.gd — o dia ao ritmo de quem joga (§26; GB-24).
#
# "Jogavel ao teu proprio ritmo — slider de duracao do dia (240–540 s). Fazer.
# Tambem e um botao de dificuldade honesto." O GameClock ja sabia escalar as
# fases (set_day_seconds); faltava quem o pedisse, e o save nao o guardava.
extends GdUnitTestSuite


func _dados() -> ClockData:
	return Registry.entry(&"economy", &"clock") as ClockData


func after_test() -> void:
	ClockService.start()


## A duracao e estado de jogo (§45): muda a simulacao, e por isso vai no save.
## Um save de antes disto nao a tem, e carrega com a do clock.csv — que era a que
## ele tinha.
func test_a_duracao_vai_no_save_e_um_save_antigo_nao_a_tem() -> void:
	var estado := GameState.new()
	estado.day_seconds = 300.0
	assert_float(GameState.from_dict(estado.to_dict()).day_seconds).is_equal(300.0)
	var antigo := estado.to_dict()
	antigo.erase(&"day_seconds")
	assert_float(GameState.from_dict(antigo).day_seconds).is_equal(0.0)


## A pausa nao mexe no relogio: enfileira uma intencao (§61), e o tick seguinte
## consome-a. Fora dos limites do §26, prende-se a eles.
func test_a_intencao_muda_o_dia_dentro_dos_limites_do_26() -> void:
	ClockService.start()
	Verbs.day_length(300.0)
	assert_float(ClockService.clock.day_seconds()).is_equal(300.0)
	Verbs.day_length(9999.0)
	assert_float(ClockService.clock.day_seconds()).is_equal(_dados().day_seconds_max)
	Verbs.day_length(1.0)
	assert_float(ClockService.clock.day_seconds()).is_equal(_dados().day_seconds_min)


## Zero e "o do clock.csv": e o que vem de um save antigo ou de quem nunca mexeu.
func test_zero_e_o_dia_do_clock_csv() -> void:
	ClockService.start()
	Verbs.day_length(300.0)
	Verbs.day_length(0.0)
	assert_float(ClockService.clock.day_seconds()).is_equal(_dados().day_seconds)


## Retomar um save de um dia de 240 s: as fases voltam escaladas e o decorrido
## fica onde estava — sem isto voltava com as fases dos 360 s e a meio de outra
## fase.
func test_retomar_repoe_a_duracao_e_o_decorrido() -> void:
	ClockService.seek(3, 100.0, 240.0)
	assert_float(ClockService.clock.day_seconds()).is_equal(240.0)
	assert_float(ClockService.clock.elapsed).is_equal(100.0)
	assert_int(ClockService.clock.day).is_equal(3)
