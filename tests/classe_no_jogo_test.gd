# tests/classe_no_jogo_test.gd — a classe do Monarca pelo SimLoop (§08, Q-114).
#
# O ClassSystem prova-se sozinho no class_system_test; aqui prova-se o que so o
# jogo inteiro mostra: que o combate passa pela aura, que a alvorada conta a
# noite, e que o Verbo 1 no nucleo evolui a classe — e so quando pode.
extends GdUnitTestSuite

const SEMENTE := 20260926
const PASSO := 1.0 / 30.0


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(SEMENTE)
	Greybox.build()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _rei() -> int:
	return SimLoop.units.index_of(SimLoop.king_id)


func _classe() -> ClassData:
	return Registry.entry(&"classes", &"monarch") as ClassData


func _largar_no_nucleo() -> void:
	var i := _rei()
	SimLoop.units.xs[i] = SimLoop.core_x
	SimLoop.units.clear_target(SimLoop.king_id)
	var args := {
		&"x": SimLoop.core_x,
		&"band": Band.Kind.SURFACE,
		&"amount": 1,
		&"source": Verbs.JOGADOR,
	}
	SimLoop.intents.queue(IntentQueue.Kind.DROP_COIN, args)
	SimLoop.step(PASSO)


func test_o_combate_passa_pela_aura_do_rei() -> void:
	assert_object(SimLoop.combat.guard).is_same(SimLoop.field.classes)


func test_largar_no_nucleo_sem_o_feito_e_so_largar() -> void:
	SimLoop.state.royal_seeds = _classe().evolve_seed_cost
	var moedas := SimLoop.coins.count()
	_largar_no_nucleo()
	assert_int(SimLoop.field.classes.phase).is_equal(1)
	assert_int(SimLoop.state.royal_seeds).is_equal(_classe().evolve_seed_cost)
	assert_int(SimLoop.coins.count()).is_equal(moedas + 1)


func test_com_o_feito_e_a_semente_o_verbo_1_no_nucleo_evolui() -> void:
	SimLoop.field.classes.nights_defended = _classe().evolve_condition_value
	SimLoop.state.royal_seeds = _classe().evolve_seed_cost
	SimLoop.units.xs[_rei()] = SimLoop.core_x
	assert_str(GameplayGuide.context(Glyphs.Device.KEYBOARD)).contains(
		TranslationServer.translate(&"BUILDING_CORE")
	)
	var saco := SimLoop.units.carried_coins[_rei()]
	var moedas := SimLoop.coins.count()
	_largar_no_nucleo()
	assert_int(SimLoop.field.classes.phase).is_equal(2)
	assert_int(SimLoop.state.royal_seeds).is_equal(0)
	# A moeda volta ao saco, como ao consagrar uma arvore (§74).
	assert_int(SimLoop.units.carried_coins[_rei()]).is_equal(saco)
	assert_int(SimLoop.coins.count()).is_equal(moedas)


func test_a_classe_vai_no_save_do_mundo() -> void:
	SimLoop.field.classes.nights_defended = 2
	var mundo := SimLoop.world()
	SimLoop.field.classes.nights_defended = 0
	SimLoop.load_world(mundo)
	assert_int(SimLoop.field.classes.nights_defended).is_equal(2)
