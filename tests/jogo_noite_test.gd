# tests/jogo_noite_test.gd — a noite inteira pelo SimLoop, com o mundo montado.
#
# A metade do dia que o jogo tem de aguentar: ao crepusculo a mancha nasce, a
# noite ela invoca, as criaturas caminham para o nucleo, e ao amanhecer ela
# recua e elas dissolvem-se (§05, §51).
#
# Corre em headless, ao passo fixo, como o §31 pede. O tick de noite e o pior
# caso do §63 — tropas, criaturas e moedas ao mesmo tempo — e e aqui que ele se
# mede, e nao no minuto 0:20, onde so ha um vagabundo e uma moeda.
extends GdUnitTestSuite

const SEMENTE := 20260915
const PASSO := 1.0 / 30.0
## §63: a simulacao inteira, tick completo.
const ORCAMENTO_TICK_US := 4000
const METADE := 0.5
const TERCO := 0.3


func _relogio() -> ClockData:
	return Registry.entry(&"economy", &"clock") as ClockData


func _noite_em(fraccao: float) -> float:
	return _relogio().phase_durations[GameClock.Phase.NIGHT] * fraccao


func _correr(segundos: float) -> void:
	for _i in int(segundos / PASSO):
		SimLoop.step(PASSO)


func _ate_a_fase(fase: GameClock.Phase) -> void:
	var limite := int(_relogio().day_seconds / PASSO) * 2
	for _i in limite:
		SimLoop.step(PASSO)
		if ClockService.clock.current_phase() == fase:
			return
	fail("o relogio nunca chegou a fase %d" % int(fase))


func _distancia_media_ao_nucleo() -> float:
	var bichos := SimLoop.creatures
	if bichos.count() == 0:
		return 0.0
	var soma := 0.0
	for c in bichos.count():
		soma += absf(bichos.xs[c] - SimLoop.core_x)
	return soma / bichos.count()


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(SEMENTE)
	Greybox.build()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func test_ao_crepusculo_a_mancha_nasce_e_a_noite_traz_criaturas() -> void:
	var nasceu: Array[int] = []
	var ouvinte := func(_x: float, _w: float, _m: float, lado: int) -> void: nasceu.append(lado)
	EventBus.rot_spawned.connect(ouvinte)

	_ate_a_fase(GameClock.Phase.DUSK)
	EventBus.rot_spawned.disconnect(ouvinte)

	assert_array(nasceu).is_not_empty()
	assert_bool(SimLoop.night.rot.active()).is_true()
	assert_float(SimLoop.night.rot.mass()).is_greater(0.0)

	_ate_a_fase(GameClock.Phase.NIGHT)
	_correr(_noite_em(METADE))

	assert_int(SimLoop.creatures.count()).is_greater(0)


func test_ao_amanhecer_a_mancha_recua_e_as_criaturas_dissolvem_se() -> void:
	_ate_a_fase(GameClock.Phase.NIGHT)
	_correr(_noite_em(METADE))
	assert_int(SimLoop.creatures.count()).is_greater(0)

	_ate_a_fase(GameClock.Phase.DAWN)

	assert_bool(SimLoop.night.rot.active()).is_false()
	assert_int(SimLoop.creatures.count()).is_equal(0)


func test_as_criaturas_caminham_para_o_nucleo() -> void:
	_ate_a_fase(GameClock.Phase.NIGHT)
	_correr(_noite_em(TERCO))
	var antes := _distancia_media_ao_nucleo()
	assert_float(antes).is_greater(0.0)

	_correr(_noite_em(TERCO))

	assert_float(_distancia_media_ao_nucleo()).is_less(antes)


func test_um_tick_de_noite_cabe_no_orcamento() -> void:
	_ate_a_fase(GameClock.Phase.NIGHT)
	_correr(_noite_em(METADE))

	var voltas := 60
	var t0 := Time.get_ticks_usec()
	for _v in voltas:
		SimLoop.step(PASSO)
	var us := float(Time.get_ticks_usec() - t0) / float(voltas)

	print(
		(
			"jogo: tick de noite com %d tropas, %d criaturas e %d moedas = %.1f us (§63: 4000)"
			% [SimLoop.units.count(), SimLoop.creatures.count(), SimLoop.coins.count(), us]
		)
	)
	var porque := "%.1f us contra os 4000 us da simulacao inteira (§63)" % us
	assert_bool(us < ORCAMENTO_TICK_US).override_failure_message(porque).is_true()
