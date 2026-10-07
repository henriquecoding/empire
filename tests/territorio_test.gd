extends GdUnitTestSuite

const AGUA := &"water"
const FLORESTA := &"forest"
const ROCHA := &"rock"
const SUPERFICIE := int(Band.Kind.SURFACE)
const SUBSOLO := int(Band.Kind.UNDERGROUND)


func _lago() -> Dictionary:
	return PlacementRules.source("home_water_0", AGUA, SUPERFICIE, Vector2(1000.0, 1200.0))


func test_sem_exigencia_cabe_em_qualquer_lado() -> void:
	var r := PlacementRules.evaluate(&"", 0.0, SUPERFICIE, [], 0.0)
	assert_bool(r[PlacementRules.ALLOWED]).is_true()
	assert_array(r[PlacementRules.REASONS]).is_empty()
	assert_array(r[PlacementRules.SOURCES]).is_empty()


func test_a_agua_ao_alcance_serve_e_diz_qual_e() -> void:
	var r := PlacementRules.evaluate(AGUA, 1250.0, SUPERFICIE, [_lago()], 64.0)
	assert_bool(r[PlacementRules.ALLOWED]).is_true()
	assert_array(r[PlacementRules.SOURCES]).contains_exactly(["home_water_0"])
	assert_float(r[PlacementRules.GAP]).is_equal(50.0)
	var dentro := PlacementRules.evaluate(AGUA, 1100.0, SUPERFICIE, [_lago()], 0.0)
	assert_float(dentro[PlacementRules.GAP]).is_equal(0.0)
	assert_bool(dentro[PlacementRules.ALLOWED]).is_true()


func test_ver_agua_ao_longe_nao_chega_e_diz_porque() -> void:
	var r := PlacementRules.evaluate(AGUA, 1300.0, SUPERFICIE, [_lago()], 64.0)
	assert_bool(r[PlacementRules.ALLOWED]).is_false()
	assert_array(r[PlacementRules.REASONS]).contains_exactly([&"TERRAIN_NO_WATER"])
	assert_array(r[PlacementRules.SOURCES]).is_empty()
	assert_float(r[PlacementRules.GAP]).is_equal(100.0)
	var nada := PlacementRules.evaluate(AGUA, 0.0, SUPERFICIE, [], 64.0)
	assert_bool(nada[PlacementRules.ALLOWED]).is_false()
	assert_float(nada[PlacementRules.GAP]).is_equal(INF)


func test_a_fonte_de_outra_faixa_nao_serve_sem_acesso() -> void:
	var falha := PlacementRules.source("rock_fault", ROCHA, SUPERFICIE, Vector2(0.0, 200.0))
	var r := PlacementRules.evaluate(ROCHA, 100.0, SUBSOLO, [falha], 0.0)
	assert_bool(r[PlacementRules.ALLOWED]).is_false()
	assert_array(r[PlacementRules.REASONS]).contains_exactly([&"TERRAIN_NO_ROCK"])
	var porao := PlacementRules.source("cellar_0", ROCHA, SUBSOLO, Vector2(0.0, 200.0))
	var r2 := PlacementRules.evaluate(ROCHA, 100.0, SUBSOLO, [porao], 0.0)
	assert_bool(r2[PlacementRules.ALLOWED]).is_true()


func test_uma_arvore_so_nao_e_um_bosque() -> void:
	var arvores := []
	for k in 2:
		var x := 100.0 + 40.0 * k
		arvores.append(PlacementRules.source("tree_%d" % k, FLORESTA, SUPERFICIE, Vector2(x, x)))
	var poucas := PlacementRules.evaluate(FLORESTA, 100.0, SUPERFICIE, arvores, 160.0, 3)
	assert_bool(poucas[PlacementRules.ALLOWED]).is_false()
	arvores.append(PlacementRules.source("tree_2", FLORESTA, SUPERFICIE, Vector2(180.0, 180.0)))
	var r := PlacementRules.evaluate(FLORESTA, 100.0, SUPERFICIE, arvores, 160.0, 3)
	assert_bool(r[PlacementRules.ALLOWED]).is_true()
	assert_array(r[PlacementRules.SOURCES]).has_size(3)


func test_uma_exigencia_desconhecida_recusa_com_razao_generica() -> void:
	var r := PlacementRules.evaluate(&"fertile", 0.0, SUPERFICIE, [], 64.0)
	assert_bool(r[PlacementRules.ALLOWED]).is_false()
	assert_array(r[PlacementRules.REASONS]).contains_exactly([PlacementRules.UNKNOWN])


func test_o_perfil_responde_por_sitio_e_resume_por_necessidade() -> void:
	var sitios := [
		TerritoryProfile.site(7, AGUA, 1250.0, SUPERFICIE, 64.0),
		TerritoryProfile.site(9, AGUA, 1400.0, SUPERFICIE, 64.0),
		TerritoryProfile.site(11, ROCHA, 300.0, SUBSOLO, 0.0),
	]
	var perfil := TerritoryProfile.of(sitios, [_lago()])
	var por_sitio: Dictionary = perfil[TerritoryProfile.SITES]
	assert_bool(por_sitio[7][PlacementRules.ALLOWED]).is_true()
	assert_bool(por_sitio[9][PlacementRules.ALLOWED]).is_false()
	assert_bool(por_sitio[11][PlacementRules.ALLOWED]).is_false()
	var por_fonte: Dictionary = perfil[TerritoryProfile.NEEDS]
	assert_that(por_fonte[AGUA]).is_equal(Vector2i(1, 2))
	assert_that(por_fonte[ROCHA]).is_equal(Vector2i(0, 1))
	assert_array(TerritoryProfile.barred(perfil)).contains_exactly([9, 11])


func test_o_perfil_e_o_mesmo_para_as_mesmas_fontes() -> void:
	var sitios := [TerritoryProfile.site(1, AGUA, 1250.0, SUPERFICIE, 64.0)]
	assert_dict(TerritoryProfile.of(sitios, [_lago()])).is_equal(
		TerritoryProfile.of(sitios, [_lago()])
	)
	assert_dict(TerritoryProfile.of([], [_lago()])[TerritoryProfile.NEEDS]).is_empty()


func test_o_territorio_so_fecha_a_obra_intacta() -> void:
	var obras := BuildSystem.new()
	var vaga := BuildSlot.new()
	assert_bool(RealmGrowth.barred(vaga)).is_false()
	vaga.terrain_bar = &"TERRAIN_NO_WATER"
	assert_bool(RealmGrowth.barred(vaga)).is_true()
	assert_int(RealmGrowth.refusal(obras, vaga)).is_equal(RealmGrowth.Need.TERRAIN)
	assert_bool(RealmGrowth.allows(obras, vaga)).is_false()
	vaga.paid = 2  # o que ja se pagou nao se perde
	assert_bool(RealmGrowth.barred(vaga)).is_false()
	vaga.paid = 0
	vaga.state = BuildSlot.State.SCAFFOLD
	assert_bool(RealmGrowth.barred(vaga)).is_false()
	vaga.state = BuildSlot.State.EMPTY
	vaga.level = 1  # nem o que um save de antes ja tinha de pe
	assert_bool(RealmGrowth.barred(vaga)).is_false()
