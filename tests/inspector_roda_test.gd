# UX-11: a roda nao abre o diagnostico; F3 conserva o inspetor separado.
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


func test_o_y_nao_abre_o_diagnostico() -> void:
	var painel: Inspector = auto_free(Inspector.new())
	add_child(painel)
	for _gesto in 2:
		painel._unhandled_input(_y(true))
		assert_bool(painel.visible).is_false()
		painel._unhandled_input(_y(false))
		assert_bool(painel.visible).is_false()


func test_o_diagnostico_so_alterna_com_f3() -> void:
	var painel: Inspector = auto_free(Inspector.new())
	add_child(painel)
	var key := _tab()
	key.physical_keycode = KEY_F3
	painel._unhandled_input(key)
	assert_bool(painel.visible).is_true()
	painel._unhandled_input(key)
	assert_bool(painel.visible).is_false()
