extends GdUnitTestSuite

var units: UnitSystem
var state: GameState
var hunt: HuntingSystem


func before_test() -> void:
	units = UnitSystem.new()
	state = GameState.new()
	hunt = HuntingSystem.new(SimFactory.by_id(&"units"), Registry.entry(&"wildlife", &"rabbit"))
	hunt.open_day(1, [100.0, 120.0, 900.0])


func _archer(owner: int = 1) -> int:
	return units.spawn(state, Registry.entry(&"units", &"archer"), owner, 0.0)


func test_neutral_archer_does_not_create_a_coin_at_the_first_tick() -> void:
	_archer(0)
	assert_array(hunt.resolve(units, true, false)).is_empty()
	assert_int(hunt.rabbits.size()).is_equal(3)


func test_intro_happens_once_then_requires_recruitment() -> void:
	var id := _archer(0)
	assert_int(hunt.resolve(units, true, true).size()).is_equal(1)
	units.cooldowns[units.index_of(id)] = 0.0
	assert_array(hunt.resolve(units, true, true)).is_empty()
	units.owners[units.index_of(id)] = 1
	assert_int(hunt.resolve(units, true, true).size()).is_equal(1)


func test_hunt_obeys_weapon_cadence_and_stops_at_night() -> void:
	_archer()
	var drops := hunt.resolve(units, true, false)
	assert_int(drops.size()).is_equal(1)
	assert_int(drops[0][&"amount"]).is_equal(1)
	assert_str(String(drops[0][&"source"])).is_equal("hunt")
	assert_array(hunt.resolve(units, true, false)).is_empty()
	assert_array(hunt.resolve(units, false, true)).is_empty()


func test_free_hunter_moves_to_a_distant_clearing_and_yields_to_posts() -> void:
	var id := _archer()
	var i := units.index_of(id)
	hunt.rabbits.assign([900.0])
	hunt.plan(units, true)
	assert_float(units.target_xs[i]).is_equal(900.0)
	units.job_ids[i] = 0
	units.set_target_x(id, 300.0)
	hunt.plan(units, true)
	assert_float(units.target_xs[i]).is_equal(300.0)


func test_dead_underground_and_fighting_hunters_do_not_hunt() -> void:
	var id := _archer()
	var i := units.index_of(id)
	units.bands[i] = Band.Kind.UNDERGROUND
	assert_array(hunt.resolve(units, true, true)).is_empty()
	units.bands[i] = Band.Kind.SURFACE
	units.states[i] = UnitFsm.State.FIGHT
	assert_array(hunt.resolve(units, true, true)).is_empty()
	units.states[i] = UnitFsm.State.WORK
	units.healths[i] = 0
	assert_array(hunt.resolve(units, true, true)).is_empty()


func test_save_preserves_exhausted_clearings_until_the_next_day() -> void:
	_archer()
	hunt.resolve(units, true, true)
	var copy := HuntingSystem.new(
		SimFactory.by_id(&"units"), Registry.entry(&"wildlife", &"rabbit")
	)
	copy.from_dict(hunt.to_dict())
	copy.open_day(1, [1.0, 2.0])
	assert_array(copy.rabbits).is_equal(hunt.rabbits)
	copy.open_day(2, [1.0, 2.0])
	assert_array(copy.rabbits).is_equal([1.0, 2.0])


func test_two_hunters_cannot_claim_the_same_rabbit() -> void:
	_archer()
	_archer()
	hunt.rabbits.assign([100.0])
	assert_int(hunt.resolve(units, true, true).size()).is_equal(1)


func test_the_intro_is_the_first_clearing_taken_by_the_nearest_neutral_hunter() -> void:
	var far := units.spawn(state, Registry.entry(&"units", &"archer"), 0, 1000.0)
	var near := units.spawn(state, Registry.entry(&"units", &"archer"), 0, 1640.0)
	var intro := HuntingSystem.new(
		SimFactory.by_id(&"units"), Registry.entry(&"wildlife", &"rabbit")
	)
	intro.open_day(1, [1760.0, 1160.0])
	var drops := intro.resolve(units, true, true)
	assert_int(drops.size()).is_equal(1)
	assert_float(drops[0][&"x"]).is_equal(1760.0)
	assert_float(units.cooldowns[units.index_of(near)]).is_greater(0.0)
	assert_float(units.cooldowns[units.index_of(far)]).is_equal(0.0)
	assert_array(intro.resolve(units, true, true)).is_empty()
	assert_array(intro.rabbits).is_equal([1160.0])


func test_the_intro_is_moot_once_the_players_hunter_took_its_rabbit() -> void:
	var own := _archer()
	units.cooldowns[units.index_of(own)] = 0.0
	units.spawn(state, Registry.entry(&"units", &"archer"), 0, 900.0)
	hunt.rabbits.erase(100.0)
	assert_int(hunt.resolve(units, true, true).size()).is_equal(1)
	assert_bool(hunt.intro_done).is_true()
	assert_array(hunt.rabbits).is_equal([900.0])


func test_as_clareiras_do_dia_abrem_em_vagas_e_o_total_nao_muda() -> void:
	var dia := HuntingSystem.new(SimFactory.by_id(&"units"), Registry.entry(&"wildlife", &"rabbit"))
	dia.open_day(1, [10.0, 20.0, 30.0, 40.0, 50.0], 3)
	assert_array(dia.rabbits).is_equal([10.0, 40.0])
	assert_float(dia.intro_x).is_equal(10.0)
	dia.release()
	assert_array(dia.rabbits).is_equal([10.0, 40.0, 20.0, 50.0])
	var copia := HuntingSystem.new(
		SimFactory.by_id(&"units"), Registry.entry(&"wildlife", &"rabbit")
	)
	copia.from_dict(dia.to_dict())
	copia.release()
	assert_array(copia.rabbits).is_equal([10.0, 40.0, 20.0, 50.0, 30.0])
	copia.release()
	assert_int(copia.rabbits.size()).is_equal(5)


func test_a_vigia_abre_cada_vaga_na_sua_fase_de_luz() -> void:
	var dia := HuntingSystem.new(SimFactory.by_id(&"units"), Registry.entry(&"wildlife", &"rabbit"))
	dia.open_day(1, [10.0, 20.0, 30.0], HuntWatch.WAVE_PHASES.size())
	HuntWatch.release_due(dia, GameClock.Phase.MORNING)
	assert_int(dia.rabbits.size()).is_equal(1)
	HuntWatch.release_due(dia, GameClock.Phase.NOON)
	assert_int(dia.rabbits.size()).is_equal(2)
	HuntWatch.release_due(dia, GameClock.Phase.DUSK)
	assert_int(dia.rabbits.size()).is_equal(3)


func test_o_cacador_teu_guarda_a_caca_no_saco_e_o_sem_dono_larga_a() -> void:
	var meu := _archer()
	var drops := hunt.resolve(units, true, true)
	var chao := hunt.bag(units, drops)
	assert_array(chao).is_empty()
	assert_int(units.carried_coins[units.index_of(meu)]).is_equal(1)
	assert_int(hunt.bagged[meu]).is_equal(1)
	var livre := units.spawn(state, Registry.entry(&"units", &"archer"), 0, 120.0)
	var so_dele: Array[Dictionary] = [{&"x": 120.0, &"amount": 1, &"hunter": livre}]
	assert_int(hunt.bag(units, so_dele).size()).is_equal(1)


func test_entrega_ao_rei_so_o_que_cacou_e_so_perto_dele() -> void:
	var meu := _archer()
	var i := units.index_of(meu)
	units.carried_coins[i] = 3  # o preco que pagaste para o recrutar fica com ele
	hunt.bagged[meu] = 2
	units.carried_coins[i] += 2
	var rei := units.spawn(state, Registry.entry(&"units", &"monarch"), 1, 900.0)
	assert_int(hunt.deliver(units, rei, 120.0)).is_equal(0)
	units.xs[units.index_of(rei)] = 60.0
	assert_int(hunt.deliver(units, rei, 120.0)).is_equal(2)
	assert_int(units.carried_coins[i]).is_equal(3)
	assert_int(units.carried_coins[units.index_of(rei)]).is_equal(2)
	assert_bool(hunt.bagged.has(meu)).is_false()
