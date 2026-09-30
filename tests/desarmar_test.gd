# tests/desarmar_test.gd — quem tem arma larga-a antes de morrer (Q-168, o dono a
# 30/09/2026; relatorio Kingdom, K3).
#
# "A 0 de vida, quem tem arma larga-a e foge como trabalhador; so morre quem cai sem
# arma." O arqueiro que cai passa a trabalhador, a fugir para o nucleo, e larga o arco
# no chao (weapon_dropped, §46); o trabalhador que cai morre.
extends GdUnitTestSuite

const REFUGIO := 500.0
const MEU := 1

var _estado := GameState.new()
var _u := UnitSystem.new()


func before_test() -> void:
	_estado = GameState.new()
	_u = UnitSystem.new()


func _por(id: StringName, x := 100.0) -> int:
	return _u.spawn(_estado, Registry.entry(&"units", id) as UnitData, MEU, x)


func _vagabundo() -> UnitData:
	return Registry.entry(&"units", &"vagrant") as UnitData


func test_o_arqueiro_que_cai_larga_o_arco_e_foge_como_trabalhador() -> void:
	var arqueiro := _por(&"archer")
	var i := _u.index_of(arqueiro)
	_u.healths[i] = 0
	_u.carried_coins[i] = 9
	var eventos := Disarm.spare(_u, SimFactory.by_id(&"units"), _vagabundo(), REFUGIO)
	assert_int(eventos.size()).is_equal(1)
	assert_int(int(eventos[0][CombatSystem.CHAVE])).is_equal(Disarm.EV)
	assert_str(String(_u.data_ids[i])).is_equal("vagrant")
	assert_int(_u.healths[i]).is_equal(_vagabundo().max_health)
	assert_int(_u.states[i]).is_equal(UnitFsm.State.FLEE)
	assert_float(_u.target_xs[i]).is_equal(REFUGIO)
	assert_int(_u.owners[i]).is_equal(MEU)
	# O saco do trabalhador leva menos: o resto cai, e nada desaparece em silencio (§50).
	assert_int(_u.carried_coins[i]).is_equal(_vagabundo().coin_capacity)
	assert_int(int(eventos[0][CombatSystem.MOEDAS])).is_equal(9 - _vagabundo().coin_capacity)


func test_quem_cai_sem_arma_morre() -> void:
	var trabalhador := _por(&"vagrant")
	_u.healths[_u.index_of(trabalhador)] = 0
	assert_array(Disarm.spare(_u, SimFactory.by_id(&"units"), _vagabundo(), REFUGIO)).is_empty()
	assert_str(String(_u.data_ids[_u.index_of(trabalhador)])).is_equal("vagrant")


## O rei e os corpos das classes jogaveis tem o §16 deles: nao largam arma nenhuma.
func test_o_rei_e_as_classes_nao_largam_arma() -> void:
	var dados := SimFactory.by_id(&"units")
	assert_bool(Disarm.armed(dados[&"monarch"])).is_false()
	assert_bool(Disarm.armed(dados[&"archer_hero"])).is_false()
	assert_bool(Disarm.armed(dados[&"archer"])).is_true()
	assert_bool(Disarm.armed(dados[&"spearman"])).is_true()
	assert_bool(Disarm.armed(dados[&"vagrant"])).is_false()


## No combate: o golpe que deixa o arqueiro a zero desarma-o em vez de o matar, e o
## sinal do §46 diz que a arma caiu.
func test_no_combate_o_golpe_final_desarma() -> void:
	EventBus.reset()
	var caidas: Array = []
	var ouvir := func(x: float, faixa: int, nivel: int) -> void: caidas.append([x, faixa, nivel])
	EventBus.weapon_dropped.connect(ouvir)
	var combate := SimFactory.combat(SimFactory.job_board())
	combate.refuge = REFUGIO
	var arqueiro := _por(&"archer")
	var i := _u.index_of(arqueiro)
	_u.healths[i] = 0
	var bichos := CreatureSystem.new()
	var eventos := combate.resolve(_u, bichos, BuildSystem.new(), func() -> float: return 0.0)
	EventRelay.combat(eventos)
	EventBus.flush()
	EventBus.weapon_dropped.disconnect(ouvir)
	assert_bool(_u.alive(i)).is_true()
	assert_str(String(_u.data_ids[i])).is_equal("vagrant")
	assert_int(caidas.size()).is_equal(1)
	for e in eventos:
		assert_int(int(e[CombatSystem.CHAVE])).is_not_equal(CombatSystem.EV_MORTE)
