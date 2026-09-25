# tests/amargueiro_destinos_test.gd — o XIII-03, segunda metade: os tres
# destinos de um Amargueiro, sempre com o Verbo 1 (§74). Cortar, consagrar,
# deixar — e o save que os guarda (§84).
#
# O preco e o tempo do corte vem de amargueiros.csv; nenhum esta aqui.
extends GdUnitTestSuite

const B := preload("res://tests/support/bosque.gd")

# ─── Cortar: regra 2, uma noite de pe ────────────────────────────────────────


func test_a_serra_so_pega_depois_de_uma_noite_de_pe() -> void:
	var estado := GameState.new()
	var u := UnitSystem.new()
	var o := BuildSystem.new()
	B.morto(u, estado, &"archer", B.FORA)
	var bosque := SimFactory.amargueiros()
	B.alvorada(bosque, 3, u, o)
	assert_int(o.count()).is_equal(0)  # primeira alvorada: nada onde largar
	B.alvorada(bosque, 4, u, o)
	assert_int(o.count()).is_equal(1)  # segunda: o slot de destino do §55
	var vaga := o.slots[0]
	var cortar := B.destino(&"fell")
	assert_str(String(vaga.kind)).is_equal(String(AmargueiroSystem.CORTE))
	assert_float(vaga.x).is_equal(B.FORA)
	assert_int(vaga.next_cost()).is_equal(cortar.cost_coins)
	assert_float(vaga.works[0]).is_equal(cortar.work_seconds)
	assert_float(vaga.width).is_equal(B.perfil().amargueiro_base_px)
	B.alvorada(bosque, 5, u, o)
	assert_int(o.count()).is_equal(1)  # e so uma serra por arvore


func test_moedas_na_base_antes_da_segunda_alvorada_ficam_no_chao() -> void:
	var estado := GameState.new()
	var u := UnitSystem.new()
	var o := BuildSystem.new()
	B.morto(u, estado, &"archer", B.FORA)
	var bosque := SimFactory.amargueiros()
	B.alvorada(bosque, 3, u, o)
	var moedas := B.moedas_pousadas(estado, B.FORA, B.destino(&"fell").cost_coins)
	o.absorb(moedas)
	assert_int(moedas.count()).is_equal(B.destino(&"fell").cost_coins)


func test_cortar_rende_lenho_pela_escala_e_tira_a_arvore_da_massa() -> void:
	var estado := GameState.new()
	var u := UnitSystem.new()
	var o := BuildSystem.new()
	B.morto(u, estado, &"archer", B.FORA)
	var bosque := SimFactory.amargueiros()
	B.alvorada(bosque, 3, u, o)
	B.alvorada(bosque, 4, u, o)
	var eventos := B.cortar(bosque, estado, u, o, B.FORA)
	assert_int(bosque.count()).is_equal(0)
	assert_int(bosque.anonymous()).is_equal(0)
	assert_int(bosque.bitter_wood).is_equal(B.destino(&"fell").yield_by_tier[1])
	assert_int(eventos.size()).is_equal(1)
	assert_int(eventos[0][AmargueiroSystem.CHAVE]).is_equal(AmargueiroSystem.EV_CORTADO)
	assert_bool(o.slots[0].standing()).is_false()  # o toco nao e obra
	assert_int(o.slots[0].next_cost()).is_equal(BuildSlot.NENHUM)


func test_um_nomeado_cortado_rende_5_e_cobra_moral() -> void:
	var estado := GameState.new()
	var u := UnitSystem.new()
	var o := BuildSystem.new()
	var nomeado := B.morto(u, estado, &"archer", B.FORA)
	var bosque := SimFactory.amargueiros()
	bosque.at_dawn(3, u, o, B.NUCLEO, B.LARGURA, {nomeado: B.TITULO})
	B.alvorada(bosque, 4, u, o)
	var eventos := B.cortar(bosque, estado, u, o, B.FORA)
	var cortar := B.destino(&"fell")
	assert_int(bosque.bitter_wood).is_equal(cortar.yield_named)
	assert_int(eventos[0][AmargueiroSystem.MORAL]).is_equal(cortar.morale_cost)
	assert_int(eventos[0][AmargueiroSystem.DIAS]).is_equal(cortar.morale_days)


# ─── Consagrar ───────────────────────────────────────────────────────────────


func test_consagrar_vira_marco_sai_da_massa_e_abranda_a_podridao() -> void:
	var estado := GameState.new()
	var u := UnitSystem.new()
	var o := BuildSystem.new()
	B.morto(u, estado, &"archer", B.FORA)
	var bosque := SimFactory.amargueiros()
	B.alvorada(bosque, 3, u, o)
	assert_bool(bosque.consecrate(0, o)).is_true()  # logo na primeira alvorada
	assert_int(bosque.anonymous()).is_equal(0)
	assert_int(bosque.count()).is_equal(1)  # o Marco fica
	var raio := float(B.destino(&"consecrate").protect_radius_px)
	assert_array(bosque.consecrated()).is_equal([Vector2(B.FORA - raio, B.FORA + raio)])
	assert_bool(bosque.consecrate(0, o)).is_false()  # um Marco nao se consagra duas vezes
	B.alvorada(bosque, 4, u, o)
	assert_int(o.count()).is_equal(0)  # e a serra nao pega em pedra


func test_o_marco_protege_o_raio_de_raizes_novas() -> void:
	var estado := GameState.new()
	var u := UnitSystem.new()
	var o := BuildSystem.new()
	B.morto(u, estado, &"archer", B.FORA)
	var bosque := SimFactory.amargueiros()
	B.alvorada(bosque, 3, u, o)
	bosque.consecrate(0, o)
	var raio := float(B.destino(&"consecrate").protect_radius_px)
	B.morto(u, estado, &"archer", B.FORA + raio - 1.0)
	B.morto(u, estado, &"archer", B.FORA + raio + 1.0)
	B.alvorada(bosque, 4, u, o)
	assert_int(bosque.count()).is_equal(2)  # o Marco e a de fora do raio
	assert_int(bosque.anonymous()).is_equal(1)


func test_nao_se_consagra_com_a_serra_ja_dentro() -> void:
	var estado := GameState.new()
	var u := UnitSystem.new()
	var o := BuildSystem.new()
	B.morto(u, estado, &"archer", B.FORA)
	var bosque := SimFactory.amargueiros()
	B.alvorada(bosque, 3, u, o)
	B.alvorada(bosque, 4, u, o)
	o.absorb(B.moedas_pousadas(estado, B.FORA, B.destino(&"fell").cost_coins))
	assert_bool(bosque.consecrate(0, o)).is_false()


# ─── O save (§84) ────────────────────────────────────────────────────────────


func test_o_save_guarda_as_arvores_o_lenho_e_a_serra_a_meio() -> void:
	var estado := GameState.new()
	var u := UnitSystem.new()
	var o := BuildSystem.new()
	var nomeado := B.morto(u, estado, &"archer", B.FORA)
	B.morto(u, estado, &"vagrant", B.FORA + 300.0)
	var bosque := SimFactory.amargueiros()
	bosque.at_dawn(3, u, o, B.NUCLEO, B.LARGURA, {nomeado: B.TITULO})
	B.alvorada(bosque, 4, u, o)
	o.absorb(B.moedas_pousadas(estado, B.FORA, B.destino(&"fell").cost_coins))
	bosque.consecrate(1, o)
	bosque.bitter_wood = 4
	var guardado := bosque.to_dict(o)
	for campo in [&"amargueiro_x", &"amargueiro_band", &"amargueiro_tier", &"amargueiro_day"]:
		assert_bool(guardado.has(campo)).is_true()

	var outras := BuildSystem.new()
	var lido := SimFactory.amargueiros()
	lido.from_dict(guardado, outras)
	assert_array(Array(lido.xs)).is_equal(Array(bosque.xs))
	assert_array(Array(lido.titles)).is_equal(Array(bosque.titles))
	assert_int(lido.bitter_wood).is_equal(4)
	assert_int(lido.named()).is_equal(bosque.named())
	assert_array(lido.consecrated()).is_equal(bosque.consecrated())
	assert_int(outras.count()).is_equal(1)  # a serra volta, e a meio
	assert_int(outras.slots[0].state).is_equal(BuildSlot.State.SCAFFOLD)
