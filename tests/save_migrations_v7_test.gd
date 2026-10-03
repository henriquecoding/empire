# tests/save_migrations_v7_test.gd — o save de antes dos monarcas (ADR 0052, UN-06).
#
# "Atualizacoes novas retiram controle de tropa, mas preservam a campanha e suas
# pessoas. Nao exigir comecar do zero" (plano §19.2). Quem comecou como Arqueiro ou
# Bardo continua com o rei oficial: o corpo de classe fica no mundo, sob IA, com o que
# levava; o controlo volta ao rei; o escudeiro passa a vinculo; o perfil e o Rei.
extends GdUnitTestSuite

const REI := 10
const ESCUDEIRO := 14
const ARQUEIRO := 20


func _v6(piloto: int = ARQUEIRO, classe: StringName = &"archer") -> Dictionary:
	var unidades := {
		&"ids": PackedInt32Array([REI, 11, ESCUDEIRO, ARQUEIRO, 30]),
		# Como o save real o guarda (Columns._base): um Array[StringName] vai como texto.
		&"data_ids": PackedStringArray(["monarch", "vagrant", "squire", "archer_hero", "squire"]),
		&"owners": PackedInt32Array([1, 1, 1, 1, 2]),
		&"states": PackedByteArray([0, 0, 0, 0, 0]),
		&"carried_coins": PackedInt32Array([6, 0, 0, 4, 0]),
	}
	var roster := {&"starting_class": classe, &"arrived": PackedStringArray(), &"storages": {}}
	return {
		&"save_version": 6,
		&"state": {},
		&"world": {&"king_id": REI, &"pilot": piloto, &"units": unidades, &"roster": roster},
	}


func test_o_controlo_volta_ao_rei_e_o_corpo_de_classe_fica_com_o_que_levava() -> void:
	var d := SaveMigrations.migrate(_v6())
	var mundo: Dictionary = d[&"world"]
	assert_int(int(mundo[&"pilot"])).is_equal(UnitSystem.NENHUM)
	var unidades: Dictionary = mundo[&"units"]
	var i := (unidades[&"ids"] as PackedInt32Array).find(ARQUEIRO)
	assert_str(String(unidades[&"data_ids"][i])).is_equal("archer_hero")
	assert_int((unidades[&"carried_coins"] as PackedInt32Array)[i]).is_equal(4)


func test_o_perfil_e_o_rei_e_a_escolha_antiga_sai_do_roster() -> void:
	var mundo: Dictionary = SaveMigrations.migrate(_v6(ARQUEIRO, &"bard"))[&"world"]
	assert_str(String(mundo[&"monarchy"][&"profile"])).is_equal("monarch")
	assert_bool((mundo[&"roster"] as Dictionary).has(&"starting_class")).is_false()


func test_o_escudeiro_do_rei_passa_a_vinculo_e_o_de_outro_reino_nao() -> void:
	var mundo: Dictionary = SaveMigrations.migrate(_v6())[&"world"]
	var vinculos: Dictionary = mundo[&"monarchy"][&"bonds"]
	assert_int(int(vinculos.get(REI, -1))).is_equal(ESCUDEIRO)
	assert_int(vinculos.size()).is_equal(1)


## Os testes de antes guardavam os data_ids como Array: a forma tambem conta.
func test_os_data_ids_em_array_tambem_dao_o_vinculo() -> void:
	var antigo := _v6()
	var nomes: Array = []
	for nome in antigo[&"world"][&"units"][&"data_ids"]:
		nomes.append(StringName(nome))
	antigo[&"world"][&"units"][&"data_ids"] = nomes
	var mundo: Dictionary = SaveMigrations.migrate(antigo)[&"world"]
	assert_int(int(mundo[&"monarchy"][&"bonds"].get(REI, -1))).is_equal(ESCUDEIRO)


func test_sem_escudeiro_vivo_nao_nasce_vinculo() -> void:
	var antigo := _v6()
	antigo[&"world"][&"units"][&"states"] = PackedByteArray([0, 0, UnitFsm.State.DEAD, 0, 0])
	var mundo: Dictionary = SaveMigrations.migrate(antigo)[&"world"]
	assert_dict(mundo[&"monarchy"][&"bonds"]).is_empty()


func test_migrar_duas_vezes_da_o_mesmo_e_o_original_nao_muda() -> void:
	var antigo := _v6()
	var uma := SaveMigrations.migrate(antigo)
	assert_int(int(antigo[&"save_version"])).is_equal(6)
	assert_int(int(antigo[&"world"][&"pilot"])).is_equal(ARQUEIRO)
	var outra := SaveMigrations.migrate(antigo)
	assert_dict(outra).is_equal(uma)
	assert_dict(SaveMigrations.migrate(uma)).is_equal(uma)


func test_o_save_migrado_carrega_com_o_rei_conduzido_e_o_escudeiro_ligado() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20261002)
	Greybox.build()
	var mundo := SimLoop.world()
	mundo.erase(&"monarchy")
	(mundo[&"roster"] as Dictionary)[&"starting_class"] = &"archer"
	var d := SaveMigrations.migrate({&"save_version": 6, &"state": {}, &"world": mundo})
	SimLoop.load_world(d[&"world"])
	assert_int(Assume.driven()).is_equal(SimLoop.king_id)
	assert_str(String(SimLoop.field.monarchy.current())).is_equal("monarch")
	assert_bool(SimLoop.field.monarchy.bonds.has(SimLoop.king_id)).is_true()
	var e := SimLoop.field.classes.squire_index(SimLoop.units, SimLoop.king_id)
	assert_int(e).is_not_equal(-1)
	assert_str(String(SimLoop.units.data_ids[e])).is_equal("squire")
	SimLoop.stop()
	SimLoop.autosave_enabled = true
