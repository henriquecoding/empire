# src/world/terrain_backdrop.gd — o cenario de uma faixa, redesenhado so quando
# a luz muda (§80, ADR 0011).
#
# O BandView redesenha a cada frame porque tudo o que ele mostra anda: tropa,
# bicho, moeda, mancha. O cenario nao anda — so muda de cor — e desenha-lo a
# cada frame era refazer dezenas de poligonos por faixa para dar exactamente a
# mesma imagem. Este no e a outra metade: um so `_draw()`, e um `queue_redraw()`
# so quando a fase ou o balde de luz mudam.
class_name TerrainBackdrop
extends Node2D

## Em quantos degraus se parte o progresso de uma fase. Oito: a luz anda
## devagar, e um degrau por fase dava um salto que se ve.
const BALDES := 8.0

@export var band: Band.Kind = Band.Kind.SURFACE

var _relogio: ClockData
var _fase := -1
var _balde := -1


func _ready() -> void:
	_relogio = Registry.entry(&"economy", &"clock") as ClockData
	queue_redraw()


func _process(_delta: float) -> void:
	if _relogio == null or ClockService.clock == null:
		return
	var fase := int(ClockService.clock.current_phase())
	var balde := int(ClockService.clock.phase_progress() * BALDES)
	if fase == _fase and balde == _balde:
		return
	_fase = fase
	_balde = balde
	queue_redraw()


func _draw() -> void:
	if _relogio == null or ClockService.clock == null:
		return
	var luz := BandLight.of(
		_relogio, band, int(ClockService.clock.current_phase()), ClockService.clock.phase_progress()
	)
	TerrainArt.draw_on(self, band, SimLoop.world_width, luz)
