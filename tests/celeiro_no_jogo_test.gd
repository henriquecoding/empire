# tests/celeiro_no_jogo_test.gd — o circuito 2 do §06 no jogo inteiro: com o
# celeiro de pe o grao vende-se la com o bonus; com um cozinheiro teu vivo, o
# Verbo 2 no celeiro escolhe a vida das tropas em vez da moeda (Q-112, Q-115).
extends GdUnitTestSuite

const Posto := preload("res://tests/support/posto.gd")

const STEP := 1.0 / 30.0
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
	Posto.staff_all()


func after_test() -> void:
	EventBus.coin_dropped.disconnect(_caiu)
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func test_o_grao_vende_se_no_celeiro_e_o_verbo_2_manda_o_cozinheiro() -> void:
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
	SimLoop.units.set_target_x(SimLoop.king_id, _celeiro.x)
	SimLoop.intents.queue(IntentQueue.Kind.ASSUME)
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
		# O teste económico atravessa a noite. O rei agora precisa do gesto de
		# defesa que antes era automático, tal como o jogador (ADR 0045).
		var who := Assume.driven()
		var target := SimLoop.creatures.index_of(SimLoop.combat.target_of(who))
		var i := SimLoop.units.index_of(who)
		if target >= 0 and i >= 0:
			var direction := signf(SimLoop.creatures.xs[target] - SimLoop.units.xs[i])
			SimLoop.intents.queue(IntentQueue.Kind.ATTACK, {&"who": who, &"direction": direction})
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
