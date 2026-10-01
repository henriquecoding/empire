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
	picker.cards[2].pressed.emit()
	assert_str(String(picker.selected)).is_equal("bard")
	assert_bool(picker.cards[2].button_pressed).is_true()
	assert_bool(picker.cards[0].button_pressed).is_false()
	assert_array(chosen).is_empty()
	assert_str(picker.start_button.text).contains(tr(&"CLASS_BARD"))
	picker.begin()
	assert_array(chosen).contains(["bard"])


func test_as_tres_classes_explicam_a_base_a_evolucao_e_os_controlos() -> void:
	var picker: ClassSelection = auto_free(ClassSelection.new())
	add_child(picker)
	for id in Roster.STARTERS:
		picker.select(id)
		for label in [picker._base, picker._evolved, picker._controls]:
			assert_str(label.text).is_not_empty()
			assert_str(label.text).not_contains("CLASS_")
	picker.select(&"diplomat")
	assert_str(String(picker.selected)).is_equal("bard")


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
	picker.select(&"archer")
	var pending := SimLoop.intents.pending()
	Input.action_press(&"verb_drop")  # A/espaco confirmam, mas nao largam uma moeda
	picker.begin()
	(game.get_node(^"Entrada") as InputRouter)._process(0.05)
	assert_int(SimLoop.intents.pending()).is_equal(pending)
	assert_bool(ClassSelection.active).is_false()
	assert_bool(SimLoop.running()).is_true()
	var i := SimLoop.units.index_of(Assume.driven())
	assert_str(String(SimLoop.units.data_ids[i])).is_equal("archer_hero")
	assert_str(String(SimLoop.field.roster.starting_class)).is_equal("archer")
	SimLoop.stop()
