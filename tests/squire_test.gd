# tests/squire_test.gd — o escudeiro (§08; Q-114, o dono a 29/09/2026).
#
# "5 moedas deixam o escudeiro levar 5 golpes de inimigos fracos e 2 de inimigos
# fortes; 3 moedas caidas de inimigos dao uma espada de 3 golpes, que se parte e
# o ciclo recomeca; cavaleiro: escudo que recebe mais moedas, espada de 5 golpes."
extends GdUnitTestSuite

var dados: UnitData
var s: Squire


func before_test() -> void:
	dados = Registry.entry(&"units", &"squire") as UnitData
	s = Squire.new(dados.ability_params)


func _fraco() -> int:
	return (Registry.entry(&"creatures", &"crawler") as CreatureData).damage


func _forte() -> int:
	return (Registry.entry(&"creatures", &"brute") as CreatureData).damage


func test_cinco_moedas_levam_cinco_golpes_fracos() -> void:
	assert_int(s.arm(7)).is_equal(5)
	for _k in 5:
		assert_bool(s.block(_fraco())).is_true()
	assert_bool(s.block(_fraco())).is_false()


func test_cinco_moedas_levam_dois_golpes_fortes() -> void:
	s.arm(5)
	assert_bool(s.block(_forte())).is_true()
	assert_bool(s.block(_forte())).is_true()
	assert_bool(s.shielded()).is_false()


func test_tres_moedas_caidas_dao_uma_espada_de_tres_golpes_que_se_parte() -> void:
	s.take_loot(2)
	assert_int(s.sword).is_equal(0)
	s.take_loot(1)
	var golpes := 0
	while s.strike() > 0:
		golpes += 1
	assert_int(golpes).is_equal(3)
	s.take_loot(3)
	assert_int(s.sword).is_equal(3)


func test_o_cavaleiro_aceita_mais_moedas_e_a_espada_da_cinco_golpes() -> void:
	s.knight = true
	assert_int(s.coins_wanted()).is_greater(5)
	s.take_loot(3)
	var golpes := 0
	var dano := 0
	while true:
		var d := s.strike()
		if d <= 0:
			break
		golpes += 1
		dano = d
	assert_int(golpes).is_equal(5)
	assert_int(dano).is_greater(int(dados.ability_params[&"sword_damage"]))


func test_vai_no_save() -> void:
	s.arm(3)
	s.take_loot(4)
	var copia := Squire.new(dados.ability_params)
	copia.from_dict(s.to_dict())
	assert_dict(copia.to_dict()).is_equal(s.to_dict())
