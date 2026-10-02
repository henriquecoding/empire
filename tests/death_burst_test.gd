# tests/death_burst_test.gd — uma morte que se ve (§07: "nada desaparece
# silenciosamente").
#
# O sorteio e fixo (o meio de cada intervalo) para os pedacos serem sempre os
# mesmos: o que se prova e a forma da morte, e nao um sorteio.
extends GdUnitTestSuite

const CAIXA := Rect2(100.0, 470.0, 24.0, 30.0)


func _meio(de: float, ate: float) -> float:
	return (de + ate) * 0.5


func test_uma_morte_deixa_pedacos_e_depois_nada() -> void:
	var m := DeathBurst.new()
	m.burst(CAIXA, Silhouette.Form.BRUTO, Color.RED, 1.0, 0.0, _meio)
	var n := m.pieces().size()
	assert_int(n).is_between(DeathBurst.PEDACOS.min, DeathBurst.PEDACOS.max)
	var t := 0.0
	while t < DeathBurst.SEGURA_S + DeathBurst.VIDA_S + 0.1:
		t += 1.0 / 60.0
		m.step(1.0 / 60.0, t)
	assert_int(m.live()).is_equal(0)


## Os pedacos vao para o lado do golpe, saltam, e nunca atravessam o chao.
func test_os_pedacos_saltam_para_o_lado_do_golpe_e_ficam_no_chao() -> void:
	var m := DeathBurst.new()
	m.burst(CAIXA, Silhouette.Form.BRUTO, Color.RED, -1.0, 0.0, _meio)
	var t := 0.0
	for k in 30:
		t += 1.0 / 60.0
		m.step(1.0 / 60.0, t)
		for p in m.pieces():
			assert_float(p.p.y).is_less_equal(CAIXA.end.y)
	for p in m.pieces():
		assert_float(p.p.x).is_less(CAIXA.get_center().x)


## O corpo espalma-se com os pes onde estavam.
func test_o_corpo_espalma_se_contra_o_chao() -> void:
	var meio := DeathBurst.flatten(CAIXA, 0.5)
	assert_float(meio.end.y).is_equal(CAIXA.end.y)
	assert_float(meio.size.y).is_equal(CAIXA.size.y * 0.5)
	assert_float(meio.get_center().x).is_equal(CAIXA.get_center().x)
	assert_float(DeathBurst.flatten(CAIXA, 1.0).size.y).is_greater(0.0)


func test_o_po_de_uma_tropa_caida_assenta() -> void:
	var m := DeathBurst.new()
	m.dust(Vector2(10.0, 500.0), 0.0)
	assert_int(m.live()).is_greater(0)
	m.step(0.1, DeathBurst.VIDA_S + 1.0)
	assert_int(m.live()).is_equal(0)
