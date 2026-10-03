# tests/armazenamento_test.gd — o armazenamento de cada personagem jogavel (Q-153).
#
# O dono, no painel (29/09/2026): "Equipments faz parte do armazenamento do
# personagem, cada personagem jogavel [tem] um tipo de armazenamento que deve ser
# desenvolvido e bem feito." Os tipos e os tetos sao do storages.csv; o slot de
# arte e o `storage` do §58.
extends GdUnitTestSuite

const SEMENTE := 20260929
const ARMAZENS := &"classes/storages"


func _dados(id: StringName) -> StorageData:
	return Registry.entry(ARMAZENS, id) as StorageData


func test_cada_personagem_jogavel_tem_o_seu_armazenamento() -> void:
	var vistos := {}
	for id in Registry.ids(&"classes"):
		var classe := Registry.entry(&"classes", StringName(id)) as ClassData
		var tem := Registry.has_entry(ARMAZENS, classe.storage)
		assert_bool(tem).override_failure_message("%s: sem armazenamento" % id).is_true()
		# Um tipo por personagem: dois personagens nao partilham o mesmo.
		assert_bool(vistos.has(classe.storage)).is_false()
		vistos[classe.storage] = id
		# E o corpo dele tem onde o desenhar: a camada Equipments (§58).
		var corpo := Registry.entry(&"units", classe.base_unit) as UnitData
		assert_bool(&"storage" in corpo.layer_slots).is_true()
	assert_int(vistos.size()).is_equal(Registry.ids(ARMAZENS).size())


func test_so_quem_se_joga_traz_o_armazenamento() -> void:
	var jogaveis := {}
	for classe: ClassData in Registry.entries(&"classes"):
		jogaveis[classe.base_unit] = true
	for monarca: MonarchData in Registry.entries(&"monarchs"):  # ADR 0052
		jogaveis[monarca.unit] = true
	for tropa: UnitData in Registry.entries(&"units"):
		var traz := &"storage" in tropa.layer_slots
		var porque := "%s: storage so para quem se joga" % tropa.id
		assert_bool(traz == jogaveis.has(tropa.id)).override_failure_message(porque).is_true()


func test_as_moedas_vao_no_saco_do_corpo_e_nao_no_armazenamento() -> void:
	# O saco de moedas e de toda a gente (§02); o armazenamento e de quem se joga.
	for armazem: StorageData in Registry.entries(ARMAZENS):
		assert_bool(armazem.holds.has(&"coin")).is_false()
		assert_bool(armazem.holds.has(&"coins")).is_false()
		assert_bool(armazem.holds.is_empty()).is_false()
		assert_bool(armazem.worn in [&"hip", &"back", &"side", &"saddle"]).is_true()


func test_guarda_ate_ao_teto_e_tira_o_que_tem() -> void:
	var cinto := Storage.new(_dados(&"royal_belt"))
	assert_int(cinto.cap(Storage.ARCHOTE)).is_equal(2)
	assert_int(cinto.put(Storage.ARCHOTE, 1)).is_equal(1)
	assert_int(cinto.room(Storage.ARCHOTE)).is_equal(1)
	assert_int(cinto.put(Storage.ARCHOTE, 5)).is_equal(1)
	assert_int(cinto.count(Storage.ARCHOTE)).is_equal(2)
	assert_int(cinto.take(Storage.ARCHOTE, 3)).is_equal(2)
	assert_int(cinto.count(Storage.ARCHOTE)).is_equal(0)
	assert_int(cinto.take(Storage.ARCHOTE, 1)).is_equal(0)
	# Quantidades negativas nao tiram nem poem nada.
	assert_int(cinto.put(Storage.ARCHOTE, -3)).is_equal(0)
	assert_int(cinto.take(Storage.ARCHOTE, -3)).is_equal(0)


func test_o_que_um_armazenamento_nao_leva_nao_entra() -> void:
	var cinto := Storage.new(_dados(&"royal_belt"))
	assert_int(cinto.cap(&"relic")).is_equal(0)
	assert_int(cinto.put(&"relic", 3)).is_equal(0)
	assert_array(cinto.kinds()).is_equal([Storage.ARCHOTE])


func test_cada_tipo_leva_o_que_o_seu_personagem_precisa() -> void:
	# O trepador explora (§08, mobilidade) e leva mais do que o rei; os alforges
	# vao no cavalo e levam mais do que qualquer um a pe.
	var rei := _dados(&"royal_belt").holds[Storage.ARCHOTE] as float
	assert_float(_dados(&"climbing_belt").holds[Storage.ARCHOTE]).is_greater(rei)
	for id in Registry.ids(ARMAZENS):
		if id != "saddlebags":
			assert_float(_dados(&"saddlebags").holds[Storage.ARCHOTE]).is_greater(
				_dados(StringName(id)).holds[Storage.ARCHOTE]
			)


func test_trocar_de_personagem_fica_o_que_cabe_e_o_resto_cai() -> void:
	# O Verbo 2 sobre uma tropa da classe (§08) troca o armazenamento.
	var armazem := Storage.new(_dados(&"saddlebags"))
	armazem.put(Storage.ARCHOTE, 4)
	var caiu := armazem.refit(_dados(&"quiver"))
	assert_str(String(armazem.kind)).is_equal("quiver")
	assert_str(String(armazem.worn)).is_equal("back")
	assert_int(armazem.count(Storage.ARCHOTE)).is_equal(1)
	assert_dict(caiu).is_equal({Storage.ARCHOTE: 3})
	# E para um maior nao cai nada.
	assert_dict(armazem.refit(_dados(&"climbing_belt"))).is_empty()
	assert_int(armazem.count(Storage.ARCHOTE)).is_equal(1)


func test_a_camada_equipments_enche_com_o_que_leva() -> void:
	var cinto := Storage.new(_dados(&"royal_belt"))
	assert_float(cinto.fill()).is_equal(0.0)
	cinto.put(Storage.ARCHOTE, 1)
	assert_float(cinto.fill()).is_equal_approx(0.5, 0.001)
	cinto.put(Storage.ARCHOTE, 1)
	assert_float(cinto.fill()).is_equal(1.0)
	assert_float(Storage.new().fill()).is_equal(0.0)


func test_grava_e_volta_com_o_que_cabe() -> void:
	var cinto := Storage.new(_dados(&"royal_belt"))
	cinto.put(Storage.ARCHOTE, 2)
	var outro := Storage.new(_dados(&"royal_belt"))
	outro.from_dict(cinto.to_dict())
	assert_int(outro.count(Storage.ARCHOTE)).is_equal(2)
	# Um save com mais do que cabe (outros tetos, outra versao) fica com o teto (§62).
	outro.from_dict({&"kind": &"saddlebags", &"items": {Storage.ARCHOTE: 4}})
	assert_int(outro.count(Storage.ARCHOTE)).is_equal(2)
	assert_str(String(outro.kind)).is_equal("royal_belt")


func test_os_archotes_do_rei_vao_no_cinto_e_gravam_se_com_ele() -> void:
	SimLoop.autosave_enabled = false
	SimLoop.start(SEMENTE)
	var cinto := SimLoop.field.classes.storage
	assert_str(String(cinto.kind)).is_equal("royal_belt")
	# Um so armazenamento: o que o archote gasta e o que a classe grava.
	assert_bool(SimLoop.night.dark.torch.storage == cinto).is_true()
	assert_int(SimLoop.night.dark.torch.buy(1)).is_equal(1)
	assert_int(cinto.count(Storage.ARCHOTE)).is_equal(1)
	var guardado := SimLoop.world()
	cinto.take(Storage.ARCHOTE, 1)
	SimLoop.load_world(guardado)
	assert_int(SimLoop.field.classes.storage.count(Storage.ARCHOTE)).is_equal(1)
	assert_int(SimLoop.night.dark.torch.torches).is_equal(1)
	SimLoop.stop()
	SimLoop.autosave_enabled = true
