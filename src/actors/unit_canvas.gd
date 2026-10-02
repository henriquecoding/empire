class_name UnitCanvas
extends Node2D

## O branco do §24 com a forma do sprite: uma camada por cima, com um shader que
## pinta de branco o que o sprite tem de opaco. Um `modulate` nao chega — so
## escurece, e um corpo nao fica branco multiplicando a cor que ja tem.
const FLASH_SHADER := "res://shaders/flash_white.gdshader"

var band: Band.Kind
var light: Lighting
var time := 0.0
var _batch := UnitArtBatch.new()
var _branco: UnitFlash


func _ready() -> void:
	material = SpriteLighting.material()
	_branco = UnitFlash.new()
	var tinta := ShaderMaterial.new()
	tinta.shader = load(FLASH_SHADER)
	_branco.material = tinta
	add_child(_branco)


func _draw() -> void:
	if SimLoop.state != null and light != null:
		_batch.draw_on(self, band, light, time)
		_branco.items = _batch.flashes.duplicate()
		_branco.queue_redraw()
