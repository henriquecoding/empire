# src/core/sim_loop.gd — os onze passos do §43, pela ordem escrita (ADR 0020).
#
# O UNICO _physics_process da simulacao. 30 passos por segundo, metade do render
# (§19), e dentro de cada passo a ordem e fixa e esta escrita aqui — porque uma
# ordem implicita e uma ordem que muda sozinha quando alguem reorganiza um
# ficheiro.
#
# Os passos que ainda nao existem estao presentes como linha, com o ticket que
# os preenche. Um passo que falta e uma linha que falta, e nao um sistema que
# ninguem chama e de que ninguem da pela ausencia.
extends Node

## O estado autoritativo em execucao (§45). Quem o le e quem o grava passa por
## aqui; ninguem guarda uma copia.
var state: GameState

## As tropas, em colunas (§52). Vive aqui porque e o tick que a faz andar.
var units: UnitSystem

## As moedas no chao e no ar (§61, o Verbo 1). Criado a pedido: precisa do
## EconomyCurve do Registry, e nenhum autoload pode depender do _ready() de
## outro ter corrido primeiro (ADR 0020, regra 8b do AGENTS.md).
var coins: CoinSystem:
	get:
		if _coins == null:
			_coins = CoinSystem.new(Registry.entry(&"economy", &"curve") as EconomyCurve)
		return _coins

## §62: autosave no DAWN de cada dia. Desliga-se em testes e em ferramentas.
var autosave_enabled: bool = true

var _coins: CoinSystem
var _running: bool = false


func _ready() -> void:
	state = GameState.new()
	units = UnitSystem.new()
	EventBus.dawn_broke.connect(_no_amanhecer)


## Comeca um jogo novo: semeia, poe o relogio a andar, e da o primeiro dia.
func start(semente: int) -> void:
	state = GameState.new()
	state.seed = semente
	units = UnitSystem.new()
	_coins = null  # um jogo novo comeca sem moedas no chao
	RngService.configure(semente)
	ClockService.start()
	_running = true


## Retoma um save. Repoe o estado, o relogio e a sequencia de cada fluxo — o
## ESTADO dos fluxos, nao a semente, senao a noite recomeca (§42).
func resume(estado: GameState, rng_states: Dictionary) -> void:
	state = estado
	RngService.configure(estado.seed)
	RngService.restore(rng_states)
	ClockService.seek(estado.day, estado.clock_elapsed)
	_running = true


func stop() -> void:
	_running = false
	ClockService.stop()


func running() -> bool:
	return _running


## Um passo. Publico para que um teste possa correr um dia inteiro em
## milissegundos sem esperar por _physics_process.
func step(delta: float) -> void:
	state.tick += 1

	ClockService.step(delta)  # 1 · GameClock.advance — todo o tick
	# 2 · RotSystem — todo o tick .......................... F1-08
	# 3 · JobSystem — uma vez por fase ..................... F1-05
	for mudanca in units.tick_decisions(state.tick):  # 4 · FSM, 1/6 por tick
		EventBus.queue(
			&"unit_state_changed", [mudanca[&"unit_id"], mudanca[&"from"], mudanca[&"to"]]
		)
	units.tick_movement(delta)  # 5 · MovementSystem — todo o tick
	coins.tick(delta)  # 5 · o arco e a queda, antes de o passo 8 as ler
	# 6 · CombatSystem — todo o tick ....................... F1-07
	# 7 · EconomySystem — uma vez por fase ................. F1-10
	# 8 · BuildSystem — todo o tick ........................ F1-01
	# 9 · DebtSystem e DiplomacySystem — uma vez por dia ... F1-14
	# 10 · KingAISystem — uma vez por dia, por imperio ..... F2

	_espelhar_relogio()
	EventBus.flush()  # 11 · fim do tick, com o estado ja consolidado


## O Verbo 1 (§61). A ponte entre o sistema puro e o que ele nao pode tocar: o
## sorteio do desvio sai do fluxo `economy` — onde a moeda cai afeta a simulacao,
## por isso e determinista — e o evento sai do catalogo da §46.
func drop_coin(x: float, faixa: Band.Kind, quanto: int, origem: StringName) -> int:
	var desvio := RngService.float_range(&"economy", -CoinSystem.DESVIO_MAX, CoinSystem.DESVIO_MAX)
	var coin_id := coins.drop(state, x, faixa, quanto, desvio)
	EventBus.queue(&"coin_dropped", [x, int(faixa), quanto, origem])
	return coin_id


## Apanhar, tambem pelo catalogo. `espaco` e o que falta encher no saco, e vem
## de UnitData.coin_capacity — a capacidade nao esta escrita em lado nenhum aqui.
func collect_coins(unit_id: int, x: float, faixa: Band.Kind, espaco: int) -> int:
	var valores := coins.amounts_by_id()
	var apanhadas := coins.collect(x, faixa, espaco)
	var total := coins.value_of(apanhadas, valores)
	if total > 0:
		EventBus.queue(&"coin_collected", [unit_id, total])
	return total


func _physics_process(delta: float) -> void:
	if not _running:
		return
	step(delta)


## O relogio e dono do dia e do tempo decorrido; o GameState e o que se grava.
## Copiar aqui, uma vez por tick, evita que os dois divirjam sem ninguem ver.
func _espelhar_relogio() -> void:
	state.day = ClockService.clock.day
	state.clock_elapsed = ClockService.clock.elapsed


func _no_amanhecer(dia: int) -> void:
	# O dia 1 e o amanhecer com que o jogo comeca: gravar ai seria gravar antes
	# de ter acontecido alguma coisa.
	if autosave_enabled and _running and dia > 1:
		SaveService.autosave(state, RngService.snapshot())
