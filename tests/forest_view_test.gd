# tests/forest_view_test.gd — o que se ve da floresta, e o que o painel diz (ADR 0070).
extends GdUnitTestSuite


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20261005)
	Greybox.build()
	SimLoop.step(1.0 / 30.0)


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func test_species_silhouettes_differ_and_winter_strips_only_deciduous_crowns() -> void:
	var carvalho := Registry.entry(&"flora", &"oak") as FloraData
	var pinheiro := Registry.entry(&"flora", &"pine") as FloraData
	assert_str(String(carvalho.crown)).is_not_equal(String(pinheiro.crown))
	assert_bool(TreeArt.bare(carvalho, Seasons.WINTER)).is_true()
	assert_bool(TreeArt.bare(carvalho, Seasons.SUMMER)).is_false()
	assert_bool(TreeArt.bare(pinheiro, Seasons.WINTER)).is_false()
	assert_array(TreeArt.colors(carvalho, Seasons.AUTUMN)).is_not_equal(
		TreeArt.colors(carvalho, Seasons.SUMMER)
	)
	assert_array(TreeArt.colors(pinheiro, Seasons.AUTUMN)).is_equal(
		TreeArt.colors(pinheiro, Seasons.SUMMER)
	)


func test_every_state_draws_without_touching_the_simulation() -> void:
	var tela := Node2D.new()
	var w := SimLoop.field.woodland
	var antes := w.to_dict()
	for estado in [Woodland.State.STANDING, Woodland.State.MARKED, Woodland.State.FELLED]:
		for estacao in Seasons.COUNT:
			for especie: FloraData in ForestWatch.flora():
				TreeArt.draw(tela, Vector2.ZERO, especie, estado, estacao, 1.5, 7, Lighting.new())
	ForestView.draw_on(tela, Band.Kind.SURFACE, Lighting.new(), 2.0)
	assert_dict(w.to_dict()).is_equal(antes)
	tela.free()


func test_cleared_ground_and_the_season_shape_the_common_flora() -> void:
	var w := SimLoop.field.woodland
	w.plant(9_200_000, 3000.0, &"oak")
	w.clear(2990.0, 3010.0)
	var plantas := PackedFloat32Array(
		[Wilds.Plant.BUSH, 3005.0, 0.2, 0.1, Wilds.Plant.FLOWER, 1000.0, 0.2, 0.1]
	)
	var primavera := ForestView.field_flora(plantas)
	assert_int(primavera.size()).is_equal(Wilds.PLANTA)  # o arbusto da clareira saiu
	assert_int(int(primavera[0])).is_equal(Wilds.Plant.FLOWER)
	var outono := RulesFactory.rules().season_days * 2 + 1
	ClockService.seek(outono, 0.0, ClockService.clock.day_seconds())
	assert_int(ForestView.season()).is_equal(Seasons.AUTUMN)
	assert_int(ForestView.field_flora(plantas).size()).is_equal(0)  # as flores sao da primavera


func test_the_panel_names_the_tree_its_price_and_whom_it_serves() -> void:
	var w := SimLoop.field.woodland
	var provisoes := SimLoop.arrival.cache_x
	var regras := ForestWatch.rules()
	w.clear(provisoes - regras.grove_feeds_radius, provisoes + regras.grove_feeds_radius)
	for k in regras.grove_feeds_min:
		w.plant(9_300_000 + k, provisoes + 60.0 + 30.0 * k, &"oak")
	var texto := ForestGuide.context(provisoes + 60.0, {"drop": "A", "assume": "B"})
	assert_str(texto).is_not_empty()
	assert_str(texto).contains(TranslationServer.translate(&"FLORA_OAK"))
	assert_str(texto).contains(TranslationServer.translate(&"FOREST_FEEDS_LOST"))
	assert_str(ForestGuide.context(provisoes + 2000.0, {})).is_empty()
	var alvos := ForestView.targets(w.index_of(9_300_000))
	assert_bool(alvos.has(provisoes)).is_true()
