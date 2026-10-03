# tests/sangramento_test.gd — a ferida da flecha do Imperador Arqueiro (ADR 0052, Q-201).
#
# O dono, a 02/10/2026: "chance de sangramento ao acertar e perda gradual de vida do
# inimigo". Os numeros sao a proposta de bancada (units.csv, archer_emperor): a chance, a
# duracao e o dano por segundo saem dos dados, e nenhum esta aqui.
extends GdUnitTestSuite

const PASSO := 1.0 / 30.0
const FONTE := 7

var _bichos: CreatureSystem
var _ferida: Bleeding
var _estado: GameState


func before_test() -> void:
	_estado = GameState.new()
	_bichos = CreatureSystem.new()
	_ferida = Bleeding.new()


func _arco() -> Dictionary:
	return (Registry.entry(&"units", &"archer_emperor") as UnitData).ability_params


func _bicho(id: StringName) -> int:
	var dados := Registry.entry(&"creatures", id) as CreatureData
	return _bichos.spawn(_estado, dados, 0.0, 0.0)


func _abrir(alvo: int, id: StringName, sorte: float) -> bool:
	var dados := Registry.entry(&"creatures", id) as CreatureData
	return _ferida.strike(alvo, FONTE, dados, sorte, _arco())


func _correr(segundos: float, aliados: Dictionary = {}) -> int:
	var total := 0
	for _k in roundi(segundos / PASSO):
		_ferida.tick(PASSO, _bichos, aliados)
		for golpe in _ferida.take():
			total += int(golpe[Bleeding.DANO])
	return total


func test_so_abre_com_a_sorte_abaixo_da_chance() -> void:
	var alvo := _bicho(&"brute")
	var chance := float(_arco()[&"bleed_chance"])
	assert_bool(_abrir(alvo, &"brute", chance + 0.01)).is_false()
	assert_bool(_ferida.wounds.has(alvo)).is_false()
	assert_bool(_abrir(alvo, &"brute", chance - 0.01)).is_true()
	assert_bool(_ferida.wounds.has(alvo)).is_true()


func test_sangra_um_ponto_por_segundo_durante_o_prazo_e_acaba() -> void:
	var alvo := _bicho(&"brute")
	_abrir(alvo, &"brute", 0.0)
	var p := _arco()
	assert_int(_correr(0.9)).is_equal(0)
	var esperado := int(p[&"bleed_damage"]) * roundi(float(p[&"bleed_seconds"]))
	assert_int(_correr(float(p[&"bleed_seconds"]))).is_equal(esperado)
	assert_bool(_ferida.wounds.has(alvo)).is_false()


func test_um_proc_novo_renova_o_prazo_sem_somar_dano() -> void:
	var alvo := _bicho(&"brute")
	_abrir(alvo, &"brute", 0.0)
	_correr(2.0)
	_abrir(alvo, &"brute", 0.0)
	assert_int(_ferida.wounds.size()).is_equal(1)
	assert_float(float(_ferida.wounds[alvo][Bleeding.PRAZO])).is_equal(
		float(_arco()[&"bleed_seconds"])
	)
	_ferida.tick(1.0, _bichos, {})
	assert_int(_ferida.take().size()).is_equal(1)


func test_quem_nao_tem_sangue_nao_sangra() -> void:
	var alvo := _bicho(&"slime_ram")
	assert_bool(_abrir(alvo, &"slime_ram", 0.0)).is_false()
	var zelador := _bicho(&"tender")
	assert_bool(_abrir(zelador, &"tender", 0.0)).is_false()


func test_o_convertido_deixa_de_sangrar() -> void:
	var alvo := _bicho(&"brute")
	_abrir(alvo, &"brute", 0.0)
	assert_int(_correr(2.0, {alvo: {}})).is_equal(0)
	assert_bool(_ferida.wounds.has(alvo)).is_false()


func test_quem_morreu_deixa_de_sangrar() -> void:
	var alvo := _bicho(&"brute")
	_abrir(alvo, &"brute", 0.0)
	_bichos.remove(alvo)
	assert_int(_correr(2.0)).is_equal(0)
	assert_bool(_ferida.wounds.has(alvo)).is_false()


func test_a_ferida_volta_igual_do_save() -> void:
	var alvo := _bicho(&"brute")
	_abrir(alvo, &"brute", 0.0)
	_correr(1.5)
	var outra := Bleeding.new()
	outra.from_dict(_ferida.to_dict())
	assert_dict(outra.wounds).is_equal(_ferida.wounds)
	_ferida.tick(0.6, _bichos, {})
	outra.tick(0.6, _bichos, {})
	assert_array(outra.take()).is_equal(_ferida.take())
