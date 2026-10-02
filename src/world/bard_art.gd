class_name BardArt
extends RefCounted

const WOOD := Color("bb8858")
const EDGE := Color("5c3a29")
const STRING := Color("eee3b8")
const CENTER := Vector2(0.75, 0.66)
const BODY := Vector2(0.12, 0.16)
const NECK := Vector2(0.14, -0.22)
const NOTES := [Vector2(0.0, -0.75), Vector2(0.18, -0.9)]
const DIAMETER := 2.0
const NECK_STROKE := 4.0
const NOTE_SIZE := Vector2(4, 3)
const NOTE_BOTTOM := Vector2(3, 1)
const NOTE_TOP := Vector2(3, -5)


static func draw_on(canvas: CanvasItem, box: Rect2, singing: float) -> void:
	var center := box.position + box.size * CENTER
	var radius := box.size * BODY
	canvas.draw_rect(Rect2(center - radius, radius * DIAMETER), EDGE)
	canvas.draw_rect(
		Rect2(center - radius + Vector2.ONE, radius * DIAMETER - Vector2.ONE * DIAMETER), WOOD
	)
	var neck := center + box.size * NECK
	canvas.draw_line(center, neck, EDGE, NECK_STROKE)
	canvas.draw_line(center, neck, STRING, 1.0)
	if singing > 0.0:
		for note: Vector2 in NOTES:
			var point := center + box.size * note
			canvas.draw_rect(Rect2(point, NOTE_SIZE), STRING)
			canvas.draw_line(point + NOTE_BOTTOM, point + NOTE_TOP, STRING)
