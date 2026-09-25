# tests/build_view_test.gd — a silhueta fantasma a piscar (§25; GB-23).
#
# O §25, minuto 3:30: "Primeira estacaria construivel — silhueta fantasma a
# piscar, 6 moedas. A silhueta e o convite." O contorno existia e estava parado.
extends GdUnitTestSuite


func test_o_convite_pisca_e_nunca_apaga() -> void:
	var menor := 1.0
	var maior := 0.0
	for i in 200:
		var a := BuildView.blink(i * 0.05)
		menor = minf(menor, a)
		maior = maxf(maior, a)
	assert_float(maior).is_equal_approx(1.0, 0.01)
	assert_float(menor).is_equal_approx(BuildView.PISCAR.minimo, 0.01)
	assert_float(menor).is_greater(0.0)


## Devagar: um piscar mais rapido do que um por segundo lia-se como alarme, e o
## convite nao e um alarme.
func test_pisca_devagar() -> void:
	var periodo := TAU / BuildView.PISCAR.rad_s
	assert_float(periodo).is_greater(1.0)
