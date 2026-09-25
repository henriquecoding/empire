# tests/capitulos_no_jogo_test.gd — o XIII-07, segunda metade: o plano dos
# capitulos nasce com a partida, vai no save e volta dele (§77, §84).
#
# O sorteio e da semente do mundo (§54): a mesma semente, os mesmos seis. E o
# save leva-o (D-14: chapters_placed), para que o carregar nao volte a sortear.
extends GdUnitTestSuite

const SEMENTE := 20260925
const OUTRA := 7


func after_test() -> void:
	SimLoop.stop()


func test_uma_partida_nova_traz_os_seis_capitulos() -> void:
	SimLoop.start(SEMENTE)
	var p := SimLoop.state.chapters
	assert_int(p.count()).is_equal(SimFactory.curve().chapters_per_campaign)
	assert_bool(p.has(&"endless_siege")).is_true()
	assert_array(Array(p.regions)).is_equal(Array(SimFactory.campaign_regions()))


func test_a_mesma_semente_da_os_mesmos_capitulos() -> void:
	SimLoop.start(SEMENTE)
	var a := Array(SimLoop.state.chapters.placed)
	SimLoop.start(SEMENTE)
	assert_array(Array(SimLoop.state.chapters.placed)).is_equal(a)


func test_sementes_diferentes_podem_dar_capitulos_diferentes() -> void:
	var vistos := {}
	for s in [SEMENTE, OUTRA, SEMENTE + OUTRA, SEMENTE * OUTRA]:
		SimLoop.start(s)
		vistos[",".join(SimLoop.state.chapters.placed)] = true
	assert_int(vistos.size()).is_greater(1)


func test_o_plano_vai_no_save_e_volta_sem_sortear_outra_vez() -> void:
	SimLoop.start(SEMENTE)
	var antes := SimLoop.state.chapters
	var d := SimLoop.state.to_dict()
	var lido := GameState.from_dict(d)
	assert_array(Array(lido.chapters.placed)).is_equal(Array(antes.placed))
	assert_array(Array(lido.chapters.journals)).is_equal(Array(antes.journals))
	assert_array(Array(lido.chapters.regions)).is_equal(Array(antes.regions))


func test_um_save_antigo_sem_capitulos_carrega_vazio() -> void:
	var lido := GameState.from_dict({&"seed": SEMENTE})
	assert_int(lido.chapters.count()).is_equal(0)


func test_um_campo_de_capitulos_com_o_tipo_errado_e_ignorado() -> void:
	var lido := GameState.from_dict({&"chapters_placed": "lixo"})
	assert_int(lido.chapters.count()).is_equal(0)


func test_o_capitulo_de_uma_regiao_pelo_bioma() -> void:
	SimLoop.start(SEMENTE)
	var p := SimLoop.state.chapters
	for i in p.regions.size():
		assert_str(String(p.in_region(StringName(p.regions[i])))).is_equal(p.placed[i])
	assert_str(String(p.in_region(&"nao_existe"))).is_empty()


func test_a_regiao_de_casa_e_a_do_povo_do_segmento_de_partida() -> void:
	# O segmento de partida e dos Enramados, e o bioma deles e a floresta antiga.
	var bioma := SimFactory.biome_of_segment(Greybox.SEGMENTO)
	assert_str(String(bioma)).is_equal("ancient_forest")
	assert_bool(SimFactory.campaign_regions().has(String(bioma))).is_true()


func test_a_placa_da_bifurcacao_diz_o_capitulo_de_casa() -> void:
	SimLoop.start(SEMENTE)
	var casa := SimLoop.state.chapters.in_region(SimFactory.biome_of_segment(Greybox.SEGMENTO))
	var dados := Registry.entry(SimFactory.TABELA_CAPITULOS, casa) as ChapterData
	assert_str(SiteView.chapter_name()).is_equal(TranslationServer.translate(dados.display_key))
	assert_str(SiteView.chapter_name()).is_not_empty()
