# tests/rng_service_test.gd — a promessa da semente (§42), guardada por teste.
#
# "test_seed_reproduz passa trivialmente agora e protege o projeto durante dois
# anos" (F0-12). E esse o ponto: hoje nao ha consumidores, e e exatamente por
# isso que e barato escrever isto agora.
extends GdUnitTestSuite

const SEMENTE := 20260915
const OUTRA_SEMENTE := 20260916
const AMOSTRAS := 200


func _sequencia(fluxo: StringName, n: int) -> Array[int]:
	var saida: Array[int] = []
	for _i in n:
		saida.append(RngService.int_range(fluxo, 0, 1000000))
	return saida


func after_test() -> void:
	# Cada teste semeia o que precisa; deixar o servico semeado polui o seguinte.
	RngService.configure(SEMENTE)


func test_a_mesma_semente_reproduz_a_mesma_sequencia() -> void:
	RngService.configure(SEMENTE)
	var primeira := _sequencia(&"rot", AMOSTRAS)

	RngService.configure(SEMENTE)
	var segunda := _sequencia(&"rot", AMOSTRAS)

	assert_array(segunda).is_equal(primeira)


func test_sementes_diferentes_dao_sequencias_diferentes() -> void:
	RngService.configure(SEMENTE)
	var primeira := _sequencia(&"rot", AMOSTRAS)

	RngService.configure(OUTRA_SEMENTE)
	var segunda := _sequencia(&"rot", AMOSTRAS)

	assert_array(segunda).is_not_equal(primeira)


func test_os_fluxos_sao_independentes_entre_si() -> void:
	# O arqueiro falhar um tiro nao pode mudar a criatura que a Podridao invoca.
	RngService.configure(SEMENTE)
	var rot_sozinho := _sequencia(&"rot", AMOSTRAS)

	RngService.configure(SEMENTE)
	_sequencia(&"combat", AMOSTRAS)  # o combate consome primeiro
	var rot_depois := _sequencia(&"rot", AMOSTRAS)

	assert_array(rot_depois).is_equal(rot_sozinho)


func test_a_mesma_semente_da_fluxos_diferentes_entre_si() -> void:
	RngService.configure(SEMENTE)
	var mundo := _sequencia(&"world", AMOSTRAS)
	RngService.configure(SEMENTE)
	var combate := _sequencia(&"combat", AMOSTRAS)

	assert_array(combate).is_not_equal(mundo)


func test_o_snapshot_guarda_o_estado_e_nao_a_semente() -> void:
	RngService.configure(SEMENTE)
	_sequencia(&"rot", AMOSTRAS)  # gasta-se meia noite
	var meio := RngService.snapshot()
	var depois_do_save := _sequencia(&"rot", AMOSTRAS)

	# Recomecar pela semente NAO daria isto — daria a noite desde o principio.
	RngService.configure(SEMENTE)
	RngService.restore(meio)
	assert_array(_sequencia(&"rot", AMOSTRAS)).is_equal(depois_do_save)


func test_reconfigurar_pela_semente_volta_ao_principio() -> void:
	# O contraponto do teste anterior: e a diferenca que faz o save ter de
	# guardar o estado. Sem ela, "restaurar" e so "recomecar".
	RngService.configure(SEMENTE)
	var inicio := _sequencia(&"rot", AMOSTRAS)
	_sequencia(&"rot", AMOSTRAS)

	RngService.configure(SEMENTE)
	assert_array(_sequencia(&"rot", AMOSTRAS)).is_equal(inicio)


func test_o_snapshot_so_leva_os_cinco_deterministas() -> void:
	RngService.configure(SEMENTE)
	var estados := RngService.snapshot()

	assert_int(estados.size()).is_equal(RngService.DETERMINISTAS.size())
	for fluxo in RngService.DETERMINISTAS:
		assert_bool(estados.has(String(fluxo))).is_true()
		assert_int(typeof(estados[String(fluxo)])).is_equal(TYPE_INT)
	# O visual e livre: entrar no save quebrava a promessa de reproducao.
	assert_bool(estados.has(String(RngService.VISUAL))).is_false()


func test_restaurar_um_snapshot_incompleto_degrada_em_vez_de_rebentar() -> void:
	# §62: campos desconhecidos ou em falta nao sao erro — um save de outra
	# versao tem de ler.
	RngService.configure(SEMENTE)
	var esperado := _sequencia(&"combat", AMOSTRAS)

	RngService.configure(SEMENTE)
	RngService.restore({"rot": 12345, "fluxo_que_nao_existe": 7})

	assert_array(_sequencia(&"combat", AMOSTRAS)).is_equal(esperado)


func test_o_fluxo_visual_existe_e_nao_e_determinista() -> void:
	RngService.configure(SEMENTE)
	var primeira := _sequencia(RngService.VISUAL, AMOSTRAS)
	RngService.configure(SEMENTE)
	var segunda := _sequencia(RngService.VISUAL, AMOSTRAS)

	assert_array(segunda).is_not_equal(primeira)


func test_escolher_e_determinista_e_aceita_lista_vazia() -> void:
	RngService.configure(SEMENTE)
	var escolhas: Array[String] = []
	for _i in AMOSTRAS:
		escolhas.append(RngService.escolher(&"ai", ["a", "b", "c"]))

	RngService.configure(SEMENTE)
	var repetidas: Array[String] = []
	for _i in AMOSTRAS:
		repetidas.append(RngService.escolher(&"ai", ["a", "b", "c"]))

	assert_array(repetidas).is_equal(escolhas)
	assert_object(RngService.escolher(&"ai", [])).is_null()


func test_a_semente_do_mundo_fica_visivel_para_o_ecra_de_pausa() -> void:
	RngService.configure(SEMENTE)
	assert_int(RngService.world_seed()).is_equal(SEMENTE)
