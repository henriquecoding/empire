# tests/jogo_test.gd — a partida inteira pelo SimLoop, com o mundo montado.
#
# Os outros testes provam um sistema de cada vez. Este prova o que nenhum deles
# prova: que os onze passos do §43, postos uns a seguir aos outros com um mundo
# a volta, dao um JOGO — largar uma moeda recruta, largar numa obra constroi-a,
# o crepusculo traz a mancha, a noite traz criaturas, e o amanhecer leva-as.
#
# Corre em headless, ao passo fixo, como o §31 pede ("corre em headless com
# delta fixo"). Nao abre janela e nao le uma tecla: o que o jogador faz entra
# pela fila de intencoes do §61, que e exactamente o que o router de input
# escreve.
extends GdUnitTestSuite

const SEMENTE := 20260915
const PASSO := 1.0 / 30.0
## §63: a simulacao inteira, tick completo.
const ORCAMENTO_TICK_US := 4000


func _relogio() -> ClockData:
	return Registry.entry(&"economy", &"clock") as ClockData


func _correr(segundos: float) -> void:
	for _i in int(segundos / PASSO):
		SimLoop.step(PASSO)


func _ate_a_fase(fase: GameClock.Phase) -> void:
	var limite := int(_relogio().day_seconds / PASSO) * 2
	for _i in limite:
		SimLoop.step(PASSO)
		if ClockService.clock.current_phase() == fase:
			return
	fail("o relogio nunca chegou a fase %d" % int(fase))


func _obra(tipo: StringName) -> BuildSlot:
	for vaga in SimLoop.builds.slots:
		if vaga.kind == tipo:
			return vaga
	return null


func _vagabundo() -> int:
	for i in SimLoop.units.count():
		if SimLoop.units.owners[i] == RecruitSystem.SEM_DONO:
			return i
	return UnitSystem.NENHUM


func _por_recrutar(tipo: StringName) -> int:
	for i in SimLoop.units.count():
		if SimLoop.units.owners[i] == RecruitSystem.SEM_DONO and SimLoop.units.data_ids[i] == tipo:
			return SimLoop.units.ids[i]
	return UnitSystem.NENHUM


## Um x da regiao onde nao ha obra nenhuma a apanhar moedas do chao (§55) nem
## mais ninguem por recrutar a disputa-las.
func _longe_de_tudo() -> float:
	var x := SimLoop.world_width
	for vaga in SimLoop.builds.slots:
		x = minf(x, vaga.x)
	return maxf(0.0, x * 0.5)


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(SEMENTE)
	Greybox.build()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


# ─── O mundo ─────────────────────────────────────────────────────────────────


func test_o_mundo_monta_se_com_rei_sitios_de_obra_e_vagabundos() -> void:
	assert_int(SimLoop.king_id).is_not_equal(UnitSystem.NENHUM)
	assert_int(SimLoop.builds.count()).is_greater(0)
	assert_int(_vagabundo()).is_not_equal(UnitSystem.NENHUM)
	assert_float(SimLoop.world_width).is_greater(0.0)
	assert_array(SimLoop.passages).is_not_empty()
	assert_object(_obra(&"core")).is_not_null()


func test_o_rei_comeca_com_as_moedas_do_06() -> void:
	var i := SimLoop.units.index_of(SimLoop.king_id)
	var curva := Registry.entry(&"economy", &"curve") as EconomyCurve
	assert_int(SimLoop.units.carried_coins[i]).is_equal(curva.start_coins)


# ─── O Verbo 1, do principio ao fim ──────────────────────────────────────────


func test_largar_tira_do_saco_e_nao_cria_moeda_do_nada() -> void:
	var i := SimLoop.units.index_of(SimLoop.king_id)
	var antes := SimLoop.units.carried_coins[i]
	SimLoop.units.carried_coins[i] = 1

	for _k in 3:
		SimLoop.intents.queue(
			IntentQueue.Kind.DROP_COIN,
			{&"x": 0.0, &"band": Band.Kind.SURFACE, &"amount": 1, &"source": &"player"}
		)
	SimLoop.step(PASSO)

	assert_int(antes).is_greater(1)
	assert_int(SimLoop.units.carried_coins[i]).is_equal(0)
	assert_int(SimLoop.coins.count()).is_equal(1)


func test_uma_moeda_ao_lado_de_um_vagabundo_recruta_o() -> void:
	# O minuto 0:20 do §25, agora com o mundo montado a volta. Longe das obras:
	# uma moeda que cai em cima de um canteiro paga o canteiro (§55), e isso e o
	# que o teste de baixo prova — aqui interessa o vagabundo.
	var v := _vagabundo()
	var quem := SimLoop.units.ids[v]
	SimLoop.units.xs[v] = _longe_de_tudo()
	SimLoop.drop_coin(SimLoop.units.xs[v] + 20.0, Band.Kind.SURFACE, 1, &"player")

	_correr(6.0)

	assert_int(SimLoop.units.owners[SimLoop.units.index_of(quem)]).is_not_equal(
		RecruitSystem.SEM_DONO
	)


func test_um_arqueiro_custa_tres_moedas_e_nao_uma() -> void:
	# §07 da um preco a cada tropa e o §25 poe "um vagabundo COM ARCO" no minuto
	# 1:10. O saco dele tem de chegar ao preco: uma moeda apanha-se e nao
	# compra nada — o que acontece no Kingdom e o que o §25 desenha.
	var quem := _por_recrutar(&"archer")
	var i := SimLoop.units.index_of(quem)
	SimLoop.units.xs[i] = _longe_de_tudo()
	var preco := SimLoop.units.recruit_costs[i]
	assert_int(preco).is_greater(1)

	SimLoop.drop_coin(SimLoop.units.xs[i] + 20.0, Band.Kind.SURFACE, 1, &"player")
	_correr(6.0)
	assert_int(SimLoop.units.owners[SimLoop.units.index_of(quem)]).is_equal(RecruitSystem.SEM_DONO)

	for _k in preco - 1:
		SimLoop.drop_coin(
			SimLoop.units.xs[SimLoop.units.index_of(quem)], Band.Kind.SURFACE, 1, &"p"
		)
		_correr(4.0)

	assert_int(SimLoop.units.owners[SimLoop.units.index_of(quem)]).is_not_equal(
		RecruitSystem.SEM_DONO
	)


func test_o_rei_apanha_o_que_pisa() -> void:
	# A moeda faz um arco e deriva ate 20 px antes de pousar (§61, Q-061), e o
	# raio de apanha sao 12 (curve.tres): quem a larga tem mesmo de ir la. E o
	# que o §02 quer do Verbo 1 — a moeda e um objeto, nao um contador.
	var i := SimLoop.units.index_of(SimLoop.king_id)
	SimLoop.units.carried_coins[i] = 0
	SimLoop.drop_coin(SimLoop.units.xs[i], Band.Kind.SURFACE, 1, &"player")
	_correr(1.0)  # deixa pousar

	SimLoop.units.xs[i] = SimLoop.coins.xs[0]
	_correr(1.0)

	assert_int(SimLoop.units.carried_coins[i]).is_equal(1)


# ─── O Verbo 1 a construir (§55) ─────────────────────────────────────────────


func test_moedas_num_sitio_de_obra_pagam_na_e_alguem_a_levanta() -> void:
	var canteiro := _obra(&"farm")
	var rei := SimLoop.units.index_of(SimLoop.king_id)
	SimLoop.units.xs[rei] = canteiro.x  # o construtor tem de estar la (§55)
	for _k in canteiro.next_cost():
		SimLoop.drop_coin(canteiro.x, canteiro.band, 1, &"player")

	# Pago o custo, a obra levanta andaime; com o rei em cima dela ja passou a
	# BUILDING no mesmo par de segundos, porque o progresso e presenca (§55).
	_correr(2.0)
	assert_int(canteiro.paid).is_equal(0)
	assert_int(canteiro.state).is_equal(BuildSlot.State.BUILDING)
	assert_float(canteiro.progress).is_greater(0.0)

	_correr(canteiro.works[0] + 1.0)

	assert_int(canteiro.level).is_equal(1)
	assert_bool(canteiro.standing()).is_true()


func test_a_obra_de_pe_produz_e_a_moeda_cai_em_cima_dela() -> void:
	var canteiro := _obra(&"farm")
	canteiro.level = 1
	canteiro.state = BuildSlot.State.DONE
	canteiro.health = canteiro.max_health()
	canteiro.stock = 0.0
	var caidas: Array[float] = []
	var ouvinte := func(x: float, _b: int, _q: int, origem: StringName) -> void:
		if origem == EventRelay.FONTE_PRODUCAO:
			caidas.append(x)
	EventBus.coin_dropped.connect(ouvinte)

	_ate_a_fase(GameClock.Phase.NOON)
	_ate_a_fase(GameClock.Phase.AFTERNOON)
	_ate_a_fase(GameClock.Phase.DUSK)

	EventBus.coin_dropped.disconnect(ouvinte)
	assert_array(caidas).is_not_empty()
	assert_float(caidas[0]).is_equal(canteiro.x)


# ─── O Verbo 2 (§11) ─────────────────────────────────────────────────────────


func test_o_verbo_2_muda_de_faixa_numa_passagem() -> void:
	var i := SimLoop.units.index_of(SimLoop.king_id)
	SimLoop.units.xs[i] = SimLoop.passages[0]
	var antes := SimLoop.units.bands[i]

	SimLoop.intents.queue(IntentQueue.Kind.ASSUME)
	SimLoop.step(PASSO)

	assert_int(SimLoop.units.bands[i]).is_not_equal(antes)


func test_longe_de_uma_passagem_o_verbo_2_nao_faz_nada() -> void:
	var i := SimLoop.units.index_of(SimLoop.king_id)
	SimLoop.units.xs[i] = SimLoop.passages[0] + SimFactory.PASSAGEM_PX * 4.0
	var antes := SimLoop.units.bands[i]

	SimLoop.intents.queue(IntentQueue.Kind.ASSUME)
	SimLoop.step(PASSO)

	assert_int(SimLoop.units.bands[i]).is_equal(antes)
