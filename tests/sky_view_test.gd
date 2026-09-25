# tests/sky_view_test.gd — as horas no ceu (§24; GB-18).
#
# O HUD diegetico do §24: "Hora do dia — cor da luz ambiente + posicao do sol/lua
# no ceu — no mundo". A cor ja mudava; o sol estava pintado num ponto fixo da
# regiao, a 3033 px do principio, e nao se via do castelo. Lua nao havia.
extends GdUnitTestSuite

## As duracoes do §05, como o clock.csv as da: o dia sao as cinco primeiras e a
## noite e a ultima.
const DURACOES := [15.0, 85.0, 40.0, 85.0, 30.0, 105.0]


func _d() -> PackedFloat32Array:
	return PackedFloat32Array(DURACOES)


func test_o_sol_nasce_na_alvorada_e_poe_se_no_fim_do_crepusculo() -> void:
	var nasce := SkyView.course(0.0, _d())
	var poe := SkyView.course(254.9, _d())
	assert_bool(nasce.moon).is_false()
	assert_float(nasce.t).is_equal_approx(0.0, 0.001)
	assert_float(poe.t).is_equal_approx(1.0, 0.01)
	assert_bool(poe.moon).is_false()


func test_a_noite_e_da_lua() -> void:
	var meio_da_noite := SkyView.course(255.0 + 52.5, _d())
	assert_bool(meio_da_noite.moon).is_true()
	assert_float(meio_da_noite.t).is_equal_approx(0.5, 0.001)


## O arco nasce e poe-se no horizonte do §11, atras das montanhas, e sobe ao
## meio do percurso — e nao da voltas pelo ecra.
func test_o_arco_nasce_no_horizonte_e_sobe_ao_meio() -> void:
	var nascer := SkyView.arc(0.0, 1280.0)
	var meio := SkyView.arc(0.5, 1280.0)
	var por := SkyView.arc(1.0, 1280.0)
	assert_float(nascer.y).is_equal_approx(float(Band.HORIZON), 0.001)
	assert_float(por.y).is_equal_approx(float(Band.HORIZON), 0.001)
	assert_float(meio.y).is_less(nascer.y)
	assert_float(nascer.x).is_less(meio.x)
	assert_float(meio.x).is_less(por.x)


## Da esquerda para a direita, como o varrimento do amanhecer (§24): o sol vem de
## onde a luz veio.
func test_o_arco_vai_da_esquerda_para_a_direita_dentro_do_ecra() -> void:
	for t in [0.0, 0.25, 0.5, 0.75, 1.0]:
		var p := SkyView.arc(t, 1280.0)
		assert_float(p.x).is_between(0.0, 1280.0)
