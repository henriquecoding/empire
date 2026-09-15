# tests/design_data_test.gd — portao G5 desde o dia zero (§31, §64).
# Os testes de design do dossie, corridos sobre os dados atraves do modelo de
# referencia (tests/support/reference_model.gd). Quando o EconomySystem (F1-10) e
# o CombatSystem existirem, os testes do §31 passam a chamar esses sistemas.
extends GdUnitTestSuite

const Model := preload("res://tests/support/reference_model.gd")

## §07, "Tempo ate matar": atacante, precisao, e os cinco valores da tabela
## (Rastejante, Alado, Bruto, Cavador, Ariete).
const TTK_07 := [
	["archer", "tower", [4.2, 5.6, 11.2, 9.8, 32.2]],
	["archer", "open", [12.6, 16.8, 33.6, 29.4, 96.6]],
	["spearman", "unit", [2.2, 3.3, 6.6, 5.5, 16.5]],
	["root_berserker", "unit", [0.9, 1.8, 2.7, 2.7, 7.2]],
	["mercenary", "unit", [1.0, 2.0, 3.0, 3.0, 9.0]],
]
const TARGETS := ["crawler", "winged", "brute", "burrower", "slime_ram"]


func _curve() -> EconomyCurve:
	return load("res://data/economy/curve.tres")


func _profile(id: String) -> EconomyProfile:
	return load("res://data/economy/profiles/%s.tres" % id)


func _asfixia(id: String) -> int:
	return Model.suffocation_day(_profile(id), _curve())


func _accuracy(u: UnitData, mode: String) -> float:
	match mode:
		"tower":
			return _curve().tower_accuracy
		"open":
			return u.accuracy_open
	return u.accuracy_open


func test_tabela_de_tempo_ate_matar_do_07() -> void:
	# A tabela do §07 usa 1/3 em campo aberto; os dados usam 0,34 (§19, §44).
	# Tolerancia de 3% cobre essa diferenca e mais nada.
	for row in TTK_07:
		var u: UnitData = load("res://data/units/%s.tres" % row[0])
		for i in TARGETS.size():
			var c: CreatureData = load("res://data/creatures/%s.tres" % TARGETS[i])
			var got := Model.ttk(u, c.max_health, _accuracy(u, row[1]))
			var want: float = row[2][i]
			var msg := (
				"%s (%s) contra %s: %.2f s, a tabela diz %.2f s"
				% [row[0], row[1], TARGETS[i], got, want]
			)
			assert_float(got).override_failure_message(msg).is_equal_approx(want, want * 0.03)


# gdUnit4 le do_skip/skip_reason pela assinatura; o linter nao sabe disso.
# gdlint: disable=unused-argument
func test_arqueiros_nao_param_ariete(
	do_skip := true,
	skip_reason := "Q-001: com os numeros do §07 da 94,7 s < 105 s. Ver docs/QUESTIONS.md"
) -> void:
	var u: UnitData = load("res://data/units/archer.tres")
	var ram: CreatureData = load("res://data/creatures/slime_ram.tres")
	assert_float(Model.ttk(u, ram.max_health, u.accuracy_open)).is_greater(105.0)


# gdlint: enable=unused-argument


func test_podridao_do_29() -> void:
	var r: RotProfile = load("res://data/rot/default.tres")
	assert_float(Model.rot_speed(1, r)).is_equal_approx(14.9, 0.0001)
	# §74: 40 + 18 x 10 + 30 x 2 = 280, com o campo limpo. A §29 foi corrigida.
	assert_float(Model.rot_mass(10, 2, r)).is_equal(280.0)
	assert_float(r.summon_interval.x).is_equal(4.0)
	assert_float(r.summon_interval.y).is_equal(7.0)


func test_manutencao_do_29() -> void:
	var c := _curve()
	assert_float(Model.upkeep(8, c)).is_equal(0.0)
	assert_float(Model.upkeep(14, c)).is_equal(3.0)
	assert_float(Model.upkeep(25, c)).is_equal(13.5)


func test_dia_de_asfixia_no_intervalo() -> void:
	var target := _curve().suffocation_target
	assert_int(_asfixia("balanced")).is_between(target.x, target.y)


func test_perfis_com_alvo_proprio() -> void:
	for id in ["balanced", "two_routes", "everything_max"]:
		var p := _profile(id)
		var msg := "%s asfixia no dia %d" % [id, _asfixia(id)]
		assert_int(_asfixia(id)).override_failure_message(msg).is_between(
			p.expect_suffocation.x, p.expect_suffocation.y
		)


func test_cada_rota_adia_a_asfixia() -> void:
	# §06: "cada rota vale cerca de dois dias, com retorno decrescente".
	var p := _profile("balanced").duplicate() as EconomyProfile
	var before := Model.suffocation_day(p, _curve())
	for routes in range(1, 6):
		p.routes = routes
		var now := Model.suffocation_day(p, _curve())
		assert_int(now - before).is_between(1, 2)
		before = now


func test_ganancia_80_antecipa_pelo_menos_3_dias() -> void:
	assert_int(_asfixia("greed_20") - _asfixia("greed_80")).is_greater_equal(3)


func test_muralhas_do_10() -> void:
	var prev_cost := 0
	var slots := [2, 3, 4, 6, 7]
	for i in 5:
		var w: WallData = load(
			(
				"res://data/walls/%s.tres"
				% ["stakes", "palisade", "stone_wall", "iron_wall", "bastion"][i]
			)
		)
		assert_int(w.level).is_equal(i + 1)
		assert_int(w.cost).is_greater(prev_cost)
		assert_int(w.contact_slots).is_equal(slots[i])
		prev_cost = w.cost


func test_payback_do_06() -> void:
	var want := {
		"farm": 2.0,
		"fishery": 2.0,
		"henhouse": 2.7,
		"cow_stable": 2.8,
		"lumber_camp": 3.5,
		"ore_pit": 3.0
	}
	for id in want:
		var b: BuildingData = load("res://data/buildings/%s.tres" % id)
		assert_float(b.cost / b.yield_per_day).is_equal_approx(want[id], 0.05)
