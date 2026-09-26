class_name UnitCanvas
extends Node2D

var band: Band.Kind
var light: Lighting
var time := 0.0
var _batch := UnitArtBatch.new()


func _ready() -> void:
	material = SpriteLighting.material()


func _draw() -> void:
	if SimLoop.state != null and light != null:
		_batch.draw_on(self, band, light, time)
