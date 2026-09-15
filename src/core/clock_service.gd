# src/core/clock_service.gd — o autoload que so faz o relogio andar (ADR 0006).
#
# Zero logica. O GameClock e que sabe as fases; isto chama-lhe tick() no passo
# fixo e traduz o que ele devolve nos sinais do catalogo da §46. Se aparecer
# aqui uma decisao de jogo, esta no ficheiro errado.
extends Node

## O relogio vem de data/economy/clock.tres. O F0-11 troca este load pelo
## Registry; ate la e uma linha, e e a unica.
const CLOCK_DATA := "res://data/economy/clock.tres"

var clock: GameClock
var running: bool = false


func _ready() -> void:
	clock = GameClock.new(load(CLOCK_DATA) as ClockData)


## Poe o relogio a andar. O dia 1 entra em DAWN, e uma entrada em DAWN e um dia
## que comeca (§48) — por isso os dois sinais saem aqui, e nao no primeiro tick.
func start() -> void:
	if running:
		return
	running = true
	EventBus.queue(&"day_started", [clock.day])
	EventBus.queue(&"dawn_broke", [clock.day])


func stop() -> void:
	running = false


func _physics_process(delta: float) -> void:
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
