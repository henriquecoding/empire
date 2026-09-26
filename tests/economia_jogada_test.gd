# tests/economia_jogada_test.gd — a economia que o CI afina e a que o jogo corre
# passam a ser a mesma (D7 da auditoria de 26/09; §06, §15, AUD-02).
#
# O modelo do §06 dava 21→33 moedas/dia (dias 1–5) e o jogo produzia 17 fixas:
# sem crescimento, sem ganancia, sem manutencao. A partida passa a aplicar os tres,
# e o dia da asfixia mede-se sobre as obras que o greybox tem.
extends GdUnitTestSuite

const STEP := 1.0 / 30.0
const SEMENTE := 20260926
const METADE := 0.5
## Uma moeda por fonte e por dia de folga: a materia fica em stock entre fases e
## o que um dia nao fecha passa ao seguinte.
const FOLGA_POR_FONTE := 1

var _producao := 0
var _gasto := {}


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	EventBus.coin_dropped.connect(_caiu)
	EventBus.coin_spent.connect(_gastou)
	SimLoop.start(SEMENTE)
	Greybox.build()


func after_test() -> void:
	EventBus.coin_dropped.disconnect(_caiu)
	EventBus.coin_spent.disconnect(_gastou)
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _caiu(_x: float, _f: int, quanto: int, origem: StringName) -> void:
	if origem == EventRelay.FONTE_PRODUCAO:
		_producao += quanto


func _gastou(quanto: int, porque: StringName) -> void:
	_gasto[porque] = int(_gasto.get(porque, 0)) + quanto


func _curva() -> EconomyCurve:
	return SimFactory.curve()


func _de_pe(kinds: Array) -> Array[BuildSlot]:
	var saida: Array[BuildSlot] = []
	for obra in SimLoop.builds.slots:
		if obra.kind in kinds:
			obra.level = 1
			obra.state = BuildSlot.State.DONE
			obra.health = obra.max_health()
			saida.append(obra)
	return saida


func _um_dia() -> int:
	_producao = 0
	var dia := ClockService.clock.day
	while ClockService.clock.day == dia:
		SimLoop.units.set_target_x(SimLoop.king_id, SimLoop.core_x)
		SimLoop.step(STEP)
	return _producao


func _rendimento(obras: Array[BuildSlot]) -> float:
	var total := 0.0
	for obra in obras:
		total += obra.yield_per_day
	return total


func test_a_ganancia_nasce_no_perfil_do_inicio_e_vai_no_save() -> void:
	var perfil := Registry.entry(&"crown/greed", _curva().start_greed_profile) as GreedProfile
	assert_int(SimLoop.state.greed).is_between(perfil.greed_range.x, perfil.greed_range.y)
	var outra := SimLoop.state.greed
	SimLoop.start(SEMENTE)
	assert_int(SimLoop.state.greed).is_equal(outra)
	assert_int(GameState.from_dict(SimLoop.state.to_dict()).greed).is_equal(outra)


func test_a_producao_cresce_ao_ritmo_da_base_construida() -> void:
	SimLoop.state.greed = 0
	var obras := _de_pe([&"henhouse", &"fishery"])
	var base := _rendimento(obras)
	for dia in range(1, 4):
		var esperado := base * pow(_curva().income_growth, dia - 1)
		assert_float(float(_um_dia())).is_equal_approx(esperado, obras.size() * FOLGA_POR_FONTE)


func test_a_ganancia_leva_a_parte_dela() -> void:
	var obras := _de_pe([&"henhouse", &"fishery"])
	SimLoop.state.greed = 50
	var com := _um_dia()
	assert_float(float(com)).is_equal_approx(
		_rendimento(obras) * METADE, obras.size() * FOLGA_POR_FONTE
	)


func test_o_canteiro_sem_ninguem_no_posto_rende_menos() -> void:
	SimLoop.state.greed = 0
	var canteiros := _de_pe([&"farm"])
	var sozinhos := _um_dia()
	var cheio := _rendimento(canteiros) * pow(_curva().income_growth, 1)
	assert_float(float(sozinhos)).is_less(cheio * METADE)


func test_o_canteiro_com_quem_la_trabalha_rende_inteiro() -> void:
	SimLoop.state.greed = 0
	var canteiros := _de_pe([&"farm"])
	var dono := SimLoop.units.owners[SimLoop.units.index_of(SimLoop.king_id)]
	for obra in canteiros:
		var dados := Registry.entry(&"units", &"vagrant") as UnitData
		SimLoop.units.spawn(SimLoop.state, dados, dono, obra.x)
	var dia1 := _um_dia()
	assert_float(float(dia1)).is_equal_approx(
		_rendimento(canteiros), canteiros.size() * FOLGA_POR_FONTE
	)


## A asfixia do §06 com as obras que o greybox tem, a caca media do §25, e a
## ganancia e as tropas do perfil `balanced` que o teste do modelo usa.
func test_o_dia_da_asfixia_da_economia_do_jogo_cai_no_alvo() -> void:
	var eco := SimLoop.economy
	var perfil := Registry.entry(&"economy/profiles", &"balanced") as EconomyProfile
	var fontes := _de_pe([&"farm", &"henhouse", &"fishery"])
	assert_int(fontes.size()).is_equal(perfil.sources)
	var caca := (_curva().hunt_yield.x + _curva().hunt_yield.y) * METADE
	var asfixia := 0
	for d in range(1, 30):
		var bruto := eco.built_income(SimLoop.builds, d) + caca
		var liquido := bruto - eco.greed_cut(bruto, perfil.greed) - eco.upkeep(perfil.troops)
		if eco.night_cost(d) > liquido:
			asfixia = d
			break
	var alvo := _curva().suffocation_target
	assert_int(asfixia).is_between(alvo.x, alvo.y)


## A alvorada do dia 2, pedida ao FieldWork sem esperar pela noite: o que se mede
## e a ligacao, e nao quem a noite leva.
func _alvorada() -> void:
	SimLoop.field.prepare(2, SimLoop.core_x, SimLoop.world_width, SimLoop.units, 0, SimLoop.state)
	EventBus.flush()


func _lanceiros(quantos: int) -> void:
	var dono := SimLoop.units.owners[SimLoop.units.index_of(SimLoop.king_id)]
	var dados := Registry.entry(&"units", &"spearman") as UnitData
	for _k in quantos:
		SimLoop.units.spawn(SimLoop.state, dados, dono, SimLoop.core_x)


func test_a_manutencao_paga_se_na_alvorada_do_saco_do_rei() -> void:
	SimLoop.step(STEP)
	_lanceiros(12)
	var tropas := SimLoop.field.upkeep.troops(SimLoop.units, SimLoop.king_id)
	var rei := SimLoop.units.index_of(SimLoop.king_id)
	SimLoop.units.carried_coins[rei] = 30
	_alvorada()
	var devido := int(SimLoop.economy.upkeep(tropas))
	assert_int(devido).is_greater(0)
	assert_int(int(_gasto.get(&"upkeep", 0))).is_equal(devido)
	assert_int(SimLoop.units.carried_coins[rei]).is_equal(30 - devido)


func test_sem_moedas_para_a_manutencao_uma_tropa_vai_embora() -> void:
	SimLoop.step(STEP)
	_lanceiros(12)
	var antes := SimLoop.field.upkeep.troops(SimLoop.units, SimLoop.king_id)
	SimLoop.units.carried_coins[SimLoop.units.index_of(SimLoop.king_id)] = 0
	_alvorada()
	assert_int(SimLoop.field.upkeep.troops(SimLoop.units, SimLoop.king_id)).is_equal(antes - 1)


func test_um_vagabundo_novo_por_alvorada_num_acampamento() -> void:
	SimLoop.step(STEP)
	# O greybox nasce com o teto cheio: o acampamento repoe quem recrutaste.
	var dono := SimLoop.units.owners[SimLoop.units.index_of(SimLoop.king_id)]
	SimLoop.units.owners[SimLoop.units.index_of(2)] = dono
	var antes := _por_recrutar()
	_alvorada()
	assert_int(_por_recrutar()).is_equal(antes + _curva().vagrants_per_dawn)
	var no_acampamento := false
	for i in SimLoop.units.count():
		for x in SimLoop.field.camps:
			no_acampamento = no_acampamento or is_equal_approx(SimLoop.units.xs[i], x)
	assert_bool(no_acampamento).is_true()


func test_com_o_acampamento_cheio_nao_vem_mais_ninguem() -> void:
	SimLoop.step(STEP)
	var dados := Registry.entry(&"units", &"vagrant") as UnitData
	while _por_recrutar() < _curva().vagrant_camp_cap:
		SimLoop.units.spawn(SimLoop.state, dados, RecruitSystem.SEM_DONO, SimLoop.core_x)
	var antes := _por_recrutar()
	_alvorada()
	assert_int(_por_recrutar()).is_equal(antes)


## A Colheita Forcada do §15 tem de poder compensar nalgum dia (P-M): sem o
## crescimento da producao, nunca compensava.
func test_a_colheita_forcada_compensa_nalgum_dia() -> void:
	var eco := SimLoop.economy
	var impulso := Registry.entry(&"crown/impulses", &"forced_harvest") as ImpulseData
	_de_pe([&"farm", &"henhouse", &"fishery"])
	var canteiros := 0.0
	for obra in SimLoop.builds.standing():
		if obra.kind == &"farm":
			canteiros += obra.yield_per_day
	var compensa := false
	for d in range(1, 21):
		var hoje := eco.built_income(SimLoop.builds, d) * (impulso.benefit_value - 1.0)
		var amanha := canteiros * pow(_curva().income_growth, d)
		compensa = compensa or hoje - amanha - impulso.coin_cost > 0.0
	assert_bool(compensa).is_true()


func _por_recrutar() -> int:
	var n := 0
	for i in SimLoop.units.count():
		if SimLoop.units.owners[i] == RecruitSystem.SEM_DONO and SimLoop.units.alive(i):
			n += 1 if SimLoop.units.data_ids[i] == &"vagrant" else 0
	return n
