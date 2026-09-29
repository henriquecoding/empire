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
	LegacyStore.discard()


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
	SimLoop.state.region = 1
	var legado := Legacy.of(SimLoop.state, SimLoop.builds, _fica())
	assert_int(int(legado[Legacy.REGIAO])).is_equal(1)
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
	assert_bool(LegacyStore.leave(Legacy.of(SimLoop.state, SimLoop.builds, _fica()))).is_true()
	assert_int(SaveService.latest_slot()).is_equal(-1)
	assert_int(int(LegacyStore.pending()[Legacy.SEMENTES])).is_equal(SEMENTES)
	SaveService.autosave(SimLoop.state)  # o primeiro save do jogo novo (CONT-01)
	LegacyStore.settle()
	assert_bool(LegacyStore.pending().is_empty()).is_true()


## N1 (auditoria de 27/09): duas torres B retidas voltavam A.
func test_a_obra_que_fica_guarda_a_variante() -> void:
	var torres := _de_pe(&"archer_tower")
	for torre in torres:
		torre.variant = 1
	var legado := Legacy.of(SimLoop.state, SimLoop.builds, 1.0)
	SimLoop.stop()
	SimLoop.start(SEMENTE + 1)
	Greybox.build()
	Legacy.apply(legado, SimLoop.state, SimLoop.builds)
	for torre in torres:
		var nova := SimLoop.builds.slots[SimLoop.builds.index_of(torre.id)]
		assert_bool(nova.standing()).is_true()
		assert_int(nova.variant).is_equal(1)


func test_um_legado_sem_variante_fica_com_a_de_raiz() -> void:
	var torre := _de_pe(&"archer_tower")[0]
	var legado := {Legacy.OBRAS: [{Legacy.ID: torre.id, Legacy.NIVEL: 1}]}
	torre.variant = 0
	Legacy.apply(legado, SimLoop.state, SimLoop.builds)
	assert_int(torre.variant).is_equal(0)
	assert_int(int(torre.path)).is_equal(int(BuildSlot.Path.NENHUMA))


## Q-140 (o dono, 29/09/2026): a classe e desbloqueada para o jogo novo, mas a
## evolucao nao — volta a ganhar-se a jogar. A travessia nao e jogo novo: e a
## mesma campanha, e a evolucao vai com ela.
func test_a_evolucao_atravessa_mas_nao_fica_na_derrota() -> void:
	SimLoop.field.classes.phase = ClassSystem.PRIMEIRA + 1
	var perdido := Legacy.of(SimLoop.state, SimLoop.builds, _fica())
	var tropas := SimFactory.by_id(&"units")
	var atravessado := Legacy.crossing(
		SimLoop.state, SimLoop.units, tropas, SimLoop.king_id, 0.0, SimLoop.field.classes
	)
	var esperado := [ClassSystem.PRIMEIRA, ClassSystem.PRIMEIRA + 1]
	var legados := [perdido, atravessado]
	for k in legados.size():
		SimLoop.stop()
		SimLoop.start(SEMENTE + 1)
		Greybox.build()
		assert_int(SimLoop.field.classes.phase).is_equal(ClassSystem.PRIMEIRA)
		Legacy.apply(legados[k], SimLoop.state, SimLoop.builds, SimLoop.field.classes)
		assert_int(SimLoop.field.classes.phase).is_equal(esperado[k])


func test_um_legado_sem_classe_nao_tira_a_fase_a_ninguem() -> void:
	Legacy.apply({}, SimLoop.state, SimLoop.builds, SimLoop.field.classes)
	assert_int(SimLoop.field.classes.phase).is_equal(ClassSystem.PRIMEIRA)


func test_o_ecra_da_derrota_diz_o_que_fica() -> void:
	TranslationServer.set_locale("pt_PT")
	_de_pe(WallSite.MURO, 2)
	SimLoop.state.royal_seeds = SEMENTES
	var linha := PauseMenu.legacy_line(Legacy.of(SimLoop.state, SimLoop.builds, _fica()))
	assert_str(linha).contains("%d Sementes" % SEMENTES)
