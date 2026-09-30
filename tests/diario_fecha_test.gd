# tests/diario_fecha_test.gd — a folha de um diario fecha-se a mao, e nao fica muito
# tempo (o pedido do dono de 30/09/2026: "fica muito tempo e nao da para fechar
# manualmente"; §79, §17).
extends GdUnitTestSuite

const DIARIO := &"journal_01"


func _gesto(accao: StringName) -> InputEventAction:
	var e := InputEventAction.new()
	e.action = accao
	e.pressed = true
	return e


func _folha() -> JournalPanel:
	var folha: JournalPanel = auto_free(JournalPanel.new())
	add_child(folha)
	folha.show_journal(DIARIO)
	return folha


func test_espaco_e_esc_e_clique_fecham() -> void:
	for accao in JournalPanel.FECHAM:
		assert_bool(JournalPanel.closes(_gesto(accao))).is_true()
	var clique := InputEventMouseButton.new()
	clique.pressed = true
	clique.button_index = MOUSE_BUTTON_LEFT
	assert_bool(JournalPanel.closes(clique)).is_true()
	assert_bool(JournalPanel.closes(_gesto(&"move_left"))).is_false()


func test_o_gesto_fecha_a_folha_aberta() -> void:
	var folha := _folha()
	assert_bool(folha.visible).is_true()
	folha._input(_gesto(&"pause"))
	assert_bool(folha.visible).is_false()


func test_sozinha_sai_em_menos_de_um_quarto_de_minuto() -> void:
	assert_float(JournalPanel.DURA_S).is_less_equal(15.0)
	var folha := _folha()
	folha._process(JournalPanel.DURA_S + 0.1)
	assert_bool(folha.visible).is_false()


func test_a_folha_diz_como_se_fecha() -> void:
	var texto := TranslationServer.translate(JournalPanel.RODAPE)
	assert_str(String(texto)).is_not_equal(String(JournalPanel.RODAPE))
