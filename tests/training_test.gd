# tests/training_test.gd — a Casa de Treino (§09, §10): "Converte vagabundos em
# oficios. Um vagabundo entra, sai construtor. Custa moeda e um dia."
#
# O preco e o recruit_cost do oficio e o tempo e o train_days dele (units.csv);
# nenhum esta aqui.
extends GdUnitTestSuite

const MEU := 1
const PASSO := 1.0 / 30.0
const CASA_X := 500.0
const DIA := 360.0

var estado: GameState
var unidades: UnitSystem
var obras: BuildSystem
var treino: TrainingSystem
var casa: BuildSlot
var moedas: CoinSystem


func before_test() -> void:
	estado = GameState.new()
	unidades = UnitSystem.new()
	obras = BuildSystem.new()
	treino = SimFactory.training()
	moedas = CoinSystem.new(Registry.entry(&"economy", &"curve") as EconomyCurve)
	var dados := Registry.entry(&"buildings", &"training_house") as BuildingData
	casa = BuildSlot.new()
	casa.kind = dados.id
	casa.x = CASA_X
	casa.width = float(dados.width_px)
	casa.costs = PackedInt32Array([dados.cost])
	casa.works = PackedFloat32Array([dados.build_work])
	casa.healths = PackedInt32Array([dados.max_health])
	obras.post(casa)
	casa.level = 1
	casa.state = BuildSlot.State.DONE
	casa.health = casa.max_health()


func _construtor() -> UnitData:
	return Registry.entry(&"units", &"builder") as UnitData


func _pousar(quantas: int) -> void:
	for _k in quantas:
		var id := moedas.drop(estado, CASA_X, Band.Kind.SURFACE, 1, 0.0)
		moedas.settled[moedas.index_of(id)] = 1


func _trabalhador(x: float) -> int:
	return unidades.spawn(estado, Registry.entry(&"units", &"vagrant"), MEU, x)


func test_sem_trabalhador_teu_a_casa_nao_aceita_moeda() -> void:
	unidades.spawn(estado, Registry.entry(&"units", &"vagrant"), RecruitSystem.SEM_DONO, CASA_X)
	_pousar(3)
	assert_array(treino.absorb(moedas, obras, unidades)).is_empty()
	assert_int(moedas.count()).is_equal(3)


func test_o_preco_do_oficio_manda_o_trabalhador_mais_perto_para_dentro() -> void:
	var longe := _trabalhador(CASA_X + 900.0)
	var perto := _trabalhador(CASA_X + 100.0)
	var preco := _construtor().recruit_cost
	_pousar(preco - 1)
	treino.absorb(moedas, obras, unidades)
	assert_bool(treino.trainees.is_empty()).is_true()
	assert_int(treino.owed(casa)).is_equal(1)
	_pousar(1)
	var eventos := treino.absorb(moedas, obras, unidades)
	assert_int(moedas.count()).is_equal(0)
	assert_bool(treino.trainees.has(perto)).is_true()
	assert_bool(treino.trainees.has(longe)).is_false()
	assert_int(eventos[-1][TrainingSystem.CHAVE]).is_equal(TrainingSystem.EV_ENTROU)
	treino.plan(unidades)
	assert_float(unidades.target_xs[unidades.index_of(perto)]).is_equal(CASA_X)


func test_um_dia_dentro_da_casa_e_sai_construtor() -> void:
	var quem := _trabalhador(CASA_X)
	_pousar(_construtor().recruit_cost)
	treino.absorb(moedas, obras, unidades)
	var dias := _construtor().train_days * DIA
	for _t in int(dias / PASSO) - 2:
		assert_array(treino.tick(PASSO, unidades, obras, DIA)).is_empty()
	var eventos: Array[Dictionary] = []
	for _t in 4:
		eventos.append_array(treino.tick(PASSO, unidades, obras, DIA))
	var i := unidades.index_of(quem)
	assert_str(String(unidades.data_ids[i])).is_equal("builder")
	assert_int(unidades.max_healths[i]).is_equal(_construtor().max_health)
	assert_int(unidades.owners[i]).is_equal(MEU)
	assert_int(eventos.size()).is_equal(1)
	assert_str(String(eventos[0][TrainingSystem.PARA])).is_equal("builder")
	assert_bool(treino.trainees.is_empty()).is_true()


func test_o_tempo_so_corre_la_dentro_e_para_com_a_casa_em_ruina() -> void:
	var quem := _trabalhador(CASA_X + 600.0)
	_pousar(_construtor().recruit_cost)
	treino.absorb(moedas, obras, unidades)
	treino.tick(DIA, unidades, obras, DIA)
	assert_str(String(unidades.data_ids[unidades.index_of(quem)])).is_equal("vagrant")
	unidades.xs[unidades.index_of(quem)] = CASA_X
	obras.damage(casa.id, casa.health)
	treino.tick(DIA, unidades, obras, DIA)
	assert_str(String(unidades.data_ids[unidades.index_of(quem)])).is_equal("vagrant")
	assert_bool(treino.trainees.is_empty()).is_true()


func test_quem_morre_a_treinar_sai_da_lista_e_o_save_guarda_o_resto() -> void:
	var a := _trabalhador(CASA_X)
	_pousar(_construtor().recruit_cost + 2)
	treino.absorb(moedas, obras, unidades)
	treino.tick(DIA * 0.5, unidades, obras, DIA)
	var copia := SimFactory.training()
	copia.from_dict(treino.to_dict())
	assert_dict(copia.to_dict()).is_equal(treino.to_dict())
	unidades.healths[unidades.index_of(a)] = 0
	treino.tick(PASSO, unidades, obras, DIA)
	assert_bool(treino.trainees.is_empty()).is_true()


func test_o_construtor_da_defesa_as_muralhas_e_so_a_elas() -> void:
	assert_float(treino.wall_defense(unidades)).is_equal(0.0)
	var quem := _trabalhador(CASA_X)
	_pousar(_construtor().recruit_cost)
	treino.absorb(moedas, obras, unidades)
	treino.tick(_construtor().train_days * DIA + 1.0, unidades, obras, DIA)
	var bonus: float = _construtor().ability_params[&"wall_defense"]
	assert_float(treino.wall_defense(unidades)).is_equal(bonus)
	unidades.owners[unidades.index_of(quem)] = RecruitSystem.SEM_DONO
	assert_float(treino.wall_defense(unidades)).is_equal(0.0)


func test_a_defesa_do_construtor_poupa_vida_a_muralha_golpe_a_golpe() -> void:
	var muro := obras.post(WallSite.slot(CASA_X + 1000.0))
	muro.level = 1
	muro.state = BuildSlot.State.DONE
	muro.health = muro.max_health()
	obras.wall_defense = 0.08
	for _k in 8:
		obras.damage(muro.id, 3)
	assert_int(muro.health).is_equal(muro.max_health() - 24 + 1)
	obras.damage(casa.id, 3)
	assert_int(casa.health).is_equal(casa.max_health() - 3)
