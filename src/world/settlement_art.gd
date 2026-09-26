class_name SettlementArt
extends RefCounted

const HALF := 0.5
const GHOST := 0.28
const SOIL := Color("5e4530")
const TIMBER := Color("97794f")
const LIGHT := Color("ceb77e")
const LEAF := Color("849b45")
const ROOF := Color("85563b")
const WATER := Color("536e6e")
const DARK := Color("352c25")
const STEP := 12
const RAIL := 3.0
const FARM_HEIGHT := 32.0
const FARM_ROWS := [-26.0, -15.0, -4.0]
const LEAF_SIZE := Vector2(4, 6)
const FENCE_TOP := -38.0
const HEN_BODY := Rect2(-3, -6, 8, 5)
const HEN_HEAD := Rect2(3, -9, 4, 5)
const HEN_OFFSETS := [-18.0, 8.0, 27.0]
const SHED := Rect2(-26, -66, 52, 56)
const DOOR := Rect2(-8, -37, 16, 27)
const ROOF_POINTS := [Vector2(-34, -62), Vector2(0, -92), Vector2(34, -62)]
const POND_Y := -16.0
const POND_HEIGHT := 22.0
const POST_HEIGHT := 64.0
const NET_DROP := 24.0


static func handles(kind: StringName) -> bool:
	return kind in [&"farm", &"henhouse", &"fishery"]


static func draw_on(canvas: CanvasItem, site: BuildSlot, light: Lighting) -> void:
	var color := light.body(Color.WHITE, site.x)
	if site.state == BuildSlot.State.EMPTY:
		color.a = GHOST
	var foot := Vector2(site.x, WorldPalette.ground_of(int(site.band)))
	canvas.draw_set_transform(foot)
	if site.state == BuildSlot.State.RUIN:
		canvas.draw_rect(Rect2(-site.width * HALF, -RAIL, site.width, RAIL), TIMBER * color)
	elif site.kind == &"farm":
		_farm(canvas, site.width, color)
	elif site.kind == &"henhouse":
		_henhouse(canvas, color)
	else:
		_fishery(canvas, site.width, color)
	canvas.draw_set_transform(Vector2.ZERO)
	var box := Rect2(
		foot - Vector2(site.width * HALF, FARM_HEIGHT), Vector2(site.width, FARM_HEIGHT)
	)
	Gauge.paid(canvas, box, site)
	if site.state in [BuildSlot.State.SCAFFOLD, BuildSlot.State.BUILDING]:
		canvas.draw_line(box.position, box.end, TIMBER * color, RAIL)
	if site.standing():
		Gauge.health(canvas, box, float(site.health) / maxf(1.0, site.max_health()))


static func _farm(canvas: CanvasItem, width: float, color: Color) -> void:
	canvas.draw_rect(Rect2(-width * HALF, -FARM_HEIGHT, width, FARM_HEIGHT), SOIL * color)
	for y in FARM_ROWS:
		for x in range(int(-width * HALF), int(width * HALF), STEP):
			canvas.draw_rect(Rect2(Vector2(x, y), LEAF_SIZE), LEAF * color)
			canvas.draw_line(Vector2(x, y), Vector2(x + LEAF_SIZE.x, y - RAIL), LIGHT * color)
	for x in [-width * HALF, width * HALF]:
		canvas.draw_line(Vector2(x, 0), Vector2(x, FENCE_TOP), TIMBER * color, RAIL)
	canvas.draw_line(
		Vector2(-width * HALF, -FARM_HEIGHT),
		Vector2(width * HALF, -FARM_HEIGHT),
		TIMBER * color,
		RAIL
	)


static func _henhouse(canvas: CanvasItem, color: Color) -> void:
	canvas.draw_rect(SHED, TIMBER * color)
	canvas.draw_colored_polygon(PackedVector2Array(ROOF_POINTS), ROOF * color)
	canvas.draw_rect(DOOR, DARK * color)
	for x in HEN_OFFSETS:
		canvas.draw_rect(Rect2(HEN_BODY.position + Vector2(x, 0), HEN_BODY.size), LIGHT * color)
		canvas.draw_rect(Rect2(HEN_HEAD.position + Vector2(x, 0), HEN_HEAD.size), LIGHT * color)


static func _fishery(canvas: CanvasItem, width: float, color: Color) -> void:
	canvas.draw_rect(Rect2(-width * HALF, POND_Y, width, POND_HEIGHT), WATER * color)
	for x in range(int(-width * HALF), int(width * HALF), STEP):
		canvas.draw_rect(Rect2(x, -RAIL, STEP - 1, RAIL), TIMBER * color)
	canvas.draw_line(Vector2.ZERO, Vector2(0, -POST_HEIGHT), TIMBER * color, RAIL)
	canvas.draw_line(
		Vector2(0, -POST_HEIGHT), Vector2(width * HALF, -POST_HEIGHT), TIMBER * color, RAIL
	)
	for x in range(0, int(width * HALF), STEP):
		canvas.draw_line(Vector2(x, -POST_HEIGHT), Vector2(x, -NET_DROP), LIGHT * color)
	canvas.draw_line(Vector2(0, -NET_DROP), Vector2(width * HALF, -NET_DROP), LIGHT * color)
