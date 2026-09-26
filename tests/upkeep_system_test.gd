# tests/upkeep_system_test.gd — a manutencao do §06, paga a alvorada (Q-124).
extends GdUnitTestSuite

const MEU := 1

var estado: GameState
var unidades: UnitSystem
var manutencao: UpkeepSystem
var economia: EconomySystem
var rei: int


func before_test() -> void:
	estado = GameState.new()
	unidades = UnitSystem.new()
	manutencao = UpkeepSystem.new(SimFactory.by_id(&"units"))
	economia = SimFactory.economy()
	rei = unidades.spawn(estado, Registry.entry(&"units", &"monarch"), MEU, 0.0)


func _tropas(id: StringName, quantas: int) -> Array[int]:
	var ids: Array[int] = []
	for _k in quantas:
		ids.append(unidades.spawn(estado, Registry.entry(&"units", id), MEU, 0.0))
	return ids


func test_ate_a_oitava_tropa_nao_se_paga_nada() -> void:
	_tropas(&"archer", SimFactory.curve().upkeep_free_troops)
	unidades.carried_coins[unidades.index_of(rei)] = 10
	assert_array(manutencao.dawn(unidades, rei, economia)).is_empty()
	assert_int(unidades.carried_coins[unidades.index_of(rei)]).is_equal(10)


func test_o_rei_e_o_escudeiro_nao_contam() -> void:
	_tropas(&"squire", 3)
	_tropas(&"archer", 2)
	assert_int(manutencao.troops(unidades, rei)).is_equal(2)


func test_a_fracao_passa_para_o_dia_seguinte() -> void:
	_tropas(&"archer", SimFactory.curve().upkeep_free_troops + 1)
	unidades.carried_coins[unidades.index_of(rei)] = 10
	manutencao.dawn(unidades, rei, economia)
	assert_int(unidades.carried_coins[unidades.index_of(rei)]).is_equal(10)
	manutencao.dawn(unidades, rei, economia)
	assert_int(unidades.carried_coins[unidades.index_of(rei)]).is_equal(9)


func test_sem_moedas_vai_a_mais_barata_sem_posto() -> void:
	var caras := _tropas(&"spearman", 10)
	var barato := _tropas(&"archer", 2)
	unidades.job_ids[unidades.index_of(barato[0])] = 0
	var eventos := manutencao.dawn(unidades, rei, economia)
	var foi: int = eventos[eventos.size() - 1][UpkeepSystem.UNIDADE]
	assert_int(foi).is_equal(barato[1])
	assert_int(unidades.owners[unidades.index_of(foi)]).is_equal(RecruitSystem.SEM_DONO)
	assert_int(caras.size()).is_equal(10)


func test_vai_no_save() -> void:
	manutencao.owed = 0.5
	var copia := UpkeepSystem.new(SimFactory.by_id(&"units"))
	copia.from_dict(manutencao.to_dict())
	assert_float(copia.owed).is_equal(0.5)
