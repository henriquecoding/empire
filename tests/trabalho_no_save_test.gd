# tests/trabalho_no_save_test.gd — quem trabalhou antes de gravar conta ao retomar
# (CONT-03; §06, §52, §62; Q-121).
#
# A auditoria de 27/09 (N5): o Staffing lembrava quem esteve no posto na fase, e
# isso nao ia no save. Um trabalhador que saiu do canteiro antes de gravar deixava
# de contar ao retomar — 0,467 jogado de seguida, 0,292 carregado.
extends GdUnitTestSuite

const STEP := 1.0 / 30.0
const SEMENTE := 20260927
const PASSOS := 10

var _producao := 0


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	EventBus.coin_dropped.connect(_caiu)
	SimLoop.start(SEMENTE)
	Greybox.build()
	LastCartWatch.claim(&"road")  # esta suite mede o mundo depois da escolha territorial


func after_test() -> void:
	EventBus.coin_dropped.disconnect(_caiu)
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _caiu(_x: float, _f: int, quanto: int, origem: StringName) -> void:
	if origem == EventRelay.FONTE_PRODUCAO:
		_producao += quanto


func _canteiro() -> BuildSlot:
	for obra in SimLoop.builds.slots:
		if obra.kind == &"farm":
			obra.level = 1
			obra.state = BuildSlot.State.DONE
			obra.health = obra.max_health()
			return obra
	return null


func _passos(n: int) -> void:
	for _k in n:
		SimLoop.step(STEP)


## Corre ate a fase mudar e devolve o que o canteiro juntou, com o que ja largou.
func _fecha_a_fase(id: int) -> float:
	_producao = 0
	var fase := ClockService.clock.current_phase()
	while ClockService.clock.current_phase() == fase:
		SimLoop.step(STEP)
	return SimLoop.builds.slots[SimLoop.builds.index_of(id)].stock + _producao


func test_o_trabalho_de_antes_do_save_conta_depois_de_retomar() -> void:
	var canteiro := _canteiro()
	var vagabundo := Registry.entry(&"units", &"vagrant") as UnitData
	var quem := SimLoop.units.spawn(SimLoop.state, vagabundo, 1, canteiro.x)
	_passos(PASSOS)
	SimLoop.units.remove(quem)
	_passos(PASSOS)
	var estado: Dictionary = bytes_to_var(var_to_bytes(SimLoop.state.to_dict()))
	var mundo: Dictionary = bytes_to_var(var_to_bytes(SimLoop.world()))
	var sorte := RngService.snapshot()
	var seguido := _fecha_a_fase(canteiro.id)
	var serviu := SimLoop.jobs.staffing.worked(canteiro)
	SimLoop.stop()
	SimLoop.resume(GameState.from_dict(estado), sorte)
	Greybox.region()
	SimLoop.load_world(mundo)
	var retomado := _fecha_a_fase(canteiro.id)
	var novo := SimLoop.builds.slots[SimLoop.builds.index_of(canteiro.id)]
	assert_bool(SimLoop.jobs.staffing.worked(novo)).is_equal(serviu)
	assert_float(retomado).is_equal_approx(seguido, 0.0001)


func test_o_staffing_volta_do_dicionario_como_foi() -> void:
	var canteiro := _canteiro()
	var postos: Dictionary = SimFactory.by_id(&"jobs")
	var um := Staffing.new(postos)
	um.served = {canteiro.id: true}
	um.ended = 2
	var outro := Staffing.new(postos)
	outro.from_dict(bytes_to_var(var_to_bytes(um.to_dict())))
	assert_int(outro.ended).is_equal(2)
	assert_bool(outro.served.has(canteiro.id)).is_true()
	assert_bool(outro.worked(canteiro)).is_equal(um.worked(canteiro))


func test_um_save_sem_staffing_nao_penaliza_ninguem() -> void:
	var um := Staffing.new(SimFactory.by_id(&"jobs"))
	um.from_dict({})
	assert_int(um.ended).is_equal(Staffing.NENHUMA)
	assert_bool(um.worked(_canteiro())).is_true()
