# tests/oferta_regras_test.gd — o XIII-04, a parte que nao anda: a gramatica da
# coluna requires e a Divida da Candeia (§75).
#
# Os limiares, o teto das recusas e a janela vem de rot.csv; as ofertas de
# offers.csv. Nenhum numero de balanceamento esta aqui.
extends GdUnitTestSuite


func _perfil() -> RotProfile:
	return Registry.entry(&"rot", &"default") as RotProfile


func _oferta(id: StringName) -> OfferData:
	return Registry.entry(&"rot/offers", id) as OfferData


func _factos(extra := {}) -> Dictionary:
	var f := {
		&"gate": 0,
		&"treasury": 0,
		&"named": 0,
		&"marker": 0,
		&"peoples": 0,
		&"successor": 0,
		&"debt": 0,
		&"biome": &"",
	}
	f.merge(extra, true)
	return f


# ─── A gramatica (§75) ───────────────────────────────────────────────────────


func test_vazio_e_sem_condicao() -> void:
	assert_bool(OfferRules.holds("", _factos())).is_true()


func test_as_tres_formas_e_mais_nenhuma() -> void:
	assert_bool(OfferRules.holds("treasury>=80", _factos({&"treasury": 80}))).is_true()
	assert_bool(OfferRules.holds("treasury>=80", _factos({&"treasury": 79}))).is_false()
	assert_bool(OfferRules.holds("debt<=3", _factos({&"debt": 3}))).is_true()
	assert_bool(OfferRules.holds("debt<=3", _factos({&"debt": 4}))).is_false()
	assert_bool(OfferRules.holds("successor=1", _factos({&"successor": 1}))).is_true()
	(
		assert_bool(OfferRules.holds("biome=subterranean", _factos({&"biome": &"subterranean"})))
		. is_true()
	)
	assert_bool(OfferRules.holds("biome=subterranean", _factos({&"biome": &"forest"}))).is_false()


func test_virgula_e_e_todas_sao_obrigatorias() -> void:
	var dois := "named>=1,marker>=1"
	assert_bool(OfferRules.holds(dois, _factos({&"named": 1, &"marker": 1}))).is_true()
	assert_bool(OfferRules.holds(dois, _factos({&"named": 1}))).is_false()


func test_o_que_nao_cabe_na_gramatica_nunca_e_elegivel() -> void:
	# "Nada de parenteses, nada de ou, nada de negacao" — e uma chave que nao e
	# das oito tambem nao. Uma condicao mal escrita fecha, nao abre.
	assert_bool(OfferRules.holds("(debt>=1)", _factos({&"debt": 5}))).is_false()
	assert_bool(OfferRules.holds("debt>=1 ou named>=1", _factos({&"debt": 5}))).is_false()
	assert_bool(OfferRules.holds("debt!=1", _factos({&"debt": 5}))).is_false()
	assert_bool(OfferRules.holds("gold>=1", _factos())).is_false()


func test_elegivel_pelo_dia_pela_condicao_e_pela_campanha() -> void:
	var coxos := _oferta(&"the_lame")
	assert_bool(OfferRules.eligible(coxos, _factos(), coxos.min_day - 1, [])).is_false()
	assert_bool(OfferRules.eligible(coxos, _factos(), coxos.min_day, [])).is_true()
	var brilha := _oferta(&"all_that_shines")
	var rico := _factos({&"treasury": 1000})
	assert_bool(OfferRules.eligible(brilha, rico, brilha.min_day, [])).is_true()
	var usada := PackedStringArray([String(brilha.id)])
	assert_bool(OfferRules.eligible(brilha, rico, brilha.min_day, usada)).is_false()


func test_a_decima_segunda_so_aparece_com_a_divida_em_12() -> void:
	var ultima := _oferta(&"give_back_whats_mine")
	var tiers := _perfil().debt_tiers
	assert_bool(OfferRules.eligible(ultima, _factos({&"debt": tiers[-1] - 1}), 30, [])).is_false()
	assert_bool(OfferRules.eligible(ultima, _factos({&"debt": tiers[-1]}), 30, [])).is_true()


# ─── A Divida da Candeia (§75, D-06) ─────────────────────────────────────────


func test_a_divida_sobe_ate_ao_teto_e_nunca_desce() -> void:
	var livro := DebtLedger.new(_perfil())
	var antes := 0
	var dia := 1
	for delta in [1, 2, 0, 5, 3, 5, 5, 5, 4]:
		livro.incur(delta)
		livro.refuse(dia)
		livro.accept(dia + 1)
		dia += 2
		assert_int(livro.debt).is_greater_equal(antes)
		antes = livro.debt
	assert_int(livro.debt).is_equal(_perfil().debt_max)


func test_os_limiares_sao_os_de_rot_csv() -> void:
	var r := _perfil()
	var livro := DebtLedger.new(r)
	assert_int(livro.tier()).is_equal(0)
	assert_bool(livro.tender()).is_false()
	livro.incur(r.tender_from_debt)
	assert_bool(livro.tender()).is_true()
	assert_int(livro.tier()).is_equal(2)
	assert_bool(livro.ambient_light()).is_false()
	livro.incur(r.ambient_light_from_debt - r.tender_from_debt)
	assert_bool(livro.ambient_light()).is_true()
	assert_bool(livro.second_flame()).is_false()
	livro.incur(r.second_flame_from_debt - r.ambient_light_from_debt)
	assert_bool(livro.second_flame()).is_true()


func test_as_recusas_contam_as_ultimas_noites_e_voltam_a_zero_ao_aceitar() -> void:
	var r := _perfil()
	var livro := DebtLedger.new(r)
	for dia in range(1, 8):
		livro.refuse(dia)
	# Ao crepusculo do dia 8 contam as noites 3 a 7: a janela e de cinco.
	assert_int(livro.refusals(8)).is_equal(r.refusal_window_days)
	assert_int(livro.refusals(8 + r.refusal_window_days)).is_equal(0)
	livro.accept(8)
	assert_int(livro.refusals(9)).is_equal(0)


func test_recusar_trinta_noites_custa_o_mesmo_que_cinco() -> void:
	var r := _perfil()
	var livro := DebtLedger.new(r)
	for dia in range(1, 31):
		livro.refuse(dia)
	var rot := SimFactory.rot()
	rot.refusals = livro.refusals(31)
	rot.spawn(10, 1, 4000.0)
	var limpa := SimFactory.rot()
	limpa.spawn(10, 1, 4000.0)
	assert_float(rot.mass() - limpa.mass()).is_equal(r.refusal_cap)


func test_o_save_da_divida_tem_os_nomes_da_84() -> void:
	var livro := DebtLedger.new(_perfil())
	livro.incur(7)
	livro.refuse(3)
	livro.remember(&"all_that_shines")
	livro.mass_mult_permanent = 0.85
	livro.ended = true
	var d := livro.to_dict()
	assert_bool(d.has(&"debt_lantern")).is_true()
	assert_bool(d.has(&"refusals_by_day")).is_true()
	var lido := DebtLedger.new(_perfil())
	lido.from_dict(d)
	assert_int(lido.debt).is_equal(7)
	assert_int(lido.refusals(4)).is_equal(1)
	assert_array(Array(lido.used)).is_equal(["all_that_shines"])
	assert_float(lido.mass_mult_permanent).is_equal(0.85)
	assert_bool(lido.ended).is_true()
