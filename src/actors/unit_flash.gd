# src/actors/unit_flash.gd — o flash branco de 80 ms, com a forma do sprite (§24).
#
# Os sprites de quem acabou de levar um golpe, outra vez, por cima, com o shader
# que os pinta de branco. A lista vem do UnitArtBatch, que e quem sabe a pose.
class_name UnitFlash
extends Node2D

## [perfil, frame, pose, alfa] — o que o UnitArtBatch junta.
const PERFIL := 0
const FRAME := 1
const POSE := 2
const ALFA := 3

var items: Array[Array] = []
var _art := OriginalArt.new()


func _draw() -> void:
	for item in items:
		var alfa: float = item[ALFA]
		_art.draw_posed(self, item[PERFIL], Color(1.0, 1.0, 1.0, alfa), item[FRAME], item[POSE])
