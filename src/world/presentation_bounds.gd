class_name PresentationBounds
extends RefCounted

const MARGIN := 96.0


static func of(canvas: CanvasItem) -> Rect2:
	var viewport := canvas.get_viewport_rect()
	var inverse := canvas.get_canvas_transform().affine_inverse()
	return (inverse * viewport).grow(MARGIN)
