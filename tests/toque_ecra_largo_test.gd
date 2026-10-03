# tests/toque_ecra_largo_test.gd — no telemovel, o mundo enche o ecra (Q-188).
#
# O dono aprovou a 03/10/2026: no toque, o canvas alarga-se ate 1,25x o 16:9 (ADR 0001),
# e os botoes passam para onde estavam as barras.
extends GdUnitTestSuite


func test_com_teclado_fica_o_16_9() -> void:
	assert_int(WideTouch.width_for(Vector2(2400.0, 1080.0), false)).is_equal(1280)


func test_um_20_9_enche_se_todo() -> void:
	assert_int(WideTouch.width_for(Vector2(2400.0, 1080.0), true)).is_equal(1600)


func test_um_19_5_9_tambem() -> void:
	assert_int(WideTouch.width_for(Vector2(2340.0, 1080.0), true)).is_equal(1560)


func test_mais_largo_do_que_o_limite_leva_barras_so_no_que_passa() -> void:
	assert_int(WideTouch.width_for(Vector2(3200.0, 1080.0), true)).is_equal(1600)


func test_um_ecra_mais_alto_do_que_16_9_nao_encolhe() -> void:
	assert_int(WideTouch.width_for(Vector2(2048.0, 1536.0), true)).is_equal(1280)
