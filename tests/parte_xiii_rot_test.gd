# tests/parte_xiii_rot_test.gd — D-01 a D-06 da §84: a massa, o Amargueiro,
# a Oferta e a Divida da Candeia (§74, §75).
#
# Regra da ADR 0019: o que se mede so com os dados corre ja, contra
# data/source/ e data/**/*.tres. O que precisa de um sistema que ainda nao
# existe fica saltado com a razao escrita e o nome do sistema que falta —
# nunca comentado, nunca apagado.
extends GdUnitTestSuite

const Dados := preload("res://tests/support/dados.gd")
const Model := preload("res://tests/support/reference_model.gd")


func _rot() -> RotProfile:
	return load("res://data/rot/default.tres")


func _amargueiro(id: String) -> AmargueiroData:
	return load("res://data/rot/amargueiros/%s.tres" % id)


# ----------------------------------------------------------------- §74


func test_d01_massa_em_campo_limpo_ao_dia_20_e_400() -> void:
	# A linha "Campo limpo" da tabela da §74. Se alguem mexer nos coeficientes
	# sem refazer a tabela, e aqui que se ve.
	var r := _rot()
	assert_float(Model.rot_mass(20, 0, r)).is_equal(400.0)
	# E as outras tres linhas da mesma tabela, que sao a razao de ser da secao.
	assert_float(Model.rot_mass(20, 0, r, 3, 0)).is_equal(466.0)
	assert_float(Model.rot_mass(20, 0, r, 8, 0)).is_equal(576.0)
	assert_float(Model.rot_mass(20, 0, r, 5, 3)).is_equal(645.0)
	# Tres fortalezas ao dia 20, campo limpo: 490 contra os 700 da v5.2 (-30%).
	assert_float(Model.rot_mass(20, 3, r)).is_equal(490.0)


func test_d02_lenho_nao_e_moeda_e_rende_o_que_a_pessoa_era() -> void:
	# Regra 1 da §74: sem preco nao ha arbitragem. Se alguem lhe der valor em
	# moedas, a jogada otima passa a ser mandar vagabundos morrer la fora.
	var kv := Dados.kv("res://data/source/economy.csv")
	assert_str(str(kv.get("bitter_wood_sell_price", "?"))).is_equal("0")
	# Regra 3: a carne barata rende pouco, a cara rende muito.
	var fell := _amargueiro("fell")
	assert_array(fell.yield_by_tier).is_equal([1, 2, 3])
	assert_int(fell.yield_named).is_equal(5)
	for i in range(1, fell.yield_by_tier.size()):
		assert_int(fell.yield_by_tier[i]).is_greater(fell.yield_by_tier[i - 1])
	assert_int(fell.yield_named).is_greater(fell.yield_by_tier[-1])


func test_d03_um_amargueiro_nao_se_corta_antes_de_aguentar_uma_noite() -> void:
	# Regra 2 da §74: pagas sempre os +22 uma vez, por cada arvore. E o que
	# fecha a exploracao do vagabundo pela raiz, e nao pela margem.
	var fell := _amargueiro("fell")
	assert_int(fell.nights_standing_required).is_greater_equal(1)
	assert_int(fell.from_dawn).is_equal(2)
	assert_int(_rot().amargueiro_nights_standing).is_equal(fell.nights_standing_required)
	# Consagrar pode ser logo na primeira alvorada: e a alternativa que nao paga.
	assert_int(_amargueiro("consecrate").from_dawn).is_equal(1)


# ----------------------------------------------------------------- §75


func test_d04_a_penalizacao_por_recusa_nunca_passa_de_40() -> void:
	# Um jogador que decida nunca negociar paga um imposto fixo e conhecido.
	var r := _rot()
	assert_float(r.refusal_cap).is_equal(40.0)
	assert_float(r.refusal_mass * r.refusal_window_days).is_less_equal(r.refusal_cap)
	for refusals in [0, 1, 5, 30, 1000]:
		var mass := Model.rot_mass(10, 0, r, 0, 0, refusals)
		assert_float(mass - Model.rot_mass(10, 0, r)).is_less_equal(r.refusal_cap)


func test_d05_uma_oferta_por_noite_mesmo_com_duas_manchas() -> void:
	# A partir do dia 12 ha duas manchas (§05). As duas perguntam a mesma noite, a
	# cada tick, uma de cada lado do muro: so uma fala, e so uma vez.
	var r := _rot()
	assert_int(r.offers_per_night).is_equal(1)
	var voz := SimFactory.offers()
	voz.dusk()
	var muro := 1000.0
	var passo := 1.0 / 30.0
	var falou := 0
	for _t in int(r.offer_window_after_dusk.y * 2.0 / passo):
		for mancha in [muro + 10.0, muro - 10.0]:
			if voz.due(passo, mancha, muro):
				falou += 1
				voz.open(load("res://data/rot/offers/the_lame.tres"), mancha, 1)
	assert_int(falou).is_equal(r.offers_per_night)


func test_d06_a_divida_nunca_desce() -> void:
	# Todos os caminhos do DebtLedger, por uma ordem qualquer: nenhum desce a
	# Divida. Nao ha subtracao, e isto e o que o prova sem ler o codigo.
	var r := _rot()
	assert_int(r.debt_max).is_equal(20)
	var livro := DebtLedger.new(r)
	var antes := livro.debt
	var caminhos := [
		func() -> void: livro.incur(3),
		func() -> void: livro.refuse(4),
		func() -> void: livro.accept(5),
		func() -> void: livro.remember(&"all_that_shines"),
		func() -> void: livro.from_dict(livro.to_dict()),
		func() -> void: livro.incur(0),
	]
	for volta in 8:
		for c: Callable in caminhos:
			c.call()
			assert_int(livro.debt).is_greater_equal(antes)
			antes = livro.debt
	assert_int(livro.debt).is_equal(r.debt_max)


func test_d06_dados_nenhuma_oferta_tem_divida_negativa() -> void:
	# A metade do D-06 que os dados sabem provar: nenhuma linha desce a Divida.
	var closers := 0
	for o: OfferData in Dados.all_in("res://data/rot/offers"):
		var msg := "%s: debt_delta %d" % [o.id, o.debt_delta]
		assert_int(o.debt_delta).override_failure_message(msg).is_greater_equal(0)
		if o.ends_rot:
			closers += 1
			assert_int(o.debt_delta).is_equal(0)
	# A decima segunda fecha o ciclo em vez de subir a divida. So essa (§79).
	assert_int(closers).is_equal(1)


func test_limiares_da_divida_sobem_e_batem_com_a_luz() -> void:
	var r := _rot()
	var tiers := r.debt_tiers
	assert_array(tiers).is_equal([3, 6, 9, 12])
	for i in range(1, tiers.size()):
		assert_int(tiers[i]).is_greater(tiers[i - 1])
	assert_int(r.tender_from_debt).is_equal(tiers[1])
	assert_int(r.ambient_light_from_debt).is_equal(tiers[2])
	assert_int(r.second_flame_from_debt).is_equal(tiers[3])
	assert_int(tiers[-1]).is_less_equal(r.debt_max)


func test_a_gramatica_da_coluna_requires() -> void:
	# §75: <chave><op><numero> ou <chave>=<id>, virgulas em AND. Sem parenteses,
	# sem "ou", sem negacao. Se uma oferta precisar de mais, sao duas ofertas.
	var chaves := ["gate", "treasury", "named", "marker", "peoples", "successor", "debt", "biome"]
	var forma := RegEx.create_from_string("^([a-z_]+)(>=|<=|=)([A-Za-z0-9_]+)$")
	for o: OfferData in Dados.all_in("res://data/rot/offers"):
		if o.requires.is_empty():
			continue
		for termo in o.requires.split(","):
			var m := forma.search(termo.strip_edges())
			var msg := "%s: requires '%s' nao cabe na gramatica da §75" % [o.id, o.requires]
			assert_object(m).override_failure_message(msg).is_not_null()
			if m != null:
				assert_array(chaves).contains([m.get_string(1)])
		assert_str(o.requires).not_contains("(")
		assert_str(o.requires).not_contains(" ou ")
