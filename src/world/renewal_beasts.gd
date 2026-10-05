class_name RenewalBeasts
extends RefCounted

static var _art := OriginalArt.new()


static func handles(form: Silhouette.Form) -> bool:
	return RenewalArt.CREATURES.has(form)


static func pose(form: Silhouette.Form, box: Rect2, facing: float) -> Transform2D:
	var id: StringName = RenewalArt.CREATURES[form]
	var body := _art.body_box(id, Vector2.ZERO)
	var scale := box.size.y / body.size.y
	return OriginalArt.posed(Vector2(box.get_center().x, box.end.y), facing, Vector2.ONE * scale)


static func draw(
	canvas: CanvasItem, form: Silhouette.Form, box: Rect2, facing: float, look: Dictionary
) -> void:
	var id: StringName = RenewalArt.CREATURES[form]
	var frame := _art.frame_at(id, float(look.time), &"walk" if look.moving else &"idle")
	var transform := pose(form, box, facing)
	_art.draw_posed(canvas, id, look.tint, frame, transform)
	_art.mask_posed(canvas, id, Color.WHITE, frame, transform, "eyes_texture")
	if float(look.flash) > 0.0:
		_art.mask_posed(canvas, id, Color(1.0, 1.0, 1.0, look.flash), frame, transform)


static func silhouette(
	canvas: CanvasItem, form: Silhouette.Form, box: Rect2, color: Color, facing: float
) -> void:
	var id: StringName = RenewalArt.CREATURES[form]
	_art.mask_posed(canvas, id, color, 0, pose(form, box, facing))
