# tests/reparar_no_jogo_test.gd — a reparacao no jogo inteiro (Q-108): a muralha
# tocada pede o preco no painel, o rei paga com o Verbo 1, e um trabalhador teu
# vai la e poe-na inteira sem o rei ao pe.
extends GdUnitTestSuite

const STEP := 1.0 / 30.0
const ESPERA := 15


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20260926)
	Greybox.build()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func test_a_muralha_tocada_repara_se_com_gestos_e_um_trabalhador() -> void:
	var muro := SimLoop.builds.slots[2]
	muro.level = 1
	muro.state = BuildSlot.State.DONE
	muro.health = muro.max_health()
	SimLoop.builds.damage(muro.id, muro.max_health() / 2)
	var trabalhador := SimLoop.units.index_of(2)
	SimLoop.units.owners[trabalhador] = SimLoop.units.owners[_rei()]
	SimLoop.units.xs[_rei()] = muro.x
	var custo := muro.repair_cost()
	assert_str(GameplayGuide.goal()).is_equal(TranslationServer.translate(&"GUIDE_REPAIR"))
	var painel := GameplayGuide.context(Glyphs.Device.KEYBOARD)
	assert_str(painel).is_equal(
		TranslationServer.translate(&"CONTEXT_REPAIR").format(
			{
				"name": TranslationServer.translate(&"CONTEXT_WALL_NAME"),
				"cost": custo,
				"drop": painel.get_slice("\n", 1).get_slice(" ", 0)
			}
		)
	)
	var espera := 0
	for _t in 600:
		if muro.mending:
			break
		espera -= 1
		SimLoop.units.set_target_x(SimLoop.king_id, muro.x)
		if espera <= 0 and SimLoop.units.carried_coins[_rei()] > 0:
			espera = ESPERA
			_largar()
		SimLoop.step(STEP)
	assert_bool(muro.mending).is_true()
	SimLoop.units.set_target_x(SimLoop.king_id, SimLoop.core_x)
	for _t in int(muro.works[0] * 4.0 / STEP):
		if muro.state == BuildSlot.State.DONE:
			break
		SimLoop.units.set_target_x(SimLoop.king_id, SimLoop.core_x)
		SimLoop.step(STEP)
	assert_int(muro.state).is_equal(BuildSlot.State.DONE)
	assert_int(muro.health).is_equal(muro.max_health())
	assert_float(absf(SimLoop.units.xs[_rei()] - muro.x)).is_greater(muro.width)


func _rei() -> int:
	return SimLoop.units.index_of(SimLoop.king_id)


func _largar() -> void:
	var moeda := {
		&"x": SimLoop.units.xs[_rei()],
		&"band": Band.Kind.SURFACE,
		&"amount": InputRouter.UMA,
		&"source": Verbs.JOGADOR
	}
	SimLoop.intents.queue(IntentQueue.Kind.DROP_COIN, moeda)
