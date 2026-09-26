# tests/muro_em_obra_test.gd — um muro a subir de degrau continua a ser o muro que
# era ate o novo acabar (D4 da auditoria de 26/09; §10, §55).
#
# Pagar a paliçada punha a estacaria em andaime, e um andaime nao travava, nao
# levava golpes, nao tinha slots de contacto nem postos: melhorar o muro a tarde
# abria a porta a noite, e o jogador nao tinha como o saber.
extends GdUnitTestSuite

const STEP := 1.0 / 30.0
const SEMENTE := 20260926
const ASSENTAR := 60
const GOLPE := 5

var _muro: BuildSlot


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(SEMENTE)
	Greybox.build()
	for obra in SimLoop.builds.slots:
		if obra.two_paths() and obra.x > SimLoop.core_x:
			_muro = obra
			break
	_muro.level = 1
	_muro.state = BuildSlot.State.DONE
	_muro.health = _muro.max_health()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _pagar_o_degrau() -> void:
	SimLoop.units.xs[SimLoop.units.index_of(SimLoop.king_id)] = _muro.x
	for _k in _muro.next_cost():
		SimLoop.drop_coin(_muro.x, _muro.band, 1, Verbs.JOGADOR)
	for _t in ASSENTAR:
		SimLoop.units.set_target_x(SimLoop.king_id, SimLoop.core_x)
		SimLoop.step(STEP)


func test_pago_o_degrau_o_muro_continua_a_travar() -> void:
	_pagar_o_degrau()
	assert_bool(_muro.upgrading()).is_true()
	var fora := _muro.x + 300.0
	assert_object(SimLoop.builds.barrier(fora, SimLoop.core_x, Band.Kind.SURFACE)).is_same(_muro)
	assert_int(_muro.contact_slots()).is_greater(0)


func test_pago_o_degrau_os_postos_do_muro_continuam_publicados() -> void:
	_pagar_o_degrau()
	SimLoop.jobs.publish(SimLoop.builds)
	var guarda := 0
	var obra := 0
	for vaga in SimLoop.jobs.slots:
		if absf(vaga.x - _muro.x) > _muro.width:
			continue
		if vaga.job_id == _muro.job_id:
			guarda += 1
		elif vaga.job_id == &"build":
			obra += 1
	assert_int(guarda).is_equal(_muro.posts())
	assert_int(obra).is_equal(1)


func test_um_golpe_durante_a_obra_tira_vida_e_nao_a_para() -> void:
	_pagar_o_degrau()
	var antes := _muro.health
	SimLoop.builds.damage(_muro.id, GOLPE)
	assert_int(_muro.health).is_less(antes)
	assert_bool(_muro.upgrading()).is_true()


func test_derrubado_durante_a_obra_cai_em_ruina() -> void:
	_pagar_o_degrau()
	SimLoop.builds.damage(_muro.id, _muro.health + GOLPE)
	assert_int(_muro.state).is_equal(BuildSlot.State.RUIN)
	var fora := _muro.x + 300.0
	assert_object(SimLoop.builds.barrier(fora, SimLoop.core_x, Band.Kind.SURFACE)).is_not_same(
		_muro
	)


func test_acabada_a_obra_o_muro_fica_com_a_vida_do_degrau_novo() -> void:
	_pagar_o_degrau()
	SimLoop.builds.damage(_muro.id, GOLPE)
	for _t in int(_muro.works[_muro.level] / STEP) + ASSENTAR:
		SimLoop.builds.tick(STEP, _maos())
		if _muro.state == BuildSlot.State.DONE:
			break
	assert_int(_muro.level).is_equal(2)
	assert_int(_muro.health).is_equal(_muro.max_health())


## Uma tropa tua em cima do muro, para a obra andar sem esperar pela fila.
func _maos() -> UnitSystem:
	var u := UnitSystem.new()
	u.spawn(GameState.new(), Registry.entry(&"units", &"vagrant"), 1, _muro.x)
	return u
