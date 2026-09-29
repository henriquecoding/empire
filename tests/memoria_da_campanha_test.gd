# tests/memoria_da_campanha_test.gd — o que a campanha lembra ao atravessar (CONT-02;
# §16, §79; Q-143).
#
# A auditoria de 27/09 (N2): a travessia zerava a divida, os povos e o treino do
# herdeiro, e o epilogo so lia a regiao corrente. Agora atravessam; a derrota nao
# os leva, e a comitiva e so de quem esta perto e na faixa do rei.
extends GdUnitTestSuite

const SEMENTE := 20260927
const DIVIDA := 9
const TREINO := 7
const POVO := "fenda"


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(SEMENTE)
	Greybox.build()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _memoria() -> Dictionary:
	var noite := SimLoop.night
	return CampaignMemory.of(noite.voice.debt, noite.harvest, SimLoop.field.succession)


func _aplicar(d: Dictionary) -> void:
	var noite := SimLoop.night
	CampaignMemory.apply(d, noite.voice.debt, noite.harvest, SimLoop.field.succession)


func _regiao_nova() -> void:
	SimLoop.stop()
	SimLoop.start(SEMENTE + 1)
	Greybox.build()


func test_a_divida_os_povos_e_o_treino_atravessam() -> void:
	SimLoop.night.voice.debt.debt = DIVIDA
	SimLoop.night.harvest.released = PackedStringArray([POVO])
	SimLoop.field.succession.days = TREINO
	var d := bytes_to_var(var_to_bytes(_memoria())) as Dictionary
	_regiao_nova()
	assert_int(SimLoop.night.voice.debt.debt).is_equal(0)
	_aplicar(d)
	assert_int(SimLoop.night.voice.debt.debt).is_equal(DIVIDA)
	assert_array(Array(SimLoop.night.harvest.released)).contains([POVO])
	assert_int(SimLoop.field.succession.days).is_equal(TREINO)


func test_o_epilogo_le_a_divida_de_toda_a_campanha() -> void:
	var perfil := SimFactory.rot_profile()
	SimLoop.night.voice.debt.debt = perfil.dominion_debt_min
	var d := _memoria()
	_regiao_nova()
	assert_str(String(SimLoop.night.epilogue())).is_not_equal(String(Epilogue.DOMINIO))
	_aplicar(d)
	assert_str(String(SimLoop.night.epilogue())).is_equal(String(Epilogue.DOMINIO))


func test_um_legado_de_derrota_nao_mexe_na_memoria() -> void:
	SimLoop.night.voice.debt.debt = DIVIDA
	_aplicar(Legacy.of(SimLoop.state, SimLoop.builds, 0.4))
	assert_int(SimLoop.night.voice.debt.debt).is_equal(DIVIDA)


func test_a_comitiva_e_so_de_quem_esta_na_faixa_do_rei() -> void:
	var r := SimLoop.units.index_of(SimLoop.king_id)
	var tropas := SimFactory.by_id(&"units")
	var vagabundo := Registry.entry(&"units", &"vagrant") as UnitData
	var x := SimLoop.units.xs[r]
	var em_cima := SimLoop.units.spawn(SimLoop.state, vagabundo, SimLoop.units.owners[r], x)
	var em_baixo := SimLoop.units.spawn(SimLoop.state, vagabundo, SimLoop.units.owners[r], x)
	SimLoop.units.bands[SimLoop.units.index_of(em_baixo)] = int(Band.Kind.UNDERGROUND)
	var sem := Legacy.crossing(SimLoop.state, SimLoop.units, tropas, SimLoop.king_id, 1.0)
	var quantos := (sem[Legacy.COMITIVA] as PackedStringArray).count(String(vagabundo.id))
	assert_int(quantos).is_equal(1 + Greybox.JA_TEUS)  # os dois do inicio esperam no nucleo
	assert_int(em_cima).is_not_equal(em_baixo)


func test_o_ecra_da_travessia_diz_o_que_a_campanha_leva() -> void:
	TranslationServer.set_locale("pt_PT")
	SimLoop.night.voice.debt.debt = DIVIDA
	var d := _memoria()
	d[Legacy.COMITIVA] = PackedStringArray()
	assert_str(PauseMenu.legacy_line(d)).contains("dívida (%d)" % DIVIDA)


## §79: depois da ultima regiao so o Turno leva a campanha seguinte; a Uniao e o
## Dominio acabam-na (revisao do PR #44).
func test_depois_da_ultima_regiao_so_o_turno_leva_a_memoria() -> void:
	assert_bool(CampaignMemory.carries(false, Epilogue.UNIAO)).is_true()
	assert_bool(CampaignMemory.carries(true, Epilogue.TURNO)).is_true()
	assert_bool(CampaignMemory.carries(true, Epilogue.UNIAO)).is_false()
	assert_bool(CampaignMemory.carries(true, Epilogue.DOMINIO)).is_false()
