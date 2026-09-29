extends GdUnitTestSuite

var units: UnitSystem
var state: GameState
var hunt: HuntingSystem


func before_test() -> void:
	units = UnitSystem.new()
	state = GameState.new()
	hunt = _nova([100.0, 120.0, 900.0])
	hunt.grow(0.0, true, 1.0)


## Uma caca com as tocas nestes x, todas prontas a dar o primeiro bicho.
func _nova(tocas: Array[float]) -> HuntingSystem:
	var h := HuntingSystem.new(SimFactory.by_id(&"units"), Registry.entry(&"wildlife", &"rabbit"))
	var esperas: Array[float] = []
	esperas.resize(tocas.size())
	esperas.fill(0.0)
	h.burrows.place(tocas, esperas)
	h.open_day(1)
	return h


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


func test_o_save_guarda_as_tocas_e_quem_esta_a_porta() -> void:
	_archer()
	hunt.resolve(units, true, true)
	var copy := HuntingSystem.new(
		SimFactory.by_id(&"units"), Registry.entry(&"wildlife", &"rabbit")
	)
	copy.from_dict(hunt.to_dict())
	assert_array(copy.rabbits).is_equal(hunt.rabbits)
	assert_array(copy.burrows.xs).is_equal(hunt.burrows.xs)
	assert_int(copy.burrows.living()).is_equal(3)


func test_two_hunters_cannot_claim_the_same_rabbit() -> void:
	_archer()
	_archer()
	hunt.rabbits.assign([100.0])
	assert_int(hunt.resolve(units, true, true).size()).is_equal(1)


func test_the_intro_is_the_first_clearing_taken_by_the_nearest_neutral_hunter() -> void:
	var far := units.spawn(state, Registry.entry(&"units", &"archer"), 0, 1000.0)
	var near := units.spawn(state, Registry.entry(&"units", &"archer"), 0, 1640.0)
	var intro := _nova([1760.0, 1160.0])
	intro.grow(0.0, true, 1.0)
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


## Q-106 e Q-120 (o dono, 29/09/2026): as tocas dao os bichos aos poucos, um de
## cada vez, e so de dia. Um bicho que ninguem caca fica e a toca espera.
func test_uma_toca_da_um_bicho_de_cada_vez_e_so_de_dia() -> void:
	var dia := _nova([10.0])
	dia.burrows.waits[0] = 5.0
	dia.grow(4.0, true, 5.0)
	assert_array(dia.rabbits).is_empty()
	dia.grow(4.0, false, 5.0)
	assert_array(dia.rabbits).is_empty()
	dia.grow(1.0, true, 5.0)
	assert_array(dia.rabbits).is_equal([10.0])
	dia.grow(50.0, true, 5.0)
	assert_array(dia.rabbits).is_equal([10.0])
	dia.rabbits.clear()
	dia.grow(5.0, true, 5.0)
	assert_array(dia.rabbits).is_equal([10.0])


## "Se fizer algo errado e perder o arbusto, para de ser gerado o coelho": um
## Amargueiro que cria raiz ao pe de uma toca mata-a, e o bicho foge com ela.
func test_uma_toca_perdida_nao_da_mais_nada() -> void:
	var dia := _nova([10.0, 500.0])
	dia.grow(0.0, true, 5.0)
	assert_array(dia.wither(PackedFloat32Array([30.0]), 48.0)).is_equal([10.0])
	assert_array(dia.rabbits).is_equal([500.0])
	dia.rabbits.clear()
	dia.grow(100.0, true, 5.0)
	assert_array(dia.rabbits).is_equal([500.0])
	assert_int(dia.burrows.living()).is_equal(1)


## A media do dia continua a do hunt_yield: o periodo reparte-a pela luz.
func test_o_periodo_da_a_caca_media_do_dia() -> void:
	var relogio := Registry.entry(&"economy", &"clock") as ClockData
	var dados := Registry.entry(&"wildlife", &"rabbit") as WildlifeData
	var luz := 0.0
	for fase in HuntWatch.LUZ:
		luz += relogio.phase_durations[fase]
	var por_dia := luz / HuntWatch.period(relogio.day_seconds) * dados.burrows_per_region
	var curva := SimFactory.curve()
	assert_float(por_dia).is_equal_approx((curva.hunt_yield.x + curva.hunt_yield.y) * 0.5, 0.01)
	assert_float(HuntWatch.period(relogio.day_seconds * 1.5)).is_equal_approx(
		HuntWatch.period(relogio.day_seconds) * 1.5, 0.01
	)


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


## O coelho do 1:10 cai no mesmo PONTO do dia que o jogador escolheu (§26), e
## nao ao mesmo segundo (auditoria de 26/09, D10).
func test_o_coelho_do_1_10_acompanha_a_duracao_do_dia() -> void:
	var base := (Registry.entry(&"economy", &"clock") as ClockData).day_seconds
	assert_float(HuntWatch.intro_at(base)).is_equal(HuntWatch.INTRO_SECONDS)
	assert_float(HuntWatch.intro_at(base * 1.5)).is_equal_approx(
		HuntWatch.INTRO_SECONDS * 1.5, 0.001
	)
