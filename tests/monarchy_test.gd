# tests/monarchy_test.gd — quem reina, com que perfil, e o companheiro dele (ADR 0052).
#
# "Cada escolha reune identidade, combate, autoridade da coroa e um companheiro
# proprio" (o dono, 02/10/2026). O vinculo e por id (plano MU-19): coletar moedas nao
# faz de ninguem escudeiro; um companheiro morto fica perdido; o herdeiro herda o vivo.
extends GdUnitTestSuite

const MEU := 1
const X := 1000.0

var estado: GameState
var unidades: UnitSystem
var reino: Monarchy
var rei: int
var escudeiro: int


func before_test() -> void:
	estado = GameState.new()
	unidades = UnitSystem.new()
	reino = Monarchy.new()
	rei = unidades.spawn(estado, _corpo(&"monarch"), MEU, X)
	escudeiro = unidades.spawn(estado, _corpo(&"squire"), MEU, X + 10.0)


func _corpo(id: StringName) -> UnitData:
	return Registry.entry(&"units", id) as UnitData


func _escolher(perfil: StringName) -> bool:
	var dados := Registry.entry(&"monarchs", perfil) as MonarchData
	return reino.begin(
		unidades, rei, escudeiro, perfil, _corpo(dados.unit), _corpo(dados.companion)
	)


func test_escolher_nia_muda_o_corpo_do_rei_e_do_companheiro_sem_nascer_ninguem() -> void:
	var antes := unidades.count()
	assert_bool(_escolher(&"nia")).is_true()
	assert_int(unidades.count()).is_equal(antes)
	var r := unidades.index_of(rei)
	assert_str(String(unidades.data_ids[r])).is_equal("nia")
	assert_int(unidades.healths[r]).is_equal(_corpo(&"nia").max_health)
	assert_float(unidades.speeds[r]).is_equal(_corpo(&"nia").move_speed)
	var e := unidades.index_of(escudeiro)
	assert_str(String(unidades.data_ids[e])).is_equal("bard_banner")
	assert_int(reino.companion_index(unidades, rei)).is_equal(e)
	assert_str(String(reino.profile)).is_equal("nia")


func test_a_escolha_e_uma_vez_so() -> void:
	assert_bool(_escolher(&"archer_emperor")).is_true()
	assert_bool(_escolher(&"nia")).is_false()
	assert_str(String(unidades.data_ids[unidades.index_of(rei)])).is_equal("archer_emperor")


func test_o_rei_conserva_o_corpo_e_o_escudeiro() -> void:
	assert_bool(_escolher(&"monarch")).is_true()
	assert_str(String(unidades.data_ids[unidades.index_of(rei)])).is_equal("monarch")
	assert_int(reino.companion_index(unidades, rei)).is_equal(unidades.index_of(escudeiro))


func test_coletar_moedas_nao_faz_de_ninguem_companheiro() -> void:
	_escolher(&"nia")
	var outro := unidades.spawn(estado, _corpo(&"squire"), MEU, X)
	assert_int(reino.companion_index(unidades, rei)).is_not_equal(unidades.index_of(outro))


func test_o_companheiro_so_esta_a_mao_vivo_na_faixa_e_perto() -> void:
	_escolher(&"nia")
	assert_int(reino.at_hand(unidades, rei, 50.0)).is_equal(unidades.index_of(escudeiro))
	unidades.xs[unidades.index_of(escudeiro)] = X + 500.0
	assert_int(reino.at_hand(unidades, rei, 50.0)).is_equal(Monarchy.NENHUM)
	unidades.xs[unidades.index_of(escudeiro)] = X
	unidades.bands[unidades.index_of(escudeiro)] = Band.Kind.UNDERGROUND
	assert_int(reino.at_hand(unidades, rei, 50.0)).is_equal(Monarchy.NENHUM)


func test_o_companheiro_morto_fica_perdido_e_nao_volta() -> void:
	_escolher(&"nia")
	reino.fund(escudeiro, 3, 5)
	unidades.states[unidades.index_of(escudeiro)] = UnitFsm.State.DEAD
	reino.watch(unidades, 0.1)
	assert_int(reino.companion_index(unidades, rei)).is_equal(Monarchy.NENHUM)
	assert_int(int(reino.lost.get(rei, -1))).is_equal(escudeiro)
	assert_int(reino.budget_of(escudeiro)).is_equal(0)


func test_o_herdeiro_herda_o_companheiro_vivo_e_a_linhagem_conta() -> void:
	_escolher(&"nia")
	var herdeiro := unidades.spawn(estado, _corpo(&"nia"), MEU, X)
	reino.crown(rei, herdeiro)
	assert_int(reino.generation).is_equal(1)
	assert_int(reino.companion_index(unidades, herdeiro)).is_equal(unidades.index_of(escudeiro))
	assert_int(reino.companion_index(unidades, rei)).is_equal(Monarchy.NENHUM)


func test_o_orcamento_tem_teto_e_paga_antes_da_bolsa() -> void:
	_escolher(&"nia")
	var r := unidades.index_of(rei)
	unidades.carried_coins[r] = 4
	assert_int(reino.fund(escudeiro, 7, 5)).is_equal(5)
	assert_int(reino.budget_of(escudeiro)).is_equal(5)
	assert_bool(reino.charge(unidades, r, escudeiro, 3)).is_true()
	assert_int(reino.budget_of(escudeiro)).is_equal(2)
	assert_int(unidades.carried_coins[r]).is_equal(4)
	assert_bool(reino.charge(unidades, r, escudeiro, 3)).is_true()
	assert_int(reino.budget_of(escudeiro)).is_equal(0)
	assert_int(unidades.carried_coins[r]).is_equal(3)


func test_sem_dinheiro_nao_se_debita_nada() -> void:
	_escolher(&"nia")
	var r := unidades.index_of(rei)
	unidades.carried_coins[r] = 1
	reino.fund(escudeiro, 1, 5)
	assert_bool(reino.charge(unidades, r, escudeiro, 3)).is_false()
	assert_int(reino.budget_of(escudeiro)).is_equal(1)
	assert_int(unidades.carried_coins[r]).is_equal(1)


func test_o_incentivo_vale_o_maior_e_acaba() -> void:
	_escolher(&"nia")
	var tropa := unidades.spawn(estado, _corpo(&"archer"), MEU, X + 20.0)
	var alheia := unidades.spawn(estado, _corpo(&"archer"), RecruitSystem.SEM_DONO, X + 20.0)
	var b := unidades.index_of(escudeiro)
	assert_int(reino.encourage(unidades, b, 100.0, 0.1, 2.0)).is_equal(3)
	reino.encourage(unidades, b, 100.0, 0.05, 2.0)
	var t := unidades.index_of(tropa)
	var base := unidades.speeds[t]
	reino.boost(unidades)
	assert_float(unidades.speeds[t]).is_equal_approx(base * 1.1, 0.001)
	assert_float(unidades.speeds[unidades.index_of(alheia)]).is_equal(_corpo(&"archer").move_speed)
	reino.watch(unidades, 2.5)
	assert_bool(reino.encouraged.has(tropa)).is_false()


func test_tudo_volta_igual_do_save() -> void:
	_escolher(&"nia")
	reino.fund(escudeiro, 2, 5)
	reino.encourage(unidades, unidades.index_of(escudeiro), 100.0, 0.1, 5.0)
	var outro := Monarchy.new()
	outro.from_dict(reino.to_dict())
	assert_str(String(outro.profile)).is_equal("nia")
	assert_int(outro.companion_index(unidades, rei)).is_equal(unidades.index_of(escudeiro))
	assert_int(outro.budget_of(escudeiro)).is_equal(2)
	assert_dict(outro.encouraged).is_equal(reino.encouraged)


func test_um_save_de_antes_e_o_rei() -> void:
	var outro := Monarchy.new()
	outro.from_dict({})
	assert_str(String(outro.profile)).is_equal("")
	assert_str(String(outro.current())).is_equal("monarch")
