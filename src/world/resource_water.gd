class_name ResourceWater
extends RefCounted

const WATER := Color("527e87")
const LIGHT := Color("91b4b0")
const BANK := Color("766a48")
const HEIGHT := 18.0
const RIPPLE_STEP := 24


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
		canvas.draw_rect(Rect2(span.x + 2.0, y + 2.0, maxf(0.0, width - 4.0), HEIGHT - 2.0), WATER)
		for x in range(ceili(span.x + 4.0), floori(span.y - 4.0), RIPPLE_STEP):
			var end := minf(float(x + RIPPLE_STEP / 2), span.y - 4.0)
			canvas.draw_line(Vector2(x, y + 6.0), Vector2(end, y + 6.0), LIGHT)
			canvas.draw_line(Vector2(x + 2.0, y + 12.0), Vector2(end, y + 12.0), LIGHT)
