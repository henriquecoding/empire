# tests/caca_a_vista_test.gd — a caca que se ve e que se acerta (Q-218, ADR 0058).
#
# O dono, a 03/10/2026: «as criaturas estao microscopicas, elas tem que ser pelo menos 2
# ou 3 vezes o tamanho que estao com base 64x64 pixels de sprite para que possam fazer
# sentido em imagem, e dar para bater». As tropas e os monarcas sao sprites de 64x64.
extends GdUnitTestSuite

const SPRITE_PX := 64.0
const METADE := 0.5

var units: UnitSystem
var state: GameState


func before_test() -> void:
	units = UnitSystem.new()
	state = GameState.new()


func _bicho(id: StringName) -> WildlifeData:
	return Registry.entry(&"wildlife", id) as WildlifeData


func _caca(toca: float, bicho: String) -> HuntingSystem:
	var h := HuntingSystem.new(SimFactory.by_id(&"units"), _bicho(&"rabbit"))
	h.wildlife = SimFactory.by_id(&"wildlife")
	h.burrows.place([toca] as Array[float], [0.0] as Array[float])
	h.burrows.game = PackedStringArray([bicho])
	h.open_day(2)
	h.grow(0.0, true, 1.0)
	return h


## A altura de cada desenho, em pixeis dele: do chao ao ponto mais alto (HuntView,
## GameArt).
func _altura(id: StringName) -> float:
	var topo: float = {
		&"rabbit": HuntView.EARS[0].position.y,
		&"deer": HuntView.DEER_ANTLERS[1].position.y,
		&"pheasant": GameArt.PHEASANT_HEAD.position.y,
		&"fox": GameArt.FOX_EARS[0].position.y,
		&"boar": GameArt.BOAR_MANE.position.y,
		&"white_stag": GameArt.STAG_ANTLERS[1].position.y,
	}[id]
	return -topo


## Cada bicho desenha-se pelo menos ao dobro, e le-se contra uma tropa: pelo menos meio
## sprite de 64 px de altura.
func test_cada_bicho_se_ve_contra_uma_tropa() -> void:
	for recurso in Registry.entries(&"wildlife"):
		var dados := recurso as WildlifeData
		var nome := String(dados.id)
		assert_int(dados.sprite_scale).override_failure_message(nome).is_greater_equal(2)
		var altura := _altura(dados.id) * dados.sprite_scale
		assert_float(altura).override_failure_message(nome).is_greater_equal(SPRITE_PX * METADE)
		assert_float(altura).override_failure_message(nome).is_less(SPRITE_PX * 2.0)
		assert_int(dados.shadow_width).override_failure_message(nome).is_greater_equal(20)


## O golpe acerta no corpo do bicho, e nao so no meio dele: ate meia sombra para la do
## alcance, e ate meia sombra para tras de quem bate.
func test_o_golpe_acerta_no_corpo_do_bicho() -> void:
	var javali := _bicho(&"boar")
	var meia := javali.shadow_width * METADE
	var golpe := {&"who": 1, &"band": Band.Kind.SURFACE, &"range": 30.0, &"damage": 1}
	golpe[&"direction"] = 1.0
	golpe[&"x"] = 100.0 - 30.0 - meia - 1.0
	assert_array(RoyalHunt.swing(_caca(100.0, "boar"), golpe)).is_empty()
	var h := _caca(100.0, "boar")
	golpe[&"x"] = 100.0 - 30.0 - meia + 1.0
	RoyalHunt.swing(h, golpe)
	assert_bool(h.wounds.has(100.0)).is_true()
	h = _caca(100.0, "boar")
	golpe[&"x"] = 100.0 + meia - 1.0
	RoyalHunt.swing(h, golpe)
	assert_bool(h.wounds.has(100.0)).is_true()
	golpe[&"x"] = 100.0 + meia + 1.0
	h = _caca(100.0, "boar")
	assert_array(RoyalHunt.swing(h, golpe)).is_empty()
	assert_bool(h.wounds.has(100.0)).is_false()


## O imperador que ninguem conduz tambem acerta no corpo: ao alcance da pele do bicho.
func test_o_imperador_parado_acerta_no_corpo() -> void:
	var perfis := SimFactory.by_id(&"units")
	var nia := perfis[&"nia"] as UnitData
	var meia := _bicho(&"boar").shadow_width * METADE
	var h := _caca(100.0, "boar")
	units.spawn(state, Registry.entry(&"units", &"nia"), 1, 100.0 + nia.range_px + meia + 1.0)
	RoyalHunt.idle(h, units, perfis, UnitSystem.NENHUM, true)
	assert_bool(h.wounds.has(100.0)).is_false()
	units.xs[0] = 100.0 + nia.range_px + meia - 1.0
	RoyalHunt.idle(h, units, perfis, UnitSystem.NENHUM, true)
	assert_bool(h.wounds.has(100.0)).is_true()
