extends GdUnitTestSuite

const Sede := preload("res://tests/support/sede.gd")
var _u: UnitSystem
var _r: int
var _s: int
var _target: int


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20261005)
	Greybox.build()
	Sede.erguer()
	Sede.companhia()
	MonarchWatch.begin(&"archer_emperor")
	_u = SimLoop.units
	_r = _u.index_of(SimLoop.king_id)
	_s = SimLoop.field.monarchy.companion_index(_u, SimLoop.king_id)
	_u.xs[_s] = _u.xs[_r]
	_target = SimLoop.creatures.spawn(
		SimLoop.state, Registry.entry(&"creatures", &"crawler"), _u.xs[_s] + 100.0, -1
	)
	SimLoop.combat.manual.controlled = SimLoop.king_id


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _arrows() -> int:
	return SimLoop.field.supply.left(_u, _r, Registry.entry(&"units", &"archer_emperor"))


func _fire(evolved: bool) -> Array[Dictionary]:
	SimLoop.field.hero_progress.phases[&"archer"] = 2 if evolved else 1
	MonarchWatch.sync()
	SimLoop.combat.choose(_u, SimLoop.creatures, SimLoop.builds)
	return SimLoop.combat.resolve(
		_u, SimLoop.creatures, SimLoop.builds, func() -> float: return 0.0
	)


func test_base_nao_dispara_e_evoluido_gasta_flecha_paga() -> void:
	var antes := _arrows()
	_fire(false)
	assert_int(_arrows()).is_equal(antes)
	var eventos := _fire(true)
	assert_int(_arrows()).is_equal(antes - 1)
	var tiros := 0
	for e in eventos:
		if e[CombatSystem.CHAVE] == CombatSystem.EV_ATAQUE and e[CombatSystem.DE] == _u.ids[_s]:
			tiros += 1
	assert_int(tiros).is_equal(1)


func test_sem_flechas_nao_dispara_nem_cobra_moedas() -> void:
	var corpo: UnitData = Registry.entry(&"units", &"archer_emperor")
	SimLoop.field.supply.arm(_u, _r, corpo, 0)
	_u.carried_coins[_r] = 5
	_fire(true)
	assert_int(_arrows()).is_equal(0)
	assert_int(_u.carried_coins[_r]).is_equal(5)
	assert_float(_u.cooldowns[_s]).is_equal(0.0)


func test_sem_patrono_vivo_nao_dispara() -> void:
	var antes := _arrows()
	_u.healths[_r] = 0
	_u.states[_r] = UnitFsm.State.DEAD
	_fire(true)
	assert_int(_arrows()).is_equal(antes)


func test_fora_de_alcance_nao_gasta() -> void:
	SimLoop.creatures.xs[SimLoop.creatures.index_of(_target)] += 1000.0
	var antes := _arrows()
	_fire(true)
	assert_int(_arrows()).is_equal(antes)
