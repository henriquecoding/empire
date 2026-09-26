# tests/crown_test.gd — os impulsos reais (§15, §57): "Um impulso por dia. Cada um
# tem vantagem e desvantagem — nunca so vantagem."
#
# Os custos e os valores sao os de impulses.csv; nenhum esta aqui.
extends GdUnitTestSuite

const MEU := 1

var estado: GameState
var unidades: UnitSystem
var coroa: CrownSystem
var rei: int


func before_test() -> void:
	estado = GameState.new()
	unidades = UnitSystem.new()
	coroa = SimFactory.crown()
	rei = unidades.spawn(estado, Registry.entry(&"units", &"monarch"), MEU, 0.0)
	unidades.carried_coins[unidades.index_of(rei)] = 30


func _impulso(id: StringName) -> ImpulseData:
	return Registry.entry(&"crown/impulses", id) as ImpulseData


func _saco() -> int:
	return unidades.carried_coins[unidades.index_of(rei)]


func test_um_impulso_custa_o_preco_e_so_um_por_dia() -> void:
	var colheita := _impulso(&"forced_harvest")
	assert_bool(coroa.use(&"forced_harvest", 1, unidades, rei)).is_true()
	assert_int(_saco()).is_equal(30 - colheita.coin_cost)
	assert_bool(coroa.use(&"vigil", 1, unidades, rei)).is_false()
	assert_int(_saco()).is_equal(30 - colheita.coin_cost)
	assert_bool(coroa.use(&"vigil", 2, unidades, rei)).is_true()


func test_sem_moedas_no_saco_nao_ha_impulso() -> void:
	unidades.carried_coins[unidades.index_of(rei)] = _impulso(&"vigil").coin_cost - 1
	assert_bool(coroa.use(&"vigil", 1, unidades, rei)).is_false()
	assert_int(_saco()).is_equal(_impulso(&"vigil").coin_cost - 1)


func test_um_impulso_sem_sistema_por_tras_e_recusado_e_nao_cobra() -> void:
	assert_bool(coroa.available(&"protected_route")).is_false()
	assert_bool(coroa.use(&"protected_route", 1, unidades, rei)).is_false()
	assert_int(_saco()).is_equal(30)
	assert_bool(coroa.available(&"forced_harvest")).is_true()


func test_colheita_forcada_rende_mais_hoje_e_as_plantacoes_param_amanha() -> void:
	var colheita := _impulso(&"forced_harvest")
	coroa.use(&"forced_harvest", 3, unidades, rei)
	assert_float(coroa.yield_mult(3, &"farm")).is_equal(colheita.benefit_value)
	assert_float(coroa.yield_mult(4, &"farm")).is_equal(0.0)
	assert_float(coroa.yield_mult(4, &"fishery")).is_equal(1.0)
	assert_float(coroa.yield_mult(5, &"farm")).is_equal(1.0)


func test_chamada_as_armas_arma_os_vagabundos_e_a_producao_para_hoje() -> void:
	var livre := unidades.spawn(estado, Registry.entry(&"units", &"vagrant"), 0, 100.0)
	var arqueiro := unidades.spawn(estado, Registry.entry(&"units", &"archer"), 0, 120.0)
	coroa.use(&"call_to_arms", 2, unidades, rei)
	var i := unidades.index_of(livre)
	assert_str(String(unidades.data_ids[i])).is_equal("spearman")
	assert_int(unidades.owners[i]).is_equal(MEU)
	assert_int(unidades.owners[unidades.index_of(arqueiro)]).is_equal(0)
	assert_float(coroa.yield_mult(2, &"farm")).is_equal(0.0)
	assert_float(coroa.yield_mult(3, &"farm")).is_equal(1.0)


func test_vigilia_ninguem_foge_esta_noite_e_amanha_a_vida_cai() -> void:
	var tropa := unidades.spawn(estado, Registry.entry(&"units", &"archer"), MEU, 50.0)
	coroa.use(&"vigil", 5, unidades, rei)
	assert_bool(coroa.steadfast(5)).is_true()
	assert_bool(coroa.steadfast(6)).is_false()
	var i := unidades.index_of(tropa)
	var cheia := unidades.max_healths[i]
	coroa.dawn(6, unidades)
	var fator := _impulso(&"vigil").drawback_value
	assert_int(unidades.healths[i]).is_equal(ceili(cheia * fator))
	coroa.dawn(7, unidades)
	assert_int(unidades.healths[i]).is_equal(ceili(cheia * fator))


func test_o_save_guarda_o_dia_e_os_efeitos() -> void:
	coroa.use(&"forced_harvest", 3, unidades, rei)
	var copia := SimFactory.crown()
	copia.from_dict(coroa.to_dict())
	assert_bool(copia.use(&"vigil", 3, unidades, rei)).is_false()
	assert_float(copia.yield_mult(4, &"farm")).is_equal(0.0)
