# tests/forest_plan_test.gd — o mapa funciona primeiro, a floresta enche o resto
# (ADR 0070).
extends GdUnitTestSuite


func _roll(celula: int) -> Array:
	return [fposmod(float(celula) * 0.37, 1.0)]


func _sempre(_celula: int, _x: float) -> StringName:
	return &"oak"


func test_one_tree_at_most_per_cell_and_the_same_cell_gives_the_same_tree() -> void:
	var a := ForestPlan.place(0, 0.0, 760.0, 76.0, _roll, _sempre, [])
	var b := ForestPlan.place(0, 0.0, 760.0, 76.0, _roll, _sempre, [])
	assert_array(a).is_equal(b)
	assert_int(a.size()).is_equal(10)
	var vistos := {}
	for arvore: Array in a:
		var celula := floori(float(arvore[1]) / 76.0)
		assert_bool(vistos.has(celula)).is_false()
		vistos[celula] = true
	# metade do mundo pedida a parte da as mesmas arvores, com os mesmos ids
	var metade := ForestPlan.place(0, 380.0, 760.0, 76.0, _roll, _sempre, [])
	for arvore: Array in metade:
		assert_bool(a.has(arvore)).is_true()


func test_reserved_ground_is_never_planted() -> void:
	var reservado: Array = [Vector2(100.0, 300.0)]
	for arvore: Array in ForestPlan.place(0, 0.0, 760.0, 76.0, _roll, _sempre, reservado):
		var x: float = arvore[1]
		assert_bool(x >= 100.0 and x <= 300.0).is_false()


func test_species_choice_can_leave_a_cell_empty() -> void:
	var clareira := func(celula: int, _x: float) -> StringName:
		return &"" if celula % 2 == 0 else &"pine"
	var a := ForestPlan.place(0, 0.0, 760.0, 76.0, _roll, clareira, [])
	assert_int(a.size()).is_equal(5)
	for arvore: Array in a:
		assert_str(String(arvore[2])).is_equal("pine")


func test_ids_are_stable_per_zone_even_to_the_west() -> void:
	assert_int(ForestPlan.id_of(0, 3)).is_equal(3)
	assert_int(ForestPlan.id_of(4, -2)).is_equal(4 * ForestPlan.ZONA + ForestPlan.ZONA - 2)
	assert_int(ForestPlan.id_of(4, -2)).is_not_equal(ForestPlan.id_of(5, -2))


func test_a_habitat_that_lives_on_trees_is_born_with_shelter() -> void:
	var sitios := ForestPlan.grove(1000.0, 200.0, 3, 1, 76.0, [])
	assert_int(sitios.size()).is_equal(2)
	for x in sitios:
		assert_float(absf(x - 1000.0)).is_less_equal(200.0)
	assert_array(ForestPlan.grove(1000.0, 200.0, 3, 3, 76.0, [])).is_empty()
	var tapado := ForestPlan.grove(1000.0, 200.0, 2, 0, 76.0, [Vector2(900.0, 1100.0)])
	for x in tapado:
		assert_bool(x >= 900.0 and x <= 1100.0).is_false()
