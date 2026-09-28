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


# ─── O preco (Q-014, o sistema que o dono pediu) ─────────────────────────────


func _curva() -> EconomyCurve:
	return Registry.entry(&"economy", &"curve") as EconomyCurve


func test_o_preco_do_dia_1_e_a_base_da_tabela() -> void:
	assert_int(coroa.price(&"vigil", 1)).is_equal(_impulso(&"vigil").coin_cost)


func test_o_preco_cresce_com_a_producao() -> void:
	# Ao ritmo do income_growth do §06: custa sempre o mesmo em dias de trabalho.
	var base := _impulso(&"royal_pardon").coin_cost
	var esperado := roundi(base * pow(_curva().income_growth, 9))
	assert_int(coroa.price(&"royal_pardon", 10)).is_equal(esperado)
	assert_int(coroa.price(&"royal_pardon", 10)).is_greater(base)


func test_o_tirano_paga_metade() -> void:
	# §15: "os impulsos reais custam metade". O perfil e o da gama da ganancia.
	var tirano := Registry.entry(&"crown/greed", &"tyrant") as GreedProfile
	var perfil := RulesFactory.impulse_cost_mult(tirano.greed_range.x)
	assert_float(perfil).is_equal(0.5)
	assert_float(RulesFactory.impulse_cost_mult(27)).is_equal(1.0)
	var base := _impulso(&"royal_pardon").coin_cost
	assert_int(coroa.price(&"royal_pardon", 1, perfil)).is_equal(roundi(base * perfil))


func test_repetir_o_mesmo_decreto_sai_mais_caro_e_o_reino_esquece() -> void:
	var c := _curva()
	assert_bool(coroa.use(&"vigil", 1, unidades, rei)).is_true()
	var base := _impulso(&"vigil").coin_cost
	var dia2 := roundi(base * c.income_growth * c.impulse_repeat_mult)
	assert_int(coroa.price(&"vigil", 2)).is_equal(dia2)
	# Outro decreto nao se lembra deste.
	var outro := _impulso(&"forced_harvest").coin_cost
	assert_int(coroa.price(&"forced_harvest", 2)).is_equal(roundi(outro * c.income_growth))
	# Passados os dias de memoria, volta ao preco do dia.
	var longe := 2 + c.impulse_repeat_days
	coroa.dawn(longe, unidades)
	var so_o_dia := roundi(base * pow(c.income_growth, longe - 1))
	assert_int(coroa.price(&"vigil", longe)).is_equal(so_o_dia)


func test_cobra_o_preco_de_hoje_e_ele_vai_no_save() -> void:
	unidades.carried_coins[unidades.index_of(rei)] = 100
	var preco := coroa.price(&"vigil", 5)
	assert_bool(coroa.use(&"vigil", 5, unidades, rei, preco)).is_true()
	assert_int(_saco()).is_equal(100 - preco)
	var outra := SimFactory.crown()
	outra.from_dict(coroa.to_dict())
	assert_int(outra.price(&"vigil", 6)).is_equal(coroa.price(&"vigil", 6))
