class_name ClassPortrait
extends Control

const HEIGHT := 158
const HALF := 0.5
const PORTRAITS := {
	&"monarch": preload("res://art/export/renewal/portrait_king.png"),
	&"nia": preload("res://art/export/renewal/portrait_nia.png"),
	&"archer_emperor": preload("res://art/export/renewal/portrait_archer.png"),
}
var monarch_id: StringName = &"monarch"


func _ready() -> void:
	custom_minimum_size.y = HEIGHT
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	resized.connect(queue_redraw)


func _draw() -> void:
	var portrait: Texture2D = PORTRAITS.get(monarch_id, PORTRAITS[&"monarch"])
	var factor := minf(size.x / portrait.get_width(), size.y / portrait.get_height())
	var target := portrait.get_size() * factor
	var origin := (size - target) * HALF
	draw_texture_rect(portrait, Rect2(origin, target), false)
