# tests/starting_classes_test.gd — comecar como um dos tres monarcas (§08; ADR 0052, UN-04).
#
# O dono, a 02/10/2026: comecar como o Rei, a Imperatriz Nia ou o Imperador Arqueiro. "Um
# monarca selecionado e sua companhia; governo correto" (T01 do plano): o escolhido e o
# titular da coroa, com o companheiro dele ligado por id, e nao ha outro rei escondido.
extends GdUnitTestSuite

const PASSO := 1.0 / 30.0


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20261001)
	Greybox.build()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _dados(id: StringName) -> MonarchData:
	return Registry.entry(&"monarchs", id) as MonarchData


func _corpo(unit_id: int) -> StringName:
	return SimLoop.units.data_ids[SimLoop.units.index_of(unit_id)]


func test_cada_monarca_e_o_titular_sem_companhia_gratis_ou_rei_escondido() -> void:
	for id: StringName in [&"monarch", &"nia", &"archer_emperor"]:
		SimLoop.stop()
		SimLoop.start(20261001)
		Greybox.build()
		var antes := SimLoop.units.count()
		assert_bool(MonarchWatch.begin(id)).is_true()
		assert_int(SimLoop.units.count()).is_equal(antes)
		assert_int(Assume.driven()).is_equal(SimLoop.king_id)
		assert_str(String(_corpo(SimLoop.king_id))).is_equal(String(_dados(id).unit))
		var c := SimLoop.field.monarchy.companion_index(SimLoop.units, SimLoop.king_id)
		assert_int(c).is_equal(-1)
		var reis := 0
		for i in SimLoop.units.count():
			var dados := Registry.entry(&"units", SimLoop.units.data_ids[i]) as UnitData
			if dados.tags.has(&"king"):
				reis += 1
		assert_int(reis).is_equal(1)


func test_todos_comecam_com_as_moedas_do_inicio_e_gerem() -> void:
	MonarchWatch.begin(&"nia")
	var r := SimLoop.units.index_of(SimLoop.king_id)
	assert_int(SimLoop.units.carried_coins[r]).is_equal(SimFactory.curve().start_coins)
	assert_bool(Assume.king()).is_true()


func test_uma_escolha_so_e_um_perfil_que_nao_existe_nao_escolhe() -> void:
	assert_bool(MonarchWatch.begin(&"diplomat")).is_false()
	assert_bool(MonarchWatch.begin(&"nia")).is_true()
	assert_bool(MonarchWatch.begin(&"archer_emperor")).is_false()
	assert_str(String(_corpo(SimLoop.king_id))).is_equal("nia")


func test_so_o_rei_tem_a_aura_e_o_escudeiro_do_escudo() -> void:
	MonarchWatch.begin(&"monarch")
	SimLoop.step(PASSO)
	assert_bool(SimLoop.field.classes.active).is_true()
	assert_int(SimLoop.field.classes.squire_index(SimLoop.units)).is_equal(-1)
	preload("res://tests/support/sede.gd").companhia()
	assert_int(SimLoop.field.classes.squire_index(SimLoop.units)).is_not_equal(-1)
	SimLoop.stop()
	SimLoop.start(20261001)
	Greybox.build()
	MonarchWatch.begin(&"nia")
	SimLoop.step(PASSO)
	assert_bool(SimLoop.field.classes.active).is_false()
	assert_int(SimLoop.field.classes.squire_index(SimLoop.units)).is_equal(-1)


func test_o_arqueiro_comeca_com_as_flechas_iniciais_e_a_aljava_pessoal() -> void:
	MonarchWatch.begin(&"archer_emperor")
	var r := SimLoop.units.index_of(SimLoop.king_id)
	var corpo := Registry.entry(&"units", &"archer_emperor") as UnitData
	var iniciais := int(corpo.ability_params[&"start_ammo"])
	assert_int(SimLoop.field.supply.left(SimLoop.units, r, corpo)).is_equal(iniciais)
	assert_bool(SimLoop.field.supply.personal.has(SimLoop.king_id)).is_true()


func test_a_escolha_persiste_no_save_sem_duplicar_ninguem() -> void:
	MonarchWatch.begin(&"nia")
	var count := SimLoop.units.count()
	var mundo := SimLoop.world()
	SimLoop.load_world(mundo)
	assert_str(String(SimLoop.field.monarchy.profile)).is_equal("nia")
	assert_int(SimLoop.units.count()).is_equal(count)
	var c := SimLoop.field.monarchy.companion_index(SimLoop.units, SimLoop.king_id)
	assert_int(c).is_equal(-1)
	assert_bool(MonarchWatch.begin(&"monarch")).is_false()
