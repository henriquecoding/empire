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
## O veado (Q-150): maior, de pernas altas e com hastes.
const DEER := Color("8a6844")
const DEER_BODY := Rect2(-11, -19, 22, 9)
const DEER_NECK := Rect2(7, -26, 5, 9)
const DEER_HEAD := Rect2(9, -30, 8, 5)
const DEER_LEGS := [Rect2(-10, -10, 2, 10), Rect2(-6, -10, 2, 10), Rect2(5, -10, 2, 10)]
const DEER_ANTLERS := [Rect2(10, -36, 1, 6), Rect2(13, -37, 1, 7), Rect2(8, -35, 3, 1)]
const DEER_EYE := Vector2(14, -29)
## A toca (Q-106) e o sitio de onde o bicho sai (Q-150). Uma toca perdida nao se desenha.
const BUSH := Color("4f6a3a")
const BUSH_DARK := Color("33452a")
const BUSH_PARTS := [Rect2(-14, -10, 28, 10), Rect2(-9, -16, 18, 8), Rect2(-4, -19, 9, 5)]
const BUSH_ROOT := Rect2(-14, -2, 28, 2)
const HOLE := [Rect2(-12, -6, 24, 6), Rect2(-8, -9, 16, 3)]
const HOLE_MOUTH := Rect2(-5, -5, 10, 5)
const ROCK := Color("7c776c")
const ROCK_DARK := Color("514d46")
const ROCK_PARTS := [Rect2(-13, -12, 26, 12), Rect2(-8, -17, 15, 6)]
const ROCK_ROOT := Rect2(-13, -2, 26, 2)
const TREE_TRUNK := Rect2(-3, -30, 6, 30)
const TREE_CROWN := [Rect2(-15, -52, 30, 18), Rect2(-10, -60, 20, 9)]
const WATER := Color("4f6a72")
const WATER_LIGHT := Color("7d9aa0")
const POND := Rect2(-26, -3, 52, 5)
const POND_GLINT := Rect2(-12, -2, 9, 1)
## A toca fica ao lado de onde o bicho se senta, e nao por baixo dele.
const BUSH_SIDE := 18.0


static func draw_on(canvas: CanvasItem, light: Lighting, time: float) -> void:
	if SimLoop.hunting == null:
		return
	var tocas := SimLoop.hunting.burrows
	for k in tocas.xs.size():
		if tocas.alive[k] == 0:
			continue
		var bx: float = tocas.xs[k] - BUSH_SIDE
		var sitio := StringName(tocas.kinds[k]) if k < tocas.kinds.size() else &"bush"
		canvas.draw_set_transform(Vector2(bx, Band.GROUND_LINE))
		_sitio(canvas, sitio, light, bx)
	canvas.draw_set_transform(Vector2.ZERO)
	var manada := SimLoop.hunting.herd
	for toca in SimLoop.hunting.rabbits:
		var x := manada.where(toca)
		var bob := floorf(sin(time * BREATH + toca))
		var lado := Vector2(float(manada.facing.get(toca, 1.0)), 1.0)  # ADR 0057
		canvas.draw_set_transform(Vector2(x, Band.GROUND_LINE + bob), 0.0, lado)
		var bicho := SimLoop.hunting.species_at(toca).id
		if bicho == &"deer":
			_veado(canvas, light, x)
		elif not GameArt.draw(canvas, bicho, light, x):
			_coelho(canvas, light, x)
		canvas.draw_set_transform(Vector2.ZERO)


static func _sitio(canvas: CanvasItem, sitio: StringName, light: Lighting, bx: float) -> void:
	match sitio:
		&"hole":
			for parte: Rect2 in HOLE:
				canvas.draw_rect(parte, light.body(SHADE, bx))
			canvas.draw_rect(HOLE_MOUTH, light.body(EYE, bx))
		&"rock":
			for parte: Rect2 in ROCK_PARTS:
				canvas.draw_rect(parte, light.body(ROCK, bx))
			canvas.draw_rect(ROCK_ROOT, light.body(ROCK_DARK, bx))
		&"tree":
			canvas.draw_rect(TREE_TRUNK, light.body(SHADE, bx))
			for parte: Rect2 in TREE_CROWN:
				canvas.draw_rect(parte, light.body(BUSH, bx))
		&"lake":
			canvas.draw_rect(POND, light.body(WATER, bx))
			canvas.draw_rect(POND_GLINT, light.body(WATER_LIGHT, bx))
		_:
			for parte: Rect2 in BUSH_PARTS:
				canvas.draw_rect(parte, light.body(BUSH, bx))
			canvas.draw_rect(BUSH_ROOT, light.body(BUSH_DARK, bx))


static func _coelho(canvas: CanvasItem, light: Lighting, x: float) -> void:
	canvas.draw_rect(BODY, light.body(FUR, x))
	canvas.draw_rect(HEAD, light.body(FUR, x))
	canvas.draw_rect(TAIL, light.body(FUR, x))
	canvas.draw_rect(PAWS, light.body(SHADE, x))
	for ear in EARS:
		canvas.draw_rect(ear, light.body(FUR, x))
	canvas.draw_rect(Rect2(EYE_OFFSET, Vector2.ONE), light.body(EYE, x))


static func _veado(canvas: CanvasItem, light: Lighting, x: float) -> void:
	for perna: Rect2 in DEER_LEGS:
		canvas.draw_rect(perna, light.body(SHADE, x))
	canvas.draw_rect(DEER_BODY, light.body(DEER, x))
	canvas.draw_rect(DEER_NECK, light.body(DEER, x))
	canvas.draw_rect(DEER_HEAD, light.body(DEER, x))
	for haste: Rect2 in DEER_ANTLERS:
		canvas.draw_rect(haste, light.body(SHADE, x))
	canvas.draw_rect(Rect2(DEER_EYE, Vector2.ONE), light.body(EYE, x))
