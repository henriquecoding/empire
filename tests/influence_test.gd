# tests/influence_test.gd — origem, destino, alcance e acumulacao explicitos (ADR 0070).
extends GdUnitTestSuite


func _especie(id: StringName, tags: Array[StringName]) -> FloraData:
	var f := FloraData.new()
	f.id = id
	f.tags = tags
	return f


func test_only_species_with_the_tag_are_origins() -> void:
	var flora := [
		_especie(&"oak", [Influence.SHELTER, Influence.FORAGE]),
		_especie(&"pine", [Influence.SHELTER]),
		_especie(&"willow", [Influence.FORAGE]),
	]
	assert_dict(Influence.kinds(flora, Influence.FORAGE)).is_equal({&"oak": true, &"willow": true})
	assert_dict(Influence.kinds(flora, Influence.SHELTER)).is_equal({&"oak": true, &"pine": true})


func test_the_bonus_needs_the_minimum_and_never_stacks_past_the_cap() -> void:
	assert_int(Influence.bonus(2, 3, 1, 1)).is_equal(0)
	assert_int(Influence.bonus(3, 3, 1, 1)).is_equal(1)
	assert_int(Influence.bonus(300, 3, 1, 1)).is_equal(1)  # centenas de arvores nao somam
	assert_int(Influence.bonus(300, 3, 4, 2)).is_equal(2)


func test_the_preview_says_which_target_loses_an_origin() -> void:
	var w := Woodland.new()
	w.plant(1, 100.0, &"oak")
	w.plant(2, 600.0, &"oak")
	var carvalhos := {&"oak": true}
	assert_int(Influence.would_lose(w, w.index_of(1), 200.0, 240.0, carvalhos)).is_equal(1)
	assert_int(Influence.would_lose(w, w.index_of(2), 200.0, 240.0, carvalhos)).is_equal(0)
	assert_int(Influence.would_lose(w, w.index_of(1), 200.0, 240.0, {&"pine": true})).is_equal(0)
	w.clear(90.0, 110.0)
	assert_int(Influence.would_lose(w, w.index_of(1), 200.0, 240.0, carvalhos)).is_equal(0)
