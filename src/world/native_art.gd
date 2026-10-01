class_name NativeArt
extends RefCounted
const HALF := 0.5
const HEIGHT := 66.0
const GHOST := 0.3
const DOOR := Rect2(-8, -26, 16, 26)
const WINDOW := Rect2(10, -42, 12, 10)
const LINE := 3.0
const COLORS := {
	&"enramados": Color("91744c"),
	&"portuarios": Color("7597a1"),
	&"fenda": Color("bd9178"),
	&"horta": Color("b39b52"),
	&"fornalha": Color("755865"),
	&"sobraiz": Color("a286ac"),
	&"geada": Color("b8d6de"),
	&"bruma": Color("758657"),
	&"mercenary": Color("9b6c53")
}
const ROOFS := {
	&"enramados":
	[Vector2(-44, -48), Vector2(-20, -82), Vector2(0, -70), Vector2(20, -82), Vector2(44, -48)],
	&"portuarios": [Vector2(-48, -46), Vector2(0, -62), Vector2(48, -46)],
	&"fenda": [Vector2(-40, -50), Vector2(-40, -62), Vector2(40, -62), Vector2(40, -50)],
	&"horta": [Vector2(-46, -48), Vector2(0, -78), Vector2(46, -48)],
	&"fornalha":
	[
		Vector2(-42, -48),
		Vector2(-22, -64),
		Vector2(-22, -90),
		Vector2(-8, -90),
		Vector2(-8, -64),
		Vector2(42, -48)
	],
	&"sobraiz":
	[Vector2(-46, -48), Vector2(-30, -68), Vector2(0, -78), Vector2(30, -68), Vector2(46, -48)],
	&"geada":
	[Vector2(-46, -48), Vector2(-28, -76), Vector2(0, -86), Vector2(28, -76), Vector2(46, -48)],
	&"bruma": [Vector2(-44, -48), Vector2(0, -94), Vector2(44, -48)],
	&"mercenary": [Vector2(-44, -48), Vector2(0, -76), Vector2(44, -48)],
}


static func handles(kind: StringName) -> bool:
	return (
		kind == &"citizen_house"
		or String(kind).ends_with("_house") and COLORS.has(_people(kind))
		or String(kind).ends_with("_work")
		or String(kind).ends_with("_defense")
	)


static func box(slot: BuildSlot) -> Rect2:
	return Rect2(
		slot.x - slot.width * HALF,
		WorldPalette.ground_of(int(slot.band)) - HEIGHT,
		slot.width,
		HEIGHT
	)


static func draw_on(canvas: CanvasItem, slot: BuildSlot, light: Lighting, tempo: float) -> void:
	var foot := Vector2(slot.x, WorldPalette.ground_of(int(slot.band)))
	var people := _people(slot.kind)
	var color := light.body(COLORS.get(people, COLORS[&"enramados"]), slot.x)
	if not slot.holds():
		color.a = GHOST
	var body := box(slot)
	if slot.state == BuildSlot.State.RUIN:
		body.position.y = foot.y - LINE
		body.size.y = LINE
	canvas.draw_rect(body, color)
	if slot.state != BuildSlot.State.RUIN:
		var points := PackedVector2Array()
		for vertex: Vector2 in ROOFS.get(people, ROOFS[&"enramados"]):
			points.append(foot + vertex)
		canvas.draw_colored_polygon(points, color.darkened(HALF))
		canvas.draw_rect(Rect2(foot + DOOR.position, DOOR.size), color.darkened(HALF))
		canvas.draw_rect(Rect2(foot + WINDOW.position, WINDOW.size), color.lightened(HALF))
		if String(slot.kind).ends_with("_defense"):
			canvas.draw_line(
				body.position,
				body.position + Vector2(body.size.x, 0.0),
				color.lightened(HALF),
				LINE
			)
		if slot.standing():
			Gauge.health(canvas, body, float(slot.health) / maxf(1.0, slot.max_health()))
	SiteMarks.coins(canvas, foot, slot.paid, SiteStage.cost_now(slot), color)
	if slot.state in [BuildSlot.State.SCAFFOLD, BuildSlot.State.BUILDING]:
		SiteMarks.scaffold(
			canvas, body, SiteStage.built(slot), color, tempo, SiteMarks.working(slot, tempo)
		)


static func _people(kind: StringName) -> StringName:
	return &"enramados" if kind == &"citizen_house" else StringName(String(kind).get_slice("_", 0))
