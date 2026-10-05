# tests/woodland_test.gd — cada arvore e uma coisa do mundo, e o que se corta fica
# cortado (ADR 0070).
extends GdUnitTestSuite


func _bosque() -> Woodland:
	var w := Woodland.new()
	w.plant(10, 100.0, &"oak")
	w.plant(11, 180.0, &"pine")
	w.plant(12, 400.0, &"oak")
	return w


func test_a_tree_has_a_stable_id_and_is_planted_once() -> void:
	var w := _bosque()
	assert_bool(w.plant(10, 999.0, &"pine")).is_false()
	assert_int(w.count()).is_equal(3)
	assert_float(w.xs[w.index_of(10)]).is_equal(100.0)
	assert_int(w.index_of(77)).is_equal(Woodland.NONE)


func test_paying_marks_and_only_work_fells() -> void:
	var w := _bosque()
	var i := w.nearest(110.0, 28.0)
	assert_int(w.ids[i]).is_equal(10)
	assert_bool(w.chop(i, 99.0, 12.0)).is_false()  # sem pagar, nao ha corte
	assert_bool(w.mark(i)).is_true()
	assert_bool(w.mark(i)).is_false()
	assert_bool(w.standing(i)).is_true()  # marcada ainda abriga e alimenta
	assert_bool(w.chop(i, 6.0, 12.0)).is_false()
	assert_bool(w.chop(i, 6.0, 12.0)).is_true()
	assert_bool(w.standing(i)).is_false()
	assert_bool(w.chop(i, 6.0, 12.0)).is_false()  # cai uma vez
	assert_int(w.nearest(110.0, 28.0)).is_equal(Woodland.NONE)


func test_clearing_takes_what_is_inside_and_nothing_beyond() -> void:
	var w := _bosque()
	var limpas := w.clear(90.0, 180.0)
	assert_array(Array(limpas)).contains_exactly([10, 11])
	assert_bool(w.standing(w.index_of(12))).is_true()
	assert_int(w.states[w.index_of(10)]).is_equal(Woodland.State.CLEARED)


func test_influence_counts_only_living_trees_of_the_kinds_in_range() -> void:
	var w := _bosque()
	var carvalhos := {&"oak": true}
	assert_int(w.count_near(260.0, 160.0, carvalhos)).is_equal(2)  # o limite e inclusivo
	assert_int(w.count_near(260.0, 159.0, carvalhos)).is_equal(1)
	assert_int(w.count_near(260.0, 160.0, {&"pine": true})).is_equal(1)
	w.clear(390.0, 410.0)
	assert_int(w.count_near(260.0, 160.0, carvalhos)).is_equal(1)


func test_the_ground_of_gone_trees_is_the_clearing_that_reads() -> void:
	var w := _bosque()
	w.mark(0)
	w.chop(0, 12.0, 12.0)
	w.clear(390.0, 410.0)
	var vazio := w.gone_spans(32.0)
	assert_array(vazio).contains_exactly([Vector2(68.0, 132.0), Vector2(368.0, 432.0)])


func test_cut_trees_stay_cut_after_load_and_ids_still_resolve() -> void:
	var w := _bosque()
	w.generated = true
	w.version = 1
	w.zones[&"1:0"] = true
	w.mark(1)
	w.chop(1, 5.0, 14.0)
	w.clear(390.0, 410.0)
	var c := Woodland.new()
	c.from_dict(w.to_dict())
	assert_bool(c.generated).is_true()
	assert_bool(c.legacy).is_false()
	assert_int(c.states[c.index_of(11)]).is_equal(Woodland.State.MARKED)
	assert_float(c.progress[c.index_of(11)]).is_equal(5.0)
	assert_int(c.states[c.index_of(12)]).is_equal(Woodland.State.CLEARED)
	assert_bool(c.zones.has(&"1:0")).is_true()
	assert_bool(c.plant(12, 400.0, &"oak")).is_false()  # nao renasce por replantar


func test_a_save_from_before_the_forest_is_unplanted_and_legacy() -> void:
	var c := Woodland.new()
	c.from_dict({})
	assert_bool(c.generated).is_false()
	assert_bool(c.legacy).is_true()
	assert_int(c.count()).is_equal(0)
	assert_bool(Woodland.new().legacy).is_false()
