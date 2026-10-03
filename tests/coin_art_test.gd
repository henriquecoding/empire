# tests/coin_art_test.gd — a moeda que se ve (o dono, 02/10/2026).
#
# "As moedas e itens que sao dropados devem ser bem grandes para serem bem vistos
# como e em Kingdom." Mede-se o tamanho contra as tropas, e que uma quantia se le
# pela forma: uma moeda, uma pilha, um saco.
extends GdUnitTestSuite


func test_uma_moeda_se_ve_ao_lado_de_uma_tropa() -> void:
	var tropa: float = OriginalArt.new().box(&"vagrant", Vector2.ZERO).size.y
	var moeda := CoinArt.size_of(1)
	assert_float(moeda.y).is_greater(tropa / 2.0)
	assert_float(moeda.y).is_less(tropa)
	assert_float(moeda.x).is_greater(WorldPalette.MOEDA_R * 2.0 * 2.0)


## O dono, a 03/10/2026 (Q-192): "quero que o tamanho seja o dobro do atual". Era de 18 px.
func test_a_moeda_tem_o_dobro_do_tamanho() -> void:
	assert_float(CoinArt.size_of(1).x).is_equal(36.0)
	assert_float(CoinArt.CHAO).is_equal(CoinArt.PIXEL * 2.0)


func test_a_quantia_le_se_pela_forma() -> void:
	var uma := CoinArt.size_of(1)
	var pilha := CoinArt.size_of(4)
	var mais := CoinArt.size_of(6)
	var saco := CoinArt.size_of(CoinArt.SACO_DE)
	assert_bool(uma == CoinArt.size_of(2)).is_false()  # uma de pe, duas deitadas
	assert_float(mais.y).is_greater(pilha.y)  # a pilha cresce
	assert_float(CoinArt.size_of(CoinArt.SACO_DE - 1).y).is_less(saco.y)  # o saco e maior
	assert_float(saco.x).is_greater(uma.x)


func test_os_mapas_sao_rectangulos_e_so_usam_a_paleta() -> void:
	for mapa: Array in [CoinArt.FACE, CoinArt.DEITADA, CoinArt.SACO]:
		var largo := String(mapa[0]).length()
		for linha: String in mapa:
			assert_int(linha.length()).is_equal(largo)
			for letra in linha:
				assert_bool(CoinArt.PALETA.has(letra) or letra == " ").is_true()


func test_brilha_de_vez_em_quando_e_nao_todas_ao_mesmo_tempo() -> void:
	var acesas := 0
	for passo in 260:
		if CoinArt.glint(7, float(passo) * 0.01) > 0.0:
			acesas += 1
	assert_int(acesas).is_greater(0)
	assert_int(acesas).is_less(130)
	var juntas := 0
	for passo in 260:
		var t := float(passo) * 0.01
		if CoinArt.glint(7, t) > 0.0 and CoinArt.glint(8, t) > 0.0:
			juntas += 1
	assert_int(juntas).is_less(acesas)


func test_o_ouro_nunca_se_apaga_de_todo() -> void:
	var luz := Lighting.new()
	luz.set_phase(Registry.entry(&"economy", &"clock") as ClockData, GameClock.Phase.NIGHT, 0.5)
	var cor: Color = CoinArt.lit(luz, 0.0).call(CoinArt.PALETA["o"])
	assert_float(cor.get_luminance()).is_greater(luz.body(CoinArt.PALETA["o"], 0.0).get_luminance())


func test_a_coroa_e_maior_que_uma_moeda_e_so_usa_a_paleta() -> void:
	var largo := String(CrownView.COROA[0]).length()
	assert_float(float(largo) * CoinArt.CHAO).is_greater(CoinArt.size_of(1).x)
	for linha: String in CrownView.COROA:
		assert_int(linha.length()).is_equal(largo)
		for letra in linha:
			assert_bool(CoinArt.PALETA.has(letra) or letra in [" ", "r"]).is_true()


func test_a_coroa_cai_da_cabeca_do_rei_ate_ao_chao() -> void:
	var g := SimFactory.curve().coin_gravity_px_s2
	assert_float(CrownView.fall(0.0, g)).is_equal(CrownView.QUEDA)
	assert_float(CrownView.fall(0.1, g)).is_less(CrownView.QUEDA)
	assert_float(CrownView.fall(2.0, g)).is_equal(0.0)
