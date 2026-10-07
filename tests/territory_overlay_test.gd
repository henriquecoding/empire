# tests/territory_overlay_test.gd — o diagnostico mostra o territorio que o jogo conhece
# (CV-39 e EX-07 do plano de cenarios; ADR 0078).
#
# A sobreposicao do inspetor nao tem uma segunda lista de rios nem de rochas: le as
# mesmas fontes e as mesmas respostas do TerritoryWatch que decidem se uma obra se
# levanta. Se a agua pintada nao coincidir com a agua contada, ve-se ali.
extends GdUnitTestSuite

const CENARIO := "res://scenes/segments/enramados/enramados_start_base_01.tscn"


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20261005)
	Greybox.build()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func test_the_home_water_is_drawn_where_it_is_counted() -> void:
	var marcas := TerritoryOverlay.marks()
	var meia := TerritoryWatch.rules().water_half_px
	var agua := SimLoop.field.waters[0]
	var achou := false
	for f: Dictionary in marcas[TerritoryOverlay.SOURCES]:
		if f[PlacementRules.NEED] != TerritoryWatch.AGUA:
			continue
		var span: Vector2 = f[PlacementRules.SPAN]
		achou = achou or span.is_equal_approx(Vector2(agua - meia, agua + meia))
	assert_bool(achou).is_true()


func test_every_site_says_what_the_rules_answered() -> void:
	TerritoryWatch.apply()
	var marcas := TerritoryOverlay.marks()
	var sitios: Array = marcas[TerritoryOverlay.SITES]
	assert_array(sitios).is_not_empty()
	var por_id := {}
	for vaga in SimLoop.builds.slots:
		por_id[vaga.id] = vaga
	for s: Dictionary in sitios:
		var vaga: BuildSlot = por_id[s[TerritoryProfile.ID]]
		assert_bool(s[PlacementRules.ALLOWED]).is_equal(vaga.terrain_bar.is_empty())
		assert_float(s[TerritoryProfile.REACH]).is_greater(-1.0)


func test_nothing_is_drawn_while_the_inspector_is_closed() -> void:
	var camada: TerritoryOverlay = auto_free(TerritoryOverlay.new())
	add_child(camada)
	Inspector.shown = false
	camada._process(0.0)
	assert_bool(camada.visible).is_false()
	Inspector.shown = true
	camada._process(0.0)
	assert_bool(camada.visible).is_true()
	Inspector.shown = false


func test_the_planes_slide_slower_the_farther_they_are() -> void:
	var planos := PlaneContract.planes(load(CENARIO) as PackedScene)
	assert_array(planos).is_not_empty()
	var antes := 0.0
	for p: Dictionary in planos:
		var escala: float = p[PlaneContract.SCROLL]
		assert_float(escala).is_greater(antes)  # de tras para a frente, cada vez mais depressa
		assert_float(escala).is_less(1.0)  # o mundo funcional e 1: nada do jogo desliza
		antes = escala


func test_no_gameplay_layer_lives_inside_a_parallax_plane() -> void:
	var jogo := load("res://scenes/game.tscn") as PackedScene
	for camada: String in PlaneContract.GAMEPLAY:
		assert_bool(PlaneContract.in_parallax(jogo, camada)).is_false()
	var cenario := load(CENARIO)
	for chao: String in PlaneContract.GROUND:
		assert_bool(PlaneContract.in_parallax(cenario as PackedScene, chao)).is_false()
