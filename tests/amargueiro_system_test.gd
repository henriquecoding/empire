# tests/amargueiro_system_test.gd — XIII-03: quem fica no campo cria raiz (§74).
#
# Os numeros vem todos de data/: o custo, o tempo de corte e o rendimento sao os
# de amargueiros.csv; o raio do Marco tambem. Nenhum esta escrito aqui.
extends GdUnitTestSuite

const MEU_IMPERIO := 7
const PASSO := 1.0 / 30.0
const NUCLEO := 1000.0
const LONGE := 400.0


func _destino(id: StringName) -> AmargueiroData:
	return Registry.entry(&"rot/amargueiros", id) as AmargueiroData


func _sistema() -> AmargueiroSystem:
	return SimFactory.amargueiros()


func _tropa(u: UnitSystem, e: GameState, id: StringName, x: float, dono := MEU_IMPERIO) -> int:
	return u.spawn(e, Registry.entry(&"units", id) as UnitData, dono, x)


func _matar(u: UnitSystem, unit_id: int) -> void:
	u.states[u.index_of(unit_id)] = UnitFsm.State.DEAD


func _muro(obras: BuildSystem, x: float) -> void:
	var vaga := BuildSlot.new()
	vaga.x = x
	vaga.blocks = true
	for w in SimFactory.walls_by_level():
		vaga.costs.append(w.cost)
		vaga.healths.append(w.max_health_b)
		vaga.healths_a.append(w.max_health_a)
	vaga.level = 1
	vaga.state = BuildSlot.State.DONE
	obras.post(vaga)


## Uma arvore anonima de um arqueiro, longe de qualquer muro. Devolve o id.
func _arvore(s: AmargueiroSystem, e: GameState, u: UnitSystem, x := LONGE) -> int:
	_matar(u, _tropa(u, e, &"archer", x))
	return s.at_dawn(e, u, BuildSystem.new(), NUCLEO)[0][AmargueiroSystem.ID]


func _pagar(s: AmargueiroSystem, e: GameState, u: UnitSystem, x: float, n: int) -> Array:
	var moedas := CoinSystem.new(Registry.entry(&"economy", &"curve") as EconomyCurve)
	for _k in n:
		moedas.settled[moedas.index_of(moedas.drop(e, x, Band.Kind.SURFACE, 1, 0.0))] = 1
	return s.tick(PASSO, u, moedas)


func test_quem_morre_fora_das_muralhas_cria_raiz_na_alvorada() -> void:
	var e := GameState.new()
	var u := UnitSystem.new()
	var s := _sistema()
	_matar(u, _tropa(u, e, &"archer", LONGE))
	var ev := s.at_dawn(e, u, BuildSystem.new(), NUCLEO)
	assert_int(ev[0][AmargueiroSystem.CHAVE]).is_equal(AmargueiroSystem.EV_RAIZ)
	assert_int(s.standing(false)).is_equal(1)
	assert_int(u.count()).is_equal(0)  # o corpo levantou-se: ja nao e tropa


func test_dentro_das_muralhas_o_corpo_desaparece() -> void:
	var e := GameState.new()
	var u := UnitSystem.new()
	var obras := BuildSystem.new()
	_muro(obras, NUCLEO - 300.0)
	_muro(obras, NUCLEO + 300.0)
	_matar(u, _tropa(u, e, &"archer", NUCLEO - 100.0))
	_matar(u, _tropa(u, e, &"archer", NUCLEO - 500.0))
	var s := _sistema()
	var ev := s.at_dawn(e, u, obras, NUCLEO)
	assert_int(ev[0][AmargueiroSystem.CHAVE]).is_equal(AmargueiroSystem.EV_SUMIU)
	assert_int(ev[1][AmargueiroSystem.CHAVE]).is_equal(AmargueiroSystem.EV_RAIZ)
	assert_int(s.standing(false)).is_equal(1)
	assert_int(u.count()).is_equal(0)


func test_so_os_mortos_criam_raiz_e_so_os_teus() -> void:
	var e := GameState.new()
	var u := UnitSystem.new()
	_tropa(u, e, &"archer", LONGE)  # vivo
	_matar(u, _tropa(u, e, &"vagrant", LONGE, RecruitSystem.SEM_DONO))  # nao e teu
	var s := _sistema()
	s.at_dawn(e, u, BuildSystem.new(), NUCLEO)
	assert_int(s.count()).is_equal(0)
	assert_int(u.count()).is_equal(1)


func test_no_subsolo_cria_raiz_e_no_ar_cai() -> void:
	var e := GameState.new()
	var u := UnitSystem.new()
	_matar(u, _tropa(u, e, &"digger", NUCLEO))
	_matar(u, _tropa(u, e, &"dragonfly", LONGE))
	var s := _sistema()
	s.at_dawn(e, u, BuildSystem.new(), NUCLEO)
	assert_int(s.count()).is_equal(2)
	assert_int(s.bands[0]).is_equal(Band.Kind.UNDERGROUND)
	assert_int(s.bands[1]).is_equal(Band.Kind.SURFACE)


func test_regra_2_a_serra_nao_pega_antes_de_uma_noite_de_pe() -> void:
	var e := GameState.new()
	var u := UnitSystem.new()
	var s := _sistema()
	var arvore := _arvore(s, e, u)
	var custo := _destino(&"fell").cost_coins
	assert_bool(s.ready_for(arvore, &"fell")).is_false()
	assert_array(_pagar(s, e, u, LONGE, custo)).is_empty()  # as moedas ficam no chao
	s.at_dawn(e, u, BuildSystem.new(), NUCLEO)  # a segunda alvorada
	assert_bool(s.ready_for(arvore, &"fell")).is_true()
	assert_int(s.fell_cost()).is_equal(custo)


func test_consagrar_pode_ser_logo_na_primeira_alvorada() -> void:
	var e := GameState.new()
	var u := UnitSystem.new()
	var s := _sistema()
	var arvore := _arvore(s, e, u)
	assert_bool(s.ready_for(arvore, &"consecrate")).is_true()
	assert_bool(s.consecrate(arvore)).is_true()
	assert_bool(s.consecrate(arvore)).is_false()  # uma vez so
	assert_int(s.standing(false)).is_equal(0)  # um Marco ja nao pesa
	var r := float(_destino(&"consecrate").protect_radius_px)
	assert_array(s.markers()).is_equal([Vector2(LONGE - r, LONGE + r)])


func test_num_marco_nao_nasce_raiz_nova() -> void:
	var e := GameState.new()
	var u := UnitSystem.new()
	var s := _sistema()
	s.consecrate(_arvore(s, e, u))
	_matar(u, _tropa(u, e, &"archer", LONGE + 10.0))
	var ev := s.at_dawn(e, u, BuildSystem.new(), NUCLEO)
	assert_int(ev[0][AmargueiroSystem.CHAVE]).is_equal(AmargueiroSystem.EV_SUMIU)
	assert_int(s.count()).is_equal(1)


func test_cortar_custa_as_moedas_e_o_tempo_e_rende_pela_escala() -> void:
	var e := GameState.new()
	var u := UnitSystem.new()
	var s := _sistema()
	var fell := _destino(&"fell")
	_arvore(s, e, u)
	s.at_dawn(e, u, BuildSystem.new(), NUCLEO)
	var ev := _pagar(s, e, u, LONGE, fell.cost_coins)
	assert_int(ev[-1][AmargueiroSystem.CHAVE]).is_equal(AmargueiroSystem.EV_CORTE)
	# Sem ninguem la, a serra nao anda: o §55 e presenca e nao tempo.
	var moedas := CoinSystem.new(Registry.entry(&"economy", &"curve") as EconomyCurve)
	for _i in int(fell.work_seconds / PASSO) + 2:
		s.tick(PASSO, u, moedas)
	assert_int(s.count()).is_equal(1)
	_tropa(u, e, &"builder", LONGE)
	var cortada: Dictionary = {}
	for _i in int(fell.work_seconds / PASSO) + 2:
		for x in s.tick(PASSO, u, moedas):
			cortada = x
	assert_int(cortada[AmargueiroSystem.QUANTO]).is_equal(fell.yield_by_tier[1])  # arqueiro: 2
	assert_int(s.bitter_wood).is_equal(fell.yield_by_tier[1])
	assert_int(s.count()).is_equal(0)


func test_regra_3_o_vagabundo_rende_o_minimo_e_a_elite_o_maximo() -> void:
	var e := GameState.new()
	var u := UnitSystem.new()
	_matar(u, _tropa(u, e, &"vagrant", LONGE))
	_matar(u, _tropa(u, e, &"root_berserker", LONGE + 50.0))
	var s := _sistema()
	s.at_dawn(e, u, BuildSystem.new(), NUCLEO)
	assert_array(Array(s.tiers)).is_equal([1, 3])


func test_o_nomeado_pesa_a_dobrar_e_rende_cinco() -> void:
	var e := GameState.new()
	var u := UnitSystem.new()
	var nome := _tropa(u, e, &"archer", LONGE)
	_matar(u, nome)
	var s := _sistema()
	s.at_dawn(e, u, BuildSystem.new(), NUCLEO, {nome: true})
	assert_int(s.standing(true)).is_equal(1)
	assert_int(s.standing(false)).is_equal(0)
	assert_int(s.wood_of(s.ids[0])).is_equal(_destino(&"fell").yield_named)


func test_o_campo_sobrevive_ao_save() -> void:
	var e := GameState.new()
	var u := UnitSystem.new()
	var s := _sistema()
	s.consecrate(_arvore(s, e, u))
	_arvore(s, e, u, LONGE - 300.0)
	s.bitter_wood = 3
	var copia := _sistema()
	copia.from_dict(s.to_dict())
	assert_array(Array(copia.ids)).is_equal(Array(s.ids))
	assert_array(copia.markers()).is_equal(s.markers())
	assert_int(copia.standing(false)).is_equal(1)
	assert_int(copia.bitter_wood).is_equal(3)
