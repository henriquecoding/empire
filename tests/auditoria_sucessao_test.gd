extends GdUnitTestSuite


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20261007)
	Greybox.build()
	MonarchWatch.begin(&"monarch")
	WorldWorks.post(&"heir_house", SimLoop.core_x).raise_to(1)
	SimLoop.units.xs[SimLoop.units.index_of(SimLoop.king_id)] = SimLoop.core_x
	SimLoop.field.succession.days = SimFactory.curve().heir_training_days


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func test_menu_da_casa_abre_pausa_e_confirma_o_novo_imperador() -> void:
	var menu := _menu()
	assert_bool(SimLoop.running()).is_false()
	assert_bool(ClassSelection.active).is_true()
	var back := menu._layout.get_child(menu._layout.get_child_count() - 1) as Button
	assert_str(back.text).is_equal(tr(&"UI_MENU_BACK"))
	menu.select(&"nia")
	menu.begin()
	assert_str(String(MonarchWatch.data().id)).is_equal("nia")
	assert_bool(SimLoop.field.succession.ready()).is_false()
	assert_bool(SimLoop.running()).is_true()
	assert_bool(ClassSelection.active).is_false()


func test_cancelar_o_menu_preserva_o_herdeiro_e_retoma() -> void:
	var menu := _menu()
	var cancel := InputEventAction.new()
	cancel.action = &"ui_cancel"
	cancel.pressed = true
	menu._unhandled_input(cancel)
	assert_bool(SimLoop.field.succession.ready()).is_true()
	assert_str(String(MonarchWatch.data().id)).is_equal("monarch")
	assert_bool(SimLoop.running()).is_true()
	assert_bool(ClassSelection.active).is_false()


func _menu() -> ClassSelection:
	var parent: Control = auto_free(Control.new())
	add_child(parent)
	HeirMenu.open(parent)
	return parent.get_child(0) as ClassSelection


func test_troca_consome_o_herdeiro_preserva_bolsa_e_uma_coroa() -> void:
	var king := SimLoop.king_id
	var u := SimLoop.units
	var i := u.index_of(king)
	u.healths[i] = u.max_healths[i] / 2
	u.carried_coins[i] = 7
	var count := u.count()
	assert_bool(ImperialSuccession.exchange(&"archer_emperor")).is_true()
	assert_int(SimLoop.king_id).is_equal(king)
	assert_int(u.count()).is_equal(count)
	assert_int(u.carried_coins[i]).is_equal(7)
	assert_float(float(u.healths[i]) / u.max_healths[i]).is_less_equal(0.5)
	assert_bool(SimLoop.field.succession.ready()).is_false()
	assert_int(SimLoop.field.succession.recovery_nights).is_equal(5)
	assert_bool(ImperialSuccession.exchange(&"nia")).is_false()
	assert_bool(ImperialSuccession.exchange(&"missing")).is_false()
	var saved := SimLoop.world()
	SimLoop.load_world(saved)
	assert_str(String(MonarchWatch.data().id)).is_equal("archer_emperor")
	assert_int(SimLoop.field.succession.recovery_nights).is_equal(5)


func test_coroa_no_chao_ou_rei_morto_recusam_sem_consumir() -> void:
	SimLoop.field.crown_drop.down = true
	assert_bool(ImperialSuccession.exchange(&"nia")).is_false()
	assert_bool(SimLoop.field.succession.ready()).is_true()
	SimLoop.field.crown_drop.down = false
	SimLoop.units.healths[SimLoop.units.index_of(SimLoop.king_id)] = 0
	assert_bool(ImperialSuccession.exchange(&"nia")).is_false()
	assert_bool(SimLoop.field.succession.ready()).is_true()


func test_recuperacao_dos_bonus_e_flechas_pagas_nao_se_renovam_na_troca() -> void:
	assert_bool(ImperialSuccession.exchange(&"archer_emperor")).is_true()
	var field := SimLoop.field
	var u := SimLoop.units
	var i := u.index_of(SimLoop.king_id)
	var body := Registry.entry(&"units", u.data_ids[i]) as UnitData
	assert_int(field.supply.left(u, i, body)).is_zero()
	field.supply.arm(u, i, body, 3)
	assert_float(ImperialSuccession.bonus()).is_equal(SimFactory.curve().heir_boost_inheritance)
	field.succession.days = SimFactory.curve().heir_training_days
	assert_bool(ImperialSuccession.exchange(&"nia")).is_true()
	field.succession.days = SimFactory.curve().heir_training_days
	assert_bool(ImperialSuccession.exchange(&"archer_emperor")).is_true()
	assert_int(field.supply.left(u, i, body)).is_equal(3)
	field.succession.recovery_nights = 0
	MonarchWatch.sync()
	assert_float(ImperialSuccession.bonus()).is_equal(1.0)
	assert_float(field.focus.inheritance).is_equal(1.0)
