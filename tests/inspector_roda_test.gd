# tests/inspector_roda_test.gd — o painel da roda no comando e manter e largar
# (§24, Q-148; revisao do PR #44). No teclado o Tab continua a alternar (Q-067).
extends GdUnitTestSuite

const BOTAO_Y := 3


func _y(premido: bool) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = BOTAO_Y as JoyButton
	e.pressed = premido
	return e


func _tab() -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = KEY_TAB
	e.pressed = true
	return e


func test_o_y_abre_ao_manter_e_fecha_ao_largar_em_cada_gesto() -> void:
	var painel: Inspector = auto_free(Inspector.new())
	add_child(painel)
	for _gesto in 2:
		painel._unhandled_input(_y(true))
		assert_bool(painel.visible).is_true()
		painel._unhandled_input(_y(false))
		assert_bool(painel.visible).is_false()


func test_o_tab_continua_a_alternar() -> void:
	var painel: Inspector = auto_free(Inspector.new())
	add_child(painel)
	painel._unhandled_input(_tab())
	assert_bool(painel.visible).is_true()
	painel._unhandled_input(_tab())
	assert_bool(painel.visible).is_false()
