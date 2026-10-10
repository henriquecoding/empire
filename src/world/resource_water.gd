class_name ResourceWater
extends RefCounted

const WATER := Color("527e87")
const LIGHT := Color("91b4b0")
const BANK := Color("766a48")
const HEIGHT := 18.0
const RIPPLE_STEP := 24
const INSET := 2.0
const MARGIN := 4.0
const RIPPLE_Y := 6.0
const LOWER_Y := 12.0


## A agua funcional usa exactamente a fonte que autoriza o pesqueiro.
static func draw(canvas: CanvasItem, window := Vector2(-INF, INF)) -> void:
	for source: Dictionary in TerritoryWatch.sources(0.0, {TerritoryWatch.AGUA: true}):
		var span: Vector2 = source[PlacementRules.SPAN]
		span = Vector2(maxf(span.x, window.x), minf(span.y, window.y))
		var width := span.y - span.x
		if width <= 0.0:
			continue
		var y := float(Band.GROUND_LINE) - HEIGHT
		canvas.draw_rect(Rect2(span.x, y, width, HEIGHT), BANK)
		canvas.draw_rect(
			Rect2(span.x + INSET, y + INSET, maxf(0.0, width - MARGIN), HEIGHT - INSET), WATER
		)
		for x in range(ceili(span.x + MARGIN), floori(span.y - MARGIN), RIPPLE_STEP):
			var end := minf(float(x + RIPPLE_STEP / 2), span.y - MARGIN)
			canvas.draw_line(Vector2(x, y + RIPPLE_Y), Vector2(end, y + RIPPLE_Y), LIGHT)
			canvas.draw_line(Vector2(x + INSET, y + LOWER_Y), Vector2(end, y + LOWER_Y), LIGHT)
