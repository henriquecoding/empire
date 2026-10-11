extends GdUnitTestSuite

var _locale := ""


func before_test() -> void:
	_locale = TranslationServer.get_locale()
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20261006)
	Greybox.build()
	SimLoop.step(1.0 / 60.0)


func after_test() -> void:
	TouchControls.active = false
	SimLoop.stop()
	SimLoop.autosave_enabled = true
	TranslationServer.set_locale(_locale)


func test_unfounded_keep_is_not_reported_as_destroyed() -> void:
	var seat := RealmLadder.seat(SimLoop.builds)
	seat.level = 0
	seat.health = 0
	assert_int(RealmReadout.core_health()).is_equal(-1)
	for locale: String in ["pt_PT", "en"]:
		TranslationServer.set_locale(locale)
		assert_str(RealmReadout.overview()).contains(tr(&"HUD_NOT_FOUNDED"))
	seat.level = 1
	assert_int(RealmReadout.core_health()).is_equal(0)


func test_overview_keeps_all_resources_in_both_languages() -> void:
	for locale: String in ["pt_PT", "en"]:
		TranslationServer.set_locale(locale)
		var overview := RealmReadout.overview()
		assert_int(overview.split("\n").size()).is_equal(11)
		assert_str(overview).contains(tr(&"HUD_DETAIL_TREASURY").get_slice("{", 0))
		assert_str(overview).not_contains("HUD_")
		assert_str(overview).not_contains("{")


func test_combat_buttons_disappear_on_touch_and_return_on_keyboard() -> void:
	var bar: CombatBar = auto_free(CombatBar.new())
	add_child(bar)
	TouchControls.active = true
	bar._process(0.0)
	assert_bool(bar.visible).is_false()
	TouchControls.active = false
	bar._process(0.0)
	assert_bool(bar.visible).is_true()


func test_realm_overview_stays_paused_and_back_restores_focus() -> void:
	var menu: PauseMenu = auto_free(PauseMenu.new())
	add_child(menu)
	SimLoop.set_paused(true)
	menu._show_controls(PauseMenu.Page.REALM)
	assert_bool(menu._pages.realm.visible).is_true()
	assert_str(menu._pages.overview.text).is_not_empty()
	menu.back()
	assert_bool(SimLoop.running()).is_false()
	assert_bool(menu._realm.has_focus()).is_true()


func test_compact_keyboard_context_does_not_cover_combat() -> void:
	var viewport: SubViewport = auto_free(SubViewport.new())
	viewport.size = Vector2i(667, 375)
	add_child(viewport)
	var bar := CombatBar.new()
	var context := ContextPanel.new()
	viewport.add_child(bar)
	viewport.add_child(context)
	bar._process(0)
	context._process(0)
	assert_bool(context.get_global_rect().intersects(bar.get_global_rect())).is_false()


func test_long_objective_grows_its_card_and_moves_context_below_it() -> void:
	var viewport: SubViewport = auto_free(SubViewport.new())
	# 760 unidades de interface: no toque cada uma vale TOUCH_POINTS pontos (UX-06).
	viewport.size = Vector2i(ceili(HudLayout.GOAL_MIN_WIDTH * HudLayout.TOUCH_POINTS), 390)
	add_child(viewport)
	TouchControls.active = true
	var ribbon := HudRibbon.new()
	var context := ContextPanel.new()
	viewport.add_child(ribbon)
	viewport.add_child(context)
	for locale: String in ["pt_PT", "en"]:
		TranslationServer.set_locale(locale)
		ribbon._goal.text = tr(&"GUIDE_WINTER")
		ribbon.fit()
		context._process(0)
		var box: Rect2 = ribbon._cards[&"goal"]
		assert_bool(box.encloses(ribbon._goal.get_rect())).is_true()
		assert_int(ribbon._goal.get_visible_line_count()).is_equal(ribbon._goal.get_line_count())
		assert_float(context.position.y).is_greater(ribbon.get_rect().end.y)


func test_touch_keeps_the_archers_ammunition_visible() -> void:
	var king := SimLoop.units.index_of(SimLoop.king_id)
	SimLoop.units.data_ids[king] = &"archer_emperor"
	TouchControls.active = true
	var ribbon: HudRibbon = auto_free(HudRibbon.new())
	add_child(ribbon)
	for locale: String in ["pt_PT", "en"]:
		TranslationServer.set_locale(locale)
		ribbon.refresh()
		assert_str(ribbon._season.text).is_equal(
			MonarchHud.arrows(SimLoop.king_id).trim_prefix(" · ")
		)
		assert_str(ribbon._season.text).contains("/")


func test_captions_clear_context_and_visible_notice() -> void:
	var hud: GameHud = auto_free(GameHud.new())
	var captions: Captions = auto_free(Captions.new())
	add_child(hud)
	add_child(captions)
	hud._context._process(HintCue.STOP_SECONDS)
	hud.say(tr(&"CAPTION_DUSK_WARNING"))
	hud._process(0)
	captions._process(0)
	assert_float(captions.position.y).is_greater(hud._context.get_global_rect().end.y)
	assert_float(captions.position.y).is_greater(hud._aviso.get_global_rect().end.y)
