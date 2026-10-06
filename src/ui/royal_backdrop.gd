class_name RoyalBackdrop
extends Control

const LANDSCAPE := preload("res://art/export/renewal/valley.png")
const HALF := 0.5
const SHADE := Color(0.035, 0.075, 0.075, 0.78)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	resized.connect(queue_redraw)


func _draw() -> void:
	var scale_factor := maxf(size.x / LANDSCAPE.get_width(), size.y / LANDSCAPE.get_height())
	var target := LANDSCAPE.get_size() * scale_factor
	draw_texture_rect(LANDSCAPE, Rect2((size - target) * HALF, target), false)
	draw_rect(Rect2(Vector2.ZERO, size), SHADE)
