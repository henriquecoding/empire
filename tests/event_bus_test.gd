# tests/event_bus_test.gd — o portao G3 (§64): o catalogo da §46 e fechado.
#
# A lista de sinais NAO esta escrita aqui. E lida de docs/design/46-*.md, que e
# a fonte canonica, pela mesma razao que o indice do dossie deriva das fontes em
# vez de alguem se lembrar dele: uma lista repetida a mao diverge, e diverge em
# silencio porque uma lista desatualizada nao da erro.
extends GdUnitTestSuite

const CATALOGO := "res://docs/design/46-o-catalogo-completo.md"


## Os nomes de sinal da primeira coluna da tabela da §46.
func _sinais_do_catalogo() -> PackedStringArray:
	var re := RegEx.create_from_string("^[a-z][a-z0-9_]+$")
	var nomes := PackedStringArray()
	for linha in FileAccess.get_file_as_string(CATALOGO).split("\n"):
		if not linha.begins_with("|"):
			continue
		var celula := linha.split("|")[1].strip_edges()
		if re.search(celula) != null:
			nomes.append(celula)
	return nomes


func _sinais_do_event_bus() -> PackedStringArray:
	var nomes := PackedStringArray()
	for s in EventBus.get_signal_list():
		nomes.append(s["name"])
	return nomes


func test_o_event_bus_declara_todos_os_sinais_do_catalogo() -> void:
	var em_falta: Array[String] = []
	for nome in _sinais_do_catalogo():
		if not EventBus.has_signal(nome):
			em_falta.append(nome)
	var porque := "sinais da §46 que o EventBus nao declara: %s" % ", ".join(em_falta)
	assert_array(em_falta).override_failure_message(porque).is_empty()


func test_o_catalogo_e_fechado_nao_ha_sinais_inventados() -> void:
	# Q-035: o §30 declarava treasury_changed, creature_requested e outros que a
	# §46 nao tem. A §46 manda (§39) — e este teste e quem o garante.
	var permitidos := _sinais_do_catalogo()
	var herdados := PackedStringArray()  # os que o proprio Node traz
	var sonda: Node = auto_free(Node.new())
	for s in sonda.get_signal_list():
		herdados.append(s["name"])

	var a_mais: Array[String] = []
	for nome in _sinais_do_event_bus():
		if nome not in permitidos and nome not in herdados:
			a_mais.append(nome)
	var porque := "sinais fora do catalogo da §46: %s" % ", ".join(a_mais)
	assert_array(a_mais).override_failure_message(porque).is_empty()


func test_sao_sessenta_e_um() -> void:
	# O numero esta escrito na §46 em prosa; se um dia a tabela crescer, e aqui
	# que se descobre — e a prosa tem de mudar no mesmo commit.
	assert_int(_sinais_do_catalogo().size()).is_equal(61)


func test_enfileirar_nao_emite_so_o_flush_emite() -> void:
	EventBus.reset()
	var vistos: Array[int] = []
	var ouvinte := func(dia: int) -> void: vistos.append(dia)
	EventBus.day_started.connect(ouvinte)

	EventBus.queue(&"day_started", [7])
	assert_array(vistos).override_failure_message("§43 passo 11: emitiu durante o tick").is_empty()
	assert_int(EventBus.pending()).is_equal(1)

	EventBus.flush()
	assert_array(vistos).is_equal([7])
	assert_int(EventBus.pending()).is_equal(0)

	EventBus.day_started.disconnect(ouvinte)


func test_a_ordem_de_entrega_e_a_ordem_de_chegada() -> void:
	EventBus.reset()
	var vistos: Array[int] = []
	var ouvinte := func(dia: int) -> void: vistos.append(dia)
	EventBus.day_started.connect(ouvinte)

	for dia in [3, 1, 2]:
		EventBus.queue(&"day_started", [dia])
	EventBus.flush()

	assert_array(vistos).is_equal([3, 1, 2])
	EventBus.day_started.disconnect(ouvinte)


func test_o_que_um_ouvinte_enfileira_fica_para_o_tick_seguinte() -> void:
	EventBus.reset()
	var ouvinte := func(_dia: int) -> void: EventBus.queue(&"dusk_fell", [1])
	EventBus.day_started.connect(ouvinte)

	EventBus.queue(&"day_started", [1])
	EventBus.flush()

	# Se a fila nao fosse trocada antes de emitir, o dusk_fell saia no mesmo
	# flush — e um ouvinte que se realimente prendia o jogo num ciclo infinito.
	assert_int(EventBus.pending()).is_equal(1)
	EventBus.day_started.disconnect(ouvinte)


func test_a_historia_guarda_os_ultimos_seiscentos() -> void:
	EventBus.reset()
	for i in EventBus.EVENT_LOG_SIZE + 10:
		EventBus.queue(&"dawn_broke", [i])
	EventBus.flush()

	var historia := EventBus.history()
	assert_int(historia.size()).is_equal(EventBus.EVENT_LOG_SIZE)
	# O mais antigo caiu: a janela e dos ULTIMOS, nao dos primeiros.
	assert_int(historia[0][1][0]).is_equal(10)
	assert_int(historia[-1][1][0]).is_equal(EventBus.EVENT_LOG_SIZE + 9)
	EventBus.reset()
