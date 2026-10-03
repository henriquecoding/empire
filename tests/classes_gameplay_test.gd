# tests/classes_gameplay_test.gd — a marca e o canto no jogo, agora do Imperador Arqueiro e
# do Bardo pago da Nia (ADR 0044, ADR 0052).
extends GdUnitTestSuite

const PASSO := 1.0 / 60.0
const MONARCAS := {&"archer": &"archer_emperor", &"bard": &"nia"}


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20261001)
	Greybox.build()
	SimLoop.step(PASSO)  # a alvorada inicial vem antes de aparecerem os alvos


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _begin(id: StringName) -> int:
	MonarchWatch.begin(MONARCAS[id])
	return SimLoop.king_id


func _enemy(id: StringName, x: float) -> int:
	return SimLoop.creatures.spawn(
		SimLoop.state, Registry.entry(&"creatures", id), x, SimLoop.core_x
	)


func _x(id: int) -> float:
	return SimLoop.units.xs[SimLoop.units.index_of(id)]


func _mark(x: float) -> void:
	SimLoop.intents.queue(IntentQueue.Kind.MARK_TARGET, {&"x": x})
	SimLoop.step(PASSO)


func test_a_marca_faz_as_tropas_aliadas_priorizarem_o_mesmo_alvo() -> void:
	var hero := _begin(&"archer")
	var near := _enemy(&"brute", _x(hero) + 80.0)
	var marked := _enemy(&"brute", _x(hero) + 150.0)
	var data := Registry.entry(&"units", &"archer") as UnitData
	var ally := SimLoop.units.spawn(SimLoop.state, data, Greybox.MEU_IMPERIO, _x(hero))
	var other := SimLoop.units.spawn(SimLoop.state, data, 99, _x(hero))
	_mark(_x(hero) + 150.0)
	assert_int(SimLoop.combat.target_of(hero)).is_equal(marked)
	assert_int(SimLoop.combat.target_of(ally)).is_equal(marked)
	assert_int(SimLoop.combat.target_of(other)).is_equal(near)


func test_a_flecha_evoluida_causa_dano_em_toda_a_coluna_mas_nao_atras() -> void:
	var hero := _begin(&"archer")
	SimLoop.field.hero_progress.phases[&"archer"] = 2
	var front := _enemy(&"brute", _x(hero) + 60.0)
	var next := _enemy(&"brute", _x(hero) + 110.0)
	var back := _enemy(&"brute", _x(hero) - 100.0)
	HeroWatch.tick(0.0)
	HeroWatch.action(_x(hero) + 60.0)
	SimLoop.combat.manual.request(hero, 1.0)
	SimLoop.combat.choose(SimLoop.units, SimLoop.creatures, SimLoop.builds)
	SimLoop.combat.resolve(
		SimLoop.units, SimLoop.creatures, SimLoop.builds, func() -> float: return 0.0
	)
	var creatures := SimLoop.creatures
	var data := Registry.entry(&"units", &"archer_emperor") as UnitData
	assert_int(creatures.healths[creatures.index_of(front)]).is_equal(32 - data.damage)
	assert_int(creatures.healths[creatures.index_of(next)]).is_equal(32 - data.damage)
	assert_int(creatures.healths[creatures.index_of(back)]).is_equal(32)
	(
		assert_bool(
			SimLoop.field.supply.can_shoot(SimLoop.units, SimLoop.units.index_of(hero), data)
		)
		. is_true()
	)


func test_o_encantado_bate_na_podridao_e_as_tropas_nao_lhe_disparam() -> void:
	var bard := _begin(&"bard")
	var ally := _enemy(&"crawler", _x(bard) + 60.0)
	var enemy := _enemy(&"crawler", _x(bard) + 70.0)
	var archer := SimLoop.units.spawn(
		SimLoop.state, Registry.entry(&"units", &"archer"), Greybox.MEU_IMPERIO, _x(bard)
	)
	HeroWatch.action(_x(bard) + 60.0)
	HeroWatch.tick(0.0)
	SimLoop.combat.choose(SimLoop.units, SimLoop.creatures, SimLoop.builds)
	assert_int(SimLoop.combat.target_of(archer)).is_equal(enemy)
	assert_int(SimLoop.creatures.target_ids[SimLoop.creatures.index_of(enemy)]).is_equal(ally)
	SimLoop.combat.resolve(
		SimLoop.units, SimLoop.creatures, SimLoop.builds, func() -> float: return 0.0
	)
	assert_int(SimLoop.creatures.healths[SimLoop.creatures.index_of(ally)]).is_equal(6)
	assert_int(SimLoop.creatures.healths[SimLoop.creatures.index_of(enemy)]).is_equal(2)


func test_reencantar_a_mesma_criatura_nao_repete_o_feito() -> void:
	var bard := _begin(&"bard")
	var target := _enemy(&"crawler", _x(bard) + 60.0)
	HeroWatch.action(_x(bard) + 60.0)
	assert_int(SimLoop.field.hero_progress.feat_of(&"bard")).is_equal(1)
	SimLoop.field.song.tick(30.0, SimLoop.creatures)
	SimLoop.field.song.cooldowns.clear()  # o canto e do Bardo da Nia
	HeroWatch.action(_x(bard) + 60.0)
	assert_bool(SimLoop.field.song.allies.has(target)).is_true()
	assert_int(SimLoop.field.hero_progress.feat_of(&"bard")).is_equal(1)


## A Nia evolui como o Rei: o Verbo 1 no nucleo, com a Semente e o feito (ADR 0052), com o
## monarca escolhido no marco pelo Verbo 2 (ADR 0059). A moeda volta ao saco.
func test_o_verbo_1_no_nucleo_evolui_a_nia_com_semente_e_quinze_conversoes() -> void:
	var nia := _begin(&"bard")
	for _n in 15:
		SimLoop.field.hero_progress.record(&"bard")
	SimLoop.state.royal_seeds = 1
	var i := SimLoop.units.index_of(nia)
	SimLoop.units.xs[i] = SimLoop.core_x
	SimLoop.units.clear_target(nia)
	var coins := SimLoop.units.carried_coins[i]
	assert_bool(MonarchWatch.can_evolve(SimLoop.field, 1)).is_true()
	SimLoop.intents.queue(IntentQueue.Kind.ASSUME, {})  # o monarca, e nao a sede (ADR 0059)
	SimLoop.step(PASSO)
	var args := {&"x": SimLoop.core_x, &"band": Band.Kind.SURFACE, &"amount": 1}
	args[&"source"] = Verbs.JOGADOR
	SimLoop.intents.queue(IntentQueue.Kind.DROP_COIN, args)
	SimLoop.step(PASSO)
	assert_int(SimLoop.field.hero_progress.phase_of(&"bard")).is_equal(2)
	assert_int(SimLoop.state.royal_seeds).is_equal(0)
	assert_int(SimLoop.units.carried_coins[i]).is_equal(coins)
	assert_int(SimLoop.field.classes.phase).is_equal(1)


func test_o_maestro_promove_preservando_a_vida_e_so_tropas_do_seu_dono() -> void:
	var bard := _begin(&"bard")
	SimLoop.field.hero_progress.phases[&"bard"] = 2
	var data := Registry.entry(&"units", &"archer") as UnitData
	var ally := SimLoop.units.spawn(SimLoop.state, data, Greybox.MEU_IMPERIO, _x(bard) + 30.0)
	var other := SimLoop.units.spawn(SimLoop.state, data, 99, _x(bard) + 35.0)
	var i := SimLoop.units.index_of(ally)
	SimLoop.units.healths[i] = data.max_health / 2
	var r := SimLoop.units.index_of(bard)
	var bolsa := SimLoop.units.carried_coins[r]
	HeroWatch.action(_x(ally))
	assert_str(String(SimLoop.units.data_ids[i])).is_equal("canopy_archer")
	var bardo := Registry.entry(&"units", &"bard_banner") as UnitData
	var preco := int(bardo.ability_params[&"promote_cost"])
	assert_int(SimLoop.units.carried_coins[r]).is_equal(bolsa - preco)
	assert_int(SimLoop.units.healths[i]).is_equal(data.max_health / 2)
	assert_str(String(SimLoop.units.data_ids[SimLoop.units.index_of(other)])).is_equal("archer")


func test_o_save_restaura_a_classe_a_evolucao_e_os_convertidos() -> void:
	var bard := _begin(&"bard")
	SimLoop.field.hero_progress.phases[&"bard"] = 2
	SimLoop.field.hero_progress.feats[&"bard"] = 15
	var ally := _enemy(&"brute", _x(bard) + 60.0)
	HeroWatch.action(_x(bard) + 60.0)
	var world := SimLoop.world()
	SimLoop.load_world(world)
	assert_int(Assume.driven()).is_equal(bard)
	assert_int(SimLoop.field.hero_progress.phase_of(&"bard")).is_equal(2)
	assert_array(SimLoop.field.song.permanent()).contains([ally])
	HeroWatch.tick(0.0)
	SimLoop.creatures.dissolve(SimLoop.field.song.permanent())
	assert_int(SimLoop.creatures.index_of(ally)).is_not_equal(-1)
	var old := world.duplicate(true)
	old.erase(&"hero_progress")
	old.erase(&"song")
	old.erase(&"focus")
	SimLoop.load_world(old)
	assert_int(SimLoop.field.hero_progress.phase_of(&"bard")).is_equal(1)
	assert_array(SimLoop.field.song.permanent()).is_empty()


func test_a_luz_do_reino_nao_repele_uma_criatura_convertida() -> void:
	var bard := _begin(&"bard")
	var ally := _enemy(&"crawler", _x(bard) + 60.0)
	HeroWatch.action(_x(bard) + 60.0)
	HeroWatch.tick(0.0)
	SimLoop.field.song.plan(SimLoop.units, SimLoop.creatures)
	var i := SimLoop.creatures.index_of(ally)
	var before := SimLoop.creatures.xs[i]
	SimLoop.creatures.set_lights([Vector4(before - 30.0, before + 30.0, 20.0, 0.5)], 2.0)
	SimLoop.creatures.tick_movement(PASSO)
	assert_float(SimLoop.creatures.recoils[i]).is_equal(0.0)
	assert_float(SimLoop.creatures.xs[i]).is_less(before)
