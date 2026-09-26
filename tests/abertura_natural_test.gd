extends GdUnitTestSuite

# A abertura jogada so com os gestos do §61 — mover o rei e largar uma moeda —,
# sem pagar obras nem mudar estado a mao (ASTRA-RETOMADA §19, etapa C). Prova o
# circuito do §06: recrutar -> cacar -> recolher -> pagar -> ver trabalhar -> render.

const STEP := 1.0 / 30.0
const SEMENTE := 20260926
## A distancia a que o rei larga, e o intervalo entre moedas: a tolerancia de um
## gesto, como o CHEGOU_PX do piloto — nao e balanceamento.
const PERTO_PX := 24.0
const ENTRE_MOEDAS := 15
const O_VAGABUNDO := 2
const O_ARQUEIRO := 7
const O_CANTEIRO := 1500.0
## O §25 mede a primeira moeda largada em menos de 40 s (first_coin_dropped):
## recrutar os dois do lado do castelo nao pode levar mais do que isso.
const RECRUTAR_S := 40.0

var _origens: Array[StringName] = []
var _caca: Array[float] = []
var _producao: Array[float] = []
var _espera := 0
var _no_saco_do_arqueiro := 0


func before_test() -> void:
	SimLoop.autosave_enabled = false
	EventBus.reset()
	SimLoop.start(SEMENTE)
	Greybox.build()
	EventBus.coin_dropped.connect(_caiu)
	EventBus.coin_collected.connect(_apanhou)


func after_test() -> void:
	EventBus.coin_dropped.disconnect(_caiu)
	EventBus.coin_collected.disconnect(_apanhou)
	SimLoop.stop()
	SimLoop.autosave_enabled = true


func test_sem_ninguem_a_jogar_o_coelho_do_1_10_cai_junto_ao_castelo_uma_so_vez() -> void:
	_correr_ate(HuntWatch.INTRO_SECONDS - 1.0)
	assert_array(_caca).is_empty()
	_correr_ate(HuntWatch.INTRO_SECONDS + 2.0)
	assert_int(_caca.size()).is_equal(1)
	assert_float(_caca[0]).is_equal(SimLoop.core_x + HuntWatch.CLEARINGS[0])
	var salvo := SimLoop.world()
	SimLoop.load_world(salvo)
	_correr_ate(HuntWatch.INTRO_SECONDS + 30.0)
	assert_int(_caca.size()).is_equal(1)


func test_a_abertura_financia_um_canteiro_so_com_gestos() -> void:
	_recrutar(O_VAGABUNDO)
	_recrutar(O_ARQUEIRO)
	var canteiro := _obra(O_CANTEIRO)
	var preco := canteiro.next_cost()
	# A caca abre em vagas pela luz (Q-106): o canteiro paga-se antes do crepusculo.
	var limite := _fase_em(GameClock.Phase.DUSK)
	while _saco() < preco and ClockService.clock.elapsed < limite:
		_passo(_moeda_mais_perto())
	assert_int(_saco()).is_greater_equal(preco)
	# A caca chega ao saco do rei pela mao do arqueiro (Q-111), e nao do chao.
	assert_int(_no_saco_do_arqueiro).is_greater_equal(preco - 2)
	while canteiro.state == BuildSlot.State.EMPTY and ClockService.clock.elapsed < limite:
		_passo(canteiro.x, true)
	assert_int(canteiro.state).is_not_equal(BuildSlot.State.EMPTY)
	# O rei vai-se embora: a obra acaba com o trabalhador e sem ele (§55).
	var longe := SimLoop.core_x + SimLoop.world_width * 0.25
	while canteiro.state != BuildSlot.State.DONE and ClockService.clock.elapsed < limite:
		_passo(longe)
	assert_int(canteiro.state).is_equal(BuildSlot.State.DONE)
	assert_float(absf(_x_do_rei() - canteiro.x)).is_greater(canteiro.width)
	while _producao.is_empty() and ClockService.clock.day == 1:
		_passo(longe)
	assert_array(_producao).contains([canteiro.x])
	# Nenhuma moeda apareceu por outra via: tudo o que caiu foi largado, cacado,
	# produzido ou largado por quem morreu — a regra "nada cria moeda do nada" do
	# §02, na abertura. O saque entrou com a formacao da noite (Q-128): o arqueiro
	# defende a borda do nucleo e os Rastejantes que ele abate largam a moeda (§25).
	var fisicas := [Verbs.JOGADOR, &"hunt", &"production", EventRelay.FONTE_MORTE]
	for origem in _origens:
		assert_bool(origem in fisicas).override_failure_message(String(origem)).is_true()


func _recrutar(id: int) -> void:
	var i := SimLoop.units.index_of(id)
	var limite := ClockService.clock.elapsed + RECRUTAR_S
	while SimLoop.units.owners[i] == RecruitSystem.SEM_DONO:
		assert_float(ClockService.clock.elapsed).is_less(limite)
		_passo(SimLoop.units.xs[i], true)
		i = SimLoop.units.index_of(id)


## Um tick de quem joga: o rei anda para x e, se ja la esta e deve largar, larga
## uma moeda — a mesma intencao que o InputRouter enfileira.
func _passo(x: float, larga: bool = false) -> void:
	var rei := SimLoop.units.index_of(SimLoop.king_id)
	SimLoop.units.set_target_x(SimLoop.king_id, x)
	_espera -= 1
	if larga and _espera <= 0 and _saco() > 0 and absf(SimLoop.units.xs[rei] - x) <= PERTO_PX:
		_espera = ENTRE_MOEDAS
		var moeda := {
			&"x": SimLoop.units.xs[rei],
			&"band": Band.Kind.SURFACE,
			&"amount": InputRouter.UMA,
			&"source": Verbs.JOGADOR
		}
		SimLoop.intents.queue(IntentQueue.Kind.DROP_COIN, moeda)
	SimLoop.step(STEP)


func _correr_ate(segundos: float) -> void:
	while ClockService.clock.elapsed < segundos:
		SimLoop.step(STEP)


func _caiu(x: float, _faixa: int, _quanto: int, origem: StringName) -> void:
	_origens.append(origem)
	if origem == &"hunt":
		_caca.append(x)
	elif origem == &"production":
		_producao.append(x)


func _apanhou(quem: int, quanto: int) -> void:
	if quem == O_ARQUEIRO and SimLoop.units.owners[SimLoop.units.index_of(quem)] != 0:
		_no_saco_do_arqueiro += quanto


func _moeda_mais_perto() -> float:
	var rei := _x_do_rei()
	var melhor := rei
	for c in SimLoop.coins.count():
		var x := SimLoop.coins.xs[c]
		if SimLoop.coins.settled[c] != 0 and (melhor == rei or absf(x - rei) < absf(melhor - rei)):
			melhor = x
	return melhor


func _obra(x: float) -> BuildSlot:
	for obra in SimLoop.builds.slots:
		if is_equal_approx(obra.x, x):
			return obra
	return null


## O instante em que a fase comeca hoje; ja dentro dela, e agora.
func _fase_em(fase: GameClock.Phase) -> float:
	var relogio := ClockService.clock
	return (
		relogio.elapsed
		if relogio.current_phase() == fase
		else relogio.elapsed + relogio.seconds_until(fase)
	)


func _saco() -> int:
	return SimLoop.units.carried_coins[SimLoop.units.index_of(SimLoop.king_id)]


func _x_do_rei() -> float:
	return SimLoop.units.xs[SimLoop.units.index_of(SimLoop.king_id)]
