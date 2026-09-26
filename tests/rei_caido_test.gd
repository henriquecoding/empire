# tests/rei_caido_test.gd — quando e que a partida acabou, e quando se grava
# (D6 e D11 da auditoria de 26/09; §10, §16, §62).
#
# Um rei morto deixava o mundo a correr sem ninguem para comandar. Ate haver
# herdeiro (§16), e a mesma derrota que o nucleo caido. E gravar ao pausar ou ao
# fechar so se faz de dia, com a partida viva.
extends GdUnitTestSuite

const STEP := 1.0 / 30.0
const SEMENTE := 20260926
const SLOT_LIVRE := 0


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	for slot in SaveService.SLOTS:
		SaveService.delete_slot(slot)
	SimLoop.start(SEMENTE)
	Greybox.build()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true
	for slot in SaveService.SLOTS:
		SaveService.delete_slot(slot)


func _rei() -> int:
	return SimLoop.units.index_of(SimLoop.king_id)


func test_uma_partida_nova_nao_esta_perdida() -> void:
	assert_bool(Defeat.happened()).is_false()


func test_o_rei_morto_acaba_a_partida() -> void:
	SimLoop.units.healths[_rei()] = 0
	assert_bool(Defeat.happened()).is_true()
	assert_bool(PauseMenu.defeated()).is_true()


func test_o_rei_levado_na_alvorada_continua_a_ser_derrota() -> void:
	SimLoop.builds.slots[0].health = 1000000  # a pergunta e o rei, nao o nucleo
	SimLoop.units.healths[_rei()] = 0
	while ClockService.clock.day < 2:
		SimLoop.step(STEP)
	SimLoop.step(STEP)
	assert_int(_rei()).is_equal(UnitSystem.NENHUM)
	assert_bool(Defeat.happened()).is_true()


func test_o_nucleo_caido_acaba_a_partida() -> void:
	var nucleo := SimLoop.builds.slots[0]
	SimLoop.builds.damage(nucleo.id, nucleo.health)
	assert_bool(Defeat.happened()).is_true()


func test_de_dia_grava_e_o_save_retoma_o_mesmo_instante() -> void:
	for _t in 300:
		SimLoop.step(STEP)
	assert_bool(SavePoint.allowed()).is_true()
	var slot := SavePoint.now()
	assert_int(slot).is_greater_equal(SLOT_LIVRE)
	var antes := ClockService.clock.elapsed
	SimLoop.stop()
	SimLoop.resume(SaveService.restore(slot), SaveService.restore_rng(slot))
	Greybox.region()
	SimLoop.load_world(SaveService.restore_world(slot))
	assert_float(ClockService.clock.elapsed).is_equal_approx(antes, STEP)
	assert_int(SimLoop.units.index_of(SimLoop.king_id)).is_not_equal(UnitSystem.NENHUM)


func test_de_noite_nao_grava() -> void:
	while ClockService.clock.current_phase() < GameClock.Phase.DUSK:
		SimLoop.step(STEP)
	assert_bool(SavePoint.allowed()).is_false()
	assert_int(SavePoint.now()).is_equal(-1)


func test_perdida_nao_grava() -> void:
	SimLoop.units.healths[_rei()] = 0
	assert_int(SavePoint.now()).is_equal(-1)
