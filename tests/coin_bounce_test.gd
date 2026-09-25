# tests/coin_bounce_test.gd — o pequeno bounce da moeda (§24; GB-19).
#
# "Moeda largada — arco parabolico, som com pitch variavel, pequeno bounce e
# sombra. E a animacao mais importante do jogo." O arco e a sombra (GB-09)
# estavam feitos; o bounce ficou de fora porque a fisica da moeda decide ONDE
# ela pousa (§55). Este e so o que se ve: a moeda da um salto no sitio onde a
# simulacao a pousou, e nao sai dele.
extends GdUnitTestSuite

const G := 700.0


func test_uma_moeda_que_pousa_da_um_salto_e_para() -> void:
	var b := CoinBounce.new(G)
	b.observe(1, 10.0, 0.0)
	b.observe(1, 0.0, 1.0)
	var meio := b.duration() * 0.5
	assert_float(b.offset(1, 1.0 + meio)).is_equal_approx(CoinBounce.ALTO, 0.01)
	assert_float(b.offset(1, 1.0 + b.duration() + 0.01)).is_equal(0.0)


## Uma moeda que ja estava no chao quando se comecou a olhar — um save, a
## abertura — nao salta: nao caiu agora.
func test_quem_ja_estava_pousada_nao_salta() -> void:
	var b := CoinBounce.new(G)
	b.observe(2, 0.0, 0.0)
	assert_float(b.offset(2, 0.05)).is_equal(0.0)


## A duracao nao e um numero novo: e o voo de um salto de ALTO px na gravidade
## que a economy.csv ja da ao arco (2·√(2h/g)).
func test_a_duracao_sai_da_gravidade_do_arco() -> void:
	var curva := Registry.entry(&"economy", &"curve") as EconomyCurve
	var b := CoinBounce.new(curva.coin_gravity_px_s2)
	var esperado := 2.0 * sqrt(2.0 * CoinBounce.ALTO / curva.coin_gravity_px_s2)
	assert_float(b.duration()).is_equal_approx(esperado, 0.0001)


## Pequeno: menos de um quarto do arco. Um salto do tamanho do arco era uma
## moeda a cair duas vezes.
func test_o_salto_e_pequeno_ao_lado_do_arco() -> void:
	var curva := Registry.entry(&"economy", &"curve") as EconomyCurve
	var apice := pow(curva.coin_drop_speed_px_s, 2) / (2.0 * curva.coin_gravity_px_s2)
	assert_float(CoinBounce.ALTO).is_less(apice / 4.0)


func test_esquece_as_moedas_que_ja_nao_estao() -> void:
	var b := CoinBounce.new(G)
	b.observe(3, 10.0, 0.0)
	b.observe(3, 0.0, 1.0)
	b.forget_except(PackedInt32Array())
	assert_int(b.tracked()).is_equal(0)
