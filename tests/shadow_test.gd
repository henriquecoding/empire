# tests/shadow_test.gd — a sombra de contacto (GB-08, §22, §24).
#
# O desenho nao se testa; a regra por tras dele testa-se, e e uma so: quanto
# mais alto, menor. O que se prova aqui e que ela nunca chega a zero — uma
# sombra que desaparece leva com ela a informacao de onde a moeda vai cair, que
# e exactamente para o que ela serve — e que nao rebenta sem arco nenhum.
extends GdUnitTestSuite


func _curva() -> EconomyCurve:
	return Registry.entry(&"economy", &"curve") as EconomyCurve


func _moedas() -> CoinSystem:
	return CoinSystem.new(_curva())


## v²/2g, com os dois numeros de `economy.csv` e nenhum escrito aqui.
func test_o_apice_sai_do_arco_que_a_economia_ja_define() -> void:
	var curva := _curva()
	var esperado := (
		curva.coin_drop_speed_px_s * curva.coin_drop_speed_px_s / (2.0 * curva.coin_gravity_px_s2)
	)
	assert_float(_moedas().apex_px()).is_equal_approx(esperado, 0.001)


## Sem gravidade nao ha arco, e uma divisao por zero dava uma sombra infinita.
func test_sem_gravidade_nao_ha_apice() -> void:
	var curva := EconomyCurve.new()
	curva.coin_drop_speed_px_s = 180.0
	curva.coin_gravity_px_s2 = 0.0
	assert_float(CoinSystem.new(curva).apex_px()).is_equal(0.0)


func test_pousada_a_sombra_esta_inteira() -> void:
	assert_float(Shadow.fade(0.0, 23.0)).is_equal(1.0)


func test_no_apice_a_sombra_encolhe_mas_nao_desaparece() -> void:
	# `is_equal_approx` e nao `is_equal`: o lerpf de 1 ate 0,45 com razao 1 da
	# 0,45000000000000007, e um teste que exija o bit certo chumba por isso.
	var no_topo := Shadow.fade(23.0, 23.0)
	assert_float(no_topo).is_equal_approx(Shadow.NO_APICE, 0.0001)
	assert_float(no_topo).is_greater(0.0)


## Acima do apice nao encolhe mais: uma moeda atirada de uma torre nao tem de ter
## sombra nenhuma.
func test_acima_do_apice_a_sombra_nao_encolhe_mais() -> void:
	assert_float(Shadow.fade(1000.0, 23.0)).is_equal_approx(Shadow.NO_APICE, 0.0001)


func test_sem_apice_a_sombra_fica_inteira_em_vez_de_rebentar() -> void:
	assert_float(Shadow.fade(10.0, 0.0)).is_equal(1.0)
