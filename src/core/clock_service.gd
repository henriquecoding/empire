# src/core/clock_service.gd — o autoload que so faz o relogio andar (ADR 0006).
#
# Zero logica. O GameClock e que sabe as fases; isto chama-lhe tick() e traduz o
# que ele devolve nos sinais do catalogo da §46. Se aparecer aqui uma decisao de
# jogo, esta no ficheiro errado.
#
# ADR 0020: nao tem _physics_process proprio. Quem o faz andar e o SimLoop, que
# e dono da ordem dos onze passos do §43 — senao a ordem da simulacao passava a
# ser a ordem de declaracao dos autoloads, que ninguem ve ao ler o codigo.
extends Node

## O relogio vem de data/economy/clock.tres. O Registry ja o tem indexado.
const CLOCK_TABLE := &"economy"
const CLOCK_ID := &"clock"

var running: bool = false

## O relogio, criado a pedido. NENHUM autoload pode depender do _ready() de
## outro ter corrido primeiro: a ordem em que correm e a ordem de declaracao no
## project.godot, que e exatamente a ordem implicita que a ADR 0020 tira do
## caminho. Este ficheiro ja caiu nisso uma vez — o Registry ainda estava vazio.
var clock: GameClock:
	get:
		if _clock == null:
			_clock = GameClock.new(_dados_do_relogio())
		return _clock

var _clock: GameClock
var _dados: ClockData


func _dados_do_relogio() -> ClockData:
	if _dados == null:
		_dados = Registry.entry(CLOCK_TABLE, CLOCK_ID) as ClockData
	return _dados


## Um jogo novo, do principio. O dia 1 entra em DAWN, e uma entrada em DAWN e um
## dia que comeca (§48) — por isso os dois sinais saem aqui e nao no primeiro
## tick. Reinicia o relogio: comecar um jogo novo nao continua o anterior.
func start() -> void:
	_clock = GameClock.new(_dados_do_relogio())
	running = true
	EventBus.queue(&"day_started", [clock.day])
	EventBus.queue(&"dawn_broke", [clock.day])


func stop() -> void:
	running = false


## Poe o relogio num ponto do dia. Para retomar um save, e mais nada — ninguem
## deve andar com o tempo para tras a meio de um jogo.
func seek(dia: int, decorrido: float) -> void:
	_clock = GameClock.new(_dados_do_relogio())
	_clock.day = dia
	_clock.elapsed = decorrido
	running = true


## Onde vai a frente da luz do amanhecer, em x de mundo, ou INF fora dela. A
## luz que se ve e as tropas que ela solta leem esta mesma frente (§24, GB-21).
func dawn_front() -> float:
	if _clock == null:
		return INF
	var velocidade := _dados_do_relogio().dawn_sweep_px_s
	return DawnCascade.front(int(clock.current_phase()), clock.elapsed, velocidade)


## Um passo do relogio. Chamado pelo SimLoop, na posicao 1 do §43.
func step(delta: float) -> void:
	if not running:
		return
	for evento in clock.tick(delta):
		_traduzir(evento)


func _traduzir(evento: Dictionary) -> void:
	if evento[GameClock.EVENTO] == GameClock.EVENTO_DIA:
		EventBus.queue(&"day_started", [evento[GameClock.CAMPO_DIA]])
		return

	var de: int = evento[GameClock.CAMPO_DE]
	var para: int = evento[GameClock.CAMPO_PARA]
	EventBus.queue(&"phase_changed", [de, para])

	# §48, coluna "Emite a entrada": tres fases trazem um sinal proprio.
	match para:
		GameClock.Phase.DAWN:
			EventBus.queue(&"dawn_broke", [clock.day])
		GameClock.Phase.DUSK:
			EventBus.queue(&"dusk_fell", [clock.day])
		GameClock.Phase.NIGHT:
			EventBus.queue(&"night_started", [clock.day])
