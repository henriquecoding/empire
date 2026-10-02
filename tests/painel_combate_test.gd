# tests/painel_combate_test.gd — o painel do ataque e da habilidade fica no canto e nao tapa
# o jogo (o pedido do dono de 02/10/2026; ADR 0045, Q-186).
#
# "Esses botoes nao devem estar ali na frente atrapalhando, pois ao entrar no subsolo eles
# ficam por cima." O corte de solo vai da linha do chao ao fundo do ecra (§11); o painel
# fica no ceu, por baixo da faixa de cima e acima do aviso e das legendas.
extends GdUnitTestSuite

const ECRA := Vector2(1280.0, 720.0)
const PEQUENO := Vector2(640.0, 360.0)


func _no_ecra(area: Vector2, escala: float) -> Rect2:
	var caixa := CombatBar.place(area, escala)
	return Rect2(caixa.position, caixa.size * escala)


func test_o_painel_nunca_entra_no_corte_de_solo() -> void:
	var caixa := _no_ecra(ECRA, 1.0)
	assert_float(caixa.end.y).is_less(float(Band.GROUND_LINE))
	assert_float(caixa.position.y).is_greater_equal(GameHud.FAIXA_TOPO)


func test_o_painel_nao_tapa_o_aviso_nem_as_legendas() -> void:
	var caixa := _no_ecra(ECRA, 1.0)
	var aviso := GameHud.AVISO_CAIXA
	var moldura := Rect2(aviso.x, aviso.y, aviso.w, aviso.h)
	assert_bool(caixa.intersects(moldura)).is_false()
	assert_float(caixa.end.y).is_less_equal(Captions.CAIXA.topo)
	assert_float(caixa.end.x).is_less_equal(ECRA.x)


func test_numa_janela_pequena_continua_no_ecra_e_no_ceu() -> void:
	var escala := 2.0
	var caixa := _no_ecra(PEQUENO * escala, escala)
	assert_float(caixa.position.x).is_greater_equal(0.0)
	assert_float(caixa.end.x).is_less_equal(PEQUENO.x * escala)
	assert_float(caixa.end.y).is_less(float(Band.GROUND_LINE) * escala)
