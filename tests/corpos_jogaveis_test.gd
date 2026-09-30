# tests/corpos_jogaveis_test.gd — tropa < personagem jogavel < rei (§22; Q-097, Q-162).
#
# O dono (Q-162, 30/09/2026): "as tropas podem ter similaridades as classes jogaveis,
# mas tem tamanho de tropa padrao; as classes jogaveis sao maiores do que as tropas, e
# normalmente os imperadores sao mais altos que as classes controlaveis tambem." O
# arqueiro, o bardo e o diplomata eram tropa e corpo da classe ao mesmo tempo, na
# escala da tropa; passam a ter um corpo jogavel proprio, e a tropa fica como era.
extends GdUnitTestSuite

const TROPA := 2
const JOGAVEL := 3
const REI := 4


func _corpo(classe: ClassData) -> UnitData:
	return Registry.entry(&"units", classe.base_unit) as UnitData


func test_cada_classe_tem_um_corpo_jogavel_maior_do_que_a_tropa() -> void:
	for classe: ClassData in Registry.entries(&"classes"):
		var corpo := _corpo(classe)
		var esperado := REI if classe.id == &"monarch" else JOGAVEL
		var porque := "%s: o corpo e da escala %d" % [classe.id, esperado]
		assert_int(corpo.scale_tier).override_failure_message(porque).is_equal(esperado)
		if classe.troop == &"":
			continue
		var tropa := Registry.entry(&"units", classe.troop) as UnitData
		assert_int(tropa.scale_tier).is_equal(TROPA)
		assert_bool(tropa.tags.has(&"playable")).is_false()
		assert_bool(corpo.tags.has(&"playable")).is_true()


func test_quem_e_jogavel_e_o_corpo_de_uma_classe() -> void:
	var corpos := {}
	for classe: ClassData in Registry.entries(&"classes"):
		corpos[classe.base_unit] = true
	for unidade: UnitData in Registry.entries(&"units"):
		if unidade.tags.has(&"playable"):
			assert_bool(corpos.has(unidade.id)).is_true()


func test_o_rei_e_o_maior_de_todos() -> void:
	var rei := Registry.entry(&"units", &"monarch") as UnitData
	for unidade: UnitData in Registry.entries(&"units"):
		if unidade.id != rei.id:
			assert_int(unidade.scale_tier).is_less(rei.scale_tier)
