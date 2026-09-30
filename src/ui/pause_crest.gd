class_name PauseCrest
extends Control

const GOLD := Color("cfa35c")
const LIGHT := Color("f1d38b")
const EDGE := Color("282621")
const LEAF := Color("74805b")
const BARK := Color("493a2a")
const GRID := Vector2(64, 62)
const MINIMUM_SIZE := Vector2(256, 248)
const INNER_INSET := 4
const TRUNK := Rect2(29, 29, 6, 25)
const TRUNK_LIGHT := Rect2(31, 28, 2, 26)
const ROOTS := Rect2(24, 52, 16, 3)
const BRANCH_LEFT := Vector2(23, 34)
const BRANCH_RIGHT := Vector2(36, 36)
const BRANCH_SIZE := Vector2(3, 3)
const BRANCH_LENGTH := 6
const CROWN_EDGE := Rect2(20, 12, 24, 5)
const CROWN_BASE := Rect2(22, 11, 20, 4)
const CROWN_LIGHT := Rect2(22, 13, 20, 1)
const TEETH := [Rect2(22, 7, 4, 7), Rect2(30, 5, 4, 7), Rect2(38, 7, 4, 7)]
const TOOTH_LIGHT := Vector2(3, 2)
const LAUREL_ORIGIN := Vector2(32, 23)
const LAUREL_SPREAD := 23
const LAUREL_BEND := 4
const LAUREL_LENGTH := 10
const LAUREL_STRIDE := 3
const LAUREL_LEAF := Vector2(3, 2)
const SHIELD := [
	Vector2(13, 17),
	Vector2(51, 17),
	Vector2(51, 43),
	Vector2(46, 51),
	Vector2(32, 60),
	Vector2(18, 51),
	Vector2(13, 43),
]
const INSET_DIRECTION := [
	Vector2(1, 1),
	Vector2(-1, 1),
	Vector2(-1, -1),
	Vector2(-1, -1),
	Vector2(0, -1),
	Vector2(1, -1),
	Vector2(1, -1),
]
const FOLIAGE := [
	Rect2(23, 19, 18, 6),
	Rect2(18, 25, 28, 8),
	Rect2(15, 33, 34, 6),
	Rect2(20, 39, 24, 4),
]


func _ready() -> void:
	custom_minimum_size = MINIMUM_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var step := floorf(minf(size.x / GRID.x, size.y / GRID.y))
	var origin := (size - GRID * step) / 2
	draw_set_transform(origin.floor(), 0.0, Vector2.ONE * step)
	_shield(EDGE, 0)
	_shield(GOLD, 2)
	_shield(Color("414b39"), INNER_INSET)
	for patch: Rect2 in FOLIAGE:
		draw_rect(patch, LEAF)
		draw_rect(Rect2(patch.position, Vector2(patch.size.x, 2)), Color("97a06f"))
	draw_rect(TRUNK, BARK)
	draw_rect(TRUNK_LIGHT, Color("b09462"))
	for i in BRANCH_LENGTH:
		draw_rect(Rect2(BRANCH_LEFT + Vector2(i, i), BRANCH_SIZE), BARK)
		draw_rect(Rect2(BRANCH_RIGHT + Vector2(-i, i), BRANCH_SIZE), BARK)
	draw_rect(ROOTS, BARK)
	draw_rect(CROWN_EDGE, EDGE)
	draw_rect(CROWN_BASE, GOLD)
	for tooth: Rect2 in TEETH:
		draw_rect(tooth, GOLD)
		draw_rect(Rect2(tooth.position, TOOTH_LIGHT), LIGHT)
	draw_rect(CROWN_LIGHT, LIGHT)
	for side: int in [-1, 1]:
		for i in LAUREL_LENGTH:
			var point := (
				LAUREL_ORIGIN
				+ Vector2(side * (LAUREL_SPREAD + mini(i, LAUREL_BEND)), i * LAUREL_STRIDE)
			)
			draw_rect(Rect2(point, LAUREL_LEAF), Color("81704a"))
			point += Vector2(-side * LAUREL_LEAF.x, 1)
			draw_rect(Rect2(point, LAUREL_LEAF), Color("5b6047"))


func _shield(color: Color, inset: int) -> void:
	var points := PackedVector2Array(SHIELD)
	for i in points.size():
		points[i] += INSET_DIRECTION[i] * inset
	draw_colored_polygon(points, color)
