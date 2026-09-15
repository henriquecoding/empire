# tests/save_service_test.gd — o canal da ADR 0007, ida e volta, e o ataque.
#
# "Fazer o save cedo e o que o torna trivial para sempre. E e onde esta a unica
# falha de seguranca que a revisao encontrou" (F0-13).
extends GdUnitTestSuite

const SEMENTE := 20260915


func _estado(dia: int = 1) -> GameState:
	var e := GameState.new()
	e.seed = SEMENTE
	e.day = dia
	e.tick = dia * 100
	e.clock_elapsed = 42.5
	e.next_id = 7
	return e


func before_test() -> void:
	for slot in SaveService.SLOTS:
		SaveService.delete_slot(slot)


func after_test() -> void:
	for slot in SaveService.SLOTS:
		SaveService.delete_slot(slot)
	# Um temporario que sobreviva a um teste esconde um rename que nao aconteceu.
	for slot in SaveService.SLOTS:
		var tmp := SaveService.caminho(slot) + ".tmp"
		if FileAccess.file_exists(tmp):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))


func test_gravar_e_carregar_um_estado_vazio() -> void:
	var vazio := GameState.new()
	assert_bool(SaveService.save(0, vazio)).is_true()

	var lido := SaveService.restore(0)
	assert_object(lido).is_not_null()
	assert_int(lido.day).is_equal(vazio.day)
	assert_int(lido.tick).is_equal(vazio.tick)
	assert_int(lido.next_id).is_equal(vazio.next_id)


func test_ida_e_volta_preserva_os_campos_e_os_tipos() -> void:
	var antes := _estado(9)
	SaveService.save(0, antes)
	var depois := SaveService.restore(0)

	assert_int(depois.seed).is_equal(antes.seed)
	assert_int(depois.day).is_equal(antes.day)
	assert_int(depois.tick).is_equal(antes.tick)
	assert_int(depois.next_id).is_equal(antes.next_id)
	# int contra float sobrevive: e a razao de nao ser JSON (ADR 0007).
	assert_float(depois.clock_elapsed).is_equal_approx(antes.clock_elapsed, 0.0001)
	assert_int(typeof(depois.clock_elapsed)).is_equal(TYPE_FLOAT)


func test_o_save_so_contem_tipos_base() -> void:
	SaveService.save(0, _estado(3), {"rot": 12345})

	var f := FileAccess.open(SaveService.caminho(0), FileAccess.READ)
	var cru: Variant = f.get_var(false)
	f.close()

	assert_int(typeof(cru)).is_equal(TYPE_DICTIONARY)
	for chave in cru as Dictionary:
		var valor: Variant = (cru as Dictionary)[chave]
		assert_int(typeof(valor)).is_not_equal(TYPE_OBJECT)


func test_um_save_com_um_objeto_la_dentro_nao_o_executa() -> void:
	# O ataque que a ADR 0007 existe para impedir, escrito ao contrario: grava-se
	# um save COM allow_objects ligado e le-se pelo canal do jogo. O que sai tem
	# de ser um save recusado, nao um Object instanciado.
	var malicioso := {
		&"save_version": SaveService.SAVE_VERSION,
		&"state": {&"day": 1},
		&"carga": Resource.new(),
	}
	var f := FileAccess.open(SaveService.caminho(0), FileAccess.WRITE)
	f.store_var(malicioso, true)  # true DE PROPOSITO: e o ficheiro do atacante
	f.close()

	# As duas metades da ADR 0007, medidas. Com allow_objects desligado a
	# descodificacao falha INTEIRA e sai Nil — o SaveService ve um ficheiro que
	# nao e um dicionario e recusa-o.
	f = FileAccess.open(SaveService.caminho(0), FileAccess.READ)
	var seguro: Variant = f.get_var(false)
	f.close()
	assert_int(typeof(seguro)).is_equal(TYPE_NIL)

	# Com allow_objects ligado sairia o dicionario com um Object la dentro. E
	# este o caminho que nenhuma linha de src/core/save_service.gd pode tomar,
	# e e o G6 que o impede de la voltar.
	f = FileAccess.open(SaveService.caminho(0), FileAccess.READ)
	var perigoso: Variant = f.get_var(true)
	f.close()
	assert_int(typeof((perigoso as Dictionary)[&"carga"])).is_equal(TYPE_OBJECT)

	assert_object(SaveService.restore(0)).is_null()


func test_a_rotacao_usa_os_tres_slots_e_volta_ao_principio() -> void:
	var usados: Array[int] = []
	for dia in range(1, SaveService.SLOTS * 2 + 1):
		usados.append(SaveService.autosave(_estado(dia)))

	assert_array(usados).is_equal([0, 1, 2, 0, 1, 2])
	# Depois de seis autosaves os tres slots existem e cada um tem o dia certo.
	assert_int(SaveService.restore(0).day).is_equal(4)
	assert_int(SaveService.restore(1).day).is_equal(5)
	assert_int(SaveService.restore(2).day).is_equal(6)


func test_a_escrita_e_atomica_nao_fica_temporario_para_tras() -> void:
	SaveService.save(1, _estado(2))
	assert_bool(FileAccess.file_exists(SaveService.caminho(1))).is_true()
	assert_bool(FileAccess.file_exists(SaveService.caminho(1) + ".tmp")).is_false()


func test_um_slot_fora_do_intervalo_e_recusado_e_nao_escreve_nada() -> void:
	assert_bool(SaveService.save(SaveService.SLOTS, _estado())).is_false()
	assert_bool(SaveService.save(-1, _estado())).is_false()
	assert_object(SaveService.restore(SaveService.SLOTS)).is_null()


func test_um_slot_que_nao_existe_devolve_null_em_vez_de_rebentar() -> void:
	assert_bool(SaveService.has_slot(0)).is_false()
	assert_object(SaveService.restore(0)).is_null()
	assert_dict(SaveService.restore_rng(0)).is_empty()


func test_lixo_no_ficheiro_e_recusado() -> void:
	var f := FileAccess.open(SaveService.caminho(0), FileAccess.WRITE)
	f.store_string("isto nao e um save")
	f.close()

	assert_object(SaveService.restore(0)).is_null()


func test_um_dicionario_sem_save_version_nao_e_um_save_deste_jogo() -> void:
	var f := FileAccess.open(SaveService.caminho(0), FileAccess.WRITE)
	f.store_var({&"state": {&"day": 3}}, false)
	f.close()

	assert_object(SaveService.restore(0)).is_null()


func test_campos_desconhecidos_ignoram_se_em_vez_de_recusar() -> void:
	# §62: ler um save de uma versao futura tem de degradar, nao rebentar.
	var futuro := {
		&"save_version": SaveService.SAVE_VERSION + 1,
		&"state": {&"day": 12, &"mecanica_que_ainda_nao_existe": [1, 2, 3]},
		&"campo_novo": "o que vier",
	}
	var f := FileAccess.open(SaveService.caminho(0), FileAccess.WRITE)
	f.store_var(futuro, false)
	f.close()

	var lido := SaveService.restore(0)
	assert_object(lido).is_not_null()
	assert_int(lido.day).is_equal(12)


func test_o_estado_dos_fluxos_de_rng_faz_a_viagem() -> void:
	RngService.configure(SEMENTE)
	for _i in 50:
		RngService.int_range(&"rot", 0, 100)
	var meio := RngService.snapshot()

	SaveService.save(0, _estado(9), meio)
	var voltou := SaveService.restore_rng(0)

	assert_int(voltou.size()).is_equal(meio.size())
	for chave in meio:
		assert_int(voltou[chave]).is_equal(meio[chave])


func test_o_resumo_diz_o_que_o_menu_precisa_sem_carregar_o_jogo() -> void:
	SaveService.save(1, _estado(9))
	var resumos := SaveService.summaries()

	assert_int(resumos.size()).is_equal(SaveService.SLOTS)
	assert_bool(resumos[0][&"exists"]).is_false()
	assert_bool(resumos[1][&"exists"]).is_true()
	assert_int(resumos[1][&"day"]).is_equal(9)
	assert_int(resumos[1][&"seed"]).is_equal(SEMENTE)
	assert_bool(resumos[1][&"created_utc"] > 0).is_true()


func test_take_id_e_unico_e_monotonico() -> void:
	var estado := GameState.new()
	var ids: Array[int] = []
	for _i in 10:
		ids.append(estado.take_id())

	assert_array(ids).is_equal([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
	SaveService.save(0, estado)
	# O contador sobrevive ao save: senao, carregar um jogo reciclava ids.
	assert_int(SaveService.restore(0).next_id).is_equal(11)
