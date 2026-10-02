# tests/screen_shake_test.gd — o tremor por trauma (§24, Eiserloh 2016).
#
# §24: so para o muro a cair e o Ariete a acertar, e no maximo 4 px. O trauma
# soma e gasta-se; o tremor e o quadrado dele, e por isso um trauma pequeno
# quase nao se sente.
extends GdUnitTestSuite

const PASSO := 1.0 / 60.0


func test_sem_trauma_nao_ha_tremor() -> void:
	var t := ScreenShake.new()
	assert_vector(t.step(PASSO)).is_equal(Vector2.ZERO)


func test_nunca_passa_dos_4_px_do_24() -> void:
	var t := ScreenShake.new(Vector4(0.3, 1.1, 2.0, 0.7))
	t.add(5.0)
	assert_float(t.trauma).is_equal(1.0)
	for k in 120:
		var tremor := t.step(PASSO)
		assert_float(absf(tremor.x)).is_less_equal(ScreenShake.MAX_PX)
		assert_float(absf(tremor.y)).is_less_equal(ScreenShake.MAX_PX * ScreenShake.VERTICAL)


func test_o_trauma_gasta_se_e_o_ecra_assenta() -> void:
	var t := ScreenShake.new()
	t.add(1.0)
	for k in int(60.0 / ScreenShake.DECAI) + 2:
		t.step(PASSO)
	assert_float(t.trauma).is_equal(0.0)
	assert_vector(t.step(PASSO)).is_equal(Vector2.ZERO)


## Metade do trauma e um quarto do tremor.
func test_um_trauma_pequeno_quase_nao_se_sente() -> void:
	var t := ScreenShake.new(Vector4(0.3, 1.1, 2.0, 0.7))
	t.add(0.5)
	var maior := 0.0
	for k in 20:
		maior = maxf(maior, absf(t.step(PASSO).x))
	assert_float(maior).is_less_equal(ScreenShake.MAX_PX * 0.25)
