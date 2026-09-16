class_name TerrainBackdrop
extends Node2D

## O cenário é estático entre amostras de luz. Isto evita reconstruir dezenas de
## polígonos por faixa a cada frame só porque a simulação continua a andar.
@export var band: Band.Kind = Band.Kind.SURFACE

var _clock_data: ClockData
var _last_phase := -1
var _last_bucket := -1


func _ready() -> void:
	_clock_data = Registry.entry(&"economy", &"clock") as ClockData
	queue_redraw()


func _process(_delta: float) -> void:
	if _clock_data == null or ClockService.clock == null:
		return
	var fase := int(ClockService.clock.current_phase())
	var balde := int(ClockService.clock.phase_progress() * 8.0)
	if fase == _last_phase and balde == _last_bucket:
		return
	_last_phase = fase
	_last_bucket = balde
	queue_redraw()


func _draw() -> void:
	if _clock_data == null or SimLoop.state == null:
		return
	var largura := maxf(SimLoop.world_width, float(Band.SCREEN_BOTTOM))
	var faixa := BandLight.of(
		_clock_data,
		band,
		int(ClockService.clock.current_phase()),
		ClockService.clock.phase_progress()
	)
	TerrainArt.draw_on(self, band, largura, faixa)
