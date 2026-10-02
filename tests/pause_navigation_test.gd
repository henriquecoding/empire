# Regressao do menu cortado: paginas separadas e Escape sem retomar por engano.
extends GdUnitTestSuite


func _menu() -> PauseMenu:
	var menu: PauseMenu = auto_free(PauseMenu.new())
	add_child(menu)
	menu.open(false)
	return menu


func test_as_opcoes_nao_ocupam_a_pausa_principal() -> void:
	var menu := _menu()
	assert_bool(menu._opcoes.is_visible_in_tree()).is_false()
	assert_object(menu.get_viewport().gui_get_focus_owner()).is_same(menu._retomar)


func test_voltar_das_opcoes_mantem_a_partida_pausada() -> void:
	SimLoop.set_paused(true)
	var menu := _menu()
	menu.show_options()
	assert_bool(menu._opcoes.is_visible_in_tree()).is_true()
	assert_bool(menu._retomar.is_visible_in_tree()).is_false()
	menu.back()
	assert_bool(SimLoop.running()).is_false()
	assert_bool(menu._opcoes.is_visible_in_tree()).is_false()
	assert_object(menu.get_viewport().gui_get_focus_owner()).is_same(menu._options_button)


func test_a_confirmacao_isola_as_accoes_da_pausa() -> void:
	var menu := _menu()
	menu._zero._abrir.pressed.emit()
	assert_bool(menu._retomar.is_visible_in_tree()).is_false()
	assert_bool(menu._opcoes.is_visible_in_tree()).is_false()
	assert_object(menu.get_viewport().gui_get_focus_owner()).is_same(menu._zero._cancelar)
	menu.back()
	assert_bool(menu._retomar.is_visible_in_tree()).is_true()
	assert_bool(menu._zero._pergunta.is_visible_in_tree()).is_false()
	assert_object(menu.get_viewport().gui_get_focus_owner()).is_same(menu._zero._abrir)


func test_escape_volta_das_opcoes_antes_de_retomar() -> void:
	SimLoop.set_paused(true)
	var menu := _menu()
	menu.show_options()
	var escape := InputEventAction.new()
	escape.action = &"pause"
	escape.pressed = true
	menu._input(escape)
	assert_bool(menu._opcoes.is_visible_in_tree()).is_false()
	assert_bool(SimLoop.running()).is_false()


func test_opcoes_comecam_na_acessibilidade_e_tem_jogo_separado() -> void:
	var menu := _menu()
	menu.show_options()
	assert_bool(menu._opcoes._tremor.is_visible_in_tree()).is_true()
	assert_bool(menu._opcoes._dia.is_visible_in_tree()).is_false()
	menu._opcoes.show_tab(1)
	assert_bool(menu._opcoes._tremor.is_visible_in_tree()).is_false()
	assert_bool(menu._opcoes._dia.is_visible_in_tree()).is_true()


func test_o_recomeco_nao_expoe_a_pergunta_antes_de_ser_pedido() -> void:
	var menu := _menu()
	assert_bool(menu._zero._pergunta.is_visible_in_tree()).is_false()
	assert_bool(menu._zero._abrir.is_visible_in_tree()).is_true()


func test_a_pausa_expande_a_janela_e_devolve_o_enquadramento_ao_jogo() -> void:
	var window := get_tree().root
	var original := window.content_scale_aspect
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	var menu := _menu()
	assert_int(window.content_scale_aspect).is_equal(Window.CONTENT_SCALE_ASPECT_EXPAND)
	menu._fechar()
	assert_int(window.content_scale_aspect).is_equal(Window.CONTENT_SCALE_ASPECT_KEEP)
	window.content_scale_aspect = original


func test_o_rato_muda_o_foco_sem_tirar_a_protecao_do_cancelar() -> void:
	var menu := _menu()
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(1, 0)
	menu._options_button.gui_input.emit(motion)
	assert_object(menu.get_viewport().gui_get_focus_owner()).is_same(menu._options_button)
	menu._zero._abrir.pressed.emit()
	menu._zero._apagar.gui_input.emit(InputEventMouseMotion.new())
	assert_object(menu.get_viewport().gui_get_focus_owner()).is_same(menu._zero._cancelar)
