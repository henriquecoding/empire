# tests/lareira_test.gd — a lareira do nucleo afasta, e custa (Q-190).
#
# O dono, a 03/10/2026: "ha um custo para manter ela acesa, nao e barato, o jogador tem
# que conseguir recursos e administrar bem seu dinheiro para manter isso funcionando".
extends GdUnitTestSuite

const NUCLEO := 1000.0


func _r() -> RulesCurve:
	return RulesFactory.rules()


## Nao e barato: uma noite de lareira custa mais do que levantar uma fogueira inteira.
func test_os_numeros_estao_nos_dados_e_nao_e_barato() -> void:
	var fogueira := Registry.entry(&"buildings", &"campfire") as BuildingData
	assert_int(_r().hearth_night_cost).is_greater(fogueira.cost)
	assert_float(_r().hearth_radius_px).is_greater(0.0)
	assert_int(_r().hearth_repel_mass).is_greater(0)


func test_paga_acende_e_gasta_o_preco() -> void:
	var h := Hearth.new()
	assert_int(h.kindle(10, 5)).is_equal(5)
	assert_bool(h.lit).is_true()


func test_sem_moedas_fica_apagada_e_nao_gasta_nada() -> void:
	var h := Hearth.new()
	assert_int(h.kindle(4, 5)).is_equal(0)
	assert_bool(h.lit).is_false()
	assert_bool(h.zone(NUCLEO, 240.0, 8, 0.25) == Vector4.ZERO).is_true()


func test_acesa_faz_recuar_o_rastejante_e_so_abranda_o_bruto() -> void:
	var h := Hearth.new()
	h.kindle(9, 5)
	var zonas: Array[Vector4] = [
		h.zone(NUCLEO, _r().hearth_radius_px, _r().hearth_repel_mass, 0.25)
	]
	var rastejante := Registry.entry(&"creatures", &"crawler") as CreatureData
	var bruto := Registry.entry(&"creatures", &"brute") as CreatureData
	assert_float(LightWard.at(NUCLEO + 10.0, rastejante.mass_cost, zonas).x).is_equal(1.0)
	assert_float(LightWard.at(NUCLEO + 10.0, bruto.mass_cost, zonas).x).is_equal(0.0)


func test_a_alvorada_apaga() -> void:
	var h := Hearth.new()
	h.kindle(9, 5)
	h.dawn()
	assert_bool(h.lit).is_false()
