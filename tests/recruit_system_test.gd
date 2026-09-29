# tests/recruit_system_test.gd — as pecas do F1-04, uma a uma.
#
# O sistema puro, sem motor e sem ciclo: quem e de ninguem, quanto custa comprar
# alguem, que moeda e que se ve daqui, e a forma da fila atras do rei. A
# sequencia do §25 inteira, pelo SimLoop, e o tests/minuto_0_20_test.gd — estes
# estao aqui para dizer QUAL peca partiu quando ele chumbar.
extends GdUnitTestSuite

const SEMENTE := 20260915
const PASSO := 1.0 / 30.0
## §63, e e o unico orcamento que o dossie da que sirva aqui: a simulacao
## inteira, tick completo. Este passo nao tem linha propria porque nem existe no
## §43, e inventar-lhe um numero era inventar.
const ORCAMENTO_TICK_US := 4000
const TROPAS := 300
const MOEDAS := 60
## O imperio do jogador. Um id qualquer que nao seja o SEM_DONO serve — o que se
## testa e que ele muda de dono, nao qual e o numero.
const MEU_IMPERIO := 7


func _curva() -> EconomyCurve:
	return Registry.entry(&"economy", &"curve") as EconomyCurve


func _vagabundo() -> UnitData:
	return Registry.entry(&"units", &"vagrant")


func _monarca() -> UnitData:
	return Registry.entry(&"units", &"monarch")


func _correr(segundos: float) -> void:
	for _i in int(segundos / PASSO):
		SimLoop.step(PASSO)


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


# ─── As pecas ────────────────────────────────────────────────────────────────


func test_um_vagabundo_nasce_de_ninguem() -> void:
	var sistema := UnitSystem.new()
	var estado := GameState.new()
	var recrutas := RecruitSystem.new(_curva())

	sistema.spawn(estado, _vagabundo(), RecruitSystem.SEM_DONO, 0.0)

	assert_bool(recrutas.vagrant(sistema, 0)).is_true()


func test_uma_moeda_paga_o_preco_do_tres_e_nao_um_numero_do_codigo() -> void:
	# §07: cada tropa tem um custo, e o do vagabundo e 1. Se algum dia mudar no
	# CSV, este teste passa a exigir o novo — que e o ponto do G4.
	var sistema := UnitSystem.new()
	var estado := GameState.new()
	var recrutas := RecruitSystem.new(_curva())
	var dados := _vagabundo()
	var quem := sistema.spawn(estado, dados, RecruitSystem.SEM_DONO, 0.0)

	var barato := recrutas.hire(
		sistema, quem, MEU_IMPERIO, dados.recruit_cost - 1, dados.recruit_cost
	)
	var certo := recrutas.hire(sistema, quem, MEU_IMPERIO, dados.recruit_cost, dados.recruit_cost)

	(
		assert_bool(barato)
		. override_failure_message("pagar menos do que o preco comprou alguem")
		. is_false()
	)
	assert_bool(certo).is_true()
	assert_int(sistema.owners[0]).is_equal(MEU_IMPERIO)


func test_quem_ja_e_de_alguem_nao_se_compra_outra_vez() -> void:
	var sistema := UnitSystem.new()
	var estado := GameState.new()
	var recrutas := RecruitSystem.new(_curva())
	var quem := sistema.spawn(estado, _vagabundo(), MEU_IMPERIO, 0.0)

	assert_bool(recrutas.hire(sistema, quem, MEU_IMPERIO + 1, 99, 1)).is_false()
	assert_int(sistema.owners[0]).is_equal(MEU_IMPERIO)


func test_a_moeda_longe_de_mais_nao_e_um_destino() -> void:
	var sistema := UnitSystem.new()
	var moedas := CoinSystem.new(_curva())
	var estado := GameState.new()
	var recrutas := RecruitSystem.new(_curva())
	var curva := _curva()
	sistema.spawn(estado, _vagabundo(), RecruitSystem.SEM_DONO, 0.0)
	# Uma para la do raio de reparo, e mais nenhuma.
	var longe := moedas.drop(estado, curva.recruit_notice_px + 1.0, Band.Kind.SURFACE, 1, 0.0)
	moedas.settled[moedas.index_of(longe)] = 1

	recrutas.seek_coins(sistema, moedas, sistema.ids[0])

	(
		assert_int(sistema.has_targets[0])
		. override_failure_message(
			"poe-se a caminho de uma moeda que o jogador largou para outra pessoa"
		)
		. is_equal(0)
	)


func test_a_fila_atras_do_rei_e_por_id_e_nao_por_indice() -> void:
	# §50: "posicoes estaveis... atribuidas, nao emergentes". A ordem das colunas
	# nao e estavel (o remove() troca com a ultima), e por isso a fila tem de sair
	# do id. Sem isto, uma morte faz toda a gente mudar de lugar sem se mexer.
	# Quem anda atras do rei e quem tem `follows_king` — o escudeiro (Q-063).
	var sistema := UnitSystem.new()
	var estado := GameState.new()
	var recrutas := RulesFactory.recruits(estado)
	var curva := _curva()
	var escudeiro := Registry.entry(&"units", &"squire") as UnitData
	var rei := sistema.spawn(estado, _monarca(), MEU_IMPERIO, 0.0)
	var primeiro := sistema.spawn(estado, escudeiro, MEU_IMPERIO, -10.0)
	var segundo := sistema.spawn(estado, escudeiro, MEU_IMPERIO, -20.0)
	var terceiro := sistema.spawn(estado, escudeiro, MEU_IMPERIO, -30.0)

	sistema.remove(segundo)  # troca o terceiro para o lugar do segundo
	recrutas.follow(sistema, rei, 500.0)

	# Restam o primeiro e o terceiro, e e o ID que decide quem fica mais perto.
	assert_float(sistema.target_xs[sistema.index_of(primeiro)]).is_equal(-curva.follow_distance_px)
	assert_float(sistema.target_xs[sistema.index_of(terceiro)]).is_equal(
		-(curva.follow_distance_px + curva.follow_spacing_px)
	)


func test_quem_tem_posto_deixa_de_seguir_o_rei() -> void:
	# A condicao que o F1-05 vai usar sem tocar neste ficheiro.
	var sistema := UnitSystem.new()
	var estado := GameState.new()
	var recrutas := RecruitSystem.new(_curva())
	var rei := sistema.spawn(estado, _monarca(), MEU_IMPERIO, 0.0)
	var quem := sistema.spawn(estado, _vagabundo(), MEU_IMPERIO, 500.0)
	sistema.job_ids[sistema.index_of(quem)] = 1

	recrutas.follow(sistema, rei, 0.0)

	assert_int(sistema.has_targets[sistema.index_of(quem)]).is_equal(0)


func test_sem_rei_em_campo_ninguem_segue_ninguem() -> void:
	var sistema := UnitSystem.new()
	var estado := GameState.new()
	var recrutas := RecruitSystem.new(_curva())
	sistema.spawn(estado, _vagabundo(), MEU_IMPERIO, 500.0)

	recrutas.follow(sistema, UnitSystem.NENHUM, 0.0)

	assert_int(sistema.has_targets[0]).is_equal(0)


func test_o_recrutado_vai_para_o_nucleo_e_espera_la() -> void:
	# Q-063: como no Kingdom: New Lands, quem e teu e nao tem trabalho nao anda
	# atras do rei — vai para a vila e espera la, a volta do centro, um de cada
	# lado ao passo da fila, por id.
	var sistema := UnitSystem.new()
	var estado := GameState.new()
	var recrutas := RulesFactory.recruits(estado)
	var passo := _curva().follow_spacing_px
	var nucleo := 1000.0
	var rei := sistema.spawn(estado, _monarca(), MEU_IMPERIO, 300.0)
	var um := sistema.spawn(estado, _vagabundo(), MEU_IMPERIO, 250.0)
	var outro := sistema.spawn(estado, _vagabundo(), MEU_IMPERIO, 260.0)
	var terceiro := sistema.spawn(estado, _vagabundo(), MEU_IMPERIO, 270.0)

	recrutas.follow(sistema, rei, nucleo)

	assert_float(sistema.target_xs[sistema.index_of(um)]).is_equal(nucleo)
	assert_float(sistema.target_xs[sistema.index_of(outro)]).is_equal(nucleo + passo)
	assert_float(sistema.target_xs[sistema.index_of(terceiro)]).is_equal(nucleo - passo)


# ─── O preco do povo da regiao (§04, Q-007) ─────────────────────────────────


func test_a_horta_paga_menos_uma_moeda_por_tropa_e_nunca_menos_de_uma() -> void:
	# Q-007, aprovada pelo dono: "tropas baratissimas" (§04) e -1 moeda no
	# recrutamento de todas as tropas da Horta, com o minimo de 1. Quem ja nao
	# custava nada (o monarca) continua a nao custar.
	assert_int(RecruitSystem.discounted(3, -1)).is_equal(2)
	assert_int(RecruitSystem.discounted(1, -1)).is_equal(1)
	assert_int(RecruitSystem.discounted(0, -1)).is_equal(0)
	assert_int(RecruitSystem.discounted(3, 0)).is_equal(3)


func test_o_desconto_e_o_da_regiao_em_que_se_esta() -> void:
	var sistema := UnitSystem.new()
	var estado := GameState.new()
	var recrutas := RecruitSystem.new(_curva())
	recrutas.state = estado
	recrutas.cost_deltas = PackedInt32Array([0, -1])
	var arqueiro := Registry.entry(&"units", &"archer") as UnitData
	sistema.spawn(estado, arqueiro, RecruitSystem.SEM_DONO, 0.0)

	assert_int(recrutas.price(sistema, 0)).is_equal(arqueiro.recruit_cost)
	estado.region = 1
	assert_int(recrutas.price(sistema, 0)).is_equal(arqueiro.recruit_cost - 1)


func test_so_a_horta_tem_desconto_no_recrutamento() -> void:
	var povos := SimFactory.campaign_peoples()
	var descontos := RulesFactory.recruit_deltas()
	assert_int(descontos.size()).is_equal(povos.size())
	for r in povos.size():
		var esperado := -1 if povos[r] == "horta" else 0
		assert_int(descontos[r]).override_failure_message(povos[r]).is_equal(esperado)
