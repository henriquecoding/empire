# tests/estatuas_test.gd — o que so se sabe fazer depois de achar (§17, Q-016).
#
# O dono: "mecanicas e habilidades que so sao descobertas e podem ser usadas se o
# jogador encontrou explorando". Cada estatua do secrets.csv guarda uma coisa, e
# enquanto nao for achada essa coisa nao existe no teu jogo.
extends GdUnitTestSuite

const Sede := preload("res://tests/support/sede.gd")

const SEMENTE := 20260915


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(SEMENTE)
	Greybox.build()
	Sede.erguer()  # o castelo de antes e a Fortaleza (ADR 0059)


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func test_cada_estatua_guarda_uma_coisa_e_so_uma() -> void:
	var gates := RulesFactory.discovery_gates()
	assert_str(String(gates[&"forge"])).is_equal("buried_statue")
	assert_str(String(gates[&"sacrifice"])).is_equal("statue_offering")
	assert_str(String(gates[&"passage_seal"])).is_equal("statue_seal")
	assert_int(gates.size()).is_equal(3)


func test_o_que_nenhuma_estatua_guarda_sabe_se_desde_o_principio() -> void:
	# O nucleo do jogo nunca fica atras de uma estatua.
	for chave in [&"stakes", &"farm", &"archer_tower", &"training_house"]:
		assert_bool(Discoveries.known(SimLoop.state, chave)).is_true()


func test_sem_a_achar_a_forja_nao_aceita_moeda_e_achada_aceita() -> void:
	var forja := BuildSlot.new()
	forja.kind = &"forge"
	forja.costs = PackedInt32Array([12])
	forja.x = SimLoop.core_x + 500.0
	for vaga in SimLoop.builds.slots:
		if vaga.two_paths():
			vaga.raise_to(3)
		if vaga.kind == &"training_house":
			vaga.raise_to(1)
	assert_bool(SimLoop.builds.can_climb(forja, SimLoop.state, null)).is_false()
	SimLoop.state.found.append("buried_statue")
	assert_bool(SimLoop.builds.can_climb(forja, SimLoop.state, null)).is_true()


func test_acha_se_indo_la_com_o_rei() -> void:
	var k := SimLoop.secrets.ids.find(&"statue_offering")
	assert_int(k).is_greater_equal(0)
	assert_bool(Discoveries.known(SimLoop.state, &"sacrifice")).is_false()
	var rei := SimLoop.units.index_of(SimLoop.king_id)
	SimLoop.units.xs[rei] = SimLoop.secrets.xs[k]
	SimLoop.secrets.tick(SimLoop.units, SimLoop.king_id, SimLoop.state)
	assert_bool(Discoveries.known(SimLoop.state, &"sacrifice")).is_true()


func test_as_estatuas_ficam_fora_das_muralhas_de_fora() -> void:
	# Acha-las custa sair: e o risco que faz disto exploracao e nao um menu.
	for id in [&"statue_offering", &"statue_seal"]:
		var k := SimLoop.secrets.ids.find(id)
		var longe := absf(SimLoop.secrets.xs[k] - SimLoop.core_x)
		assert_float(longe).is_greater(absf(Greybox.MUROS_X[0]))


func test_o_que_se_achou_vai_com_o_legado() -> void:
	SimLoop.state.found.append("statue_seal")
	var d := Legacy.of(SimLoop.state, SimLoop.builds, 0.0)
	assert_array(Array(d[Legacy.ACHADOS])).contains(["statue_seal"])
