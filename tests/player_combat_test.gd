# tests/player_combat_test.gd — o ataque manual do monarca (ADR 0045, ADR 0052).
extends GdUnitTestSuite

const STEP := 1.0 / 60.0
## A classe do ataque -> o monarca que a tem desde a ADR 0052.
const MONARCAS := {&"monarch": &"monarch", &"archer": &"archer_emperor", &"bard": &"nia"}


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20261001)
	Greybox.build()
	SimLoop.step(STEP)


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _hero(id: StringName) -> int:
	MonarchWatch.begin(MONARCAS[id])
	var who := SimLoop.king_id
	HeroWatch.tick(0.0)
	for i in SimLoop.units.count():
		if SimLoop.units.ids[i] != who:
			SimLoop.units.cooldowns[i] = 99.0
	return who


func _x(who: int) -> float:
	return SimLoop.units.xs[SimLoop.units.index_of(who)]


func _enemy(x: float, band: Band.Kind = Band.Kind.SURFACE) -> int:
	var id := SimLoop.creatures.spawn(
		SimLoop.state, Registry.entry(&"creatures", &"brute"), x, SimLoop.core_x
	)
	SimLoop.creatures.bands[SimLoop.creatures.index_of(id)] = band
	SimLoop.creatures.cooldowns[SimLoop.creatures.index_of(id)] = 99.0
	return id


func _health(who: int) -> int:
	return SimLoop.creatures.healths[SimLoop.creatures.index_of(who)]


func _resolve() -> Array[Dictionary]:
	SimLoop.combat.choose(SimLoop.units, SimLoop.creatures, SimLoop.builds)
	return SimLoop.combat.resolve(
		SimLoop.units, SimLoop.creatures, SimLoop.builds, func() -> float: return 0.99
	)


func _attack(who: int, direction: float = 1.0) -> void:
	SimLoop.combat.manual.request(who, direction)


func test_o_personagem_controlado_nao_ataca_automaticamente() -> void:
	for class_id in [&"monarch", &"archer", &"bard"]:
		SimLoop.stop()
		SimLoop.start(20261001)
		Greybox.build()
		var who := _hero(class_id)
		var enemy := _enemy(_x(who) + 15.0)
		_resolve()
		assert_int(_health(enemy)).is_equal(32)
		SimLoop.creatures.remove(enemy)


func test_o_tiro_manual_acerta_sem_o_sorteio_das_tropas() -> void:
	var who := _hero(&"archer")
	var enemy := _enemy(_x(who) + 100.0)
	_attack(who)
	var events := _resolve()
	assert_int(_health(enemy)).is_equal(28)
	assert_int(events.filter(func(e: Dictionary) -> bool: return e.kind == 0).size()).is_equal(1)
	assert_float(SimLoop.units.cooldowns[SimLoop.units.index_of(who)]).is_greater(0.0)


func test_o_ataque_segue_a_direcao_e_nao_escolhe_inimigos_atras() -> void:
	var who := _hero(&"archer")
	var behind := _enemy(_x(who) - 10.0)
	var front := _enemy(_x(who) + 110.0)
	_attack(who)
	_resolve()
	assert_int(_health(behind)).is_equal(32)
	assert_int(_health(front)).is_equal(28)


func test_o_ataque_nao_atravessa_faixas_nem_atinge_aliados() -> void:
	var who := _hero(&"archer")
	var other_band := _enemy(_x(who) + 30.0, Band.Kind.UNDERGROUND)
	var ally := _enemy(_x(who) + 40.0)
	SimLoop.field.song.allies[ally] = {
		&"permanent": true, &"bard": who, &"anchor": _x(who), &"owner": Greybox.MEU_IMPERIO
	}
	SimLoop.combat.manual.allies = SimLoop.field.song.allies
	var enemy := _enemy(_x(who) + 80.0)
	_attack(who)
	_resolve()
	assert_int(_health(other_band)).is_equal(32)
	assert_int(_health(ally)).is_equal(32)
	assert_int(_health(enemy)).is_equal(28)


func test_o_ataque_revalida_o_alcance_ao_ser_resolvido() -> void:
	var who := _hero(&"monarch")
	var enemy := _enemy(_x(who) + 15.0)
	_attack(who)
	SimLoop.creatures.xs[SimLoop.creatures.index_of(enemy)] = _x(who) + 100.0
	_resolve()
	assert_int(_health(enemy)).is_equal(32)


func test_premir_muitas_vezes_nao_ignora_a_cadencia() -> void:
	var who := _hero(&"archer")
	var enemy := _enemy(_x(who) + 100.0)
	for i in 8:
		_attack(who)
		_resolve()
	assert_int(_health(enemy)).is_equal(28)


func test_a_fila_curta_guarda_um_clique_proximo_do_fim_da_recarga() -> void:
	var who := _hero(&"archer")
	var enemy := _enemy(_x(who) + 100.0)
	var i := SimLoop.units.index_of(who)
	SimLoop.units.cooldowns[i] = 0.05
	_attack(who)
	_resolve()
	assert_int(_health(enemy)).is_equal(32)
	SimLoop.combat.manual.tick(0.06)
	SimLoop.units.cooldowns[i] = 0.0
	_resolve()
	assert_int(_health(enemy)).is_equal(28)


func test_um_clique_antigo_nao_dispara_muito_depois() -> void:
	var who := _hero(&"archer")
	var enemy := _enemy(_x(who) + 100.0)
	SimLoop.units.cooldowns[SimLoop.units.index_of(who)] = 1.0
	_attack(who)
	_resolve()
	SimLoop.combat.manual.tick(0.5)
	SimLoop.units.cooldowns[SimLoop.units.index_of(who)] = 0.0
	_resolve()
	assert_int(_health(enemy)).is_equal(32)


## Trocar de imperador (UN-17) cancela o ataque de quem se largou: o gesto e de quem o fez.
func test_trocar_de_corpo_cancela_o_ataque_pendente() -> void:
	var who := _hero(&"archer")
	var enemy := _enemy(_x(who) + 100.0)
	var outro := SimLoop.units.spawn(
		SimLoop.state, Registry.entry(&"units", &"nia"), Greybox.MEU_IMPERIO, _x(who)
	)
	_attack(who)
	SimLoop.units.pilot = outro
	HeroWatch.tick(0.0)
	assert_bool(SimLoop.combat.manual.pending(who)).is_false()
	SimLoop.units.pilot = UnitSystem.NENHUM
	HeroWatch.tick(0.0)
	_resolve()
	assert_int(_health(enemy)).is_equal(32)


func test_pausar_cancela_o_ataque_sem_o_disparar_ao_retomar() -> void:
	var who := _hero(&"archer")
	var enemy := _enemy(_x(who) + 100.0)
	_attack(who)
	SimLoop.intents.queue(IntentQueue.Kind.ATTACK, {&"who": who, &"direction": 1.0})
	SimLoop.set_paused(true)
	assert_bool(SimLoop.combat.manual.pending(who)).is_false()
	assert_int(SimLoop.intents.pending()).is_equal(0)
	SimLoop.set_paused(false)
	_resolve()
	assert_int(_health(enemy)).is_equal(32)


func test_o_perfil_usado_no_hud_tem_o_alcance_e_dano_do_csv() -> void:
	var who := _hero(&"archer")
	var data := Registry.entry(&"units", &"archer_emperor") as UnitData
	var stats := SimLoop.combat.manual.profile(SimLoop.units, who)
	assert_int(stats[&"damage"]).is_equal(data.damage)
	assert_float(stats[&"range"]).is_equal(float(data.range_px))
	assert_dict(SimLoop.combat.manual.profile(SimLoop.units, -1)).is_empty()


func test_a_marca_nao_dispara_e_nao_gasta_o_intervalo_do_tiro() -> void:
	var who := _hero(&"archer")
	var enemy := _enemy(_x(who) + 100.0)
	HeroWatch.action(_x(who) + 100.0)
	_resolve()
	assert_int(_health(enemy)).is_equal(32)
	assert_float(SimLoop.units.cooldowns[SimLoop.units.index_of(who)]).is_equal(0.0)
	assert_bool(SimLoop.field.focus.marked(enemy, Greybox.MEU_IMPERIO)).is_true()


func test_o_bardo_tem_ataque_fraco_e_encanto_separado() -> void:
	var who := _hero(&"bard")
	var enemy := _enemy(_x(who) + 15.0)
	_attack(who)
	_resolve()
	assert_int(_health(enemy)).is_less(32)
	assert_bool(SimLoop.field.song.allies.has(enemy)).is_false()


func test_o_bardo_pode_encantar_durante_a_recarga_do_ataque() -> void:
	var who := _hero(&"bard")
	_enemy(_x(who) + 15.0)
	_attack(who)
	_resolve()
	var crawler := SimLoop.creatures.spawn(
		SimLoop.state, Registry.entry(&"creatures", &"crawler"), _x(who) + 80.0, SimLoop.core_x
	)
	assert_bool(HeroWatch.action(_x(who) + 80.0)).is_true()
	assert_bool(SimLoop.field.song.allies.has(crawler)).is_true()
	assert_bool(HeroWatch.action(_x(who) + 80.0)).is_false()


func test_as_tropas_continuam_a_atacar_sozinhas() -> void:
	var who := _hero(&"monarch")
	var data := Registry.entry(&"units", &"spearman") as UnitData
	SimLoop.units.spawn(SimLoop.state, data, Greybox.MEU_IMPERIO, _x(who))
	var enemy := _enemy(_x(who) + 15.0)
	_resolve()
	assert_int(_health(enemy)).is_equal(32 - data.damage)


func test_a_intencao_de_ataque_so_mexe_na_simulacao_no_tick() -> void:
	var who := _hero(&"archer")
	var enemy := _enemy(_x(who) + 100.0)
	SimLoop.intents.queue(IntentQueue.Kind.ATTACK, {&"who": who, &"direction": 1.0})
	assert_int(_health(enemy)).is_equal(32)
	SimLoop.step(STEP)
	assert_int(_health(enemy)).is_equal(28)
