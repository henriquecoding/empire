# tests/treino_no_jogo_test.gd — a Casa de Treino no jogo inteiro (§09, §10): o
# rei paga com o Verbo 1, o trabalhador vai la, passa um dia e sai construtor, e
# o save a meio nao perde nem repete nada.
extends GdUnitTestSuite

const STEP := 1.0 / 30.0
const ESPERA := 10
const O_TRABALHADOR := 2

var _promovidos: Array[StringName] = []


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20260926)
	Greybox.build()
	EventBus.unit_promoted.connect(_promovido)


func after_test() -> void:
	EventBus.unit_promoted.disconnect(_promovido)
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func test_pagar_na_casa_de_treino_forma_um_construtor_num_dia() -> void:
	var casa := _casa()
	casa.level = 1
	casa.state = BuildSlot.State.DONE
	casa.health = casa.max_health()
	var i := SimLoop.units.index_of(O_TRABALHADOR)
	SimLoop.units.owners[i] = SimLoop.units.owners[_rei()]
	var oficio := SimLoop.field.training.craft_of(casa)
	SimLoop.units.carried_coins[_rei()] = oficio.recruit_cost
	SimLoop.units.xs[_rei()] = casa.x
	var painel := GameplayGuide.context(Glyphs.Device.KEYBOARD)
	assert_str(painel).contains(TranslationServer.translate(oficio.display_key))
	var espera := 0
	for _t in 900:
		if not SimLoop.field.training.trainees.is_empty():
			break
		espera -= 1
		SimLoop.units.set_target_x(SimLoop.king_id, casa.x)
		if espera <= 0 and SimLoop.units.carried_coins[_rei()] > 0:
			espera = ESPERA
			_largar()
		SimLoop.step(STEP)
	assert_bool(SimLoop.field.training.trainees.has(O_TRABALHADOR)).is_true()
	var salvo := SimLoop.world()
	SimLoop.load_world(salvo)
	assert_bool(SimLoop.field.training.trainees.has(O_TRABALHADOR)).is_true()
	var dia := ClockService.clock.day_seconds() * oficio.train_days
	for _t in int(dia * 1.5 / STEP):
		if not _promovidos.is_empty():
			break
		SimLoop.units.set_target_x(SimLoop.king_id, SimLoop.core_x)
		SimLoop.step(STEP)
	i = SimLoop.units.index_of(O_TRABALHADOR)
	assert_str(String(SimLoop.units.data_ids[i])).is_equal(String(oficio.id))
	assert_array(_promovidos).is_equal([oficio.id])
	SimLoop.step(STEP)  # a defesa le quem esta vivo no inicio do passo seguinte
	assert_float(SimLoop.builds.wall_defense).is_greater(0.0)


func _casa() -> BuildSlot:
	for obra in SimLoop.builds.slots:
		if obra.kind == &"training_house":
			return obra
	return null


func _rei() -> int:
	return SimLoop.units.index_of(SimLoop.king_id)


func _promovido(_quem: int, _de: StringName, para: StringName) -> void:
	_promovidos.append(para)


func _largar() -> void:
	var moeda := {
		&"x": SimLoop.units.xs[_rei()],
		&"band": Band.Kind.SURFACE,
		&"amount": InputRouter.UMA,
		&"source": Verbs.JOGADOR
	}
	SimLoop.intents.queue(IntentQueue.Kind.DROP_COIN, moeda)
