# tests/chapter_plan_test.gd — o XIII-07, primeira metade: onde caem os
# capitulos de uma campanha, e que diario carrega cada um (§77, §79).
#
# D-11: seis por campanha, e o Cerco sempre. O D-09 e o D-12 vivem com os
# outros da §84, em parte_xiii_mundo_test.gd. O sorteio e o do fluxo `world`
# (§42, §54): mil sementes sao mil configure() do RngService.
extends GdUnitTestSuite

const SEMENTES := 1000

var _rng_antes: Dictionary


func before() -> void:
	_rng_antes = RngService.snapshot()


func after() -> void:
	RngService.restore(_rng_antes)


func _capitulos() -> Array[ChapterData]:
	var saida: Array[ChapterData] = []
	for c in Registry.entries(SimFactory.TABELA_CAPITULOS):
		saida.append(c as ChapterData)
	return saida


func _plano(semente: int) -> ChapterPlan:
	RngService.configure(semente)
	return SimFactory.chapter_plan(SimFactory.campaign_regions())


# ─── A campanha: seis regioes, uma por povo ──────────────────────────────────


func test_a_campanha_tem_uma_regiao_por_bioma() -> void:
	var regioes := SimFactory.campaign_regions()
	assert_int(regioes.size()).is_equal(Registry.entries(&"biomes").size())


# ─── D-11: seis, e o Cerco sempre ────────────────────────────────────────────


func test_d11_seis_capitulos_um_por_regiao_e_o_cerco_sempre() -> void:
	var seis := SimFactory.curve().chapters_per_campaign
	for semente in SEMENTES:
		var p := _plano(semente)
		var msg := "semente %d: %s" % [semente, p.placed]
		assert_int(p.count()).override_failure_message(msg).is_equal(seis)
		assert_bool(p.has(&"endless_siege")).override_failure_message(msg).is_true()
		assert_int(p.placed.size()).is_equal(p.regions.size())


func test_um_capitulo_de_bioma_so_cai_nesse_bioma() -> void:
	var por_id := SimFactory.by_id(SimFactory.TABELA_CAPITULOS)
	for semente in SEMENTES:
		var p := _plano(semente)
		for i in p.regions.size():
			if p.placed[i].is_empty():
				continue
			var c := por_id[StringName(p.placed[i])] as ChapterData
			if c.biome != &"":
				assert_str(p.regions[i]).is_equal(String(c.biome))


func test_nenhum_capitulo_sai_duas_vezes() -> void:
	for semente in SEMENTES:
		var vistos := {}
		for id in _plano(semente).placed:
			if not id.is_empty():
				assert_bool(vistos.has(id)).is_false()
				vistos[id] = true


func test_a_mesma_semente_da_o_mesmo_mundo() -> void:
	var a := _plano(20260925)
	var b := _plano(20260925)
	assert_array(Array(a.placed)).is_equal(Array(b.placed))
	assert_array(Array(a.journals)).is_equal(Array(b.journals))


func test_as_sementes_dao_mundos_diferentes() -> void:
	var mundos := {}
	for semente in SEMENTES:
		var p := _plano(semente)
		var ids := Array(p.placed).filter(func(s: String) -> bool: return not s.is_empty())
		ids.sort()
		mundos[",".join(ids)] = true
	# Dos nove, cinco a cinco — menos os que poem dois no mesmo bioma (Q-105).
	var cinco := SimFactory.curve().chapters_per_campaign - 1
	assert_int(mundos.size()).is_equal(ChapterPlan.worlds(_capitulos(), _seis_biomas(), cinco))


func test_as_contas_dos_mundos_possiveis() -> void:
	# Nove fichas cinco a cinco sao 126 (§77); duas da varzea e duas do
	# desfiladeiro nao cabem na mesma campanha, e ficam 61 (Q-105).
	assert_int(ChapterPlan.worlds(_capitulos(), _seis_biomas(), 5)).is_equal(61)


# ─── Os diarios: o preferido, ou o seguinte que saiu ─────────────────────────


func test_um_diario_vai_para_o_seu_capitulo_quando_ele_sai() -> void:
	var p := ChapterPlan.draw(_seis_biomas(), _capitulos(), 6, _primeiro)
	for i in p.regions.size():
		if p.placed[i] == "endless_siege":
			assert_str(p.journals[i]).is_equal("journal_12")


func test_um_diario_sem_capitulo_vai_para_o_seguinte_que_saiu() -> void:
	# O sorteio `_primeiro` tira sempre a primeira ficha que cabe: saem as
	# alminhas (1), a romaria (2), a casa que conta (3), o sulco cego (5) e o
	# forno (6), mais o Cerco (10); a varzea virada (4) nao cabe, que a varzea e
	# da romaria. O mercado (7) e a ponte (9) ficam de fora, e os diarios deles
	# vao para o seguinte que saiu e ainda nao tem nenhum, por ordem, dando a volta.
	var p := ChapterPlan.draw(_seis_biomas(), _capitulos(), 6, _primeiro)
	var por_capitulo := {}
	for i in p.regions.size():
		por_capitulo[p.placed[i]] = p.journals[i]
	assert_str(por_capitulo["stopped_pilgrimage"]).is_equal("journal_03")
	assert_str(por_capitulo["house_that_counts"]).is_equal("journal_04")
	assert_str(por_capitulo["blind_furrow"]).is_equal("journal_06")
	assert_str(por_capitulo["crossroad_souls"]).is_equal("journal_08")
	assert_str(por_capitulo["lit_oven"]).is_equal("journal_10")
	assert_str(por_capitulo["endless_siege"]).is_equal("journal_12")


# ─── O save ──────────────────────────────────────────────────────────────────


func test_o_plano_vai_e_volta_pelo_save() -> void:
	var p := _plano(7)
	var q := ChapterPlan.new()
	q.from_dict(p.to_dict())
	assert_array(Array(q.placed)).is_equal(Array(p.placed))
	assert_array(Array(q.journals)).is_equal(Array(p.journals))
	assert_array(Array(q.regions)).is_equal(Array(p.regions))
	assert_array(Array(q.detours)).is_equal(Array(p.detours))


# ─── Ajudas ──────────────────────────────────────────────────────────────────


func _seis_biomas() -> PackedStringArray:
	return PackedStringArray(
		["ancient_forest", "canyon", "coast", "floodplain", "subterranean", "volcanic"]
	)


## Um sorteio que tira sempre o primeiro: o baralho fica pela ordem da §77.
func _primeiro(de: int, _ate: int) -> int:
	return de
