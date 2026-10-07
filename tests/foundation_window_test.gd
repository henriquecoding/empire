# tests/foundation_window_test.gd — a fundacao livre, verificada (ADR 0066, ADR 0070):
# parado num sitio onde nao ha nada, funda-se — em qualquer lado do mundo. O que esta
# perto (estatua, raizes, boca) fica e e consequencia, nao proibicao; a noite nasce em
# relacao ao reino; e a carroca nunca fica perdida para tras.
extends GdUnitTestSuite


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20261005)
	Greybox.build()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _parar_em(x: float) -> void:
	var u := SimLoop.units
	u.xs[u.index_of(SimLoop.king_id)] = x
	u.clear_target(SimLoop.king_id)
	SimLoop.step(1.0)


func _ao_lado_de(x: float) -> float:
	return x + RealmLadder.seat(SimLoop.builds).catch_half() + Band.PASSAGE_PX + 8.0


func test_stopping_where_there_is_nothing_founds_almost_everywhere() -> void:
	var livres := 0
	var total := 0
	var bloqueado := 0.0
	var maior := 0.0
	var x := 0.0
	while x <= SimLoop.world_width:
		total += 1
		if FoundationChoice.valid(x) and not FoundationChoice.priority_at(x):
			livres += 1
			bloqueado = 0.0
		else:
			bloqueado += 16.0
			maior = maxf(maior, bloqueado)
		x += 16.0
	# Eram 37 em 241 (16 %): uma estatua, uma raiz ou uma boca a 240 px bastava, e havia
	# zonas mortas de mais de 600 px. Agora so o chao da propria sede tem de estar livre.
	assert_float(float(livres) / float(total)).is_greater(0.5)
	var sitio := RealmLadder.seat(SimLoop.builds).catch_half() + Band.PASSAGE_PX
	assert_float(maior).is_less_equal(2.0 * sitio + 32.0)
	var estatua := SimLoop.secrets.xs[0]
	assert_bool(FoundationChoice.valid(estatua)).is_false()  # em cima dela, nao
	assert_bool(FoundationChoice.valid(_ao_lado_de(estatua))).is_true()  # ao lado, sim


func test_what_is_near_stays_and_only_common_flora_is_cleared() -> void:
	var x := _ao_lado_de(SimLoop.secrets.xs[0])
	_parar_em(x)
	var segredos := SimLoop.secrets.xs.duplicate()
	assert_bool(FoundationChoice.claim(x)).is_true()
	assert_array(SimLoop.secrets.xs).is_equal(segredos)  # a estatua fica, dentro da clareira
	assert_float(SimLoop.core_x).is_equal(x)


func test_founding_in_the_generated_lands_brings_the_night_with_the_realm() -> void:
	var w := SimLoop.world_width
	var x := w + 2600.0
	_parar_em(x)
	assert_bool(FoundationChoice.claim(x)).is_true()
	assert_float(SimLoop.core_x).is_equal(x)
	var bordas := RealmFrame.edges()
	assert_float(bordas.x).is_equal(x - w * 0.5)
	assert_float(bordas.y).is_equal(x + w * 0.5)
	var rot := SimLoop.night.rot
	rot.spawn(2, 1, w)
	RealmFrame.place(rot)
	assert_float(rot.position_x()).is_equal(bordas.y)  # a leste do reino, e nao da regiao
	rot.spawn(2, -1, w)
	RealmFrame.place(rot)
	assert_float(rot.position_x()).is_equal(bordas.x)
	assert_bool(Lume.at_base(bordas.y)).is_true()
	assert_bool(Lume.at_base(w)).is_false()


func test_a_realm_at_the_old_heart_keeps_the_night_where_it_always_was() -> void:
	var o := SimLoop.arrival
	_parar_em(o.origin)
	assert_bool(FoundationChoice.claim(o.origin)).is_true()
	assert_float(RealmFrame.edges().x).is_equal(0.0)
	assert_float(RealmFrame.edges().y).is_equal(SimLoop.world_width)


func test_a_lagging_cart_anchors_to_the_realm_with_every_coin() -> void:
	var o := SimLoop.arrival
	var x := o.origin - 83.0
	_parar_em(x)
	SimLoop.seat.cart_x = o.origin - 1500.0  # a carroca ficou para tras
	var moedas := SimLoop.seat.cart_coins + o.cache_coins
	assert_bool(FoundationChoice.claim(x)).is_true()
	for tick in 30 * 30:
		SimLoop.step(1.0 / 30.0)
	assert_float(SimLoop.seat.cart_x).is_equal_approx(SimLoop.core_x + LastCartWatch.CART_X, 0.01)
	assert_int(SimLoop.seat.cart_coins + o.cache_coins).is_equal(moedas)
	assert_bool(SimLoop.seat.cart_open).is_true()


func test_the_caravan_catches_up_instead_of_falling_behind_forever() -> void:
	var u := SimLoop.units
	var rei := u.index_of(SimLoop.king_id)
	u.set_target_x(SimLoop.king_id, u.xs[rei] + 2400.0)
	for tick in 25 * 30:
		SimLoop.step(1.0 / 30.0)
	var atraso := absf(SimLoop.seat.cart_x - u.xs[rei])
	assert_float(atraso).is_less(LastCartWatch.rules().caravan_catch_up_px + 64.0)


func test_the_sheet_reads_what_founding_here_takes_and_keeps() -> void:
	var x := _ao_lado_de(SimLoop.secrets.xs[0])
	var raio := LastCartWatch.rules().foundation_clear_radius
	var w := SimLoop.field.woodland
	var arvores := 0
	for i in w.count():
		if w.standing(i) and absf(w.xs[i] - x) <= raio:
			arvores += 1
	# A ficha do sitio (UX-08, ADR 0078) le estas secoes; o painel curto ja nao as repete.
	var partes := FoundationGuide.sections(x)
	var leitura := "\n".join(partes[FoundationGuide.CLEARS] + partes[FoundationGuide.KEEPS])
	var estatua := TranslationServer.translate(&"FOUNDATION_NEAR_STATUE")
	assert_str(leitura).contains(estatua)  # fica dentro do reino, e diz-se
	if arvores > 0:
		assert_str(leitura).contains(str(arvores))
	_parar_em(x)
	var o := SimLoop.arrival
	o.stationary_s = LastCartWatch.rules().foundation_stop_s
	var painel := ArrivalGuide.context(x, Band.Kind.SURFACE, {"assume": "E"})
	assert_str(painel).not_contains(estatua)
	assert_bool(FoundationChoice.claim(x)).is_true()  # e funda-se na mesma
