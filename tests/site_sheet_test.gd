# tests/site_sheet_test.gd — a ficha do sitio de fundacao (UX-08, ADR 0078).
#
# Parar num sitio livre ja nao abre um relatorio no meio do ecra: o contexto diz uma linha,
# e o Interagir abre a ficha. A ficha le o que a clareira leva e o que o territorio permite
# da mesma conta que a confirmacao usa; abri-la nao gasta nada nem funda; confirmar passa
# pela intencao de sempre e a simulacao volta a validar; voltar deixa tudo como estava.
extends GdUnitTestSuite

var _locale := ""


func before_test() -> void:
	_locale = TranslationServer.get_locale()
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20261005)
	Greybox.build()
	SimLoop.intents.clear()


func after_test() -> void:
	SiteSheet.active = false
	TouchControls.active = false
	SimLoop.stop()
	SimLoop.autosave_enabled = true
	TranslationServer.set_locale(_locale)


## Parado ao lado da estatua: um sitio valido com alguma coisa a dizer.
func _parar_no_sitio() -> float:
	var x := (
		SimLoop.secrets.xs[0]
		+ RealmLadder.seat(SimLoop.builds).catch_half()
		+ Band.PASSAGE_PX
		+ 8.0
	)
	var u := SimLoop.units
	u.xs[u.index_of(SimLoop.king_id)] = x
	u.clear_target(SimLoop.king_id)
	SimLoop.step(1.0)
	SimLoop.arrival.stationary_s = LastCartWatch.rules().foundation_stop_s
	return x


func _ficha() -> SiteSheet:
	var ficha: SiteSheet = auto_free(SiteSheet.new())
	add_child(ficha)
	return ficha


func _bolsa() -> Vector2i:
	return RealmReadout.purse()


func test_stopping_shows_one_short_line_and_not_the_report() -> void:
	var x := _parar_no_sitio()
	var estatua := tr(&"FOUNDATION_NEAR_STATUE")
	for locale: String in ["pt_PT", "en"]:
		TranslationServer.set_locale(locale)
		var linha := ArrivalGuide.context(x, Band.Kind.SURFACE, {"assume": "E"})
		assert_str(linha).is_equal(tr(&"ARRIVAL_FOUND_HERE").format({"assume": "E"}))
		assert_str(linha).not_contains("\n")
		assert_str(linha).not_contains(tr(&"FOUNDATION_NEAR_STATUE"))
	assert_str(estatua).is_not_empty()


func test_the_sections_come_from_one_source() -> void:
	var x := _parar_no_sitio()
	var partes := FoundationGuide.sections(x)
	var fica := "\n".join(partes[FoundationGuide.KEEPS])
	assert_str(fica).contains(tr(&"FOUNDATION_NEAR_STATUE"))
	var territorio := FoundationGuide.territory(x)
	for linha: String in partes[FoundationGuide.TERRITORY]:
		assert_str(territorio).contains(linha)


func test_interact_at_the_site_asks_for_the_sheet_and_queues_nothing() -> void:
	_parar_no_sitio()
	assert_bool(SiteSheet.asks()).is_true()
	var ficha := _ficha()
	var router: InputRouter = auto_free(InputRouter.new())
	add_child(router)
	var interagir := InputEventAction.new()
	interagir.action = &"verb_assume"
	interagir.pressed = true
	router._unhandled_input(interagir)
	assert_bool(SiteSheet.active).is_true()
	assert_bool(ficha.visible).is_true()
	assert_int(SimLoop.intents.pending()).is_equal(0)
	assert_bool(SiteSheet.asks()).is_false()  # ja aberta: o segundo Interagir confirma
	assert_bool(ficha._back.has_focus()).is_true()  # o foco seguro: o Espaco nao funda


func test_the_context_line_steps_aside_while_the_sheet_is_open() -> void:
	_parar_no_sitio()
	var ficha := _ficha()
	var contexto: ContextPanel = auto_free(ContextPanel.new())
	add_child(contexto)
	contexto._process(1.0)
	assert_bool(contexto.visible).is_true()
	ficha.open()
	contexto._process(1.0)
	assert_bool(contexto.visible).is_false()
	ficha.close()
	contexto._process(1.0)
	assert_bool(contexto.visible).is_true()


func test_opening_the_sheet_spends_nothing_and_founds_nothing() -> void:
	var x := _parar_no_sitio()
	var bolsa := _bolsa()
	var ficha := _ficha()
	ficha.open()
	for tick in 30:
		SimLoop.step(1.0 / 30.0)
		ficha._process(1.0 / 30.0)
	assert_bool(SiteSheet.active).is_true()
	assert_str(String(SimLoop.arrival.choice)).is_empty()
	assert_bool(SimLoop.builds.foundation_committed).is_false()
	assert_that(_bolsa()).is_equal(bolsa)
	assert_str(ficha.text()).contains(tr(&"SHEET_FOUND_TITLE"))
	assert_str(ficha.text()).contains(tr(&"FOUNDATION_NEAR_STATUE"))
	assert_float(SimLoop.units.xs[SimLoop.units.index_of(SimLoop.king_id)]).is_equal(x)


func test_confirming_goes_through_the_intent_and_the_simulation_revalidates() -> void:
	var x := _parar_no_sitio()
	var bolsa := _bolsa()
	var ficha := _ficha()
	ficha.open()
	ficha.confirm()
	assert_bool(SiteSheet.active).is_false()
	assert_int(SimLoop.intents.pending()).is_equal(1)
	SimLoop.step(1.0 / 30.0)
	assert_str(String(SimLoop.arrival.choice)).is_not_empty()
	assert_float(SimLoop.core_x).is_equal(x)
	assert_that(_bolsa()).is_equal(bolsa)  # fundar nao gasta moedas: a lareira paga-se depois


func test_back_leaves_everything_as_it_was() -> void:
	_parar_no_sitio()
	var ficha := _ficha()
	ficha.open()
	ficha.close()
	assert_bool(SiteSheet.active).is_false()
	assert_bool(ficha.visible).is_false()
	assert_int(SimLoop.intents.pending()).is_equal(0)
	assert_str(String(SimLoop.arrival.choice)).is_empty()
	assert_bool(SiteSheet.asks()).is_true()


func test_a_site_that_stops_being_valid_closes_the_sheet_without_founding() -> void:
	_parar_no_sitio()
	var ficha := _ficha()
	ficha.open()
	var u := SimLoop.units
	u.xs[u.index_of(SimLoop.king_id)] = SimLoop.secrets.xs[0]  # em cima da estatua, nao
	ficha._process(0.0)
	assert_bool(SiteSheet.active).is_false()
	ficha.confirm()
	assert_int(SimLoop.intents.pending()).is_equal(0)


func test_the_sheet_blocks_the_world_while_open() -> void:
	_parar_no_sitio()
	var ficha := _ficha()
	ficha.open()
	assert_bool(TouchControls.playing()).is_false()
	assert_bool(CombatInput.blocked()).is_true()
	ficha.close()
	assert_bool(TouchControls.playing()).is_true()


func test_the_sheet_leaves_the_centre_free_on_desktop_and_fits_a_phone() -> void:
	_parar_no_sitio()
	for caso: Array in [[Vector2i(1280, 720), false], [Vector2i(844, 390), true]]:
		var viewport: SubViewport = auto_free(SubViewport.new())
		viewport.size = caso[0]
		add_child(viewport)
		TouchControls.active = caso[1]
		var ficha := SiteSheet.new()
		viewport.add_child(ficha)
		for locale: String in ["pt_PT", "en"]:
			TranslationServer.set_locale(locale)
			ficha.open()
			ficha._process(0.0)
			var caixa := ficha.get_global_rect()
			var ecra := Rect2(Vector2.ZERO, Vector2(caso[0]))
			assert_bool(ecra.encloses(caixa)).is_true()
			if not caso[1]:
				assert_bool(caixa.has_point(ecra.get_center())).is_false()
			assert_str(ficha.text()).not_contains("SHEET_")
			assert_str(ficha.text()).not_contains("{")
			ficha.close()
