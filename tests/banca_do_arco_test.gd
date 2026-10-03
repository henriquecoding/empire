# tests/banca_do_arco_test.gd — a banca do arco (Q-165; relatorio Kingdom, K1).
#
# A regiao tinha tres arqueiros para sempre: um vagabundo nunca passava a arqueiro.
# No Kingdom o arco custa 2 e qualquer aldeao o apanha. Aqui, a banca e uma casa de
# oficio como a Casa de Treino: a moeda largada nela manda o trabalhador teu mais
# perto buscar o arco, e ele sai arqueiro ao chegar — sem dia de treino.
extends GdUnitTestSuite

const MEU := 1
const PASSO := 1.0 / 30.0
const BANCA_X := 500.0
const DIA := 360.0
const ESPERA := 10
const O_TRABALHADOR := 2

var estado: GameState
var unidades: UnitSystem
var obras: BuildSystem
var treino: TrainingSystem
var banca: BuildSlot
var moedas: CoinSystem
var _promovidos: Array[StringName] = []


func before_test() -> void:
	estado = GameState.new()
	unidades = UnitSystem.new()
	obras = BuildSystem.new()
	treino = SimFactory.training()
	moedas = CoinSystem.new(SimFactory.curve())
	banca = _de_pe(Greybox.slot_of(_dados(), BANCA_X))


func _dados() -> BuildingData:
	return Registry.entry(&"buildings", BowRacks.BANCA) as BuildingData


func _arqueiro() -> UnitData:
	return Registry.entry(&"units", &"archer") as UnitData


func _de_pe(vaga: BuildSlot) -> BuildSlot:
	obras.post(vaga)
	vaga.level = 1
	vaga.state = BuildSlot.State.DONE
	vaga.health = vaga.max_health()
	return vaga


func _pousar(quantas: int, x: float = BANCA_X) -> void:
	for _k in quantas:
		var id := moedas.drop(estado, x, Band.Kind.SURFACE, 1, 0.0)
		moedas.settled[moedas.index_of(id)] = 1


func _trabalhador(x: float) -> int:
	return unidades.spawn(estado, Registry.entry(&"units", &"vagrant"), MEU, x)


## O arco do Kingdom (§02): 2 moedas, e nao as 3 do arqueiro ja feito.
func test_a_banca_pede_o_preco_do_arco() -> void:
	_trabalhador(BANCA_X + 50.0)
	assert_object(treino.craft_of(banca)).is_same(_arqueiro())
	assert_int(treino.owed(banca, unidades)).is_equal(int(_dados().effect_params[&"craft_cost"]))
	assert_int(treino.owed(banca, unidades)).is_less(_arqueiro().recruit_cost)


## A Casa de Treino nao muda: o preco continua a ser o do oficio.
func test_a_casa_de_treino_continua_ao_preco_do_oficio() -> void:
	var dados := Registry.entry(&"buildings", &"training_house") as BuildingData
	var casa := _de_pe(Greybox.slot_of(dados, BANCA_X + 2000.0))
	_trabalhador(BANCA_X + 2000.0)
	var construtor := Registry.entry(&"units", &"builder") as UnitData
	assert_int(treino.owed(casa, unidades)).is_equal(construtor.recruit_cost)


## Paga, o trabalhador mais perto vai a banca e sai arqueiro mal chega: o corpo, a
## vida, o saco e o preco do arqueiro, e continua a ser teu.
func test_pago_o_arco_o_trabalhador_sai_arqueiro_ao_chegar() -> void:
	var quem := _trabalhador(BANCA_X)
	_pousar(treino.owed(banca, unidades))
	treino.absorb(moedas, obras, unidades)
	assert_bool(treino.trainees.has(quem)).is_true()
	var eventos := treino.tick(PASSO, unidades, obras, DIA)
	var i := unidades.index_of(quem)
	assert_str(String(unidades.data_ids[i])).is_equal("archer")
	assert_int(unidades.max_healths[i]).is_equal(_arqueiro().max_health)
	assert_int(unidades.coin_capacities[i]).is_equal(_arqueiro().coin_capacity)
	assert_int(unidades.owners[i]).is_equal(MEU)
	assert_int(eventos.size()).is_equal(1)
	assert_str(String(eventos[0][TrainingSystem.PARA])).is_equal("archer")


## O teto acabou: cada arco pago e mais um arqueiro, enquanto houver trabalhadores.
func test_cada_arco_e_mais_um_arqueiro() -> void:
	var quantos := 4
	for k in quantos:
		_trabalhador(BANCA_X + k)
	for _k in quantos:
		_pousar(treino.owed(banca, unidades))
		treino.absorb(moedas, obras, unidades)
		treino.tick(PASSO, unidades, obras, DIA)
	var arqueiros := 0
	for i in unidades.count():
		arqueiros += 1 if unidades.data_ids[i] == &"archer" else 0
	assert_int(arqueiros).is_equal(quantos)


## Na regiao: a banca existe, a superficie, e nasce depois de todas as obras de antes
## dela — os ids de antes nao mudam e um save antigo continua a abrir (§45). So o
## estabulo do cavalo (Q-169), o martelo e as muralhas novas nascem a seguir.
func test_a_banca_esta_na_regiao_e_nasce_por_ultimo() -> void:
	SimLoop.autosave_enabled = false
	SimLoop.start(20260929)
	Greybox.build()
	assert_str(String(SimLoop.builds.slots[-4].kind)).is_equal(String(Stables.ESTABULO))
	var ultima: BuildSlot = SimLoop.builds.slots[-5]
	assert_str(String(ultima.kind)).is_equal(String(BowRacks.BANCA))
	assert_int(int(ultima.band)).is_equal(int(Band.Kind.SURFACE))
	assert_float(ultima.x - SimLoop.core_x).is_equal(BowRacks.BANCAS_X[0])
	SimLoop.stop()
	SimLoop.autosave_enabled = true


## No jogo inteiro, so com gestos: o rei larga as moedas na banca de pe e um dos
## trabalhadores dele passa a arqueiro (unit_promoted, §46).
func test_no_jogo_um_trabalhador_passa_a_arqueiro_pela_banca() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(20260929)
	Greybox.build()
	EventBus.unit_promoted.connect(_promovido)
	var casa: BuildSlot = SimLoop.builds.slots[-5]  # a banca; o estabulo vem a seguir (Q-169)
	assert_str(String(casa.kind)).is_equal(String(BowRacks.BANCA))
	casa.level = 1
	casa.state = BuildSlot.State.DONE
	casa.health = casa.max_health()
	var rei := SimLoop.units.index_of(SimLoop.king_id)
	SimLoop.units.spawn(SimLoop.state, Registry.entry(&"units", &"vagrant"), 1, casa.x)
	SimLoop.units.carried_coins[rei] = SimLoop.field.training.owed(casa, SimLoop.units)
	SimLoop.units.xs[rei] = casa.x
	var espera := 0
	for _t in 2400:
		if not _promovidos.is_empty():
			break
		espera -= 1
		SimLoop.units.set_target_x(SimLoop.king_id, casa.x)
		if espera <= 0 and SimLoop.units.carried_coins[rei] > 0:
			espera = ESPERA
			_largar(rei)
		SimLoop.step(PASSO)
	EventBus.unit_promoted.disconnect(_promovido)
	assert_array(_promovidos).is_equal([&"archer"])
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func _promovido(_quem: int, _de: StringName, para: StringName) -> void:
	_promovidos.append(para)


func _largar(rei: int) -> void:
	var moeda := {
		&"x": SimLoop.units.xs[rei],
		&"band": Band.Kind.SURFACE,
		&"amount": InputRouter.UMA,
		&"source": Verbs.JOGADOR
	}
	SimLoop.intents.queue(IntentQueue.Kind.DROP_COIN, moeda)
