# tests/forest_flow_test.gd — a floresta como territorio, de ponta a ponta (ADR 0070):
# nasce pela semente sem tapar o mapa, a fundacao e as obras limpam o chao sem moeda,
# o corte pago da moedas, e o que cai fica caido; o bosque apoia a coleta e abriga o
# veado, e cortar sem olhar custa as duas coisas.
extends GdUnitTestSuite

const SEMENTE := 20261005


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(SEMENTE)
	Greybox.build()
	SimLoop.step(1.0 / 30.0)


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _w() -> Woodland:
	return SimLoop.field.woodland


func _fundar() -> void:
	var u := SimLoop.units
	var x := SimLoop.arrival.origin - 83.0
	u.xs[u.index_of(SimLoop.king_id)] = x
	u.clear_target(SimLoop.king_id)
	SimLoop.step(1.0)
	assert_bool(FoundationChoice.claim(x)).is_true()


func _construtor(x: float) -> int:
	var dono := SimLoop.units.owners[SimLoop.units.index_of(SimLoop.king_id)]
	return SimLoop.units.spawn(SimLoop.state, Registry.entry(&"units", &"builder"), dono, x)


## Uma arvore de pe, longe das obras e da clareira, para pagar o corte.
func _arvore_livre() -> int:
	var w := _w()
	for i in w.count():
		if not w.standing(i) or absf(w.xs[i] - SimLoop.core_x) < 400.0:
			continue
		if CoinTarget.slot_at(SimLoop.builds, w.xs[i], Band.Kind.SURFACE) == CoinTarget.NENHUM:
			return i
	return Woodland.NONE


func test_the_home_forest_is_planted_once_by_the_seed() -> void:
	var w := _w()
	assert_bool(w.generated).is_true()
	assert_int(w.count()).is_greater(10)
	var antes := [w.ids.duplicate(), w.xs.duplicate(), w.species.duplicate()]
	SimLoop.stop()
	SimLoop.start(SEMENTE)
	Greybox.build()
	SimLoop.step(1.0 / 30.0)
	assert_array([_w().ids, _w().xs, _w().species]).is_equal(antes)
	SimLoop.step(1.0 / 30.0)
	assert_array(Array(_w().ids)).is_equal(Array(antes[0]))  # nao se planta outra vez


func test_the_forest_never_covers_what_the_map_needs() -> void:
	var w := _w()
	var folga := ForestWatch.rules().reserve_px
	var pontos: Array[float] = [SimLoop.arrival.cache_x]
	pontos.append_array(Array(SimLoop.field.camps))
	pontos.append_array(Array(SimLoop.secrets.xs))
	pontos.append_array(Array(SimLoop.night.amargueiros.xs))
	for i in w.count():
		if w.ids[i] >= ForestWatch.ZONA_ABRIGO * ForestPlan.ZONA:
			continue  # o abrigo de uma toca nasce a volta dela, de proposito
		for p in SimLoop.passages:
			assert_float(absf(w.xs[i] - p)).is_greater(Band.PASSAGE_PX + folga)
		for p in pontos:
			assert_float(absf(w.xs[i] - p)).is_greater(folga)


func test_foundation_clears_the_radius_without_wood_and_keeps_the_rest() -> void:
	var x := SimLoop.arrival.origin - 83.0
	var raio := LastCartWatch.rules().foundation_clear_radius
	var w := _w()
	w.plant(9_000_001, x + 10.0, &"oak")  # uma dentro, de certeza
	w.plant(9_000_002, x + raio + 40.0, &"oak")  # e uma logo fora
	var moedas := SimLoop.coins.count()
	_fundar()
	assert_int(w.states[w.index_of(9_000_001)]).is_equal(Woodland.State.CLEARED)
	assert_bool(w.standing(w.index_of(9_000_002))).is_true()
	for i in w.count():
		if absf(w.xs[i] - x) < raio:
			assert_bool(w.standing(i)).is_false()
	assert_int(SimLoop.coins.count()).is_equal(moedas)


func test_a_paid_tree_is_felled_by_a_builder_and_stays_felled() -> void:
	_fundar()
	var w := _w()
	var i := _arvore_livre()
	assert_int(i).is_not_equal(Woodland.NONE)
	var id := w.ids[i]
	var u := SimLoop.units
	var rei := u.index_of(SimLoop.king_id)
	u.xs[rei] = w.xs[i]
	u.clear_target(SimLoop.king_id)
	var saco := u.carried_coins[rei]
	var largada := {
		EventRelay.ONDE: w.xs[i],
		EventRelay.FAIXA: Band.Kind.SURFACE,
		EventRelay.QUANTO: 1,
		EventRelay.PORQUE: Verbs.JOGADOR,
	}
	assert_bool(ForestWork.mark(largada)).is_false()  # sem construtor, a moeda cai no chao
	_construtor(w.xs[i] + 200.0)
	assert_bool(ForestWork.mark(largada)).is_true()
	assert_int(w.states[i]).is_equal(Woodland.State.MARKED)
	assert_int(u.carried_coins[rei]).is_equal(saco)  # o saco ja tinha largado a moeda
	var moedas := SimLoop.coins.count()
	for tick in 40 * 30:
		SimLoop.step(1.0 / 30.0)
		if not w.standing(w.index_of(id)):
			break
	assert_int(w.states[w.index_of(id)]).is_equal(Woodland.State.FELLED)
	assert_int(SimLoop.coins.count()).is_greater(moedas)
	var salvo := SimLoop.world()
	SimLoop.load_world(salvo)
	assert_int(_w().states[_w().index_of(id)]).is_equal(Woodland.State.FELLED)


func test_a_rising_building_clears_its_own_ground() -> void:
	_fundar()
	var w := _w()
	var vaga: BuildSlot
	for s in SimLoop.builds.slots:
		if s.territory == 0 and s.state == BuildSlot.State.EMPTY and s.level == 0 and s.width > 0:
			if absf(s.x - SimLoop.core_x) > 300.0:
				vaga = s
				break
	w.plant(9_000_003, vaga.x, &"pine")
	SimLoop.step(1.0 / 30.0)
	assert_bool(w.standing(w.index_of(9_000_003))).is_true()  # o convite nao corta nada
	vaga.state = BuildSlot.State.SCAFFOLD
	SimLoop.step(1.0 / 30.0)
	assert_int(w.states[w.index_of(9_000_003)]).is_equal(Woodland.State.CLEARED)


func test_the_grove_feeds_gathering_and_cutting_it_loses_the_bonus() -> void:
	_fundar()
	var w := _w()
	var regras := ForestWatch.rules()
	var provisoes := SimLoop.arrival.cache_x
	w.clear(provisoes - regras.grove_feeds_radius, provisoes + regras.grove_feeds_radius)
	assert_int(ForestWork.forage_bonus()).is_equal(0)
	for k in regras.grove_feeds_min:
		w.plant(9_100_000 + k, provisoes + 100.0 + k, &"oak")
	assert_int(ForestWork.forage_bonus()).is_equal(regras.grove_feeds_bonus)
	for k in 10:
		w.plant(9_100_100 + k, provisoes - 100.0 - k, &"oak")
	assert_int(ForestWork.forage_bonus()).is_equal(regras.grove_feeds_cap)  # o maximo
	w.clear(provisoes - regras.grove_feeds_radius, provisoes + regras.grove_feeds_radius)
	assert_int(ForestWork.forage_bonus()).is_equal(0)


func test_the_deer_habitat_is_born_sheltered_and_sleeps_without_trees() -> void:
	var tocas := SimLoop.field.hunting.burrows
	var veado := -1
	for k in tocas.xs.size():
		if tocas.kinds[k] == String(ForestWatch.ARVORE):
			veado = k
	assert_int(veado).is_not_equal(-1)
	assert_array(ForestWork.unsheltered(SimLoop.field)).is_empty()
	var x := tocas.xs[veado]
	var regras := ForestWatch.rules()
	_w().clear(x - regras.shelter_radius, x + regras.shelter_radius)
	SimLoop.step(1.0 / 30.0)
	assert_bool(SimLoop.field.hunting.unsheltered.has(x)).is_true()
	var hunt := SimLoop.field.hunting
	hunt.burrows.waits[veado] = 0.0
	hunt.rabbits.erase(x)
	hunt.grow(5.0, true, 60.0)
	assert_bool(hunt.rabbits.has(x)).is_false()  # sem abrigo, a toca nao da bicho


func test_a_save_from_before_the_forest_plants_it_around_what_is_built() -> void:
	_fundar()
	var mundo := SimLoop.world()
	mundo.erase(&"woodland")
	SimLoop.load_world(mundo)
	assert_bool(_w().legacy).is_true()
	SimLoop.step(1.0 / 30.0)
	var w := _w()
	assert_bool(w.generated).is_true()
	var raio := LastCartWatch.rules().foundation_clear_radius
	for i in w.count():
		if w.standing(i):
			assert_float(absf(w.xs[i] - SimLoop.core_x)).is_greater_equal(raio)


func test_generated_lands_get_their_own_trees_by_both_ends() -> void:
	var u := SimLoop.units
	u.set_target_x(SimLoop.king_id, SimLoop.world_width + 2000.0)
	for tick in 20 * 30:
		SimLoop.step(1.0 / 30.0)
	var w := _w()
	assert_bool(w.zones.is_empty()).is_false()
	var la_fora := 0
	for i in w.count():
		if w.xs[i] > SimLoop.world_width:
			la_fora += 1
	assert_int(la_fora).is_greater(0)


func test_the_v12_migration_marks_old_worlds_without_touching_new_ones() -> void:
	var antigo := {&"save_version": 11, &"world": {&"units": {}}}
	var migrado := SaveMigrations.migrate(antigo)
	assert_int(migrado[&"save_version"]).is_equal(SaveMigrations.CURRENT)
	assert_bool(migrado[&"world"][&"woodland"][&"legacy"]).is_true()
	assert_bool(antigo[&"world"].has(&"woodland")).is_false()  # a entrada nao muda
	var novo := {&"save_version": 11, &"world": {&"woodland": {&"generated": true}}}
	assert_bool(SaveMigrations.migrate(novo)[&"world"][&"woodland"][&"generated"]).is_true()
