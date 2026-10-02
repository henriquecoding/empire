# tests/coin_bounce_test.gd — a fisica que se ve da moeda (§24; GB-19; o dono, 02/10).
#
# "Moeda largada — arco parabolico, som com pitch variavel, pequeno bounce e
# sombra. E a animacao mais importante do jogo." O arco e da simulacao, porque
# decide ONDE a moeda pousa (§55). Isto e so o que se ve por cima dele: sai da mao,
# gira, ressalta cada vez menos, balanca ate assentar, e sobe quando e levada — e
# nunca sai do x onde a simulacao a pos.
extends GdUnitTestSuite

const G := 700.0


func test_uma_moeda_que_pousa_ressalta_e_para() -> void:
	var b := CoinBounce.new(G)
	b.observe(1, 10.0, 0.0)
	b.observe(1, 0.0, 1.0)
	var meio := b.duration() * 0.5
	assert_float(b.offset(1, 1.0 + meio)).is_equal_approx(CoinBounce.ALTO, 0.01)
	assert_float(b.offset(1, 1.0 + b.settle_time() + 0.01)).is_equal(0.0)


func test_cada_salto_e_mais_baixo_do_que_o_anterior() -> void:
	var saltos := CoinBounce.hops()
	assert_int(saltos.size()).is_greater(1)
	for i in range(1, saltos.size()):
		assert_float(saltos[i]).is_less(saltos[i - 1])
	assert_float(saltos[saltos.size() - 1]).is_greater_equal(CoinBounce.MINIMO)


## Uma moeda que ja estava no chao quando se comecou a olhar — um save, a
## abertura — nao salta nem gira: nao caiu agora.
func test_quem_ja_estava_pousada_nao_salta() -> void:
	var b := CoinBounce.new(G)
	b.observe(2, 0.0, 0.0)
	assert_float(b.offset(2, 0.05)).is_equal(0.0)
	assert_float(b.face(2, 0.05)).is_equal(1.0)


## Os tempos nao sao numeros novos: cada salto dura o voo da altura dele na
## gravidade que a economy.csv ja da ao arco (2·√(2h/g)).
func test_a_duracao_sai_da_gravidade_do_arco() -> void:
	var curva := Registry.entry(&"economy", &"curve") as EconomyCurve
	var b := CoinBounce.new(curva.coin_gravity_px_s2)
	var esperado := 2.0 * sqrt(2.0 * CoinBounce.ALTO / curva.coin_gravity_px_s2)
	assert_float(b.duration()).is_equal_approx(esperado, 0.0001)


## Pequeno: menos de um quarto da queda que se ve (o arco mais a mao). Um salto do
## tamanho da queda era uma moeda a cair duas vezes.
func test_o_salto_e_pequeno_ao_lado_da_queda() -> void:
	var curva := Registry.entry(&"economy", &"curve") as EconomyCurve
	var apice := pow(curva.coin_drop_speed_px_s, 2) / (2.0 * curva.coin_gravity_px_s2)
	assert_float(CoinBounce.ALTO).is_less((apice + CoinBounce.MAO) / 4.0)


## Sai da mao e chega ao chao: a altura da mao vai de inteira, ao largar, a nada,
## ao pousar.
func test_a_moeda_sai_da_mao_e_desce_ate_ao_arco() -> void:
	assert_float(CoinBounce.hand(180.0, 180.0)).is_equal(1.0)
	assert_float(CoinBounce.hand(0.0, 180.0)).is_equal_approx(0.5, 0.0001)
	assert_float(CoinBounce.hand(-180.0, 180.0)).is_equal(0.0)


## Gira no ar (de lado e de frente), e assenta de frente depois de balancar.
func test_gira_no_ar_e_assenta_de_frente() -> void:
	var b := CoinBounce.new(G)
	b.observe(4, 10.0, 0.0)
	var larguras := PackedFloat32Array()
	for passo in 20:
		larguras.append(b.face(4, float(passo) * 0.02))
	assert_float(Array(larguras).min()).is_less(0.5)
	b.observe(4, 0.0, 1.0)
	assert_float(b.face(4, 1.0 + CoinBounce.ASSENTA + 0.01)).is_equal(1.0)


func test_esquece_as_moedas_que_ja_nao_estao_e_leva_as_a_subir() -> void:
	var b := CoinBounce.new(G)
	b.observe(3, 10.0, 0.0, Vector2(50.0, 517.0))
	b.observe(3, 0.0, 1.0, Vector2(50.0, 517.0))
	b.forget_except(PackedInt32Array(), 2.0)
	assert_int(b.tracked()).is_equal(0)
	var levadas := b.taken(2.1)
	assert_int(levadas.size()).is_equal(1)
	assert_vector(levadas[0][0] as Vector2).is_equal(Vector2(50.0, 517.0))
	b.forget_except(PackedInt32Array(), 2.0 + CoinBounce.LEVADA.dura + 0.01)
	assert_int(b.taken(2.5).size()).is_equal(0)
