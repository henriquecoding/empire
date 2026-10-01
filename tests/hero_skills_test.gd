extends GdUnitTestSuite

var _state: GameState
var _units: UnitSystem
var _creatures: CreatureSystem
var _classes: Dictionary
var _troops: Dictionary


func before_test() -> void:
	Registry.load_all()
	_state = GameState.new()
	_units = UnitSystem.new()
	_creatures = CreatureSystem.new()
	_classes = SimFactory.by_id(&"classes")
	_troops = SimFactory.by_id(&"units")


func _unit(id: StringName, x: float = 500.0, owner: int = 1) -> int:
	return _units.spawn(_state, _troops[id], owner, x)


func _enemy(id: StringName, x: float = 530.0) -> int:
	return _creatures.spawn(_state, Registry.entry(&"creatures", id), x, 0.0)


func test_evolucao_exige_semente_e_feito_e_persiste_por_classe() -> void:
	var p := HeroProgress.new(_classes)
	var bard: ClassData = _classes[&"bard"]
	assert_int(p.phase_of(&"bard")).is_equal(1)
	assert_bool(p.can_evolve(&"bard", 100)).is_false()
	for _n in bard.evolve_condition_value:
		p.record(&"bard")
	assert_int(p.feat_of(&"bard")).is_equal(bard.evolve_condition_value)
	assert_bool(p.evolve(&"bard", _state)).is_false()
	_state.royal_seeds = bard.evolve_seed_cost
	assert_bool(p.evolve(&"bard", _state)).is_true()
	assert_int(_state.royal_seeds).is_equal(0)
	assert_int(p.phase_of(&"archer")).is_equal(1)
	var copy := HeroProgress.new(_classes)
	copy.from_dict(p.to_dict())
	assert_int(copy.phase_of(&"bard")).is_equal(2)
	assert_bool(copy.evolve(&"bard", _state)).is_false()


func test_marca_usa_alcance_faixa_duracao_e_dono() -> void:
	var hero := _unit(&"archer_hero")
	var target := _enemy(&"crawler")
	var focus := ArcherFocus.new(_classes[&"archer"], _troops)
	assert_array(focus.aim(_units, _creatures, hero, 530.0, 1)).contains([target])
	assert_bool(focus.marked(target, 1)).is_true()
	assert_bool(focus.marked(target, 2)).is_false()
	var copy := ArcherFocus.new(_classes[&"archer"], _troops)
	copy.from_dict(focus.to_dict())
	assert_bool(copy.marked(target, 1)).is_true()
	focus.tick(float((_classes[&"archer"] as ClassData).phase1_params[&"duration"]), _creatures)
	assert_bool(focus.marked(target, 1)).is_false()
	assert_array(focus.aim(_units, _creatures, hero, 10000.0, 1)).is_empty()
	_creatures.bands[_creatures.index_of(target)] = int(Band.Kind.UNDERGROUND)
	assert_array(focus.aim(_units, _creatures, hero, 530.0, 1)).is_empty()


func test_marca_evoluida_abrange_area_e_flecha_atravessa_a_coluna() -> void:
	var hero := _unit(&"archer_hero")
	var first := _enemy(&"crawler", 530.0)
	var next := _enemy(&"crawler", 560.0)
	var behind := _enemy(&"crawler", 470.0)
	var far := _enemy(&"crawler", 900.0)
	var focus := ArcherFocus.new(_classes[&"archer"], _troops)
	assert_array(focus.aim(_units, _creatures, hero, 530.0, 2)).contains([first, next])
	var hit := focus.pierced(_units, _creatures, hero, first)
	assert_array(hit).contains([first, next])
	assert_array(hit).not_contains([behind, far])


func test_bardo_encanta_fracos_mas_nao_monstros_poderosos_na_base() -> void:
	var bard := _unit(&"bard_hero")
	var weak := _enemy(&"crawler")
	var strong := _enemy(&"brute", 555.0)
	var song := BardSong.new(_classes[&"bard"], _troops, SimFactory.by_id(&"creatures"))
	assert_int(song.cast(_units, _creatures, bard, 530.0, 1)).is_equal(weak)
	assert_bool(song.allies.has(weak)).is_true()
	assert_int(song.cast(_units, _creatures, bard, 555.0, 1)).is_equal(-1)
	_units.cooldowns[_units.index_of(bard)] = 0.0
	assert_int(song.cast(_units, _creatures, bard, 555.0, 1)).is_equal(-1)
	assert_bool(song.allies.has(strong)).is_false()
	assert_bool(song.credited(weak)).is_true()
	assert_int(song.conversions()).is_equal(1)
	song.tick(30.0, _creatures)
	assert_bool(song.allies.has(weak)).is_false()
	assert_bool(_creatures.alive(_creatures.index_of(weak))).is_true()


func test_maestro_converte_permanentemente_e_as_colunas_ficam_no_save() -> void:
	var bard := _unit(&"bard_hero")
	var strong := _enemy(&"brute")
	var song := BardSong.new(_classes[&"bard"], _troops, SimFactory.by_id(&"creatures"))
	assert_int(song.cast(_units, _creatures, bard, 530.0, 2)).is_equal(strong)
	song.tick(100.0, _creatures)
	assert_bool(song.allies.has(strong)).is_true()
	assert_array(song.permanent()).contains([strong])
	var copy := BardSong.new(_classes[&"bard"], _troops, SimFactory.by_id(&"creatures"))
	copy.from_dict(song.to_dict())
	assert_array(copy.permanent()).contains([strong])
	assert_bool(copy.credited(strong)).is_true()


func test_encantado_luta_por_ti_e_pode_ser_atacado_pela_podridao() -> void:
	var bard := _unit(&"bard_hero")
	var ally := _enemy(&"crawler", 530.0)
	var enemy := _enemy(&"crawler", 539.0)
	var song := BardSong.new(_classes[&"bard"], _troops, SimFactory.by_id(&"creatures"))
	song.cast(_units, _creatures, bard, 530.0, 1)
	song.plan(_units, _creatures)
	assert_int(_creatures.target_ids[_creatures.index_of(ally)]).is_equal(enemy)
	var data := Registry.entry(&"creatures", &"crawler") as CreatureData
	assert_int(song.defender(_creatures, _creatures.index_of(enemy), data, -1, INF)).is_equal(ally)
	assert_float(song.pace(1)).is_greater(1.0)
	assert_float(song.pace(0)).is_equal(1.0)
