# tests/fundacao_do_reino_test.gd — a fundacao do reino, pelo jogo inteiro (ADR 0059).
#
# O dono, a 03/10/2026, sobre o plano do reino: *«aplique esse relatorio»*. O monarca
# chega a uma Clareira com dois trabalhadores, um construtor pioneiro e a companhia, ha
# uma carroca de provisoes ao pe do marco, e a primeira moeda que importa funda o reino.
extends GdUnitTestSuite

const SEMENTE := 20261003
const PASSO := 1.0 / 30.0


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(SEMENTE)
	Greybox.build()


func after_test() -> void:
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _rei() -> int:
	return SimLoop.units.index_of(SimLoop.king_id)


func _sede() -> BuildSlot:
	return RealmLadder.seat(SimLoop.builds)


func _obra(kind: StringName) -> BuildSlot:
	for vaga in SimLoop.builds.slots:
		if vaga.kind == kind:
			return vaga
	return null


func _passos(n: int) -> void:
	for _k in n:
		SimLoop.step(PASSO)


## O rei larga `n` moedas em `x`, parado, e espera que assentem.
func _largar_em(x: float, n: int) -> void:
	var i := _rei()
	SimLoop.units.xs[i] = x
	SimLoop.units.clear_target(SimLoop.king_id)
	SimLoop.units.carried_coins[i] = maxi(SimLoop.units.carried_coins[i], n)
	for _k in n:
		var args := {&"x": x, &"band": Band.Kind.SURFACE, &"amount": 1}
		args[&"source"] = Verbs.JOGADOR
		SimLoop.intents.queue(IntentQueue.Kind.DROP_COIN, args)
		_passos(20)


func test_o_reino_comeca_numa_clareira_por_fundar() -> void:
	var sede := _sede()
	assert_object(sede).is_not_null()
	assert_int(sede.level).is_equal(RealmLadder.CLAREIRA)
	assert_bool(sede.standing()).is_false()
	assert_bool(Defeat.happened()).is_false()
	_passos(30)
	assert_bool(Defeat.happened()).is_false()


func test_a_chegada_traz_o_pioneiro_e_a_carroca() -> void:
	var dono := SimLoop.units.owners[_rei()]
	var construtores := 0
	for i in SimLoop.units.count():
		if SimLoop.units.data_ids[i] == FoundationWatch.CONSTRUTOR:
			construtores += 1 if SimLoop.units.owners[i] == dono else 0
	assert_int(construtores).is_equal(RulesFactory.rules().founder_pioneers)
	assert_int(SimLoop.seat.cart_coins).is_equal(RulesFactory.rules().founder_provisions)


func test_o_rei_leva_a_carroca_ao_passar_por_ela() -> void:
	var i := _rei()
	var antes := SimLoop.units.carried_coins[i]
	SimLoop.units.xs[i] = SimLoop.seat.cart_x
	SimLoop.units.clear_target(SimLoop.king_id)
	_passos(2)
	var regras := RulesFactory.rules()
	assert_int(SimLoop.units.carried_coins[i]).is_equal(antes + regras.founder_provisions)
	assert_int(SimLoop.seat.cart_coins).is_equal(0)


func test_antes_de_fundar_o_canteiro_nao_aceita_moeda() -> void:
	var canteiro := _obra(&"farm")
	_largar_em(canteiro.x, 1)
	assert_int(canteiro.paid).is_equal(0)
	assert_int(int(canteiro.state)).is_equal(int(BuildSlot.State.EMPTY))


func test_fundar_custa_duas_moedas_e_quem_esta_la_levanta_o_acampamento() -> void:
	var sede := _sede()
	_largar_em(sede.x, sede.next_cost())
	assert_bool(sede.state in [BuildSlot.State.SCAFFOLD, BuildSlot.State.BUILDING]).is_true()
	_passos(ceili(sede.works[0] / PASSO) + 30)
	assert_int(sede.level).is_equal(RealmLadder.FUNDADO)
	assert_bool(sede.standing()).is_true()
	assert_int(sede.health).is_equal(sede.max_health())
	assert_float(sede.width).is_equal(sede.widths[RealmLadder.FUNDADO])


## A bancada fundadora: a fundacao ergue a banca do arco, uma vez e sem moeda.
func test_a_fundacao_ergue_a_banca_do_arco() -> void:
	var banca := _obra(FoundationWatch.BANCA)
	assert_bool(banca.standing()).is_false()
	var sede := _sede()
	_largar_em(sede.x, sede.next_cost())
	_passos(ceili(sede.works[0] / PASSO) + 30)
	assert_bool(banca.standing()).is_true()
	assert_int(banca.paid).is_equal(0)


func test_o_acampamento_abre_o_canteiro_e_nao_a_casa_de_treino() -> void:
	_sede().raise_to(RealmLadder.FUNDADO)
	var canteiro: BuildSlot = null
	for vaga in SimLoop.builds.slots:
		if vaga.kind == &"farm" and RealmGrowth.visible(SimLoop.builds, vaga):
			canteiro = vaga
	_largar_em(canteiro.x, canteiro.next_cost())
	assert_bool(canteiro.state != BuildSlot.State.EMPTY).is_true()
	var casa := _obra(&"training_house")
	_largar_em(casa.x, 1)
	assert_int(casa.paid).is_equal(0)
	assert_bool(RealmGrowth.visible(SimLoop.builds, casa)).is_false()


func test_o_povoado_abre_a_casa_de_treino() -> void:
	_sede().raise_to(2)
	var casa := _obra(&"training_house")
	for muro in SimLoop.builds.slots:
		if muro.two_paths() and muro.x < SimLoop.core_x:
			muro.raise_to(1)
	_largar_em(casa.x, 1)
	assert_int(casa.paid).is_equal(1)


## Sem sede nao ha lareira: o crepusculo nao come a bolsa do monarca.
func test_sem_sede_a_lareira_nao_cobra() -> void:
	var i := _rei()
	SimLoop.units.carried_coins[i] = 20
	SimLoop.night.dark.kindle()
	assert_int(SimLoop.units.carried_coins[i]).is_equal(20)
	assert_bool(SimLoop.night.dark.hearth.lit).is_false()
	_sede().raise_to(RealmLadder.FUNDADO)
	SimLoop.night.dark.kindle()
	assert_bool(SimLoop.night.dark.hearth.lit).is_true()


## A moeda no marco paga a sede, mesmo com o monarca a poder evoluir; so com o monarca
## escolhido pelo Verbo 2 e que ela o evolui (plano §3.6, §23.2).
func test_a_moeda_no_marco_e_da_sede_ate_o_jogador_escolher_o_monarca() -> void:
	var classe := Registry.entry(&"classes", &"monarch") as ClassData
	SimLoop.field.classes.nights_defended = classe.evolve_condition_value
	SimLoop.state.royal_seeds = classe.evolve_seed_cost
	var sede := _sede()
	_largar_em(sede.x, 1)
	assert_int(SimLoop.field.classes.phase).is_equal(1)
	assert_int(sede.paid).is_equal(1)
	SimLoop.intents.queue(IntentQueue.Kind.ASSUME, {})
	_passos(1)
	assert_bool(SimLoop.seat.monarch_aim).is_true()
	_largar_em(sede.x, 1)
	assert_int(SimLoop.field.classes.phase).is_equal(2)
	assert_int(sede.paid).is_equal(1)


func test_a_sede_e_a_carroca_vao_no_save_e_nao_voltam_ao_carregar() -> void:
	var i := _rei()
	SimLoop.units.xs[i] = SimLoop.seat.cart_x
	_passos(2)
	_sede().raise_to(2)
	var mundo := SimLoop.world()
	SimLoop.load_world(mundo)
	assert_int(_sede().level).is_equal(2)
	assert_float(_sede().width).is_equal(_sede().widths[2])
	assert_int(SimLoop.seat.cart_coins).is_equal(0)


## Um save de antes da fundacao trazia o castelo: e a Fortaleza, com a vida que tinha, e
## a sede fica marcada como herdada (plano §27.1).
func test_o_castelo_de_um_save_antigo_e_a_fortaleza() -> void:
	var antigo := {
		&"save_version": SaveMigrations.ANTES_DA_FUNDACAO,
		&"state": {&"day": 3},
		&"world": {&"builds": [_castelo_antigo()]},
	}
	var d := SaveMigrations.migrate(antigo)
	var nucleo: Dictionary = d[&"world"][&"builds"][0]
	assert_int(int(nucleo[&"level"])).is_equal(_sede().costs.size())
	assert_int(int(nucleo[&"health"])).is_equal(640)
	assert_bool(d[&"world"][&"seat"][&"inherited"]).is_true()
	SimLoop.load_world(d[&"world"])
	assert_bool(_sede().standing()).is_true()
	assert_float(_sede().width).is_equal(float(_sede().widths[_sede().costs.size()]))
	assert_bool(SimLoop.seat.inherited).is_true()


## O nucleo como um save de antes o gravava: o castelo de pe, no nivel 1 da escada antiga.
func _castelo_antigo() -> Dictionary:
	var castelo := {&"id": 0, &"kind": &"core", &"level": 1, &"health": 640}
	castelo[&"state"] = int(BuildSlot.State.DAMAGED)
	return castelo


## Os tres monarcas chegam com o mesmo pacote: a carroca, o pioneiro e a sede por fundar
## (plano §21.1). A escolha do monarca nao repoe nem tira nada (RG-02).
func test_os_tres_monarcas_chegam_com_o_mesmo_pacote() -> void:
	for perfil in Registry.ids(&"monarchs"):
		SimLoop.stop()
		EventBus.reset()
		SimLoop.start(SEMENTE)
		Greybox.build()
		assert_bool(MonarchWatch.begin(StringName(perfil))).is_true()
		var regras := RulesFactory.rules()
		assert_int(SimLoop.seat.cart_coins).is_equal(regras.founder_provisions)
		assert_int(_sede().level).is_equal(RealmLadder.CLAREIRA)
		var dono := SimLoop.units.owners[_rei()]
		var construtores := 0
		for i in SimLoop.units.count():
			var meu := SimLoop.units.owners[i] == dono
			construtores += (
				1 if meu and SimLoop.units.data_ids[i] == FoundationWatch.CONSTRUTOR else 0
			)
		assert_int(construtores).override_failure_message(perfil).is_equal(regras.founder_pioneers)
