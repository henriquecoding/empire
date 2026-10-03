# tests/variantes_test.gd — melhorias com variante (AUD-05, P-N; §10; Q-136).
#
# A escolha A/B da muralha (§10) estendida, como a auditoria de 26/09 pediu antes
# de ligar edificios novos: a torre de arqueiros escolhe alcance ou cadencia; o
# canteiro escolhe renda ou resguardo. Escolhe-se com o Verbo 2, com o sitio vazio.
extends GdUnitTestSuite

const Sede := preload("res://tests/support/sede.gd")

const STEP := 1.0 / 30.0
const SEMENTE := 20260926
const TORRE := &"archer_tower"
const CANTEIRO := &"farm"


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(SEMENTE)
	Greybox.build()
	Sede.erguer()  # o castelo de antes e a Fortaleza (ADR 0059)
	SimLoop.step(STEP)


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _sitio(kind: StringName) -> BuildSlot:
	for obra in SimLoop.builds.slots:
		if obra.kind == kind:
			return obra
	return null


func _rei_em(obra: BuildSlot) -> void:
	var i := SimLoop.units.index_of(SimLoop.king_id)
	SimLoop.units.xs[i] = obra.x
	SimLoop.units.set_target_x(SimLoop.king_id, obra.x)


func _verbo_2() -> void:
	SimLoop.intents.queue(IntentQueue.Kind.ASSUME)
	SimLoop.step(STEP)


func test_a_torre_e_o_canteiro_tem_outra_variante_e_o_galinheiro_nao() -> void:
	assert_bool(SlotVariant.open(_sitio(TORRE))).is_true()
	assert_bool(SlotVariant.open(_sitio(CANTEIRO))).is_true()
	assert_bool(SlotVariant.open(_sitio(&"henhouse"))).is_false()


func test_o_verbo_2_troca_a_variante_enquanto_o_sitio_esta_vazio() -> void:
	var torre := _sitio(TORRE)
	for muro in SimLoop.builds.slots:
		if muro.two_paths():
			muro.raise_to(1)
	_rei_em(torre)
	_verbo_2()
	assert_int(torre.variant).is_equal(SlotVariant.B)
	_verbo_2()
	assert_int(torre.variant).is_equal(SlotVariant.A)
	torre.paid = 1
	_verbo_2()
	assert_int(torre.variant).is_equal(SlotVariant.A)


func test_a_torre_de_cadencia_dispara_mais_vezes_e_perde_o_alcance() -> void:
	var torre := _sitio(TORRE)
	var sempre := JobSlot.new(&"tower", torre.x, torre.band)
	sempre.grants(torre)
	torre.variant = SlotVariant.B
	var outra := JobSlot.new(&"tower", torre.x, torre.band)
	outra.grants(torre)
	assert_float(sempre.cadence).is_equal(1.0)
	assert_float(outra.cadence).is_less(1.0)
	assert_float(outra.range_bonus).is_less(sempre.range_bonus)
	assert_float(outra.accuracy).is_equal(sempre.accuracy)


func test_o_canteiro_resguardado_nao_para_no_rasto_e_rende_menos() -> void:
	var canteiro := _sitio(CANTEIRO)
	canteiro.level = 1
	canteiro.state = BuildSlot.State.DONE
	canteiro.health = canteiro.max_health()
	var rasto: Array[Vector2] = [Vector2(canteiro.x - 1.0, canteiro.x + 1.0)]
	var eco := SimLoop.economy
	eco.on_phase(SimLoop.builds, 0, rasto)
	assert_float(canteiro.stock).is_equal(0.0)
	canteiro.variant = SlotVariant.B
	eco.on_phase(SimLoop.builds, 0, rasto)
	assert_float(canteiro.stock).is_greater(0.0)
	var resguardado := canteiro.stock
	canteiro.variant = SlotVariant.A
	canteiro.stock = 0.0
	eco.on_phase(SimLoop.builds, 0, [])
	var fator: float = canteiro.effects_b.get(&"yield_mult", 1.0)
	assert_float(resguardado).is_equal_approx(canteiro.stock * fator, 0.0001)


func test_a_variante_vai_no_save() -> void:
	var torre := _sitio(TORRE)
	torre.variant = SlotVariant.B
	var copia := BuildSlot.new()
	copia.from_dict(torre.to_dict())
	assert_int(copia.variant).is_equal(SlotVariant.B)


func test_o_painel_diz_a_variante_e_como_se_troca() -> void:
	TranslationServer.set_locale("pt_PT")
	var torre := _sitio(TORRE)
	for muro in SimLoop.builds.slots:
		if muro.two_paths():
			muro.raise_to(1)
	_rei_em(torre)
	torre.variant = SlotVariant.B
	assert_str(GameplayGuide.context(Glyphs.Device.KEYBOARD)).contains("cadência")
