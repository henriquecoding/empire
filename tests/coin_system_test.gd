# tests/coin_system_test.gd — o Verbo 1: largar, arco, queda, apanhar, saco.
#
# "A moeda fisica e o Verbo 1. Tudo o que o jogador faz passa por ela" (F1-01).
# O que se prova aqui e que ela e mesmo fisica — que sai, sobe, cai e fica — e
# que a apanha e por distancia, com a capacidade do saco a vir de units.csv.
extends GdUnitTestSuite

const PASSO := 1.0 / 30.0
const MOEDAS := 10
const ORCAMENTO_US := 1000


func _curva() -> EconomyCurve:
	return Registry.entry(&"economy", &"curve")


func _sistema() -> CoinSystem:
	return CoinSystem.new(_curva())


func _estado() -> GameState:
	var e := GameState.new()
	e.seed = 20260915
	return e


## Corre ate tudo assentar, e devolve quantos ticks foram precisos.
func _assentar(sistema: CoinSystem) -> int:
	var ticks := 0
	while sistema.in_flight() > 0 and ticks < 300:
		sistema.tick(PASSO)
		ticks += 1
	return ticks


func test_a_moeda_sobe_antes_de_cair() -> void:
	# E o arco. Uma moeda que caia a direito nao e uma moeda largada, e uma
	# moeda pousada — e o §02 diz que ela e fisica.
	var sistema := _sistema()
	var coin_id := sistema.drop(_estado(), 100.0, Band.Kind.SURFACE, 1, 0.0)
	var i := sistema.index_of(coin_id)

	var maximo := 0.0
	for _t in 60:
		sistema.tick(PASSO)
		maximo = maxf(maximo, sistema.heights[i] if sistema.index_of(coin_id) != -1 else maximo)

	assert_bool(maximo > 0.0).override_failure_message("a moeda nunca subiu").is_true()


func test_o_arco_tem_a_altura_que_a_fisica_dos_dados_manda() -> void:
	# apice = v0^2 / (2g), que com 180 e 700 da 23,1 px. Se alguem mexer no CSV,
	# este teste muda com ele — le os dois numeros de la, nao os repete.
	var curva := _curva()
	var esperado := (
		curva.coin_drop_speed_px_s * curva.coin_drop_speed_px_s / (2.0 * curva.coin_gravity_px_s2)
	)

	var sistema := _sistema()
	var coin_id := sistema.drop(_estado(), 0.0, Band.Kind.SURFACE, 1, 0.0)
	var i := sistema.index_of(coin_id)
	var maximo := 0.0
	for _t in 60:
		sistema.tick(PASSO)
		maximo = maxf(maximo, sistema.heights[i])

	# A tolerancia nao e um numero a gosto: e o erro de discretizacao. Num passo
	# a velocidade muda em g*dt, e por isso o apice medido a 30 Hz afasta-se do
	# continuo em ate v0*dt. Escrito assim, muda sozinho se o tick_hz mudar.
	var erro := curva.coin_drop_speed_px_s * PASSO
	assert_float(maximo).is_between(esperado - erro, esperado + erro)


func test_a_moeda_assenta_e_fica() -> void:
	var sistema := _sistema()
	var coin_id := sistema.drop(_estado(), 50.0, Band.Kind.SURFACE, 1, 1.0)
	var i := sistema.index_of(coin_id)

	var ticks := _assentar(sistema)
	var onde := sistema.xs[i]

	assert_int(sistema.settled[i]).is_equal(1)
	assert_float(sistema.heights[i]).is_equal(0.0)
	assert_bool(ticks > 1).override_failure_message("assentou no mesmo tick").is_true()

	# E depois de assentar nao anda mais: uma moeda no chao fica onde caiu.
	for _t in 60:
		sistema.tick(PASSO)
	assert_float(sistema.xs[i]).is_equal(onde)


func test_o_desvio_espalha_as_moedas_para_os_dois_lados() -> void:
	var sistema := _sistema()
	var estado := _estado()
	var esquerda := sistema.drop(estado, 0.0, Band.Kind.SURFACE, 1, -1.0)
	var centro := sistema.drop(estado, 0.0, Band.Kind.SURFACE, 1, 0.0)
	var direita := sistema.drop(estado, 0.0, Band.Kind.SURFACE, 1, 1.0)
	_assentar(sistema)

	var x_esq := sistema.xs[sistema.index_of(esquerda)]
	var x_cen := sistema.xs[sistema.index_of(centro)]
	var x_dir := sistema.xs[sistema.index_of(direita)]

	assert_bool(x_esq < x_cen).is_true()
	assert_bool(x_dir > x_cen).is_true()
	# E espalham mais do que o raio de apanha, senao duas moedas largadas juntas
	# apanhavam-se como uma so.
	assert_bool(x_dir - x_esq > _curva().coin_pickup_px).is_true()


func test_a_apanha_e_por_distancia_e_respeita_o_raio() -> void:
	var sistema := _sistema()
	var estado := _estado()
	var raio := _curva().coin_pickup_px
	var perto := sistema.drop(estado, 100.0, Band.Kind.SURFACE, 1, 0.0)
	var longe := sistema.drop(estado, 100.0 + raio * 3.0, Band.Kind.SURFACE, 1, 0.0)
	_assentar(sistema)

	var apanhados := sistema.collect(100.0, Band.Kind.SURFACE, 99)

	assert_int(apanhados.size()).is_equal(1)
	assert_int(apanhados[0]).is_equal(perto)
	assert_int(sistema.index_of(longe)).is_not_equal(CoinSystem.NENHUM)


func test_nao_se_apanha_uma_moeda_no_ar() -> void:
	# Senao o jogador apanhava a sua propria moeda no instante em que a larga, e
	# o Verbo 1 deixava de fazer sentido.
	var sistema := _sistema()
	sistema.drop(_estado(), 0.0, Band.Kind.SURFACE, 1, 0.0)

	assert_int(sistema.collect(0.0, Band.Kind.SURFACE, 99).size()).is_equal(0)
	_assentar(sistema)
	assert_int(sistema.collect(0.0, Band.Kind.SURFACE, 99).size()).is_equal(1)


func test_nao_se_apanha_de_outra_faixa() -> void:
	var sistema := _sistema()
	sistema.drop(_estado(), 0.0, Band.Kind.UNDERGROUND, 1, 0.0)
	_assentar(sistema)

	assert_int(sistema.collect(0.0, Band.Kind.SURFACE, 99).size()).is_equal(0)
	assert_int(sistema.collect(0.0, Band.Kind.UNDERGROUND, 99).size()).is_equal(1)


func test_o_saco_do_vagabundo_vem_do_units_csv() -> void:
	# §58/F1-01: "a capacidade do saco vem de units.csv". O vagabundo leva 2.
	var vagabundo: UnitData = Registry.entry(&"units", &"vagrant")
	assert_int(vagabundo.coin_capacity).is_greater(0)

	var sistema := _sistema()
	var estado := _estado()
	for i in vagabundo.coin_capacity + 3:
		sistema.drop(estado, 0.0, Band.Kind.SURFACE, 1, 0.0)
	_assentar(sistema)

	var apanhadas := sistema.collect(0.0, Band.Kind.SURFACE, vagabundo.coin_capacity)
	assert_int(apanhadas.size()).is_equal(vagabundo.coin_capacity)
	# As que sobraram ficam no chao para outra pessoa.
	assert_int(sistema.count()).is_equal(3)


func test_um_saco_cheio_nao_apanha_nada() -> void:
	var sistema := _sistema()
	sistema.drop(_estado(), 0.0, Band.Kind.SURFACE, 1, 0.0)
	_assentar(sistema)

	assert_int(sistema.collect(0.0, Band.Kind.SURFACE, 0).size()).is_equal(0)
	assert_int(sistema.count()).is_equal(1)


func test_uma_pilha_que_nao_cabe_no_saco_nao_se_parte() -> void:
	# Uma moeda de valor 5 num saco com espaco para 2 fica onde esta: partir a
	# pilha seria inventar uma mecanica que o dossie nao tem.
	var sistema := _sistema()
	sistema.drop(_estado(), 0.0, Band.Kind.SURFACE, 5, 0.0)
	_assentar(sistema)

	assert_int(sistema.collect(0.0, Band.Kind.SURFACE, 2).size()).is_equal(0)
	assert_int(sistema.collect(0.0, Band.Kind.SURFACE, 5).size()).is_equal(1)


func test_o_save_das_moedas_so_leva_tipos_base() -> void:
	var sistema := _sistema()
	var estado := _estado()
	for _i in 4:
		sistema.drop(estado, 0.0, Band.Kind.SURFACE, 1, 0.0)

	for chave in sistema.to_dict():
		var valor: Variant = sistema.to_dict()[chave]
		var porque := "%s e Object" % chave
		assert_int(typeof(valor)).override_failure_message(porque).is_not_equal(TYPE_OBJECT)


func test_largar_dez_moedas_nao_custa_nada() -> void:
	# O "Feito" do ticket: "largar 10 moedas a 60 fps sem picos".
	var sistema := _sistema()
	var estado := _estado()
	for i in MOEDAS:
		sistema.drop(estado, float(i), Band.Kind.SURFACE, 1, 0.0)

	var voltas := 60
	var t0 := Time.get_ticks_usec()
	for _t in voltas:
		sistema.tick(PASSO)
	var us := float(Time.get_ticks_usec() - t0) / float(voltas)

	prints(
		"F1-01: %d moedas no ar custam %.1f us por tick (orcamento %d)" % [MOEDAS, us, ORCAMENTO_US]
	)
	var porque := "%.1f us contra o orcamento de %d" % [us, ORCAMENTO_US]
	assert_bool(us < ORCAMENTO_US).override_failure_message(porque).is_true()


func test_tirar_do_chao_so_leva_o_que_pousou_perto_e_na_faixa() -> void:
	# O pagamento de quem nao e obra (§74): o Amargueiro cobra-se assim.
	var sistema := _sistema()
	var e := _estado()
	sistema.drop(e, 100.0, Band.Kind.SURFACE, 2, 0.0)
	sistema.drop(e, 100.0, Band.Kind.UNDERGROUND, 1, 0.0)
	sistema.drop(e, 300.0, Band.Kind.SURFACE, 1, 0.0)
	assert_int(sistema.take_within(100.0, Band.Kind.SURFACE, 20.0)).is_equal(0)  # no ar
	_assentar(sistema)
	assert_int(sistema.take_within(100.0, Band.Kind.SURFACE, 20.0)).is_equal(2)
	assert_int(sistema.count()).is_equal(2)
