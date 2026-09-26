# tests/legado_test.gd — decay em vez de reset (AUD-05; §16; Q-088, Q-134).
#
# O §16: "Ao cair, o jogador mantem: Sementes Reais, classes desbloqueadas, mapas
# revelados, segredos encontrados, e 40% das estruturas do imperio principal."
extends GdUnitTestSuite

const SEMENTE := 20260926
const SEMENTES := 4
const SEGREDO := "royal_seed_chamber"


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(SEMENTE)
	Greybox.build()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true
	SaveService.take_legacy()


func _de_pe(kind: StringName, nivel: int = 1) -> Array[BuildSlot]:
	var saida: Array[BuildSlot] = []
	for obra in SimLoop.builds.slots:
		if obra.kind == kind:
			obra.level = nivel
			obra.state = BuildSlot.State.DONE
			obra.health = obra.max_health()
			saida.append(obra)
	return saida


func _fica() -> float:
	return SimFactory.curve().decay_structures_kept


func test_guarda_as_sementes_os_segredos_e_as_conquistas() -> void:
	SimLoop.state.royal_seeds = SEMENTES
	SimLoop.state.found = PackedStringArray([SEGREDO])
	var legado := Legacy.of(SimLoop.state, SimLoop.builds, _fica())
	assert_int(int(legado[Legacy.SEMENTES])).is_equal(SEMENTES)
	assert_array(Array(legado[Legacy.ACHADOS])).contains([SEGREDO])


func test_ficam_quarenta_por_cento_das_obras_as_mais_caras() -> void:
	var canteiros := _de_pe(&"farm")
	var muros := _de_pe(WallSite.MURO, 3)
	var todas := canteiros.size() + muros.size()
	var ficam := Legacy.kept(SimLoop.builds, _fica())
	assert_int(ficam.size()).is_equal(roundi(todas * _fica()))
	for obra in ficam:
		assert_bool(obra.two_paths()).is_true()  # o muro de nivel 3 custa mais


func test_o_nucleo_e_as_ruinas_nao_contam() -> void:
	var canteiros := _de_pe(&"farm")
	canteiros[0].state = BuildSlot.State.RUIN
	for obra in Legacy.kept(SimLoop.builds, 1.0):
		assert_str(String(obra.kind)).is_not_equal(String(BuildSlot.NUCLEO))
		assert_bool(obra.standing()).is_true()
	assert_int(Legacy.kept(SimLoop.builds, 1.0).size()).is_equal(canteiros.size() - 1)


func test_o_jogo_novo_levanta_o_que_ficou_no_mesmo_sitio_e_degrau() -> void:
	SimLoop.state.royal_seeds = SEMENTES
	var muros := _de_pe(WallSite.MURO, 3)
	var legado := Legacy.of(SimLoop.state, SimLoop.builds, _fica())
	var guardados: Array = legado[Legacy.OBRAS]
	SimLoop.stop()
	SimLoop.start(SEMENTE + 1)
	Greybox.build()
	Legacy.apply(legado, SimLoop.state, SimLoop.builds)
	assert_int(SimLoop.state.royal_seeds).is_equal(SEMENTES)
	var de_pe := 0
	for obra in SimLoop.builds.slots:
		if obra.two_paths() and obra.standing():
			de_pe += 1
			assert_int(obra.level).is_equal(3)
			assert_int(obra.health).is_equal(obra.max_health())
	assert_int(de_pe).is_equal(guardados.size())
	assert_int(guardados.size()).is_less(muros.size())


func test_o_legado_vai_ao_ficheiro_apaga_os_saves_e_gasta_se_uma_vez() -> void:
	SaveService.autosave(SimLoop.state)
	assert_int(SaveService.latest_slot()).is_not_equal(-1)
	SimLoop.state.royal_seeds = SEMENTES
	SaveService.lose(Legacy.of(SimLoop.state, SimLoop.builds, _fica()))
	assert_int(SaveService.latest_slot()).is_equal(-1)
	assert_int(int(SaveService.legacy()[Legacy.SEMENTES])).is_equal(SEMENTES)
	assert_int(int(SaveService.take_legacy()[Legacy.SEMENTES])).is_equal(SEMENTES)
	assert_bool(SaveService.take_legacy().is_empty()).is_true()


func test_o_ecra_da_derrota_diz_o_que_fica() -> void:
	TranslationServer.set_locale("pt_PT")
	_de_pe(WallSite.MURO, 2)
	SimLoop.state.royal_seeds = SEMENTES
	var linha := PauseMenu.legacy_line(Legacy.of(SimLoop.state, SimLoop.builds, _fica()))
	assert_str(linha).contains("%d Sementes" % SEMENTES)
