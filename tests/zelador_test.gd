# tests/zelador_test.gd — o Zelador da §75: aparece com a Divida em 6, anda atras
# da mancha, nao ataca, e se chegar ao nucleo leva uma tropa nomeada.
#
# A velocidade e a do tender em creatures.csv; o limiar e o de rot.csv.
extends GdUnitTestSuite

const B := preload("res://tests/support/bosque.gd")

const RAIO := 240.0


func _zelador() -> Tender:
	return SimFactory.tender()


func test_anda_para_o_nucleo_mas_nunca_a_frente_da_mancha() -> void:
	var z := _zelador()
	z.dusk(B.LARGURA)
	var mancha := B.LARGURA - 10.0
	for _t in 300:
		z.tick(B.PASSO, mancha, B.NUCLEO, RAIO, BuildSystem.new())
	assert_float(z.x).is_equal(mancha)  # atras dela, e nao a frente


func test_um_muro_de_pe_para_o_zelador() -> void:
	var z := _zelador()
	var obras := BuildSystem.new()
	B.muro(obras, B.MURO)
	z.dusk(B.FORA)
	for _t in 3000:
		z.tick(B.PASSO, B.NUCLEO, B.NUCLEO, RAIO, obras)
	assert_float(z.x).is_greater(B.MURO)  # fica a olhar para o nucleo


func test_chega_ao_nucleo_e_leva_uma_tropa_nomeada_e_so_uma() -> void:
	var estado := GameState.new()
	var u := UnitSystem.new()
	var tropas := SimFactory.by_id(&"units")
	var a := u.spawn(estado, tropas[&"archer"], B.MEU_IMPERIO, B.NUCLEO)
	var b := u.spawn(estado, tropas[&"archer"], B.MEU_IMPERIO, B.NUCLEO)
	var titulos := {a: B.TITULO, b: "TITLE_SECOND"}
	var z := _zelador()
	z.dusk(B.NUCLEO + RAIO + 50.0)
	var chegou := false
	for _t in 600:
		chegou = z.tick(B.PASSO, B.NUCLEO, B.NUCLEO, RAIO, BuildSystem.new()) or chegou
	assert_bool(chegou).is_true()
	var levada := z.take(u, titulos, tropas)
	assert_int(levada).is_equal(a)  # a de id mais baixo (§42)
	assert_int(u.index_of(a)).is_equal(UnitSystem.NENHUM)
	assert_bool(titulos.has(a)).is_false()
	assert_int(z.take(u, titulos, tropas)).is_equal(UnitSystem.NENHUM)  # uma por noite
	assert_int(u.index_of(b)).is_not_equal(UnitSystem.NENHUM)


func test_sem_nomeados_chega_e_nao_leva_ninguem() -> void:
	var z := _zelador()
	z.dusk(B.NUCLEO)
	var u := UnitSystem.new()
	assert_int(z.take(u, {}, SimFactory.by_id(&"units"))).is_equal(UnitSystem.NENHUM)


func test_ao_amanhecer_vai_com_ela_e_o_save_guarda_onde_estava() -> void:
	var z := _zelador()
	z.dusk(B.FORA)
	var lido := _zelador()
	lido.from_dict(z.to_dict())
	assert_bool(lido.active).is_true()
	assert_float(lido.x).is_equal(B.FORA)
	z.dawn()
	assert_bool(z.active).is_false()
