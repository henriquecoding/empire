class_name CrownBanner
extends Control

const HEIGHT := 68
const HALF_WIDTH := 40
const EDGE_HEIGHT := 50
const TIP := 64
const ROD := 54
const STROKE := 4
const ICON_Y := 28
const ICON_SCALE := 3


func _ready() -> void:
	custom_minimum_size.y = HEIGHT
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	resized.connect(queue_redraw)


func _draw() -> void:
	var x := floorf(size.x / 2)
	var cloth := PackedVector2Array(
		[
			Vector2(x - HALF_WIDTH, 0),
			Vector2(x + HALF_WIDTH, 0),
			Vector2(x + HALF_WIDTH, EDGE_HEIGHT),
			Vector2(x, TIP),
			Vector2(x - HALF_WIDTH, EDGE_HEIGHT),
		]
	)
	draw_colored_polygon(cloth, CrownSkin.CLOTH)
	draw_polyline(cloth + PackedVector2Array([cloth[0]]), CrownSkin.EDGE, 2)
	draw_line(Vector2(x - ROD, 2), Vector2(x + ROD, 2), CrownSkin.IRON, STROKE)
	CrownIcons.draw(self, &"crown", Vector2(x, ICON_Y), ICON_SCALE)
