# tests/site_stage_test.gd — em que ponto esta uma obra (planejamento 26/09, lote 3).
#
# O SiteStage le o BuildSlot e diz o que desenhar: vazio, paga em parte, a
# espera, em obra, a operar, tocada, em reparo, em ruina. Nao muda o slot, e o
# que ele chama "a operar" e o que a simulacao ja trata como tal (standing()).
extends GdUnitTestSuite

const E := SiteStage.Stage


func _casa() -> BuildSlot:
	var vaga := BuildSlot.new()
	vaga.id = 7
	vaga.kind = &"training_house"
	vaga.costs = PackedInt32Array([10])
	vaga.works = PackedFloat32Array([20.0])
	vaga.healths = PackedInt32Array([80])
	return vaga


func test_vazia_e_disponivel_e_com_moeda_e_paga_em_parte() -> void:
	var vaga := _casa()
	assert_int(SiteStage.of(vaga, false)).is_equal(E.AVAILABLE)
	vaga.paid = 4
	assert_int(SiteStage.of(vaga, false)).is_equal(E.PAYING)
	assert_int(SiteStage.cost_now(vaga)).is_equal(10)


func test_em_obra_distingue_quem_trabalha_de_quem_espera() -> void:
	var vaga := _casa()
	vaga.state = BuildSlot.State.SCAFFOLD
	vaga.progress = 5.0
	assert_int(SiteStage.of(vaga, false)).is_equal(E.WAITING)
	assert_int(SiteStage.of(vaga, true)).is_equal(E.WORKING)
	assert_float(SiteStage.built(vaga)).is_equal_approx(0.25, 0.001)
	# Uma obra a meio nao aceita moeda (BuildSystem.absorb): nada a pagar agora.
	assert_int(SiteStage.cost_now(vaga)).is_equal(BuildSlot.NENHUM)


func test_de_pe_opera_e_tocada_continua_a_operar() -> void:
	var vaga := _casa()
	vaga.level = 1
	vaga.state = BuildSlot.State.DONE
	vaga.health = 80
	assert_int(SiteStage.of(vaga, false)).is_equal(E.OPERATING)
	vaga.state = BuildSlot.State.DAMAGED
	vaga.health = 20
	assert_int(SiteStage.of(vaga, false)).is_equal(E.DAMAGED)
	assert_bool(SiteStage.operating(E.DAMAGED)).is_true()
	assert_float(SiteStage.built(vaga)).is_equal_approx(0.25, 0.001)
	assert_int(SiteStage.cost_now(vaga)).is_equal(vaga.repair_cost())


func test_em_reparo_opera_e_nao_aceita_mais_moeda() -> void:
	var vaga := _casa()
	vaga.level = 1
	vaga.state = BuildSlot.State.DAMAGED
	vaga.health = 40
	vaga.mending = true
	assert_int(SiteStage.of(vaga, true)).is_equal(E.MENDING)
	assert_bool(SiteStage.operating(E.MENDING)).is_true()
	assert_int(SiteStage.cost_now(vaga)).is_equal(BuildSlot.NENHUM)


func test_a_ruina_nao_opera_e_paga_se_a_reparacao() -> void:
	var vaga := _casa()
	vaga.level = 1
	vaga.state = BuildSlot.State.RUIN
	assert_int(SiteStage.of(vaga, false)).is_equal(E.RUIN)
	assert_bool(SiteStage.operating(E.RUIN)).is_false()
	assert_int(SiteStage.cost_now(vaga)).is_equal(10)
	assert_float(SiteStage.built(vaga)).is_equal(0.0)


func test_a_ruina_a_levantar_se_mede_o_degrau_que_tinha() -> void:
	var vaga := _casa()
	vaga.level = 1
	vaga.state = BuildSlot.State.BUILDING
	vaga.mending = true
	vaga.progress = 10.0
	assert_float(SiteStage.built(vaga)).is_equal_approx(0.5, 0.001)


func test_trabalho_e_o_progresso_a_subir_e_nao_o_tempo_a_passar() -> void:
	var vaga := _casa()
	vaga.id = 9001
	vaga.state = BuildSlot.State.BUILDING
	assert_bool(SiteMarks.working(vaga, 0.0)).is_false()
	vaga.progress = 1.0
	assert_bool(SiteMarks.working(vaga, 0.1)).is_true()
	# Parado, ainda conta durante a folga (o tick e 30 Hz, o ecra 60)...
	assert_bool(SiteMarks.working(vaga, 0.1 + SiteMarks.FOLGA_TRABALHO * 0.5)).is_true()
	# ...e depois dela deixa de contar.
	assert_bool(SiteMarks.working(vaga, 0.2 + SiteMarks.FOLGA_TRABALHO)).is_false()
