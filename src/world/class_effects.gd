class_name ClassEffects
extends RefCounted

const ALLY := Color("97d1ab")
const MARK := Color("f0c679")
const PERMANENT := Color("cab4ec")
const FLAG_HEIGHT := 12.0
const FLAG_WIDTH := 7.0
const STROKE := 2.0


static func draw_on(canvas: CanvasItem, band: Band.Kind) -> void:
	var creatures := SimLoop.creatures
	var field := SimLoop.field
	for i in creatures.count():
		if creatures.bands[i] != int(band):
			continue
		var id := creatures.ids[i]
		var allied := field.song.allies.has(id)
		var marked := false
		for owner: int in field.focus.targets:
			marked = marked or field.focus.marked(id, owner)
		if not allied and not marked:
			continue
		var data := Registry.entry(&"creatures", creatures.data_ids[i]) as CreatureData
		var height := WorldPalette.DEGRAU * maxi(1, data.scale_tier)
		var x := Smoothing.x_of(Smoothing.Group.CREATURES, id, creatures.xs[i])
		var top := Vector2(x, WorldPalette.ground_of(int(band)) - height - FLAG_HEIGHT)
		var color := ALLY if allied else MARK
		if allied and bool(field.song.allies[id][&"permanent"]):
			color = PERMANENT
		if allied:
			canvas.draw_line(
				top + Vector2(-FLAG_WIDTH, 0), top + Vector2(0, FLAG_WIDTH), color, STROKE
			)
			canvas.draw_line(
				top + Vector2(0, FLAG_WIDTH), top + Vector2(FLAG_WIDTH, 0), color, STROKE
			)
		else:
			var points := PackedVector2Array(
				[
					top + Vector2(-FLAG_WIDTH, 0),
					top + Vector2(FLAG_WIDTH, 0),
					top + Vector2(0, FLAG_WIDTH)
				]
			)
			canvas.draw_colored_polygon(points, color)
