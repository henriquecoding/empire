# tests/golpe_de_perto_test.gd — o golpe de perto atinge tudo o que alcanca (Q-185).
#
# O dono, a 03/10/2026: "os ataques corpo a corpo atingem aquilo que esta ao seu alcance
# [...] se for criaturas pequenas sao jogadas um pouco para tras, criaturas grandes
# continuam inabaladas, arqueiros e ataques a distancia acertam um inimigo por vez".
extends GdUnitTestSuite

const X := 0.0

var _estado := GameState.new()
var _c := CreatureSystem.new()


func before_test() -> void:
	_estado = GameState.new()
	_c = CreatureSystem.new()


func _criatura(id: StringName, x: float) -> int:
	return _c.spawn(_estado, Registry.entry(&"creatures", id) as CreatureData, x, X)


func _empurrao() -> Vector2:
	var r := RulesFactory.rules()
	return Vector2(r.melee_knockback_px, r.melee_knockback_max_tier)


func _dados_c() -> Dictionary:
	return SimFactory.by_id(&"creatures")


func test_a_espada_bate_em_todos_os_que_alcanca_do_lado_do_golpe() -> void:
	var alvo := _criatura(&"crawler", 20.0)
	var outro := _criatura(&"crawler", 28.0)
	var longe := _criatura(&"crawler", 80.0)
	var atras := _criatura(&"crawler", -10.0)
	var alvos := MeleeSweep.targets(_c, X, int(_c.bands[0]), 30.0, alvo)
	assert_array(alvos).contains_exactly([alvo, outro])
	assert_bool(alvos.has(longe) or alvos.has(atras)).is_false()


func test_os_encantados_nao_levam() -> void:
	var alvo := _criatura(&"crawler", 20.0)
	var amigo := _criatura(&"crawler", 24.0)
	var alvos := MeleeSweep.targets(_c, X, int(_c.bands[0]), 30.0, alvo, {amigo: true})
	assert_array(alvos).contains_exactly([alvo])


func test_quem_bate_de_perto_e_quem_dispara() -> void:
	assert_bool(MeleeSweep.melee(Registry.entry(&"units", &"monarch") as UnitData)).is_true()
	assert_bool(MeleeSweep.melee(Registry.entry(&"units", &"nia") as UnitData)).is_true()
	assert_bool(MeleeSweep.melee(Registry.entry(&"units", &"archer") as UnitData)).is_false()
	var imperador := Registry.entry(&"units", &"archer_emperor") as UnitData
	assert_bool(MeleeSweep.melee(imperador)).is_false()


func test_a_distancia_um_alvo_so() -> void:
	var u := UnitSystem.new()
	var arqueiro := Registry.entry(&"units", &"archer") as UnitData
	var i := u.index_of(u.spawn(_estado, arqueiro, 1, X))
	var alvo := _criatura(&"crawler", 20.0)
	_criatura(&"crawler", 24.0)
	assert_array(MeleeSweep.hits(u, _c, i, arqueiro, alvo, null, {})).contains_exactly([alvo])


func test_o_pequeno_recua_e_o_grande_nao() -> void:
	var pequeno := _criatura(&"crawler", 20.0)
	var grande := _criatura(&"brute", 22.0)
	var e := _empurrao()
	assert_float(e.x).is_greater(0.0)
	for id in [pequeno, grande]:
		MeleeSweep.knock(_c, _dados_c(), {CombatSystem.PARA: id, MeleeSweep.DE_X: X}, e)
	assert_float(_c.xs[_c.index_of(pequeno)]).is_equal(20.0 + e.x)
	assert_float(_c.xs[_c.index_of(grande)]).is_equal(22.0)


## A flecha nao empurra: o golpe sem DE_X fica onde estava.
func test_sem_golpe_de_perto_nao_ha_empurrao() -> void:
	var pequeno := _criatura(&"crawler", 20.0)
	MeleeSweep.knock(_c, _dados_c(), {CombatSystem.PARA: pequeno}, _empurrao())
	assert_float(_c.xs[_c.index_of(pequeno)]).is_equal(20.0)


## O combate inteiro: um lanceiro com tres Rastejantes ao alcance fere os tres.
func test_no_combate_a_tropa_de_perto_fere_todos() -> void:
	var u := UnitSystem.new()
	var lanceiro := Registry.entry(&"units", &"spearman") as UnitData
	var id := u.spawn(_estado, lanceiro, 1, X)
	var a := _criatura(&"crawler", 10.0)
	var b := _criatura(&"crawler", 14.0)
	var combate := SimFactory.combat(SimFactory.job_board())
	combate.choose(u, _c, BuildSystem.new())
	assert_int(combate.target_of(id)).is_not_equal(UnitSystem.NENHUM)
	var feridos := {}
	for e in combate.resolve(u, _c, null, func() -> float: return 0.0):
		if e[CombatSystem.CHAVE] == CombatSystem.EV_DANO:
			feridos[e[CombatSystem.PARA]] = true
	assert_bool(feridos.has(a) and feridos.has(b)).is_true()
