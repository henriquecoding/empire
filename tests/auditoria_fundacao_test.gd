extends GdUnitTestSuite


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20261007)
	Greybox.build()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func test_fundar_depois_de_visitar_preserva_o_subsolo_e_reserva_baia() -> void:
	for x in [520.0, 2620.0]:
		before_test()
		var u := SimLoop.units
		var king := u.index_of(SimLoop.king_id)
		for mouth in SimLoop.passages:
			u.xs[king] = mouth
			assert_bool(Verbs.assume(u, SimLoop.king_id, SimLoop.passages)).is_true()
			assert_bool(Verbs.assume(u, SimLoop.king_id, SimLoop.passages)).is_true()
		var known := SimLoop.field.under.layouts.duplicate(true)
		u.xs[king] = x
		u.clear_target(SimLoop.king_id)
		SimLoop.step(1.0)
		var claimed := FoundationChoice.claim(x)
		if claimed:
			_check_vault()
			var saved := SimLoop.world()
			for reload in 2:
				SimLoop.resume(SimLoop.state, RngService.snapshot())
				Greybox.region()
				SimLoop.load_world(saved)
				_check_vault()
		else:
			assert_bool(SimLoop.builds.foundation_committed).is_false()
			assert_bool(FoundationChoice.valid(x)).is_false()
		for key: String in known:
			assert_array(SimLoop.field.under.layouts[key]).is_equal(known[key])
		after_test()


func _check_vault() -> void:
	var under := SimLoop.field.under
	for k in under.count():
		if under.key_of(k) != UnderWatch.HATCH_KEY:
			continue
		UnderWatch.enter(under.mouth_of(k))
		assert_bool(under.usable(k)).is_true()
		assert_str(String(under.why(k))).is_empty()
		assert_bool(is_finite(UnderReserve.chest_x(under, k))).is_true()
		for other in under.count():
			if k == other or not under.generated(other):
				continue
			var a := under.span(k)
			var b := under.span(other)
			assert_bool(a.y <= b.x or b.y <= a.x).is_true()


func test_rampa_sete_noites_e_primeiro_pico_doze() -> void:
	var p := SimFactory.rot_profile()
	assert_int(p.ramp_nights).is_equal(7)
	for day in range(1, 21):
		var expected := 1.0
		if day in [12, 18]:
			expected = p.peak_mass_mult
		elif day in [13, 19]:
			expected = p.calm_mass_mult
		assert_float(p.rhythm(day)).is_equal(expected)
