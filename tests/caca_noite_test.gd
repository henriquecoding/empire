# tests/caca_noite_test.gd — de noite a caca foge da Podridao, e a Podridao leva-a; as
# tuas tropas cacam sozinhas (o dono, 03/10/2026; ADR 0057).
extends GdUnitTestSuite

var units: UnitSystem
var state: GameState


func before_test() -> void:
	units = UnitSystem.new()
	state = GameState.new()


func _bicho(id: StringName) -> WildlifeData:
	return Registry.entry(&"wildlife", id) as WildlifeData


func _so(bicho: WildlifeData) -> Callable:
	return func(_toca: float) -> WildlifeData: return bicho


## A criatura que chega perto fa-lo fugir; a que chega ao alcance apanha-o.
func test_o_bicho_foge_da_podridao_e_e_apanhado() -> void:
	var manada := Herd.new()
	var coelho := _bicho(&"rabbit")
	manada.arrive(500.0)
	var tocas: Array[float] = [500.0]
	manada.predators = {3: Vector2(480.0, 10.0)}
	manada.step(0.5, tocas, _so(coelho), {})
	assert_float(manada.where(500.0)).is_equal_approx(500.0 + coelho.move_speed * 0.5, 0.01)
	assert_array(manada.caught).is_empty()
	manada.predators = {3: Vector2(manada.where(500.0) - 5.0, 10.0)}
	manada.step(0.1, tocas, _so(coelho), {})
	assert_array(manada.caught).is_equal([500.0])


## So as criaturas a superficie, vivas e nao convertidas cacam bichos.
func test_quem_caca_os_bichos_de_noite() -> void:
	var feras := SimFactory.by_id(&"creatures")
	var criaturas := CreatureSystem.new()
	var rastejante := feras[&"crawler"] as CreatureData
	var a := criaturas.spawn(state, rastejante, 10.0, 0.0)
	var b := criaturas.spawn(state, rastejante, 20.0, 0.0)
	criaturas.spawn(state, feras[&"burrower"], 30.0, 0.0)
	criaturas.bands[2] = Band.Kind.UNDERGROUND
	var saida := Herd.predators_of(criaturas, feras, {b: true})
	assert_array(saida.keys()).is_equal([a])
	assert_float((saida[a] as Vector2).y).is_equal(float(rastejante.range_px))


## O bicho apanhado sai sem caca, e diz em que criatura se levanta.
func test_o_bicho_apanhado_sai_sem_caca() -> void:
	var h := HuntingSystem.new(SimFactory.by_id(&"units"), _bicho(&"rabbit"))
	h.wildlife = SimFactory.by_id(&"wildlife")
	var tocas: Array[float] = [100.0]
	var esperas: Array[float] = [0.0]
	h.burrows.place(tocas, esperas, PackedStringArray(["tree"]), PackedStringArray(["deer"]))
	h.open_day(2)
	h.grow(0.0, true, 1.0)
	assert_str(String(h.lose(100.0).rots_into)).is_equal(String(_bicho(&"deer").rots_into))
	assert_array(h.rabbits).is_empty()
	assert_dict(h.bagged).is_empty()


## No jogo: a criatura que apanha o coelho fa-lo levantar como criatura tua inimiga.
func test_o_coelho_apanhado_levanta_se_inimigo() -> void:
	SimLoop.autosave_enabled = false
	SimLoop.start(20261003)
	Greybox.build()
	ClockService.clock.elapsed = ClockService.clock.day_seconds() * 0.9  # de noite
	SimLoop.step(0.1)
	var hunt := SimLoop.hunting
	var x := SimLoop.core_x - 480.0
	hunt.rabbits.append(x)
	hunt.burrows.add(x, 99.0, "bush", "rabbit")
	hunt.herd.arrive(x)
	var feras := SimFactory.by_id(&"creatures")
	SimLoop.creatures.spawn(SimLoop.state, feras[&"crawler"], x + 2.0, x + 2.0)
	var antes := SimLoop.creatures.count()
	SimLoop.step(0.1)
	assert_bool(hunt.rabbits.has(x)).is_false()
	assert_int(SimLoop.creatures.count()).is_equal(antes + 1)
	assert_str(String(SimLoop.creatures.data_ids[-1])).is_equal(String(_bicho(&"rabbit").rots_into))
	SimLoop.stop()
	SimLoop.autosave_enabled = true


## As tuas tropas de combate cacam sozinhas, como o arqueiro, e guardam a caca para ti.
func test_as_tropas_cacam_sozinhas() -> void:
	for id in [&"spearman", &"mercenary", &"root_berserker", &"ice_warden"]:
		var dados := Registry.entry(&"units", id) as UnitData
		assert_bool(dados.tags.has(&"hunter")).override_failure_message(String(id)).is_true()
	var h := HuntingSystem.new(SimFactory.by_id(&"units"), _bicho(&"rabbit"))
	var tocas: Array[float] = [100.0]
	var esperas: Array[float] = [0.0]
	h.burrows.place(tocas, esperas)
	h.open_day(2)
	h.grow(0.0, true, 1.0)
	var lanceiro := units.spawn(state, Registry.entry(&"units", &"spearman"), 1, 400.0)
	h.plan(units, true)
	assert_float(units.target_xs[units.index_of(lanceiro)]).is_equal(100.0)
	units.xs[units.index_of(lanceiro)] = 110.0
	var caca: Array[Dictionary] = []
	for k in 4:
		caca.append_array(h.resolve(units, true, false))
		units.cooldowns[units.index_of(lanceiro)] = 0.0
	assert_int(caca.size()).is_equal(1)
	assert_array(HuntBag.bag(h.bagged, units, caca)).is_empty()
	assert_int(int(h.bagged[lanceiro])).is_equal(1)
