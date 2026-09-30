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


func _tecla(fisica: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = fisica
	e.pressed = true
	return e


func _botao(indice: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = indice
	e.pressed = true
	return e


func _rato(indice: MouseButton) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = indice
	e.pressed = true
	return e


## SCREEN_REGISTER, `journal`: os verbos, o B, o Esc e um clique fecham.
func test_os_verbos_o_b_o_esc_e_o_clique_fecham() -> void:
	for accao in JournalPanel.FECHAM:
		assert_bool(JournalPanel.closes(_gesto(accao))).is_true()
	assert_bool(JournalPanel.closes(_botao(JOY_BUTTON_B))).is_true()
	assert_bool(JournalPanel.closes(_tecla(KEY_ESCAPE))).is_true()
	assert_bool(JournalPanel.closes(_rato(MOUSE_BUTTON_LEFT))).is_true()
	assert_bool(JournalPanel.closes(_gesto(&"move_left"))).is_false()


## A roda do rato rola a folha, e o Start do comando pausa sempre (UI_UX_FLOWS).
func test_a_roda_e_o_start_nao_fecham() -> void:
	assert_bool(JournalPanel.closes(_rato(MOUSE_BUTTON_WHEEL_UP))).is_false()
	assert_bool(JournalPanel.closes(_rato(MOUSE_BUTTON_WHEEL_DOWN))).is_false()
	assert_bool(JournalPanel.closes(_botao(JOY_BUTTON_START))).is_false()


## Fechar com o Verbo 1 nao larga moeda: o InputRouter pergunta ate o largarem.
func test_fechar_com_o_verbo_1_nao_larga_moeda() -> void:
	var folha := _folha()
	Input.action_press(&"verb_drop")
	folha._input(_gesto(&"verb_drop"))
	assert_bool(folha.visible).is_false()
	assert_bool(JournalPanel.holds_drop()).is_true()
	Input.action_release(&"verb_drop")
	assert_bool(JournalPanel.holds_drop()).is_false()


## O rodape diz os botoes do dispositivo activo (§26), e nao os do teclado.
func test_o_rodape_fala_do_comando_que_se_usa() -> void:
	var teclado := JournalPanel.close_hint(Glyphs.Device.KEYBOARD)
	var xbox := JournalPanel.close_hint(Glyphs.Device.XBOX)
	assert_str(teclado).contains("ESC")
	assert_str(xbox).contains("B")
	assert_str(xbox).not_contains("ESC")
	assert_str(JournalPanel.close_hint(Glyphs.Device.PLAYSTATION)).not_contains("ESC")


func test_o_gesto_fecha_a_folha_aberta() -> void:
	var folha := _folha()
	assert_bool(folha.visible).is_true()
	folha._input(_tecla(KEY_ESCAPE))
	assert_bool(folha.visible).is_false()


func test_sozinha_sai_em_menos_de_um_quarto_de_minuto() -> void:
	assert_float(JournalPanel.DURA_S).is_less_equal(15.0)
	var folha := _folha()
	folha._process(JournalPanel.DURA_S + 0.1)
	assert_bool(folha.visible).is_false()


func test_a_folha_diz_como_se_fecha() -> void:
	var texto := TranslationServer.translate(JournalPanel.RODAPE)
	assert_str(String(texto)).is_not_equal(String(JournalPanel.RODAPE))
