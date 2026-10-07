extends GdUnitTestSuite


func test_header_cards_fit_without_overlap_on_phone_deck_and_wide_canvas() -> void:
	for width: float in [568.0, 667.0, 844.0, 1280.0, 1600.0]:
		var area := Vector2(width, 720.0)
		var cards := HudLayout.header(area)
		for key: StringName in cards:
			var box: Rect2 = cards[key]
			if not box.has_area():
				continue
			assert_bool(Rect2(Vector2.ZERO, area).encloses(box)).is_true()
			for other: StringName in cards:
				if other != key:
					assert_bool(box.intersects(cards[other])).is_false()


func test_small_phone_uses_context_for_goal_instead_of_squeezing_text() -> void:
	assert_bool(HudLayout.header(Vector2(667, 375))[&"goal"].has_area()).is_false()
	assert_bool(HudLayout.header(Vector2(844, 390))[&"goal"].has_area()).is_true()


func test_context_expands_for_consequences_and_stays_centred() -> void:
	for width: float in [568.0, 844.0, 1280.0, 1600.0]:
		var area := Vector2(width, 720)
		var short_box := HudLayout.context(area, 24.0)
		var long_box := HudLayout.context(area, 110.0)
		assert_float(long_box.size.y).is_greater(short_box.size.y)
		assert_float(long_box.get_center().x).is_equal_approx(width / 2.0, 0.1)
		assert_float(long_box.position.y).is_greater(HudLayout.HEADER_BOTTOM)
		assert_bool(Rect2(Vector2.ZERO, area).encloses(long_box)).is_true()


func test_touch_pause_uses_header_corner_and_has_room_for_the_finger() -> void:
	var layout := TouchLayout.new()
	var pause := layout.centre(TouchLayout.Role.PAUSE)
	assert_float(pause.y).is_less(GameHud.FAIXA_TOPO)
	assert_int(layout.role_at(pause)).is_equal(TouchLayout.Role.PAUSE)
	assert_float(layout.reach(TouchLayout.Role.PAUSE)).is_greater_equal(22.0)


func test_touch_actions_leave_more_of_the_world_free() -> void:
	var layout := TouchLayout.new()
	for role: TouchLayout.Role in TouchLayout.BOTOES:
		var left_edge := layout.centre(role).x - layout.radius(role)
		assert_float(left_edge).is_greater(900.0)


## UX-06: o iPhone da tres pixeis por ponto; a interface conta pontos, e nao pixeis.
func test_interface_counts_points_not_pixels_on_dense_screens() -> void:
	var iphone := HudLayout.zoom_for(1170.0 / 720.0, 3.0)
	assert_float(iphone).is_equal_approx(HudLayout.zoom_for(390.0 / 720.0, 1.0), 0.001)
	assert_float(iphone * 1170.0 / 720.0 / 3.0).is_equal_approx(1.0, 0.001)
	assert_float(HudLayout.zoom_for(1.0, 1.0)).is_equal(1.0)
	assert_float(HudLayout.zoom_for(2.5, 2.0)).is_equal(1.0)
	assert_float(HudLayout.zoom_for(2.0, 0.0)).is_equal(1.0)


## UX-06: no toque um texto so estreita se tapasse um controlo; e so fica estreito se,
## ja com a altura nova, nao tapar nenhum, couber no ecra e se ler. Senao fica largo.
func test_touch_text_moves_off_the_controls_only_when_it_stays_clear() -> void:
	var antes := TouchLayout.circles
	TouchControls.active = true
	var texto: Label = auto_free(Label.new())
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.add_theme_font_override("font", HudStyle.font())
	texto.add_theme_font_size_override("font_size", 16)
	texto.text = "Vagabundo · Moedas em falta: 1\nMOEDA largar para recrutar"
	add_child(texto)
	var ecra := Vector2(1558.0, 720.0)
	var baixos: Array[Vector3] = [Vector3(200, 680, 30), Vector3(1350, 680, 30)]
	TouchLayout.circles = baixos
	HudLayout.fit_label(texto, ecra, 2.12, 480.0, 170.0)
	assert_float(texto.size.x).is_equal_approx(480.0, 0.01)
	var altos: Array[Vector3] = [Vector3(250, 300, 90), Vector3(1300, 300, 90)]
	TouchLayout.circles = altos
	HudLayout.fit_label(texto, ecra, 2.12, 480.0, 170.0)
	assert_float(texto.size.x).is_less(480.0)
	var posto := Rect2(texto.position, Vector2(texto.size.x, 0.0))
	assert_bool(HudLayout._clear(texto, posto, 2.12, 720.0)).is_true()
	var apertados: Array[Vector3] = [Vector3(700, 300, 90), Vector3(860, 300, 90)]
	TouchLayout.circles = apertados
	HudLayout.fit_label(texto, ecra, 2.12, 480.0, 170.0)
	assert_float(texto.size.x).is_equal_approx(480.0, 0.01)
	TouchControls.active = false
	TouchLayout.circles = antes


## UX-06: com os controlos de um iPhone SE e textos compridos, o texto estreito nunca tapa
## um botao nem sai do ecra; quando nao da, fica largo como na main.
func test_long_touch_texts_never_end_narrow_over_a_button() -> void:
	var antes := TouchLayout.circles
	TouchControls.active = true
	var l := TouchLayout.new()
	l.screen = Vector2(1280.0, 720.0)
	l.scale = 1.4
	TouchLayout.circles = l.circles_now()
	var texto: Label = auto_free(Label.new())
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.add_theme_font_override("font", HudStyle.font())
	texto.add_theme_font_size_override("font_size", 16)
	add_child(texto)
	TranslationServer.set_locale("pt_PT")
	for chave: StringName in [&"CONTEXT_SEAT_UPGRADE", &"CONTEXT_TRAIN", &"ARRIVAL_CHOOSE_INTRO"]:
		texto.text = tr(chave) + "\n" + tr(&"CONTEXT_SEAT_NEW_WALLS")
		HudLayout.fit_label(texto, l.screen, 2.208, HudLayout.CONTEXT_WIDTH, 177.0)
		var largo := minf(HudLayout.CONTEXT_WIDTH, 1280.0 / 2.208 - HudLayout.MARGIN * 2)
		var onde := Rect2(texto.position, Vector2(texto.size.x, 0.0))
		var ficou_largo := is_equal_approx(texto.size.x, largo)
		assert_bool(ficou_largo or HudLayout._clear(texto, onde, 2.208, 720.0)).is_true()
	TouchControls.active = false
	TouchLayout.circles = antes


## UX-06: a altura que o fit_label mede e a que o Label desenha — com larguras partidas
## (o Label dobra em unidades inteiras) e palavras maiores do que a linha (WORD_SMART).
## Com a medida curta de uma linha, um texto estreito "livre" caia em cima do INTERAGIR.
func test_measured_text_height_is_the_drawn_height() -> void:
	var texto: Label = auto_free(Label.new())
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.add_theme_font_override("font", HudStyle.font())
	texto.add_theme_font_size_override("font_size", 16)
	var painel := HudStyle.panel()
	painel.set_content_margin_all(HudLayout.GAP)
	texto.add_theme_stylebox_override("normal", painel)
	add_child(texto)
	TranslationServer.set_locale("pt_PT")
	var textos := [
		tr(&"CONTEXT_WALL_BUILDER"),
		tr(&"ARRIVAL_GOAL_PEOPLE"),
		"Berserker de Raiz",
		"RECRUTA UM TRABALHADOR CONSTRUTORAMENTE",
	]
	for t: String in textos:
		texto.text = t
		for largura: float in [140.5, 151.5, 233.7, 426.35, 519.9]:
			texto.size = Vector2(largura, 0.0)
			var real := texto.get_minimum_size().y
			assert_float(HudLayout.text_height(texto, largura)).is_equal_approx(real, 0.5)
	# O Control guarda a largura como fim menos inicio: pedida com 190, pode ficar com
	# 189,99997 e o Label dobra uma unidade antes. A medida de 190 nao pode dar menos.
	texto.text = "Arqueiro · Train a ferreiro: 12 coins remaining\nCOIN fund the training · a worker"
	texto.text += " of yours goes in for a day"
	texto.size = Vector2(189.99997, 0.0)
	var desenhada := texto.get_minimum_size().y
	assert_float(HudLayout.text_height(texto, 190.0)).is_greater_equal(desenhada)


## UX-06: o caso do iPhone SE com o toque um pouco maior — o muro sem construtor ficava
## estreito por cima do INTERAGIR. Medido pelo Label ja posto, nunca toca num controlo
## se estreitou.
func test_narrow_context_on_a_small_phone_clears_the_drawn_buttons() -> void:
	var antes := TouchLayout.circles
	TouchControls.active = true
	var l := TouchLayout.new()
	l.screen = Vector2(1280.0, 720.0)
	l.scale = 1.54
	TouchLayout.circles = l.circles_now()
	var texto: Label = auto_free(Label.new())
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.add_theme_font_override("font", HudStyle.font())
	texto.add_theme_font_size_override("font_size", 16)
	var painel := HudStyle.panel()
	painel.set_content_margin_all(HudLayout.GAP)
	texto.add_theme_stylebox_override("normal", painel)
	add_child(texto)
	TranslationServer.set_locale("pt_PT")
	texto.text = tr(&"CONTEXT_WALL_BUILDER")
	HudLayout.fit_label(texto, l.screen, 2.208, HudLayout.CONTEXT_WIDTH, 176.64)
	var largo := minf(HudLayout.CONTEXT_WIDTH, 1280.0 / 2.208 - HudLayout.MARGIN * 2)
	if not is_equal_approx(texto.size.x, largo):
		var caixa := Rect2(texto.position, texto.get_minimum_size() * 2.208)
		caixa.size.x = texto.size.x * 2.208
		assert_float(caixa.end.y).is_less_equal(720.0)
		for c: Vector3 in TouchLayout.circles:
			var perto := Vector2(c.x, c.y).clamp(caixa.position, caixa.end)
			assert_float(perto.distance_to(Vector2(c.x, c.y))).is_greater_equal(c.z)
	TouchControls.active = false
	TouchLayout.circles = antes
