# tests/piloto_caminhos_reais_test.gd — o piloto da vistoria pelos caminhos reais de
# gente (CONT-05; relatorio Kingdom de 29/09, K1).
#
# O piloto so recrutava vagabundos e pagava obras: nunca tinha mais de tres
# arqueiros, e a vistoria media uma partida sem exercito que crescesse. Agora faz o
# que um jogador faz para armar o reino, pelas mesmas intencoes: a tarde compra o
# arco na banca (Q-165) e, com gente livre a espera, decreta a Chamada as Armas
# pela roda (Q-110). Nao joga melhor por isso — so passa por onde o jogo passa.
extends GdUnitTestSuite

const Sede := preload("res://tests/support/sede.gd")

const PASSO := 1.0 / 30.0
const SEMENTE := 20260929
const TICKS := 2400
const LIVRES := 2
const ESPERA_DECRETO := 30

var _promovidos: Array[StringName] = []
var _decretos: Array[StringName] = []


func before_test() -> void:
	_promovidos = []
	_decretos = []
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(SEMENTE)
	Greybox.build()
	Sede.erguer()  # o castelo de antes e a Fortaleza (ADR 0059)
	EventBus.unit_promoted.connect(_promovido)
	EventBus.royal_impulse_used.connect(_decretou)


func after_test() -> void:
	EventBus.unit_promoted.disconnect(_promovido)
	EventBus.royal_impulse_used.disconnect(_decretou)
	SimLoop.stop()
	SimLoop.autosave_enabled = true


## A tarde prepara a noite, e um arco e defesa: com a banca de pe, um trabalhador
## teu e o preco no saco, o piloto vai la, larga as moedas e sai um arqueiro.
func test_a_tarde_o_piloto_compra_o_arco_na_banca() -> void:
	var banca := _banca_de_pe()
	SimLoop.units.spawn(SimLoop.state, Registry.entry(&"units", &"vagrant"), 1, banca.x)
	_ate(GameClock.Phase.AFTERNOON)
	var rei := _rei()
	SimLoop.units.xs[rei] = banca.x
	SimLoop.units.carried_coins[rei] = SimLoop.field.training.owed(banca, SimLoop.units)
	_pilotar_ate(func() -> bool: return not _promovidos.is_empty())
	assert_array(_promovidos).contains([&"archer"])


## De manha a moeda vai para o que rende, como antes: o arco espera pela tarde.
func test_de_manha_o_arco_seguinte_espera() -> void:
	var banca := _banca_de_pe()
	SimLoop.units.spawn(SimLoop.state, Registry.entry(&"units", &"archer"), 1, banca.x)
	SimLoop.units.spawn(SimLoop.state, Registry.entry(&"units", &"builder"), 1, banca.x)
	SimLoop.units.spawn(SimLoop.state, Registry.entry(&"units", &"vagrant"), 1, banca.x)
	_ate(GameClock.Phase.MORNING)
	var rei := _rei()
	SimLoop.units.xs[rei] = banca.x
	SimLoop.units.carried_coins[rei] = SimLoop.field.training.owed(banca, SimLoop.units)
	Autopilot.step(SimLoop)
	SimLoop.step(PASSO)
	assert_int(SimLoop.field.training.owed(banca, SimLoop.units)).is_greater(0)
	assert_array(_promovidos).is_empty()


## Com vagabundos livres e o preco de hoje no saco, o piloto decreta a Chamada as
## Armas a tarde: os livres passam a lanceiros teus, pela mesma intencao da roda.
func test_com_gente_livre_o_piloto_chama_as_armas() -> void:
	_ate(GameClock.Phase.AFTERNOON)
	var livres := _vagabundos_livres(LIVRES)
	var rei := _rei()
	SimLoop.units.carried_coins[rei] = SimLoop.units.coin_capacities[rei]
	assert_str(InputRouter.impulse_refusal(Autopilot.CHAMADA)).is_empty()
	_pilotar_ate(func() -> bool: return not _decretos.is_empty())
	assert_array(_decretos).is_equal([Autopilot.CHAMADA])
	for id in livres:
		var i := SimLoop.units.index_of(id)
		assert_str(String(SimLoop.units.data_ids[i])).is_equal("spearman")
		assert_int(SimLoop.units.owners[i]).is_not_equal(RecruitSystem.SEM_DONO)


## Sem ninguem livre o decreto nao arma ninguem, e o piloto nao o paga.
func test_sem_gente_livre_nao_ha_decreto() -> void:
	_ate(GameClock.Phase.AFTERNOON)
	for i in SimLoop.units.count():
		if SimLoop.units.owners[i] == RecruitSystem.SEM_DONO:
			SimLoop.units.owners[i] = SimLoop.units.owners[_rei()]
	var rei := _rei()
	SimLoop.units.carried_coins[rei] = SimLoop.units.coin_capacities[rei]
	for _t in ESPERA_DECRETO:
		Autopilot.step(SimLoop)
		SimLoop.step(PASSO)
	assert_array(_decretos).is_empty()


func _banca_de_pe() -> BuildSlot:
	var banca: BuildSlot = null
	for vaga in SimLoop.builds.slots:
		if vaga.kind == BowRacks.BANCA:
			banca = vaga
	banca.level = 1
	banca.state = BuildSlot.State.DONE
	banca.health = banca.max_health()
	return banca


func _vagabundos_livres(quantos: int) -> Array[int]:
	var dados := Registry.entry(&"units", &"vagrant") as UnitData
	var ids: Array[int] = []
	for k in quantos:
		var x := SimLoop.core_x + float(k)
		ids.append(SimLoop.units.spawn(SimLoop.state, dados, RecruitSystem.SEM_DONO, x))
	return ids


func _pilotar_ate(feito: Callable) -> void:
	for _t in TICKS:
		if feito.call():
			return
		Autopilot.step(SimLoop)
		SimLoop.step(PASSO)


func _ate(fase: GameClock.Phase) -> void:
	while ClockService.clock.current_phase() != fase:
		SimLoop.step(PASSO)


func _rei() -> int:
	return SimLoop.units.index_of(SimLoop.king_id)


func _promovido(_quem: int, _de: StringName, para: StringName) -> void:
	_promovidos.append(para)


func _decretou(impulso: StringName) -> void:
	_decretos.append(impulso)
