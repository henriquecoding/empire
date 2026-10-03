# tests/class_selection_test.gd — a escolha do monarca numa partida nova (§08; ADR 0052).
extends GdUnitTestSuite


func before_test() -> void:
	Registry.load_all()
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.stop()


func after_test() -> void:
	SimLoop.stop()
	Input.action_release(&"verb_drop")
	ClassSelection.release_pending = false
	SimLoop.autosave_enabled = true


func test_escolher_um_cartao_nao_comeca_antes_de_confirmar() -> void:
	var chosen := PackedStringArray()
	var picker: ClassSelection = auto_free(
		ClassSelection.new(func(id: StringName) -> void: chosen.append(String(id)))
	)
	add_child(picker)
	assert_int(picker.cards.size()).is_equal(3)
	picker.cards[1].pressed.emit()
	assert_str(String(picker.selected)).is_equal("nia")
	assert_bool(picker.cards[1].button_pressed).is_true()
	assert_bool(picker.cards[0].button_pressed).is_false()
	assert_array(chosen).is_empty()
	assert_str(picker.start_button.text).contains(tr(&"MONARCH_NIA"))
	picker.begin()
	assert_array(chosen).contains(["nia"])


## Plano §6.1: a escolha mostra a dupla — o papel, o companheiro, a base, a evolucao e os
## controlos — e nao so tres retratos. So os tres monarcas; um oficio nao e escolha.
func test_os_tres_monarcas_explicam_o_companheiro_a_base_a_evolucao_e_os_controlos() -> void:
	var picker: ClassSelection = auto_free(ClassSelection.new())
	add_child(picker)
	var ids: Array[StringName] = []
	for dados in MonarchWatch.choices():
		ids.append(dados.id)
	assert_array(ids).is_equal([&"monarch", &"nia", &"archer_emperor"])
	for id in ids:
		picker.select(id)
		for label in [picker._companion, picker._base, picker._evolved, picker._controls]:
			assert_str(label.text).is_not_empty()
			assert_str(label.text).not_contains("MONARCH_")
	picker.select(&"diplomat")
	assert_str(String(picker.selected)).is_equal("archer_emperor")


func test_o_jogo_novo_espera_sem_andar_o_tempo_e_sem_gravar_uma_escolha_vazia() -> void:
	Game._recomecar = true
	var game: Game = auto_free(load("res://scenes/game.tscn").instantiate())
	add_child(game)
	await get_tree().process_frame
	var picker := game._selector
	assert_bool(ClassSelection.active).is_true()
	assert_bool(SimLoop.running()).is_false()
	assert_bool(SavePoint.allowed()).is_false()
	var tick := SimLoop.state.tick
	await get_tree().create_timer(0.05).timeout
	assert_int(SimLoop.state.tick).is_equal(tick)
	assert_int(picker._scroll.scroll_vertical).is_zero()
	assert_bool(picker.cards[0].has_focus()).is_true()
	picker.select(&"archer_emperor")
	var pending := SimLoop.intents.pending()
	Input.action_press(&"verb_drop")  # A/espaco confirmam, mas nao largam uma moeda
	picker.begin()
	(game.get_node(^"Entrada") as InputRouter)._process(0.05)
	assert_int(SimLoop.intents.pending()).is_equal(pending)
	assert_bool(ClassSelection.active).is_false()
	assert_bool(SimLoop.running()).is_true()
	# Um so monarca, o escolhido, e e ele que se conduz: nenhum rei escondido (UN-04).
	assert_int(Assume.driven()).is_equal(SimLoop.king_id)
	var i := SimLoop.units.index_of(SimLoop.king_id)
	assert_str(String(SimLoop.units.data_ids[i])).is_equal("archer_emperor")
	assert_int(SimLoop.units.data_ids.count(&"monarch")).is_equal(0)
	assert_str(String(SimLoop.field.monarchy.profile)).is_equal("archer_emperor")
	SimLoop.stop()
