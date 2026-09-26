# tests/impulso_no_jogo_test.gd — os impulsos reais no jogo inteiro (§15, §24,
# §61): a intencao da roda paga do saco, muda o dia, e so ha um por dia.
extends GdUnitTestSuite

const STEP := 1.0 / 30.0

var _usados: Array[StringName] = []


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20260926)
	Greybox.build()
	EventBus.royal_impulse_used.connect(_usado)


func after_test() -> void:
	EventBus.royal_impulse_used.disconnect(_usado)
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func test_a_chamada_as_armas_pela_roda_arma_os_vagabundos_e_nao_se_repete() -> void:
	var rei := SimLoop.units.index_of(SimLoop.king_id)
	var custo := (Registry.entry(&"crown/impulses", &"call_to_arms") as ImpulseData).coin_cost
	SimLoop.units.carried_coins[rei] = custo * 2
	SimLoop.intents.queue(IntentQueue.Kind.IMPULSE, {&"id": &"call_to_arms"})
	SimLoop.step(STEP)
	assert_array(_usados).is_equal([&"call_to_arms"])
	assert_int(SimLoop.units.carried_coins[SimLoop.units.index_of(SimLoop.king_id)]).is_equal(custo)
	var lanceiros := 0
	for i in SimLoop.units.count():
		if SimLoop.units.data_ids[i] == &"spearman" and SimLoop.units.owners[i] != 0:
			lanceiros += 1
	assert_int(lanceiros).is_greater_equal(4)
	var salvo := SimLoop.world()
	SimLoop.load_world(salvo)
	SimLoop.intents.queue(IntentQueue.Kind.IMPULSE, {&"id": &"vigil"})
	SimLoop.step(STEP)
	assert_array(_usados).is_equal([&"call_to_arms"])


func test_a_vigilia_tira_a_fuga_esta_noite() -> void:
	var rei := SimLoop.units.index_of(SimLoop.king_id)
	SimLoop.units.carried_coins[rei] = 30
	SimLoop.intents.queue(IntentQueue.Kind.IMPULSE, {&"id": &"vigil"})
	SimLoop.step(STEP)
	SimLoop.step(STEP)
	assert_bool(SimLoop.morale.steadfast).is_true()
	var tropa := SimLoop.units.index_of(7)
	assert_bool(SimLoop.morale.can_flee(SimLoop.units, tropa)).is_false()


func _usado(id: StringName) -> void:
	_usados.append(id)
