# tests/retomar_fase_test.gd — retomar um save nao repete a fase em que ele foi
# gravado (D2 da auditoria de 26/09, §62).
#
# O autosave e escrito DEPOIS do tick da alvorada. Quem retoma estava a repor a
# fase a NENHUM, e o primeiro passo voltava a correr a passagem de fase: a
# producao caia duas vezes e a Colheita perdia um dia por cada carregamento.
extends GdUnitTestSuite

const STEP := 1.0 / 30.0
const SEMENTE := 20260926
const SLOT := 2
const PASSOS := 10

var _producao := 0


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SaveService.delete_slot(SLOT)
	EventBus.coin_dropped.connect(_caiu)


func after_test() -> void:
	EventBus.coin_dropped.disconnect(_caiu)
	SimLoop.stop()
	SimLoop.autosave_enabled = true
	SaveService.delete_slot(SLOT)


func _caiu(_x: float, _f: int, quanto: int, origem: StringName) -> void:
	if origem == EventRelay.FONTE_PRODUCAO:
		_producao += quanto


func _passos() -> int:
	_producao = 0
	for _t in PASSOS:
		SimLoop.step(STEP)
	return _producao


func _retomar() -> void:
	SimLoop.stop()
	SimLoop.resume(SaveService.restore(SLOT), SaveService.restore_rng(SLOT))
	Greybox.region()
	SimLoop.load_world(SaveService.restore_world(SLOT))


func _arrancar_com_producao() -> void:
	SimLoop.start(SEMENTE)
	Greybox.build()
	for obra in SimLoop.builds.slots:
		if obra.yield_per_day > 0.0:
			obra.level = 1
			obra.state = BuildSlot.State.DONE
			obra.health = obra.max_health()


func test_retomar_a_alvorada_nao_volta_a_produzir() -> void:
	_arrancar_com_producao()
	while ClockService.clock.day < 2:
		SimLoop.step(STEP)
	SaveService.save(SLOT, SimLoop.state, RngService.snapshot(), SimLoop.world())
	var sem_retomar := _passos()
	_retomar()
	assert_int(_passos()).is_equal(sem_retomar)


func test_retomar_a_alvorada_nao_conta_outro_dia_de_colheita() -> void:
	_arrancar_com_producao()
	while ClockService.clock.day < 2:
		SimLoop.step(STEP)
	SimLoop.night.harvest.people = "fenda"
	SimLoop.night.harvest.days_left = 3
	SaveService.save(SLOT, SimLoop.state, RngService.snapshot(), SimLoop.world())
	_retomar()
	_passos()
	assert_int(SimLoop.night.harvest.days_left).is_equal(3)


func test_retomar_a_meio_da_tarde_produz_o_mesmo_ate_a_alvorada() -> void:
	_arrancar_com_producao()
	while ClockService.clock.current_phase() != GameClock.Phase.AFTERNOON:
		SimLoop.step(STEP)
	for _t in PASSOS:
		SimLoop.step(STEP)
	SaveService.save(SLOT, SimLoop.state, RngService.snapshot(), SimLoop.world())
	var sem_retomar := _ate_a_alvorada()
	_retomar()
	assert_int(_ate_a_alvorada()).is_equal(sem_retomar)
	assert_int(sem_retomar).is_greater(0)


func _ate_a_alvorada() -> int:
	_producao = 0
	var dia := ClockService.clock.day
	while ClockService.clock.day == dia:
		SimLoop.step(STEP)
	return _producao
