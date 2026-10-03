# tests/sede_sobe_test.gd — a sede depois de fundada: sobe e repara-se (ADR 0059).
#
# O nucleo e uma escada de estagios levantada como um muro (§55), mas nao e um muro: cada
# estagio e uma obra acabada, e a sede tocada repara-se como as outras obras (Q-224).
extends GdUnitTestSuite

const SEMENTE := 20261003
const PASSO := 1.0 / 30.0


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(SEMENTE)
	Greybox.build()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _sede() -> BuildSlot:
	return RealmLadder.seat(SimLoop.builds)


func _passos(n: int) -> void:
	for _k in n:
		SimLoop.step(PASSO)


## O rei larga `n` moedas em `x`, parado, e espera que assentem.
func _largar_em(x: float, n: int) -> void:
	var i := SimLoop.units.index_of(SimLoop.king_id)
	SimLoop.units.xs[i] = x
	SimLoop.units.clear_target(SimLoop.king_id)
	SimLoop.units.carried_coins[i] = maxi(SimLoop.units.carried_coins[i], n)
	for _k in n:
		var args := {&"x": x, &"band": Band.Kind.SURFACE, &"amount": 1}
		args[&"source"] = Verbs.JOGADOR
		SimLoop.intents.queue(IntentQueue.Kind.DROP_COIN, args)
		_passos(20)


## A sede tocada repara-se como as outras obras: o custo do degrau em que esta, a
## proporcao da vida perdida, e um construtor presente — o pioneiro serve (Q-224).
func test_a_sede_tocada_repara_se_com_construtor_contratado() -> void:
	var sede := _sede()
	SimLoop.units.spawn(SimLoop.state, Registry.entry(&"units", &"builder"), 1, sede.x)
	sede.raise_to(2)
	SimLoop.builds.damage(sede.id, sede.max_health() / 2)
	assert_int(int(sede.state)).is_equal(int(BuildSlot.State.DAMAGED))
	var custo := sede.repair_cost()
	assert_int(custo).is_greater(0)
	_largar_em(sede.x, custo)
	assert_bool(sede.mending).is_true()
	var antes := sede.health
	_passos(300)
	assert_int(sede.health).is_greater(antes)


## Cada estagio da sede e uma obra acabada (build_completed), e nao uma subida de muro:
## o wall_upgraded muda o material e o som de um muro (§55), e a sede nao e um muro.
func test_subir_a_sede_e_uma_obra_acabada_e_nao_um_muro() -> void:
	var muros: Array[int] = []
	var obras: Array[int] = []
	var ouvir_muro := func(id: int, _nivel: int) -> void: muros.append(id)
	var ouvir_obra := func(id: int) -> void: obras.append(id)
	EventBus.wall_upgraded.connect(ouvir_muro)
	EventBus.build_completed.connect(ouvir_obra)
	var sede := _sede()
	for estagio in [RealmLadder.FUNDADO, RealmLadder.FUNDADO + 1]:
		_largar_em(sede.x, sede.next_cost())
		_passos(ceili(sede.works[estagio - 1] / PASSO) + 60)
		assert_int(sede.level).is_equal(estagio)
	EventBus.wall_upgraded.disconnect(ouvir_muro)
	EventBus.build_completed.disconnect(ouvir_obra)
	assert_int(obras.count(sede.id)).is_equal(2)
	assert_array(muros).not_contains([sede.id])
