class_name RenewalFlora
extends RefCounted

const PROFILES := {
	Wilds.Plant.BUSH: &"royal_bush",
	Wilds.Plant.FERN: &"royal_meadow",
	Wilds.Plant.FAR_PINE: &"royal_pine",
	Wilds.Plant.FAR_OAK: &"royal_oak",
}
static var _art := OriginalArt.new()


static func draw_one(
	canvas: CanvasItem, kind: int, foot: Vector2, variant: float, mist: float, scale_factor: float
) -> bool:
	if not PROFILES.has(kind):
		return false
	var id: StringName = PROFILES[kind]
	var height := FloraArt.height(kind) * scale_factor
	var body := _art.body_box(id, Vector2.ZERO)
	var size_factor := height / body.size.y
	var facing := 1.0 if variant < 0.5 else -1.0
	var shade := Color.WHITE.lerp(EnramadosLayer.GROVE, mist)
	_art.draw_posed(
		canvas, id, shade, 0, OriginalArt.posed(foot, facing, Vector2.ONE * size_factor)
	)
	return true
