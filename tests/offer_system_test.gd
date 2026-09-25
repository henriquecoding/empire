# tests/offer_system_test.gd — XIII-04: a Oferta e a Divida da Candeia (§75).
#
# Os numeros vem de data/: os 20 s do prato, a janela e o teto das recusas, os
# limiares da Divida e o preco de cada oferta. Nenhum esta escrito aqui.
extends GdUnitTestSuite

const PASSO := 1.0 / 30.0
const PRATO := 500.0
const LARGO := 60.0
const LARGURA := 4000.0
const SEMENTE := 20260925


func _perfil() -> RotProfile:
	return SimFactory.rot_profile()


func _oferta(id: StringName) -> OfferData:
	return Registry.entry(&"rot/offers", id) as OfferData


func _moedas() -> CoinSystem:
	return CoinSystem.new(Registry.entry(&"economy", &"curve") as EconomyCurve)


func _largar(m: CoinSystem, x: float, n: int) -> void:
	var e := GameState.new()
	for _k in n:
		m.settled[m.index_of(m.drop(e, x, Band.Kind.SURFACE, 1, 0.0))] = 1


func _correr(rot: RotSystem, segundos: float) -> int:
	var invocadas := 0
	for _i in int(segundos / PASSO):
		if rot.needs_interval():
			rot.arm(0.0)
		invocadas += rot.tick(PASSO, []).size()
	return invocadas


func _ids(lista: Array[OfferData]) -> Array:
	return lista.map(func(o: OfferData) -> String: return String(o.id))


func test_a_gramatica_requires() -> void:
	var ctx := {&"treasury": 80, &"gate": 0, &"biome": "subterranean", &"debt": 12}
	assert_bool(OfferSystem.meets("", ctx)).is_true()
	assert_bool(OfferSystem.meets("treasury>=80", ctx)).is_true()
	assert_bool(OfferSystem.meets("treasury>=81", ctx)).is_false()
	assert_bool(OfferSystem.meets("gate>=1", ctx)).is_false()
	assert_bool(OfferSystem.meets("gate<=0,debt>=12", ctx)).is_true()
	assert_bool(OfferSystem.meets("biome=subterranean", ctx)).is_true()
	assert_bool(OfferSystem.meets("biome=forest", ctx)).is_false()
	assert_bool(OfferSystem.meets("named>=1", ctx)).is_false()  # chave que nao existe vale 0
	assert_bool(OfferSystem.meets("treasury>=80 ou gate>=1", ctx)).is_false()


func test_so_se_sorteia_o_que_o_jogo_sabe_cobrar_e_dar() -> void:
	var s := SimFactory.offers()
	assert_array(_ids(s.eligible({&"day": 2}))).is_empty()
	assert_array(_ids(s.eligible({&"day": 3}))).is_equal(["the_lame"])
	var rico := {&"day": 4, &"treasury": 80}
	assert_array(_ids(s.eligible(rico))).is_equal(["all_that_shines", "the_lame"])
	for o in s.eligible({&"day": 30, &"treasury": 999}):
		assert_array(OfferSystem.PRECOS_FEITOS).contains([o.price_kind])
		assert_array(OfferSystem.EFEITOS_FEITOS).contains([o.effect_kind])


func test_d05_uma_oferta_por_noite() -> void:
	var s := SimFactory.offers()
	assert_bool(s.can_speak(3)).is_true()
	s.open(_oferta(&"the_lame"), 3, PRATO, LARGO)
	assert_bool(s.can_speak(3)).is_false()  # a outra mancha fica calada
	s.tick(_perfil().offer_seconds + 1.0, _moedas(), 3)
	assert_bool(s.can_speak(3)).is_false()  # nem depois de caducar
	assert_bool(s.can_speak(4)).is_true()


func test_so_conta_o_que_cai_no_prato() -> void:
	var s := SimFactory.offers()
	s.open(_oferta(&"the_lame"), 3, PRATO, LARGO)
	var m := _moedas()
	_largar(m, PRATO + LARGO * 2.0, 1)
	assert_array(s.tick(PASSO, m, 3)).is_empty()
	assert_int(m.count()).is_equal(1)
	_largar(m, PRATO, 1)
	var ev := s.tick(PASSO, m, 3)
	assert_int(ev[-1][OfferSystem.CHAVE]).is_equal(OfferSystem.EV_PAGO)


func test_aceitar_sobe_a_divida_e_zera_as_recusas() -> void:
	var s := SimFactory.offers()
	s.open(_oferta(&"the_lame"), 3, PRATO, LARGO)
	s.tick(_perfil().offer_seconds + 1.0, _moedas(), 3)
	assert_int(s.refusals(3)).is_equal(1)
	s.open(_oferta(&"the_lame"), 4, PRATO, LARGO)
	var m := _moedas()
	_largar(m, PRATO, 1)
	s.tick(PASSO, m, 4)
	var ev := s.settle(true, 4)
	assert_int(ev[OfferSystem.CHAVE]).is_equal(OfferSystem.EV_ACEITE)
	assert_int(s.debt.debt).is_equal(_oferta(&"the_lame").debt_delta)
	assert_int(s.refusals(4)).is_equal(0)
	assert_bool(s.active()).is_false()


func test_caduca_como_recusa_e_devolve_o_que_estava_no_prato() -> void:
	var s := SimFactory.offers()
	s.open(_oferta(&"all_that_shines"), 4, PRATO, LARGO)
	s.paid = 0
	var ev := s.settle(false, 4)  # o preco deixou de existir
	assert_int(ev[OfferSystem.CHAVE]).is_equal(OfferSystem.EV_CADUCA)
	assert_int(s.debt.debt).is_equal(0)
	assert_int(s.refusals(4)).is_equal(1)


func test_as_recusas_saem_da_janela() -> void:
	var s := SimFactory.offers()
	var janela := _perfil().refusal_window_days
	for dia in range(1, 31):
		s.open(_oferta(&"the_lame"), dia, PRATO, LARGO)
		s.tick(_perfil().offer_seconds + 1.0, _moedas(), dia)
	assert_int(s.refusals(30)).is_equal(janela)  # recusar trinta e igual a recusar cinco
	assert_int(s.refusals(30 + janela)).is_equal(0)


func test_uma_vez_por_campanha() -> void:
	var s := SimFactory.offers()
	var o := _oferta(&"all_that_shines")
	s.open(o, 4, PRATO, LARGO)
	s.paid = s.needed()
	s.settle(true, 4)
	assert_array(_ids(s.eligible({&"day": 9, &"treasury": 999}))).not_contains(["all_that_shines"])


func test_as_de_preco_alto_so_com_o_primeiro_limiar() -> void:
	# §75: "3–5 — as ofertas passam a incluir as de preco 3". Nenhuma das que
	# o jogo sabe cobrar custa 3 hoje; a regra prova-se sobre a Divida.
	var s := SimFactory.offers()
	assert_int(s.debt.tier()).is_equal(0)
	s.debt.add(_perfil().debt_tiers[0])
	assert_int(s.debt.tier()).is_equal(1)


func test_a_divida_nunca_desce_nem_passa_do_teto() -> void:
	var d := DebtLedger.new(_perfil())
	d.add(5)
	d.add(-3)
	d.add(0)
	assert_int(d.debt).is_equal(5)
	d.add(1000)
	assert_int(d.debt).is_equal(_perfil().debt_max)
	assert_bool(d.second_flame()).is_true()


func test_os_limiares_da_luz_e_o_zelador() -> void:
	var p := _perfil()
	var d := DebtLedger.new(p)
	assert_bool(d.tender()).is_false()
	d.add(p.tender_from_debt)
	assert_bool(d.tender()).is_true()
	assert_bool(d.ambient_light()).is_false()
	d.add(p.ambient_light_from_debt - p.tender_from_debt)
	assert_bool(d.ambient_light()).is_true()
	assert_bool(d.second_flame()).is_false()


func test_a_oferta_aberta_sobrevive_ao_save() -> void:
	var s := SimFactory.offers()
	s.open(_oferta(&"the_lame"), 3, PRATO, LARGO)
	s.debt.add(4)
	s.refused_days = PackedInt32Array([1, 2])
	s.used = PackedStringArray(["all_that_shines"])
	var copia := SimFactory.offers()
	copia.from_dict(s.to_dict())
	assert_str(String(copia.offer_id)).is_equal("the_lame")
	assert_float(copia.dish_x).is_equal(PRATO)
	assert_int(copia.debt.debt).is_equal(4)
	assert_int(copia.refusals(3)).is_equal(2)
	assert_bool(copia.can_speak(3)).is_false()


# ─── XIII-04: o que a Oferta faz a mancha (§75) ─────────────────────────────


func test_parada_nao_anda_nem_invoca_e_depois_retoma() -> void:
	RngService.configure(SEMENTE)
	var rot := SimFactory.rot()
	rot.spawn(3, 1, LARGURA)
	var onde := rot.position_x()
	rot.pause(5.0)
	rot.arm(0.0)
	assert_int(_correr(rot, 4.9)).is_equal(0)
	assert_float(rot.position_x()).is_equal(onde)
	_correr(rot, 1.0)
	assert_float(rot.position_x()).is_less(onde)


func test_a_massa_desta_noite_multiplica_se_e_nunca_fica_negativa() -> void:
	var rot := SimFactory.rot()
	rot.spawn(10, 1, LARGURA)
	var antes := rot.mass()
	rot.scale_mass(0.6)
	assert_float(rot.mass()).is_equal_approx(antes * 0.6, 0.001)
	rot.scale_mass(-1.0)
	assert_float(rot.mass()).is_equal(0.0)


func test_o_que_ja_nao_anda_sao_as_tuas_tropas_fracas_menos_o_rei() -> void:
	var u := UnitSystem.new()
	var e := GameState.new()
	var arqueiro := Registry.entry(&"units", &"archer") as UnitData
	var rei := u.spawn(e, arqueiro, 7, 0.0)
	var fraco := u.spawn(e, arqueiro, 7, 0.0)
	var forte := u.spawn(e, arqueiro, 7, 0.0)
	var alheio := u.spawn(e, arqueiro, RecruitSystem.SEM_DONO, 0.0)
	for id in [rei, fraco, alheio]:
		u.healths[u.index_of(id)] = 1
	var limiar := _oferta(&"the_lame").price_amount
	var saem := OfferSystem.below_health(u, limiar, rei)
	assert_array(Array(saem)).is_equal([fraco])
	assert_bool(saem.has(forte)).is_false()
