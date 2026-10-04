extends GdUnitTestSuite

const STEP := 1.0 / 30.0


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20261004)
	Greybox.build()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _site(kind: StringName) -> BuildSlot:
	for slot in SimLoop.builds.slots:
		if slot.kind == kind and slot.territory == 0:
			return slot
	return null


func _walls(side: int) -> Array[BuildSlot]:
	var walls: Array[BuildSlot] = []
	for slot in SimLoop.builds.slots:
		if slot.two_paths() and (slot.x - SimLoop.core_x) * side > 0.0:
			walls.append(slot)
	walls.sort_custom(
		func(a: BuildSlot, b: BuildSlot) -> bool:
			return absf(a.x - SimLoop.core_x) < absf(b.x - SimLoop.core_x)
	)
	return walls


func _found() -> void:
	var seat := RealmLadder.seat(SimLoop.builds)
	seat.raise_to(RealmLadder.FUNDADO)
	FoundationWatch.after(
		[{BuildSystem.CHAVE: BuildSystem.EV_COMPLETA, BuildSystem.VAGA: seat}]
	)


func test_as_duas_bancas_so_aparecem_depois_de_fundar_dentro_do_primeiro_recinto() -> void:
	for kind in [&"hammer_rack", &"bow_rack"]:
		var bench := _site(kind)
		assert_bool(bench.standing()).is_false()
		assert_bool(RealmGrowth.visible(SimLoop.builds, bench)).is_false()
		assert_int(CoinTarget.slot_at(SimLoop.builds, bench.x, int(bench.band))).is_equal(-1)
	_found()
	for kind in [&"hammer_rack", &"bow_rack"]:
		var bench := _site(kind)
		assert_bool(bench.standing()).is_true()
		assert_bool(RealmGrowth.visible(SimLoop.builds, bench)).is_true()
		var side := -1 if bench.x < SimLoop.core_x else 1
		var wall := _walls(side)[0]
		assert_float(absf(bench.x - SimLoop.core_x) + bench.width * 0.5).is_less(
			absf(wall.x - SimLoop.core_x) - wall.width * 0.5
		)


func test_retomar_a_clareira_nao_cria_bancas() -> void:
	SimLoop.load_world(SimLoop.world())
	assert_int(_site(&"hammer_rack").level).is_equal(0)
	assert_int(_site(&"bow_rack").level).is_equal(0)


func test_cada_estagio_abre_so_a_proxima_muralha_de_cada_lado() -> void:
	_found()
	var seat := RealmLadder.seat(SimLoop.builds)
	for side in [-1, 1]:
		var walls := _walls(side)
		assert_int(walls.size()).is_equal(3)
		assert_bool(RealmGrowth.visible(SimLoop.builds, walls[0])).is_true()
		assert_bool(RealmGrowth.visible(SimLoop.builds, walls[1])).is_false()
		walls[0].raise_to(1)
		assert_bool(RealmGrowth.visible(SimLoop.builds, walls[1])).is_false()
		seat.raise_to(2)
		assert_bool(RealmGrowth.visible(SimLoop.builds, walls[1])).is_true()
		assert_bool(RealmGrowth.visible(SimLoop.builds, walls[2])).is_false()
		walls[1].raise_to(1)
		assert_bool(RealmGrowth.visible(SimLoop.builds, walls[2])).is_false()
		seat.raise_to(3)
		assert_bool(RealmGrowth.visible(SimLoop.builds, walls[2])).is_true()
		seat.raise_to(1)


func test_o_andaime_exterior_nao_publica_obras_ate_o_muro_ficar_de_pe() -> void:
	_found()
	RealmLadder.seat(SimLoop.builds).raise_to(2)
	var walls := _walls(-1)
	walls[0].raise_to(1)
	var tower := _site(&"archer_tower")
	var hens := _site(&"henhouse")
	assert_bool(RealmGrowth.visible(SimLoop.builds, tower)).is_false()
	assert_bool(RealmGrowth.visible(SimLoop.builds, hens)).is_false()
	walls[1].state = BuildSlot.State.SCAFFOLD
	assert_bool(RealmGrowth.visible(SimLoop.builds, tower)).is_false()
	walls[1].raise_to(1)
	assert_bool(RealmGrowth.visible(SimLoop.builds, tower)).is_true()
	assert_bool(RealmGrowth.visible(SimLoop.builds, hens)).is_true()
	assert_bool(RealmGrowth.protected(SimLoop.builds, tower)).is_true()
	assert_bool(RealmGrowth.visible(SimLoop.builds, _site(&"granary"))).is_false()


func test_o_canteiro_inicial_pede_o_primeiro_muro_e_os_exteriores_pedem_expansao() -> void:
	_found()
	var inner: BuildSlot = null
	var outer: BuildSlot = null
	for slot in SimLoop.builds.slots:
		if slot.kind != &"farm" or slot.x < SimLoop.core_x:
			continue
		if inner == null or slot.x < inner.x:
			inner = slot
		if outer == null or slot.x > outer.x:
			outer = slot
	assert_bool(RealmGrowth.visible(SimLoop.builds, inner)).is_false()
	_walls(1)[0].raise_to(1)
	assert_bool(RealmGrowth.visible(SimLoop.builds, inner)).is_true()
	assert_bool(RealmGrowth.visible(SimLoop.builds, outer)).is_false()
	RealmLadder.seat(SimLoop.builds).raise_to(3)
	_walls(1)[1].raise_to(1)
	_walls(1)[2].raise_to(1)
	assert_bool(RealmGrowth.visible(SimLoop.builds, outer)).is_true()


func test_todos_os_convites_da_cidade_cabem_em_area_defendida_em_cada_estagio() -> void:
	for stage in range(1, 6):
		RealmLadder.seat(SimLoop.builds).raise_to(stage)
		for side in [-1, 1]:
			var walls := _walls(side)
			for rank in mini(stage, walls.size()):
				walls[rank].raise_to(3)
		for slot in SimLoop.builds.slots:
			if slot.territory != 0 or slot.band != Band.Kind.SURFACE:
				continue
			if slot.kind == BuildSlot.NUCLEO or slot.two_paths():
				continue
			var policy := RealmGrowth.policy(slot)
			if policy == null or policy.placement in [&"wilderness", &"native"]:
				continue
			if RealmGrowth.visible(SimLoop.builds, slot, SimLoop.state):
				assert_bool(RealmGrowth.protected(SimLoop.builds, slot)).override_failure_message(
					"%s no estagio %d" % [slot.kind, stage]
				).is_true()
