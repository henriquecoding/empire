# tests/animo_test.gd — o animo do reino (Q-102, o dono a 29/09/2026: "elabore
# algo concreto que faca sentido ao meu jogo"). Memorias com peso e prazo; tres
# efeitos por limiar: quem foge, quanto se produz, quem chega aos acampamentos.
extends GdUnitTestSuite

const STEP := 1.0 / 30.0


func _curva() -> EconomyCurve:
	return SimFactory.curve()


func test_as_memorias_somam_a_base_e_passam() -> void:
	var s := Spirit.new(50.0, 35.0, 65.0)
	assert_float(s.value(1)).is_equal(50.0)
	s.note(&"a", 20.0, 1, 2)
	assert_float(s.value(1)).is_equal(70.0)
	assert_int(s.level(1)).is_equal(1)
	assert_float(s.value(2)).is_equal(70.0)
	assert_float(s.value(3)).is_equal(50.0)
	s.note(&"b", -30.0, 3, 1)
	assert_int(s.level(3)).is_equal(-1)
	s.dawn(4)
	assert_int(s.memories.size()).is_equal(0)


func test_o_animo_fica_entre_0_e_100_e_vai_no_save() -> void:
	var s := Spirit.new(50.0, 35.0, 65.0)
	for _k in 10:
		s.note(&"x", 30.0, 1, 5)
	assert_float(s.value(1)).is_equal(100.0)
	var copia := Spirit.new(50.0, 35.0, 65.0)
	copia.from_dict(s.to_dict())
	assert_float(copia.value(1)).is_equal(100.0)


## §74: "serra-lo tira 1 ponto de moral ao imperio durante 2 dias".
func test_a_arvore_com_nome_serrada_tira_um_ponto_dois_dias() -> void:
	assert_float(float(_curva().spirit_weights[&"named_tree_felled"])).is_equal(-1.0)
	assert_int(int(_curva().spirit_days[&"named_tree_felled"])).is_equal(2)


func test_abatido_foge_se_mais_cedo_e_animado_mais_tarde() -> void:
	var moral := SimFactory.morale()
	var u := UnitSystem.new()
	var estado := GameState.new()
	var t := u.spawn(estado, Registry.entry(&"units", &"archer"), 1, 0.0)
	var i := u.index_of(t)
	u.healths[i] = int(ceilf(u.max_healths[i] * _curva().flee_health * 1.05))
	assert_array(moral.tick(u, UnitSystem.NENHUM, 500.0, false)).is_empty()
	u.states[i] = UnitFsm.State.WORK
	moral.spirit = -1
	assert_array(moral.tick(u, UnitSystem.NENHUM, 500.0, false)).is_not_empty()


func test_no_jogo_a_noite_ganha_deixa_memoria_e_o_painel_mostra_o_animo() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20260929)
	Greybox.build()
	SimLoop.step(STEP)
	var antes := SimLoop.field.spirit.value(1)
	EventBus.night_survived.emit(1, 0, 0)
	assert_float(SimLoop.field.spirit.value(1)).is_greater(antes)
	TranslationServer.set_locale("pt_PT")
	assert_str(HudText.extras(0, 57.0, 2)).contains("ÂNIMO 57")
	assert_str(HudText.extras(0, 57.0, 2)).contains("SEMENTES 2")
	SimLoop.stop()
	SimLoop.autosave_enabled = true


## As bonificacoes dos titulos que ja tem onde pegar (§76, Q-102).
func test_os_titulos_dao_cadencia_dano_contra_cerco_e_nao_fugir() -> void:
	assert_float(TitlePerks.rate({&"attack_rate": 1.1})).is_equal_approx(1.1, 0.001)
	assert_float(TitlePerks.rate({})).is_equal(1.0)
	var bichos := CreatureSystem.new()
	var estado := GameState.new()
	var ariete := bichos.spawn(estado, Registry.entry(&"creatures", &"slime_ram"), 0.0, 1)
	var rastejante := bichos.spawn(estado, Registry.entry(&"creatures", &"crawler"), 0.0, 1)
	var dados := SimFactory.by_id(&"creatures")
	var bonus := {&"damage_vs_siege": 2.0}
	assert_int(TitlePerks.vs_siege(bonus, bichos, dados, ariete)).is_equal(2)
	assert_int(TitlePerks.vs_siege(bonus, bichos, dados, rastejante)).is_equal(0)
	var moral := SimFactory.morale()
	var u := UnitSystem.new()
	var t := u.spawn(estado, Registry.entry(&"units", &"archer"), 1, 0.0)
	assert_bool(moral.can_flee(u, u.index_of(t))).is_true()
	moral.perks = {t: {&"never_flees": 1.0}}
	assert_bool(moral.can_flee(u, u.index_of(t))).is_false()
