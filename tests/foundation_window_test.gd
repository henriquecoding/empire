# tests/foundation_window_test.gd — a verificacao da fundacao livre (ADR 0066, ADR 0070):
# a sede so nasce onde a noite e as muralhas continuam a fazer sentido, e a carroca
# nunca fica perdida para tras.
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


func test_the_generated_lands_are_not_foundation_ground() -> void:
	var w := SimLoop.world_width
	_parar_em(w + 2600.0)
	assert_bool(FoundationChoice.valid(w + 2600.0)).is_false()
	assert_bool(FoundationChoice.claim(w + 2600.0)).is_false()
	assert_float(SimLoop.core_x).is_equal(SimLoop.arrival.origin)


func test_the_window_keeps_the_second_ring_inside_the_edges_where_night_is_born() -> void:
	var o := SimLoop.arrival.origin
	var janela := LastCartWatch.rules().foundation_window_px
	assert_bool(FoundationChoice.valid(o + janela + 1.0)).is_false()
	assert_bool(FoundationChoice.valid(o - janela - 1.0)).is_false()
	assert_bool(FoundationChoice.valid(o - 83.0)).is_true()
	_parar_em(o - 83.0)
	assert_bool(FoundationChoice.claim(o - 83.0)).is_true()
	for vaga in SimLoop.builds.slots:
		if vaga.two_paths() and vaga.territory == 0 and absf(vaga.x - SimLoop.core_x) < 1500.0:
			assert_float(vaga.x).is_between(0.0, SimLoop.world_width)


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
