class_name BuildingSkins
extends RefCounted

const GHOST_ALPHA := 0.18
const HALF := 0.5
const RUIN_HEIGHT := 0.25
const TIMBER := Color("776343")
const STONE := Color("746c54")
const BEAM := 4.0
const BEAM_SPACING := 32.0

static var art := OriginalArt.new()


static func profile(kind: StringName) -> StringName:
	match kind:
		BuildSlot.NUCLEO:
			return &"tree_castle"
		&"training_house":
			return &"training_house"
	return &""


static func draw_on(canvas: CanvasItem, slot: BuildSlot, light: Lighting) -> bool:
	var skin := profile(slot.kind)
	if skin.is_empty():
		return false
	var foot := Vector2(slot.x, WorldPalette.ground_of(int(slot.band)))
	var box := art.box(skin, foot)
	var color := light.body(Color.WHITE, slot.x)
	if slot.state == BuildSlot.State.EMPTY:
		color.a = GHOST_ALPHA
	elif slot.state == BuildSlot.State.RUIN:
		var height := box.size.y * RUIN_HEIGHT
		var size := Vector2(box.size.x, height)
		var source := Rect2(Vector2(0.0, box.size.y - height), size)
		canvas.draw_texture_rect_region(
			art.texture(skin), Rect2(box.end - size, size), source, color
		)
		return true
	art.draw_on(canvas, skin, foot, color)
	if slot.state in [BuildSlot.State.SCAFFOLD, BuildSlot.State.BUILDING]:
		for x in range(int(box.position.x), int(box.end.x), int(BEAM_SPACING)):
			canvas.draw_line(Vector2(x, box.end.y), Vector2(x, box.position.y), TIMBER, BEAM)
		canvas.draw_line(box.position, box.end, TIMBER, BEAM)
	if slot.state == BuildSlot.State.DAMAGED:
		var center := box.get_center()
		canvas.draw_polyline(
			PackedVector2Array(
				[
					center - Vector2(BEAM_SPACING, BEAM_SPACING),
					center,
					center + Vector2(-BEAM, BEAM_SPACING)
				]
			),
			light.body(STONE, slot.x),
			BEAM
		)
	Gauge.paid(canvas, box, slot)
	if slot.standing():
		Gauge.health(canvas, box, float(slot.health) / maxf(1.0, slot.max_health()))
	return true
