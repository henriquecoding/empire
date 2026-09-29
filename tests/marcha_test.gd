# tests/marcha_test.gd — a marcha e os vassalos (§13; Q-103, Q-146, Q-154; ADR 0035).
#
# "Designas tropas para avancar. Elas saem do imperio, que fica desguarnecido nessa
# noite." O povo conquistado "continua a funcionar como imperio, mas gera-me um
# imposto real" (Q-103) — o §13 da 4–6 moedas por dia — e pode ser consumido pela
# Podridao, no modo em que os vassalos caem.
extends GdUnitTestSuite

const STEP := 1.0 / 30.0
const MEU := 1

var estado: GameState
var unidades: UnitSystem


func before_test() -> void:
	estado = GameState.new()
	unidades = UnitSystem.new()


func _curva() -> EconomyCurve:
	return SimFactory.curve()


func test_vai_quem_esta_perto_ate_ao_teto_de_cada_papel() -> void:
	var rei := unidades.spawn(estado, Registry.entry(&"units", &"monarch"), MEU, 0.0)
	for _k in 6:
		unidades.spawn(estado, Registry.entry(&"units", &"archer"), MEU, 10.0)
	for _k in 5:
		unidades.spawn(estado, Registry.entry(&"units", &"builder"), MEU, 10.0)
	unidades.spawn(estado, Registry.entry(&"units", &"vagrant"), MEU, 10.0)
	unidades.spawn(estado, Registry.entry(&"units", &"archer"), MEU, 5000.0)
	var tetos := _curva().march_party_caps
	var quem := March.who(unidades, SimFactory.by_id(&"units"), rei, 120.0, tetos)
	assert_int(quem.size()).is_equal(int(tetos[&"ranged"]) + int(tetos[&"builder"]))


func test_quem_marcha_sai_das_colunas_e_volta_na_alvorada() -> void:
	var m := March.new()
	var a := unidades.spawn(estado, Registry.entry(&"units", &"archer"), MEU, 10.0)
	m.start(unidades, PackedInt32Array([a]), 2, 11, 1)
	assert_int(unidades.count()).is_equal(0)
	assert_bool(m.due(11)).is_false()
	assert_bool(m.due(12)).is_true()
	assert_array(Array(m.finish())).is_equal(["archer"])
	assert_bool(m.marching()).is_false()


func test_o_vassalo_paga_tributo_e_a_noite_come_lhe_a_firmeza() -> void:
	var v := VassalSystem.new()
	v.add(&"portuarios", 5, 10.0, 11)
	var dia := v.dawn(100.0, 0.02, true)
	assert_int(int(dia[&"coins"])).is_equal(5)
	assert_array(Array(dia[&"fallen"])).is_empty()
	dia = v.dawn(500.0, 0.02, true)
	assert_array(Array(dia[&"fallen"])).is_equal(["portuarios"])
	assert_bool(v.has(&"portuarios")).is_false()


func test_no_modo_em_que_nao_caem_o_vassalo_fica_para_sempre() -> void:
	var v := VassalSystem.new()
	v.add(&"horta", 4, 1.0, 11)
	for _k in 10:
		v.dawn(1000.0, 1.0, false)
	assert_bool(v.has(&"horta")).is_true()
	var copia := VassalSystem.new()
	copia.from_dict(v.to_dict())
	assert_array(Array(copia.peoples())).is_equal(["horta"])


func test_no_jogo_a_marcha_conquista_o_povo_seguinte() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20260929)
	Greybox.build()
	SimLoop.step(STEP)
	var reino := SimLoop.field.realm
	var r := SimLoop.units.index_of(SimLoop.king_id)
	var dono := SimLoop.units.owners[r]
	for _k in _curva().march_min_party:
		SimLoop.units.spawn(
			SimLoop.state, Registry.entry(&"units", &"archer"), dono, SimLoop.units.xs[r]
		)
	var alvo := reino.next_target(SimLoop.state)
	assert_int(alvo).is_equal(1)
	var sementes := SimLoop.state.royal_seeds
	assert_bool(reino.send(SimLoop.units, SimLoop.king_id, SimLoop.state, 11)).is_true()
	var fork := Vector2(SimLoop.core_x, SimLoop.secrets.chapters[0])
	reino.dawn(12, SimLoop.units, SimLoop.state, SimLoop.king_id, fork)
	var povo := Realm._povo(SimLoop.state.chapters.regions[alvo])
	assert_bool(reino.vassals.has(povo)).is_true()
	assert_int(SimLoop.state.royal_seeds).is_greater(sementes)
	assert_int(reino.next_target(SimLoop.state)).is_equal(2)
	var moedas := SimLoop.coins.count()
	reino.dawn(13, SimLoop.units, SimLoop.state, SimLoop.king_id, fork)
	assert_int(SimLoop.coins.count()).is_greater(moedas)
	var copia := Realm.new()
	copia.from_dict(reino.to_dict())
	assert_bool(copia.vassals.has(povo)).is_true()
	SimLoop.stop()
	SimLoop.autosave_enabled = true
