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
	manutencao = UpkeepSystem.new(SimFactory.by_id(&"units"), SimFactory.curve())
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


## Q-144 (o dono, 29/09/2026): um dia sem soldo nao leva ninguem — fica em atraso.
func test_um_dia_sem_moedas_fica_em_atraso_e_ninguem_se_vai() -> void:
	_tropas(&"archer", 12)
	assert_array(_foram(manutencao.dawn(unidades, rei, economia, 2))).is_empty()
	assert_int(manutencao.arrears()).is_equal(int(economia.upkeep(12)))


func test_o_atraso_paga_se_primeiro() -> void:
	_tropas(&"archer", 12)
	manutencao.dawn(unidades, rei, economia, 2)
	var r := unidades.index_of(rei)
	unidades.carried_coins[r] = 10
	manutencao.dawn(unidades, rei, economia, 3)
	assert_int(unidades.carried_coins[r]).is_equal(10 - 2 * int(economia.upkeep(12)))
	assert_int(manutencao.arrears()).is_equal(0)


## Para la da tolerancia vai-se quem o excesso paga, a mais barata sem posto
## primeiro — proporcional ao defice, e nao uma por dia.
func test_sem_moedas_vai_quem_o_excesso_paga_a_mais_barata_sem_posto() -> void:
	var caras := _tropas(&"spearman", 10)
	var barato := _tropas(&"archer", 2)
	unidades.job_ids[unidades.index_of(barato[0])] = 0
	manutencao.dawn(unidades, rei, economia, 2)
	var foram := _foram(manutencao.dawn(unidades, rei, economia, 3))
	assert_int(foram[0]).is_equal(barato[1])
	assert_int(foram.size()).is_greater(1)
	for quem in foram:
		assert_int(unidades.owners[unidades.index_of(quem)]).is_equal(RecruitSystem.SEM_DONO)
	var conta := economia.upkeep(12)
	assert_float(manutencao.owed).is_less_equal(conta * manutencao.grace_days + 1.0)
	assert_int(caras.size()).is_equal(10)


## Quem desertou so volta a poder ser recrutado passados os dias de descanso.
func test_quem_desertou_descansa_antes_de_voltar() -> void:
	_tropas(&"archer", 12)
	manutencao.dawn(unidades, rei, economia, 2)
	var foi: int = _foram(manutencao.dawn(unidades, rei, economia, 3))[0]
	var recrutas := RulesFactory.recruits(estado)
	recrutas.resting = manutencao.resting
	estado.day = 3
	assert_bool(recrutas.hire(unidades, foi, MEU, 99, 1)).is_false()
	estado.day = 3 + manutencao.rest_days
	assert_bool(recrutas.hire(unidades, foi, MEU, 99, 1)).is_true()


func _foram(eventos: Array[Dictionary]) -> Array[int]:
	var ids: Array[int] = []
	for e in eventos:
		if e[UpkeepSystem.CHAVE] == UpkeepSystem.EV_FOI:
			ids.append(e[UpkeepSystem.UNIDADE])
	return ids


func test_vai_no_save() -> void:
	manutencao.owed = 0.5
	manutencao.resting[7] = 4
	var copia := UpkeepSystem.new(SimFactory.by_id(&"units"))
	copia.from_dict(manutencao.to_dict())
	assert_float(copia.owed).is_equal(0.5)
	assert_int(int(copia.resting[7])).is_equal(4)
