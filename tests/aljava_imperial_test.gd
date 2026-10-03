# tests/aljava_imperial_test.gd — as flechas do Imperador Arqueiro (ADR 0052, Q-200).
#
# O dono, a 02/10/2026: "o escudeiro do Arqueiro fornece flechas enquanto recebe moedas
# do proprio imperador; sem moedas, nao ha novo fornecimento." As flechas ja carregadas
# continuam a servir; a banca do arco repoe as tropas e nao o imperador; o lote que nao
# cabe fica pago para a reposicao seguinte, e nunca se cobra sem espaco.
extends GdUnitTestSuite

const MEU := 1

var _estado := GameState.new()
var _u := UnitSystem.new()
var _s := Supply.new()


func before_test() -> void:
	_estado = GameState.new()
	_u = UnitSystem.new()
	_s = Supply.new()


func _dados(id: StringName) -> UnitData:
	return Registry.entry(&"units", id) as UnitData


func _imperador(flechas: int, moedas: int) -> int:
	var dados := _dados(&"archer_emperor")
	var id := _u.spawn(_estado, dados, MEU, 0.0)
	_s.arm(_u, _u.index_of(id), dados, flechas)
	_u.carried_coins[_u.index_of(id)] = moedas
	return _u.index_of(id)


func _lote() -> int:
	return RulesFactory.rules().arrows_per_coin


func test_o_imperador_comeca_com_as_flechas_iniciais_e_a_aljava_e_dele() -> void:
	var i := _imperador(12, 0)
	assert_int(_s.left(_u, i, _dados(&"archer_emperor"))).is_equal(12)
	assert_bool(_s.personal.has(_u.ids[i])).is_true()


func test_sem_moedas_nao_ha_flechas_novas_mas_as_carregadas_servem() -> void:
	var dados := _dados(&"archer_emperor")
	var i := _imperador(2, 0)
	assert_int(_s.refill(_u, i, dados, _lote())).is_equal(0)
	assert_int(_s.left(_u, i, dados)).is_equal(2)
	assert_bool(_s.can_shoot(_u, i, dados)).is_true()
	_s.shoot(_u, i, dados)
	_s.shoot(_u, i, dados)
	assert_bool(_s.can_shoot(_u, i, dados)).is_false()
	assert_int(_s.refill(_u, i, dados, _lote())).is_equal(0)
	assert_bool(_s.can_shoot(_u, i, dados)).is_false()


func test_uma_moeda_da_bolsa_dele_vale_um_lote() -> void:
	var dados := _dados(&"archer_emperor")
	var i := _imperador(0, 3)
	assert_int(_s.refill(_u, i, dados, _lote())).is_equal(1)
	assert_int(_u.carried_coins[i]).is_equal(2)
	assert_int(_s.left(_u, i, dados)).is_equal(_lote())


func test_sem_espaco_nao_se_cobra() -> void:
	var dados := _dados(&"archer_emperor")
	var i := _imperador(dados.ammo, 5)
	assert_int(_s.refill(_u, i, dados, _lote())).is_equal(0)
	assert_int(_u.carried_coins[i]).is_equal(5)


func test_o_que_nao_cabe_fica_pago_para_a_proxima() -> void:
	var dados := _dados(&"archer_emperor")
	var i := _imperador(dados.ammo - 2, 5)
	assert_int(_s.refill(_u, i, dados, _lote())).is_equal(1)
	assert_int(_s.left(_u, i, dados)).is_equal(dados.ammo)
	assert_int(int(_s.credit[_u.ids[i]])).is_equal(_lote() - 2)
	for _k in 4:
		_s.shoot(_u, i, dados)
	assert_int(_s.refill(_u, i, dados, _lote())).is_equal(0)
	assert_int(_u.carried_coins[i]).is_equal(4)
	assert_int(_s.left(_u, i, dados)).is_equal(dados.ammo)


func test_a_banca_do_arco_repoe_as_tropas_e_nao_o_imperador() -> void:
	var dados := _dados(&"archer_emperor")
	var i := _imperador(0, 0)
	var arqueiro := _u.spawn(_estado, _dados(&"archer"), MEU, 0.0)
	_s.shoot(_u, _u.index_of(arqueiro), _dados(&"archer"))
	var gasto := _s.restock(_u, MEU, 10, _lote())
	assert_int(gasto).is_equal(1)
	assert_int(_s.left(_u, i, dados)).is_equal(0)


func test_a_aljava_e_o_credito_voltam_do_save() -> void:
	var dados := _dados(&"archer_emperor")
	var i := _imperador(dados.ammo - 2, 5)
	_s.refill(_u, i, dados, _lote())
	var outra := Supply.new()
	outra.from_dict(_s.to_dict())
	assert_int(outra.left(_u, i, dados)).is_equal(_s.left(_u, i, dados))
	assert_dict(outra.credit).is_equal(_s.credit)
	assert_dict(outra.personal).is_equal(_s.personal)
