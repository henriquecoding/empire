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


## Q-114 (o dono, 29/09/2026): o escudo do escudeiro leva os golpes dirigidos ao
## rei e a ele; a espada golpeia primeiro quem ataca.
func test_o_escudeiro_leva_o_golpe_do_rei_e_revida_com_a_espada() -> void:
	var dados := Registry.entry(&"units", &"squire") as UnitData
	var e := unidades.spawn(estado, dados, MEU, 1000.0 + 20.0)
	classes.squire_id = e  # o vinculo do Monarchy (ADR 0052)
	classes.watch(unidades, rei, false)
	assert_int(classes.squire_index(unidades)).is_equal(unidades.index_of(e))
	assert_int(classes.soak(unidades, rei, 4)).is_equal(4)
	classes.squire.arm(5)
	assert_int(classes.soak(unidades, rei, 4)).is_equal(0)
	assert_int(classes.soak(unidades, e, 4)).is_equal(0)
	assert_int(classes.riposte()).is_equal(0)
	classes.squire.take_loot(int(dados.ability_params[&"sword_coins"]))
	classes.soak(unidades, rei, 4)
	assert_int(classes.riposte()).is_equal(int(dados.ability_params[&"sword_damage"]))
	assert_int(classes.riposte()).is_equal(0)


func test_o_escudeiro_longe_do_rei_nao_lhe_apara_o_golpe() -> void:
	var dados := Registry.entry(&"units", &"squire") as UnitData
	classes.squire_id = unidades.spawn(estado, dados, MEU, 1000.0 + LONGE)
	classes.watch(unidades, rei, false)
	classes.squire.arm(5)
	var escudo := classes.squire.shield
	assert_int(classes.soak(unidades, rei, 4)).is_equal(4)
	assert_int(classes.squire.shield).is_equal(escudo)


func test_o_escudeiro_vai_a_frente_com_escudo_e_atras_sem_ele() -> void:
	var dados := Registry.entry(&"units", &"squire") as UnitData
	var e := unidades.spawn(estado, dados, MEU, 1000.0)
	classes.squire_id = e
	classes.watch(unidades, rei, false)
	var r := unidades.index_of(rei)
	var perto := classes.squire.escort_px()
	classes.escort(unidades, 1)
	assert_float(unidades.target_xs[unidades.index_of(e)]).is_equal(unidades.xs[r] - perto)
	classes.squire.arm(1)
	classes.escort(unidades, 1)
	assert_float(unidades.target_xs[unidades.index_of(e)]).is_equal(unidades.xs[r] + perto)


## ADR 0052 (MU-19): o escudeiro e o do vinculo; quem apanha moedas sem vinculo nao o e.
func test_sem_vinculo_um_coletor_de_moedas_nao_e_escudeiro() -> void:
	unidades.spawn(estado, Registry.entry(&"units", &"squire") as UnitData, MEU, 1000.0)
	classes.watch(unidades, rei, false)
	assert_int(classes.squire_index(unidades)).is_equal(ClassSystem.NENHUM)


## ADR 0052 (MU-22): a aura, as noites e a evolucao do Rei nao passam a Nia nem ao
## Arqueiro — com outro monarca no trono a classe do Rei fica parada.
func test_sem_o_rei_no_trono_nao_ha_aura_nem_evolucao() -> void:
	var tropa := _tropa(1000.0 + 10.0)
	classes.active = false
	classes.watch(unidades, rei, false)
	assert_float(classes.defense_of(unidades, unidades.index_of(tropa))).is_equal(0.0)
	classes.nights_defended = _monarca().evolve_condition_value
	assert_bool(classes.can_evolve(_monarca().evolve_seed_cost)).is_false()


func test_a_fase_2_investe_o_escudeiro_cavaleiro() -> void:
	classes.nights_defended = _monarca().evolve_condition_value
	estado.royal_seeds = _monarca().evolve_seed_cost
	assert_bool(classes.squire.knight).is_false()
	classes.evolve(estado)
	assert_bool(classes.squire.knight).is_true()
	var copia := ClassSystem.new(_monarca(), SimFactory.by_id(&"units"))
	copia.from_dict(classes.to_dict())
	assert_bool(copia.squire.knight).is_true()


func test_so_uma_classe_de_arco_marca_alvos() -> void:
	# §24: "Marcar alvo — so classe Arqueiro"; e o dono: "vale para a classe
	# arqueiro e para outras que podem ter uma gameplay parecida" (Q-086). Quem
	# marca e quem o classes.csv da o verbo mark_target, e o Monarca nao o tem.
	var monarca := ClassSystem.new(Registry.entry(&"classes", &"monarch") as ClassData)
	var arqueiro := ClassSystem.new(Registry.entry(&"classes", &"archer") as ClassData)
	assert_bool(monarca.marks()).is_false()
	assert_bool(arqueiro.marks()).is_true()
	for recurso in Registry.entries(&"classes"):
		var dados := recurso as ClassData
		var marca := ClassSystem.new(dados).marks()
		assert_bool(marca).override_failure_message(String(dados.id)).is_equal(
			dados.verb == &"mark_target"
		)
