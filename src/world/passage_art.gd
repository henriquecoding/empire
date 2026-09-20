class_name PassageArt
extends RefCounted

const SIDES := [-1.0, 1.0]
const WIDTH := 28.0
const HALF := 0.5
const RUNG := 8
const RAIL := 3.0
const WOOD := Color("b29965")
const SHAFT := Color("171912")
const FRAME := Color("716143")


static func draw_on(canvas: CanvasItem, light: Lighting) -> void:
	var top := WorldPalette.ground_of(int(Band.Kind.SURFACE))
	var bottom := WorldPalette.ground_of(int(Band.Kind.UNDERGROUND))
	for x in SimLoop.passages:
		var rect := Rect2(x - WIDTH * HALF, top, WIDTH, bottom - top)
		canvas.draw_rect(rect.grow(RAIL), light.body(FRAME, x))
		canvas.draw_rect(rect, light.body(SHAFT, x))
		for side in SIDES:
			var rail_x: float = x + side * (WIDTH * HALF - RAIL)
			canvas.draw_line(
				Vector2(rail_x, top), Vector2(rail_x, bottom), light.body(WOOD, x), RAIL
			)
		for y in range(int(top), int(bottom), RUNG):
			canvas.draw_line(
				Vector2(rect.position.x, y), Vector2(rect.end.x, y), light.body(WOOD, x), RAIL
			)
