extends GdUnitTestSuite

const STEP := 1.0 / 30.0
const FIRST_VIEW_HALF := 640.0


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20261004)
	Greybox.build()
	SimLoop.step(STEP)


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _wall(offset: float) -> BuildSlot:
	for site in SimLoop.builds.slots:
		if site.two_paths() and is_equal_approx(site.x, SimLoop.core_x + offset):
			return site
	return null


func test_a_primeira_vista_nao_tem_tocas_nem_animais_de_caca() -> void:
	var hunt := SimLoop.hunting
	for x in hunt.burrows.xs:
		var data := hunt.species_at(x)
		var roam := maxf(data.roam_px, data.flee_px)
		assert_float(absf(x - SimLoop.core_x) - roam - data.shadow_width * 0.5).is_greater(
			FIRST_VIEW_HALF
		)
	for x in hunt.rabbits:
		assert_float(absf(hunt.herd.where(x) - SimLoop.core_x)).is_greater(FIRST_VIEW_HALF)


func test_preserva_o_coelho_dos_arrabaldes_sem_javali_na_chegada() -> void:
	var rabbits := 0
	for x in SimLoop.hunting.burrows.xs:
		var data := SimLoop.hunting.species_at(x)
		assert_int(data.damage).is_equal(0)
		if data.id == &"rabbit":
			rabbits += 1
			assert_float(x).is_less(SimLoop.core_x)
			assert_float(absf(x - SimLoop.core_x)).is_less_equal(1400.0)
	assert_int(rabbits).is_equal(1)


func test_a_expansao_fecha_o_respawn_mas_nao_apaga_a_caca_que_ja_estava() -> void:
	var hunt := SimLoop.hunting
	var inside := SimLoop.core_x + 1000.0
	hunt.burrows.add(inside, 0.0, "bush", "rabbit")
	hunt.rabbits.append(inside)
	hunt.herd.arrive(inside)
	_wall(1408.0).raise_to(1)
	SimLoop.step(STEP)
	assert_int(hunt.burrows.alive[hunt.burrows.xs.find(inside)]).is_equal(0)
	assert_bool(hunt.rabbits.has(inside)).is_true()
	hunt.lose(inside)
	hunt.grow(600.0, true, 1.0)
	assert_bool(hunt.rabbits.has(inside)).is_false()
	var left := SimLoop.core_x - 830.0
	assert_int(hunt.burrows.alive[hunt.burrows.xs.find(left)]).is_equal(1)


func test_o_primeiro_trecho_exterior_nao_amontoa_todas_as_especies() -> void:
	var i := SimLoop.units.index_of(SimLoop.king_id)
	SimLoop.units.xs[i] = SimLoop.world_width
	SimLoop.units.clear_target(SimLoop.king_id)
	SimLoop.step(STEP)
	var end := SimLoop.world_width + SimLoop.field.wilds.width
	var count := 0
	for x in SimLoop.hunting.burrows.xs:
		if x <= SimLoop.world_width or x >= end:
			continue
		count += 1
		assert_int(SimLoop.hunting.species_at(x).damage).is_equal(0)
	assert_int(count).is_between(1, 2)


func test_carregar_um_reino_expandido_nao_inventa_animais_nas_tocas_encerradas() -> void:
	_wall(-1408.0).raise_to(1)
	var save := {&"save_version": 8, &"world": SimLoop.world()}
	SimLoop.load_world(SaveMigrations.migrate(save)[&"world"])
	SimLoop.step(STEP)
	for offset in [-830.0]:
		var x: float = SimLoop.core_x + offset
		var k := SimLoop.hunting.burrows.xs.find(x)
		assert_int(k).is_greater_equal(0)
		assert_int(SimLoop.hunting.burrows.alive[k]).is_equal(0)
		assert_bool(SimLoop.hunting.rabbits.has(x)).is_false()
	var deer := SimLoop.hunting.burrows.xs.find(SimLoop.core_x - 1692.0)
	assert_int(SimLoop.hunting.burrows.alive[deer]).is_equal(1)


func test_o_save_v8_corrige_os_habitats_sem_apagar_o_reino_ou_a_receita() -> void:
	var old := {
		&"save_version": 8,
		&"state": {&"day": 8, &"royal_seeds": 2},
		&"world":
		{
			&"units": {&"carried_coins": [12]},
			&"builds": [{&"level": 3}],
			&"hunting":
			{
				&"day": 8,
				&"intro_done": true,
				&"bagged": {2: 7},
				&"rabbits": [180.0],
				&"burrows": {&"xs": [180.0]},
				&"wounds": {180.0: 2},
				&"herd": {&"positions": {180.0: 190.0}},
			},
		},
	}
	var migrated := SaveMigrations.migrate(old)
	var hunt: Dictionary = migrated[&"world"][&"hunting"]
	assert_int(int(migrated[&"save_version"])).is_equal(SaveMigrations.CURRENT)
	assert_array(hunt[&"rabbits"]).is_empty()
	assert_dict(hunt[&"burrows"]).is_empty()
	assert_dict(hunt[&"wounds"]).is_empty()
	assert_dict(hunt[&"herd"]).is_empty()
	assert_dict(hunt[&"bagged"]).is_equal({2: 7})
	assert_dict(migrated[&"state"]).is_equal(old[&"state"])
	assert_dict(migrated[&"world"][&"units"]).is_equal(old[&"world"][&"units"])
	assert_array(migrated[&"world"][&"builds"]).is_equal(old[&"world"][&"builds"])
	assert_array(old[&"world"][&"hunting"][&"rabbits"]).is_equal([180.0])
