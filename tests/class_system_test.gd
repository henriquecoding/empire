# tests/class_system_test.gd — a classe do Monarca (§08): a aura, as noites e a evolucao.
#
# "Tanque. +10% defesa as tropas num raio. [...] O boost passa a +25% e aplica-se
# ao imperio inteiro." Os numeros sao os de classes.csv; nenhum esta aqui. A
# leitura de "defesa" como menos dano recebido e a mesma da Q-109 (o construtor e
# as muralhas), e as escolhas que o dossie nao faz estao na Q-114.
extends GdUnitTestSuite

const MEU := 1
const LONGE := 5000.0

var estado: GameState
var unidades: UnitSystem
var classes: ClassSystem
var rei: int


func before_test() -> void:
	estado = GameState.new()
	unidades = UnitSystem.new()
	classes = ClassSystem.new(_monarca(), SimFactory.by_id(&"units"))
	rei = unidades.spawn(estado, Registry.entry(&"units", &"monarch"), MEU, 1000.0)


func _monarca() -> ClassData:
	return Registry.entry(&"classes", &"monarch") as ClassData


func _tropa(x: float, dono: int = MEU) -> int:
	return unidades.spawn(estado, Registry.entry(&"units", &"archer"), dono, x)


func _raio() -> float:
	return float(_monarca().phase1_params[&"radius"])


func test_a_aura_so_protege_as_tuas_tropas_perto_do_rei() -> void:
	var defesa := float(_monarca().phase1_params[&"defense"])
	var perto := _tropa(1000.0 + _raio() * 0.5)
	var longe := _tropa(1000.0 + _raio() * 2.0)
	var alheia := _tropa(1000.0 + 10.0, RecruitSystem.SEM_DONO)
	classes.watch(unidades, rei, false)
	assert_float(classes.defense_of(unidades, unidades.index_of(perto))).is_equal(defesa)
	assert_float(classes.defense_of(unidades, unidades.index_of(longe))).is_equal(0.0)
	assert_float(classes.defense_of(unidades, unidades.index_of(alheia))).is_equal(0.0)
	# O rei e quem da a aura, nao quem a recebe.
	assert_float(classes.defense_of(unidades, unidades.index_of(rei))).is_equal(0.0)


func test_a_aura_nao_passa_de_faixa() -> void:
	var baixo := _tropa(1000.0)
	unidades.bands[unidades.index_of(baixo)] = Band.Kind.UNDERGROUND
	classes.watch(unidades, rei, false)
	assert_float(classes.defense_of(unidades, unidades.index_of(baixo))).is_equal(0.0)


func test_a_fraccao_poupada_guarda_se_de_golpe_para_golpe() -> void:
	var tropa := _tropa(1000.0)
	classes.watch(unidades, rei, false)
	var defesa := float(_monarca().phase1_params[&"defense"])
	# Dez golpes de 4 com 10% poupam 4 de vida, e nao zero de cada vez (Q-109).
	var total := 0
	for _g in 10:
		total += classes.soak(unidades, tropa, 4)
	assert_int(total).is_equal(40 - roundi(40 * defesa))
	# Longe do rei o golpe passa inteiro.
	unidades.xs[unidades.index_of(tropa)] = LONGE
	assert_int(classes.soak(unidades, tropa, 4)).is_equal(4)


func test_uma_noite_so_conta_com_o_rei_la_e_uma_tropa_a_combater() -> void:
	var tropa := _tropa(1000.0 + 10.0)
	classes.watch(unidades, rei, true)
	classes.dawn()
	assert_int(classes.nights_defended).is_equal(0)
	unidades.states[unidades.index_of(tropa)] = UnitFsm.State.FIGHT
	# De dia um combate nao e uma noite defendida.
	classes.watch(unidades, rei, false)
	classes.dawn()
	assert_int(classes.nights_defended).is_equal(0)
	classes.watch(unidades, rei, true)
	classes.dawn()
	assert_int(classes.nights_defended).is_equal(1)
	# Longe do rei, a mesma luta nao e em pessoa.
	unidades.xs[unidades.index_of(tropa)] = LONGE
	classes.watch(unidades, rei, true)
	classes.dawn()
	assert_int(classes.nights_defended).is_equal(1)


func test_evoluir_pede_a_semente_e_o_feito_e_gasta_a_semente() -> void:
	var dados := _monarca()
	assert_bool(classes.can_evolve(dados.evolve_seed_cost)).is_false()
	classes.nights_defended = dados.evolve_condition_value
	assert_bool(classes.can_evolve(dados.evolve_seed_cost - 1)).is_false()
	assert_bool(classes.can_evolve(dados.evolve_seed_cost)).is_true()
	estado.royal_seeds = dados.evolve_seed_cost
	assert_bool(classes.evolve(estado)).is_true()
	assert_int(estado.royal_seeds).is_equal(0)
	assert_int(classes.phase).is_equal(2)
	# Duas fases (§08): nao ha terceira.
	estado.royal_seeds = dados.evolve_seed_cost
	assert_bool(classes.evolve(estado)).is_false()
	assert_int(estado.royal_seeds).is_equal(dados.evolve_seed_cost)


func test_evoluida_a_defesa_e_do_imperio_inteiro() -> void:
	var longe := _tropa(LONGE)
	classes.nights_defended = _monarca().evolve_condition_value
	estado.royal_seeds = _monarca().evolve_seed_cost
	classes.evolve(estado)
	classes.watch(unidades, rei, false)
	var defesa := float(_monarca().phase2_params[&"defense"])
	assert_float(classes.defense_of(unidades, unidades.index_of(longe))).is_equal(defesa)


func test_a_fase_e_as_noites_vao_no_save() -> void:
	classes.nights_defended = 3
	classes.phase = 2
	var copia := ClassSystem.new(_monarca())
	copia.from_dict(classes.to_dict())
	assert_int(copia.nights_defended).is_equal(3)
	assert_int(copia.phase).is_equal(2)


func test_o_save_leva_o_que_muda_o_proximo_golpe() -> void:
	var tropa := _tropa(1000.0)
	classes.watch(unidades, rei, false)
	var seguido: Array[int] = []
	for _g in 3:
		seguido.append(classes.soak(unidades, tropa, 4))
	var copia := ClassSystem.new(_monarca())
	copia.from_dict(classes.to_dict())
	# Sem watch() depois de carregar: o proximo golpe e igual nos dois.
	assert_int(copia.soak(unidades, tropa, 4)).is_equal(classes.soak(unidades, tropa, 4))


func test_o_escudeiro_entrega_ao_rei_o_que_apanhou_quando_esta_perto() -> void:
	var dados := Registry.entry(&"units", &"squire") as UnitData
	var escudeiro := unidades.spawn(estado, dados, MEU, 1000.0 + 20.0)
	var e := unidades.index_of(escudeiro)
	var r := unidades.index_of(rei)
	unidades.carried_coins[e] = 3
	var antes := unidades.carried_coins[r]
	assert_int(classes.hand_over(unidades, rei, 64.0)).is_equal(3)
	assert_int(unidades.carried_coins[e]).is_equal(0)
	assert_int(unidades.carried_coins[r]).is_equal(antes + 3)
	# Longe, fica com elas; e um arqueiro com moedas nao e escudeiro.
	unidades.carried_coins[e] = 2
	unidades.xs[e] = LONGE
	assert_int(classes.hand_over(unidades, rei, 64.0)).is_equal(0)
	var arqueiro := unidades.index_of(_tropa(1000.0))
	unidades.carried_coins[arqueiro] = 2
	assert_int(classes.hand_over(unidades, rei, 64.0)).is_equal(0)


func test_o_saco_cheio_do_rei_nao_recebe_mais() -> void:
	var dados := Registry.entry(&"units", &"squire") as UnitData
	var e := unidades.index_of(unidades.spawn(estado, dados, MEU, 1000.0))
	var r := unidades.index_of(rei)
	unidades.carried_coins[r] = unidades.coin_capacities[r] - 1
	unidades.carried_coins[e] = 4
	assert_int(classes.hand_over(unidades, rei, 64.0)).is_equal(1)
	assert_int(unidades.carried_coins[e]).is_equal(3)
