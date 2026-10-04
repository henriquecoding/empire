extends GdUnitTestSuite


func _profile() -> WildlifeData:
	var data := WildlifeData.new()
	data.id = &"rabbit"
	data.roam_px = 40.0
	data.flee_px = 80.0
	data.shadow_width = 20
	data.habitat_min_px = 640.0
	return data


func _wall(x: float, territory: int = 0, band: Band.Kind = Band.Kind.SURFACE) -> BuildSlot:
	var site := BuildSlot.new()
	site.x = x
	site.width = 40.0
	site.band = band
	site.territory = territory
	site.blocks = true
	site.costs = PackedInt32Array([1])
	site.healths = PackedInt32Array([10])
	site.healths_a = PackedInt32Array([10])
	site.raise_to(1)
	return site


func _builds() -> BuildSystem:
	var builds := BuildSystem.new()
	var seat := BuildSlot.new()
	seat.kind = BuildSlot.NUCLEO
	seat.x = 2000.0
	seat.width = 480.0
	builds.post(seat)
	return builds


func test_a_margem_inclui_fuga_e_o_corpo_inteiro() -> void:
	assert_float(HuntHabitats.margin(_profile())).is_equal(90.0)
	var data := _profile()
	data.roam_px = 120.0
	assert_float(HuntHabitats.margin(data)).is_equal(130.0)


func test_o_segmento_respeita_a_distancia_nos_dois_lados() -> void:
	var data := _profile()
	assert_bool(HuntHabitats.supports(data, Vector2(730.0, 1370.0), 0.0)).is_true()
	assert_bool(HuntHabitats.supports(data, Vector2(-1370.0, -730.0), 0.0)).is_true()
	assert_bool(HuntHabitats.supports(data, Vector2(729.0, 1369.0), 0.0)).is_false()
	assert_bool(HuntHabitats.supports(data, Vector2(-10.0, 10.0), 0.0)).is_false()
	data.habitat_min_px = 0.0
	assert_bool(HuntHabitats.supports(data, Vector2(-10.0, 10.0), 0.0)).is_true()


func test_so_muralhas_proprias_de_pe_reclamam_territorio() -> void:
	var builds := _builds()
	assert_vector(HuntHabitats.claimed(builds)).is_equal(Vector2(1760.0, 2240.0))
	builds.post(_wall(1320.0))
	builds.post(_wall(4000.0, 2))
	builds.post(_wall(3500.0, 0, Band.Kind.UNDERGROUND))
	var broken := _wall(3408.0)
	broken.state = BuildSlot.State.RUIN
	builds.post(broken)
	assert_vector(HuntHabitats.claimed(builds)).is_equal(Vector2(1300.0, 2240.0))
	builds.post(_wall(2680.0))
	assert_vector(HuntHabitats.claimed(builds)).is_equal(Vector2(1300.0, 2700.0))
	assert_vector(HuntHabitats.claimed(BuildSystem.new())).is_equal(Vector2(INF, -INF))


func test_uma_obra_ocupada_encerra_a_toca_sem_apagar_receita_ou_animais() -> void:
	var data := _profile()
	var hunt := HuntingSystem.new({}, data)
	hunt.wildlife = {&"rabbit": data}
	hunt.burrows.place([2500.0, 2900.0] as Array[float], [0.0, 0.0] as Array[float])
	hunt.rabbits = [2500.0]
	hunt.herd.arrive(2500.0)
	hunt.bagged = {4: 3}
	var builds := _builds()
	var farm := _wall(2500.0)
	farm.healths_a = PackedInt32Array()
	farm.blocks = false
	farm.kind = &"farm"
	builds.post(farm)
	HuntHabitats.reserve(hunt, builds)
	assert_array(Array(hunt.burrows.alive)).is_equal([0, 1])
	assert_array(hunt.rabbits).is_equal([2500.0])
	assert_dict(hunt.bagged).is_equal({4: 3})
	hunt.lose(2500.0)
	hunt.grow(500.0, true, 1.0)
	assert_bool(hunt.rabbits.has(2500.0)).is_false()


func test_um_convite_vazio_nao_fecha_o_habitat_mas_uma_obra_paga_sim() -> void:
	var hunt := HuntingSystem.new({}, _profile())
	hunt.burrows.place([2500.0] as Array[float], [0.0] as Array[float])
	var builds := _builds()
	var farm := _wall(2500.0)
	farm.healths_a = PackedInt32Array()
	farm.raise_to(0)
	builds.post(farm)
	HuntHabitats.reserve(hunt, builds)
	assert_int(hunt.burrows.living()).is_equal(1)
	farm.paid = 1
	farm.state = BuildSlot.State.SCAFFOLD
	HuntHabitats.reserve(hunt, builds)
	assert_int(hunt.burrows.living()).is_equal(0)


func test_o_save_conserva_a_toca_encerrada() -> void:
	var hunt := HuntingSystem.new({}, _profile())
	hunt.burrows.place([2000.0] as Array[float], [0.0] as Array[float])
	HuntHabitats.reserve(hunt, _builds())
	var copy := HuntingSystem.new({}, _profile())
	copy.from_dict(hunt.to_dict())
	copy.grow(600.0, true, 1.0)
	assert_int(copy.burrows.living()).is_equal(0)
	assert_array(copy.rabbits).is_empty()
