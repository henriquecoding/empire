# tests/save_migrations_test.gd — uma migracao por versao (§62, ADR 0007; Q-091).
extends GdUnitTestSuite


func _v1() -> Dictionary:
	return {
		&"save_version": 1,
		&"state": {&"day": 4},
		&"world":
		{
			&"hunting": {&"day": 4, &"rabbits": [10.0, 20.0], &"pending": [[30.0]]},
			&"succession": {&"days": 2},
			&"upkeep": {&"owed": 0.5},
			&"classes": {&"phase": 1},
			&"torch": {&"torches": 2, &"burning": 0.0},
		},
	}


func test_um_save_v1_sobe_a_versao_de_agora() -> void:
	var d := SaveMigrations.migrate(_v1())
	assert_int(int(d[&"save_version"])).is_equal(SaveMigrations.CURRENT)
	assert_float(float(d[&"state"][&"day_seconds"])).is_equal(0.0)
	var mundo: Dictionary = d[&"world"]
	assert_bool(mundo[&"hunting"].has(&"pending")).is_false()
	assert_array(mundo[&"hunting"][&"rabbits"]).is_empty()
	assert_dict(mundo[&"realm"]).is_empty()
	assert_bool(mundo[&"succession"][&"declined"]).is_false()
	assert_int(int(mundo[&"succession"][&"days"])).is_equal(2)
	assert_dict(mundo[&"upkeep"][&"resting"]).is_empty()


func test_os_archotes_passam_para_o_cinto_do_rei() -> void:
	# Q-153: os archotes deixaram de ser do archote e passaram a ser do armazenamento.
	var mundo: Dictionary = SaveMigrations.migrate(_v1())[&"world"]
	var cinto: Dictionary = mundo[&"classes"][&"storage"]
	assert_str(String(cinto[&"kind"])).is_equal("royal_belt")
	assert_int(int(cinto[&"items"][&"torch"])).is_equal(2)
	assert_bool(mundo[&"torch"].has(&"torches")).is_false()


func test_a_migracao_nao_mexe_no_dicionario_de_entrada() -> void:
	var v1 := _v1()
	SaveMigrations.migrate(v1)
	assert_int(int(v1[&"save_version"])).is_equal(1)
	assert_bool(v1[&"world"][&"hunting"].has(&"pending")).is_true()


func test_um_save_de_agora_nao_muda_e_um_do_futuro_nao_se_toca() -> void:
	var agora := {&"save_version": SaveMigrations.CURRENT, &"state": {&"day": 1}}
	assert_dict(SaveMigrations.migrate(agora)).is_equal(agora)
	var futuro := {&"save_version": SaveMigrations.CURRENT + 1, &"state": {}}
	assert_dict(SaveMigrations.migrate(futuro)).is_equal(futuro)


func test_o_save_grava_a_versao_de_agora() -> void:
	assert_int(SaveService.SAVE_VERSION).is_equal(SaveMigrations.CURRENT)
