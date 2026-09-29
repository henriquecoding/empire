class_name HuntView
extends RefCounted

const FUR := Color("baad84")
const SHADE := Color("574b39")
const EYE := Color("241f18")
const BODY := Rect2(-6, -8, 12, 7)
const HEAD := Rect2(3, -11, 6, 7)
const EARS := [Rect2(4, -18, 2, 8), Rect2(7, -17, 2, 7)]
const TAIL := Rect2(-9, -7, 4, 4)
const PAWS := Rect2(-4, -2, 11, 2)
const EYE_OFFSET := Vector2(7, -9)
const BREATH := 2.0
## A toca (Q-106): um arbusto baixo onde o bicho sai. Uma toca perdida nao se desenha.
const BUSH := Color("4f6a3a")
const BUSH_DARK := Color("33452a")
const BUSH_PARTS := [Rect2(-14, -10, 28, 10), Rect2(-9, -16, 18, 8), Rect2(-4, -19, 9, 5)]


static func draw_on(canvas: CanvasItem, light: Lighting, time: float) -> void:
	if SimLoop.hunting == null:
		return
	var tocas := SimLoop.hunting.burrows
	for k in tocas.xs.size():
		if tocas.alive[k] == 0:
			continue
		var bx: float = tocas.xs[k] - 18.0
		canvas.draw_set_transform(Vector2(bx, Band.GROUND_LINE))
		for parte: Rect2 in BUSH_PARTS:
			canvas.draw_rect(parte, light.body(BUSH, bx))
		canvas.draw_rect(Rect2(-14, -2, 28, 2), light.body(BUSH_DARK, bx))
	canvas.draw_set_transform(Vector2.ZERO)
	for x in SimLoop.hunting.rabbits:
		var bob := floorf(sin(time * BREATH + x))
		canvas.draw_set_transform(Vector2(x, Band.GROUND_LINE + bob))
		canvas.draw_rect(BODY, light.body(FUR, x))
		canvas.draw_rect(HEAD, light.body(FUR, x))
		canvas.draw_rect(TAIL, light.body(FUR, x))
		canvas.draw_rect(PAWS, light.body(SHADE, x))
		for ear in EARS:
			canvas.draw_rect(ear, light.body(FUR, x))
		canvas.draw_rect(Rect2(EYE_OFFSET, Vector2.ONE), light.body(EYE, x))
		canvas.draw_set_transform(Vector2.ZERO)
