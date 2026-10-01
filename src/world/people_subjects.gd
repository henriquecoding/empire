class_name PeopleSubjects
extends RefCounted
const R := ShapeArt.Forma.RECT
const P := ShapeArt.Forma.POLY
const L := ShapeArt.Forma.LINE
const C := ShapeArt.Forma.CIRCLE
const WATER := Color("4f767e")
const STONE := Color("9a8f80")
const WOOD := Color("846643")
const REED := Color("829656")
const SNOW := Color("b8d6de")
const SHAPES := {
	&"forest_pool": [[R, WATER, -34, -8, 68, 8], [L, WOOD, 3, -32, -8, 34, -8]],
	&"tidal_boat":
	[
		[P, WOOD, -38, -14, 38, -14, 24, 0, -24, 0],
		[R, WOOD, -2, -62, 4, 48],
		[P, SNOW, 2, -60, 2, -20, 30, -20]
	],
	&"stone_door":
	[[R, STONE, -40, -66, 16, 66], [R, STONE, 24, -66, 16, 66], [R, STONE, -40, -66, 80, 16]],
	&"irrigation_gate":
	[
		[R, WATER, -42, -8, 84, 8],
		[R, WOOD, -24, -40, 4, 40],
		[R, WOOD, 20, -40, 4, 40],
		[L, WOOD, 3, -24, -30, 24, -30]
	],
	&"slag_heap": [[P, STONE, -48, 0, -28, -28, -8, -16, 8, -38, 48, 0]],
	&"fungal_niche":
	[[R, STONE, -44, -54, 16, 54], [C, REED, 0, -24, 22], [R, WOOD, -4, -24, 8, 24]],
	&"ice_cairn":
	[[R, SNOW, -28, -18, 56, 18], [R, SNOW, -20, -36, 40, 18], [R, SNOW, -12, -54, 24, 18]],
	&"reed_pool":
	[
		[R, WATER, -48, -10, 96, 10],
		[L, REED, 3, -20, 0, -24, -54],
		[L, REED, 3, 18, 0, 24, -62],
		[L, REED, 3, 0, 0, 4, -48]
	],
}


static func draw(canvas: CanvasItem, subject: StringName, x: float) -> bool:
	if not SHAPES.has(subject):
		return false
	ShapeArt.draw(canvas, SHAPES[subject], Vector2(x, WildSubjects.PE))
	return true
