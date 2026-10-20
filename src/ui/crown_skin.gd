class_name CrownSkin
extends RefCounted

const WOOD := Color("493327")
const GRAIN := Color("36271f")
const EDGE := Color("95744e")
const IRON := Color("62605a")
const SHADOW := Color("171515")
const CLOTH := Color("562b34")

const SIZE := 32
const PADDING := 12
const SLICE := 10
const RIM := Rect2i(2, 2, 28, 27)
const TRIM := Rect2i(4, 4, 24, 23)
const FACE := Rect2i(6, 6, 20, 19)
const LIGHT := Rect2i(6, 7, 20, 1)
const SHADE := Rect2i(6, 23, 20, 2)
const LIGHT_GAIN := 0.07
const SHADE_GAIN := 0.2
const CORNERS := [Vector2i(2, 2), Vector2i(24, 2), Vector2i(2, 24), Vector2i(24, 24)]
const CAP := Vector2i(6, 6)
const FRAME_PADDING := 24
const FRAME_INSET := 12
const GRAIN_STEP := 16
const GRAIN_INSET := 4

static var _plates := {}


static func plate(fill: Color = Atlas.FIELD, padding: int = PADDING) -> StyleBoxTexture:
	if not _plates.has(fill):
		var image := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
		image.fill(SHADOW)
		image.fill_rect(RIM, WOOD)
		image.fill_rect(TRIM, EDGE)
		image.fill_rect(FACE, fill)
		image.fill_rect(LIGHT, fill.lightened(LIGHT_GAIN))
		image.fill_rect(SHADE, fill.darkened(SHADE_GAIN))
		for point: Vector2i in CORNERS:
			image.fill_rect(Rect2i(point, CAP), IRON)
			image.fill_rect(Rect2i(point + Vector2i(2, 2), Vector2i(2, 2)), Atlas.COIN)
		_plates[fill] = ImageTexture.create_from_image(image)
	var style := StyleBoxTexture.new()
	style.texture = _plates[fill]
	for side: Side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_texture_margin(side, SLICE)
		style.set_content_margin(side, padding)
	return style


static func frame(ci: CanvasItem, rect: Rect2) -> void:
	ci.draw_style_box(plate(WOOD, FRAME_PADDING), rect)
	var inside := rect.grow(-FRAME_INSET)
	ci.draw_rect(inside, Atlas.FIELD)
	for y in range(int(inside.position.y) + GRAIN_INSET, int(inside.end.y), GRAIN_STEP):
		ci.draw_line(Vector2(inside.position.x, y), Vector2(inside.end.x, y), GRAIN, 2)
	ci.draw_rect(inside.grow(-GRAIN_INSET), Atlas.FIELD)
