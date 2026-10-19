class_name ClassPortrait
extends Control

const HEIGHT := 158
const HALF := 0.5
const FRAME_FIT := Vector2(130, 68)
const BODY_HEIGHT := 64.0
const OFFSETS := [-28.0, 40.0]
const PAIRS := {
	&"monarch": [&"royal_king", &"royal_squire"],
	&"nia": [&"royal_nia", &"royal_bard"],
	&"archer_emperor": [&"royal_archer", &"royal_quiver"]
}
var monarch_id: StringName = &"monarch"
var _time := 0.0
var _art := OriginalArt.new()


func _ready() -> void:
	custom_minimum_size.y = HEIGHT
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	resized.connect(queue_redraw)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var pair: Array = PAIRS.get(monarch_id, PAIRS[&"monarch"])
	var zoom := maxf(1.0, floorf(minf(size.x / FRAME_FIT.x, size.y / FRAME_FIT.y)))
	var ground := floorf((size.y + BODY_HEIGHT * zoom) * HALF)
	var center := floorf(size.x * HALF)
	for k in pair.size():
		var foot := Vector2(center + float(OFFSETS[k]) * zoom, ground)
		var frame := _art.frame_at(pair[k], _time, &"idle")
		RoyalArt.preview(self, pair[k], frame, foot, zoom)
