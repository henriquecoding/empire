# tests/celeiro_no_jogo_test.gd — o circuito 2 do §06 no jogo inteiro: com o
# celeiro de pe o grao vende-se la com o bonus; uma moeda largada nele com um
# cozinheiro teu vivo troca a moeda pela vida das tropas (Q-112).
extends GdUnitTestSuite

const STEP := 1.0 / 30.0
const ESPERA := 10

var _no_celeiro := 0
var _celeiro: BuildSlot


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20260926)
	Greybox.build()
	EventBus.coin_dropped.connect(_caiu)
	_celeiro = _obra(&"granary")
	for obra in [_celeiro, _obra(&"farm")]:
		obra.level = 1
		obra.state = BuildSlot.State.DONE
		obra.health = obra.max_health()


func after_test() -> void:
	EventBus.coin_dropped.disconnect(_caiu)
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func test_o_grao_vende_se_no_celeiro_e_a_moeda_manda_o_cozinheiro() -> void:
	_correr(ClockService.clock.day_seconds() * 0.7)
	assert_int(_no_celeiro).is_greater(0)
	var rei := SimLoop.units.index_of(SimLoop.king_id)
	var arqueiro := SimLoop.units.index_of(7)
	SimLoop.units.owners[arqueiro] = SimLoop.units.owners[rei]
	var base := SimLoop.units.max_healths[arqueiro]
	SimLoop.units.xs[rei] = _celeiro.x
	var sem := GameplayGuide.context(Glyphs.Device.KEYBOARD)
	assert_str(sem).contains(TranslationServer.translate(&"BUILDING_GRANARY"))
	var cozinheiro := SimLoop.units.spawn(
		SimLoop.state, Registry.entry(&"units", &"cook"), SimLoop.units.owners[rei], SimLoop.core_x
	)
	assert_int(cozinheiro).is_greater(0)
	var espera := 0
	for _t in 600:
		if SimLoop.field.conversion.mode_of(_celeiro) == CraftData.Mode.CAPACITY:
			break
		espera -= 1
		SimLoop.units.set_target_x(SimLoop.king_id, _celeiro.x)
		if espera <= 0 and SimLoop.units.carried_coins[_rei()] > 0:
			espera = ESPERA
			_largar()
		SimLoop.step(STEP)
	assert_int(SimLoop.field.conversion.mode_of(_celeiro)).is_equal(CraftData.Mode.CAPACITY)
	_correr(ClockService.clock.day_seconds() * 0.4)
	assert_float(SimLoop.field.conversion.capacity(&"troop_health")).is_greater(0.0)
	arqueiro = SimLoop.units.index_of(7)
	assert_int(SimLoop.units.max_healths[arqueiro]).is_greater(base)


func test_o_guia_diz_o_estado_efectivo_e_nao_so_o_modo_guardado() -> void:
	var estado := ConversionSystem.Status
	var chave := GameplayGuide.conversion_key
	assert_str(String(chave.call(estado.ACTIVE, true))).is_equal("CONTEXT_CONVERT_CAPACITY")
	assert_str(String(chave.call(estado.WAITING, true))).is_equal("CONTEXT_CONVERT_WAITING")
	assert_str(String(chave.call(estado.WANTS_CRAFT, false))).is_equal(
		"CONTEXT_CONVERT_WANTS_CRAFT"
	)
	assert_str(String(chave.call(estado.COIN, true))).is_equal("CONTEXT_CONVERT_COIN")
	assert_str(String(chave.call(estado.COIN, false))).is_equal("CONTEXT_CONVERT_NOBODY")
	# Sem cozinheiro, o modo guardado continua capacidade e o estado efectivo nao.
	SimLoop.field.conversion.modes[_celeiro.id] = CraftData.Mode.CAPACITY
	assert_int(SimLoop.field.conversion.status(_celeiro)).is_equal(estado.WANTS_CRAFT)
	SimLoop.units.xs[_rei()] = _celeiro.x
	assert_str(GameplayGuide.context(Glyphs.Device.KEYBOARD)).contains(
		TranslationServer.translate(&"BUILDING_GRANARY")
	)


func _correr(segundos: float) -> void:
	for _t in int(segundos / STEP):
		SimLoop.step(STEP)


func _obra(kind: StringName) -> BuildSlot:
	for obra in SimLoop.builds.slots:
		if obra.kind == kind:
			return obra
	return null


func _rei() -> int:
	return SimLoop.units.index_of(SimLoop.king_id)


func _caiu(x: float, _faixa: int, quanto: int, origem: StringName) -> void:
	if origem == &"production" and is_equal_approx(x, _celeiro.x):
		_no_celeiro += quanto


func _largar() -> void:
	var moeda := {
		&"x": SimLoop.units.xs[_rei()],
		&"band": Band.Kind.SURFACE,
		&"amount": InputRouter.UMA,
		&"source": Verbs.JOGADOR
	}
	SimLoop.intents.queue(IntentQueue.Kind.DROP_COIN, moeda)
