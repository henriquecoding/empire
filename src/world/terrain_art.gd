class_name TerrainArt
extends RefCounted

# Arte procedural de fundo: poucos planos grandes e detalhes deterministas.
# Fica separado dos atores para que o mundo possa ser desenhado uma vez por
# mudança de fase, em vez de refazer o cenário inteiro a cada frame.

const SKY_TOP := Color(0.15, 0.24, 0.34)
const SKY_BOTTOM := Color(0.76, 0.67, 0.49)
const FAR_MOUNTAIN := Color(0.18, 0.22, 0.27)
const NEAR_MOUNTAIN := Color(0.25, 0.28, 0.28)
const FIELD := Color(0.39, 0.45, 0.25)
const FIELD_LIGHT := Color(0.57, 0.56, 0.30)
const PATH := Color(0.65, 0.49, 0.29)
const SOIL := Color(0.34, 0.21, 0.13)
const SOIL_LIGHT := Color(0.48, 0.29, 0.16)
const ROCK := Color(0.13, 0.12, 0.15)
const ROCK_LIGHT := Color(0.22, 0.19, 0.19)
const ROOT := Color(0.30, 0.18, 0.11)
const HOUSE := Color(0.28, 0.22, 0.20)
const ROOF := Color(0.16, 0.14, 0.17)
const LEAF := Color(0.20, 0.31, 0.23)
const TRUNK := Color(0.25, 0.16, 0.10)
const WINDOW := Color(0.95, 0.66, 0.28)


static func draw_on(canvas: CanvasItem, faixa: Band.Kind, width: float, light: Color) -> void:
	var largura := maxf(width, 1280.0)
	match faixa:
		Band.Kind.AERIAL:
			_aerial(canvas, largura, light)
		Band.Kind.SURFACE:
			_surface(canvas, largura, light)
		Band.Kind.UNDERGROUND:
			_underground(canvas, largura, light)


static func _aerial(canvas: CanvasItem, width: float, light: Color) -> void:
	var strip := float(Band.GROUND_LINE) / 8.0
	for i in 8:
		var t := float(i) / 7.0
		var cor := _paint(SKY_TOP.lerp(SKY_BOTTOM, t), light)
		canvas.draw_rect(Rect2(0.0, strip * float(i), width, strip + 2.0), cor)

	canvas.draw_circle(Vector2(width * 0.79, 112.0), 38.0, _paint(WINDOW, light))
	var far := PackedVector2Array([
		Vector2(0.0, 365.0),
		Vector2(width * 0.12, 320.0),
		Vector2(width * 0.22, 350.0),
		Vector2(width * 0.36, 274.0),
		Vector2(width * 0.50, 346.0),
		Vector2(width * 0.64, 290.0),
		Vector2(width * 0.79, 344.0),
		Vector2(width * 0.91, 305.0),
		Vector2(width, 350.0),
		Vector2(width, 420.0),
		Vector2(0.0, 420.0),
	])
	canvas.draw_colored_polygon(far, _paint(FAR_MOUNTAIN, light))
	var near := PackedVector2Array([
		Vector2(0.0, 407.0),
		Vector2(width * 0.16, 363.0),
		Vector2(width * 0.30, 392.0),
		Vector2(width * 0.47, 330.0),
		Vector2(width * 0.61, 397.0),
		Vector2(width * 0.76, 351.0),
		Vector2(width, 391.0),
		Vector2(width, 446.0),
		Vector2(0.0, 446.0),
	])
	canvas.draw_colored_polygon(near, _paint(NEAR_MOUNTAIN, light))

	# Silhuetas distantes dão escala ao horizonte sem competir com a região jogável.
	for i in 9:
		var x := width * (0.035 + float(i) * 0.117)
		_tree(canvas, Vector2(x, 420.0), 0.72, _paint(LEAF, light), _paint(TRUNK, light))
	_house(canvas, Vector2(width * 0.23, 420.0), 0.72, light)
	_house(canvas, Vector2(width * 0.88, 420.0), 0.58, light)


static func _surface(canvas: CanvasItem, width: float, light: Color) -> void:
	canvas.draw_rect(
		Rect2(0.0, float(Band.HORIZON), width, float(Band.GROUND_LINE - Band.HORIZON)),
		_paint(Color(0.32, 0.39, 0.29), light)
	)
	var hill := PackedVector2Array([
		Vector2(0.0, 494.0),
		Vector2(width * 0.16, 454.0),
		Vector2(width * 0.31, 480.0),
		Vector2(width * 0.49, 438.0),
		Vector2(width * 0.67, 477.0),
		Vector2(width * 0.84, 447.0),
		Vector2(width, 474.0),
		Vector2(width, float(Band.GROUND_LINE)),
		Vector2(0.0, float(Band.GROUND_LINE)),
	])
	canvas.draw_colored_polygon(hill, _paint(FIELD, light))
	_field_rows(canvas, width, light)

	var path := PackedVector2Array([
		Vector2(0.0, 505.0),
		Vector2(width * 0.19, 498.0),
		Vector2(width * 0.37, 511.0),
		Vector2(width * 0.55, 491.0),
		Vector2(width * 0.73, 505.0),
		Vector2(width, 493.0),
	])
	canvas.draw_polyline(path, _paint(PATH, light), 18.0)
	canvas.draw_polyline(path, _paint(PATH.lightened(0.18), light), 2.0)

	_tree(canvas, Vector2(width * 0.09, 517.0), 1.1, _paint(LEAF, light), _paint(TRUNK, light))
	_tree(canvas, Vector2(width * 0.91, 517.0), 0.88, _paint(LEAF, light), _paint(TRUNK, light))
	_house(canvas, Vector2(width * 0.18, 517.0), 1.0, light)
	_house(canvas, Vector2(width * 0.77, 517.0), 0.92, light)
	_soil(canvas, width, light)
	canvas.draw_line(
		Vector2(0.0, float(Band.GROUND_LINE)),
		Vector2(width, float(Band.GROUND_LINE)),
		_paint(WorldPalette.LINHA, light), WorldPalette.CONTORNO
	)


static func _field_rows(canvas: CanvasItem, width: float, light: Color) -> void:
	for i in 5:
		var y := 462.0 + float(i) * 10.0
		var start := width * (0.04 + float(i % 2) * 0.12)
		var finish := width * (0.42 + float(i % 3) * 0.14)
		canvas.draw_line(
			Vector2(start, y), Vector2(finish, y - 5.0),
			_paint(FIELD_LIGHT, light), 3.0
		)
	for i in 4:
		var x := width * (0.52 + float(i) * 0.095)
		canvas.draw_line(
			Vector2(x, 467.0), Vector2(x + 16.0, 505.0),
			_paint(FIELD_LIGHT, light), 3.0
		)


static func _soil(canvas: CanvasItem, width: float, light: Color) -> void:
	canvas.draw_rect(
		Rect2(0.0, float(Band.GROUND_LINE), width, float(Band.SCREEN_BOTTOM - Band.GROUND_LINE)),
		_paint(SOIL, light)
	)
	for i in 6:
		var y := float(Band.GROUND_LINE) + 18.0 + float(i) * 28.0
		canvas.draw_line(
			Vector2(0.0, y), Vector2(width, y + sin(float(i) * 2.1) * 5.0),
			_paint(SOIL_LIGHT, light), 2.0
		)
	for i in 7:
		var x := width * (0.07 + float(i) * 0.139)
		var root := PackedVector2Array([
			Vector2(x, 517.0),
			Vector2(x - 12.0, 548.0 + float(i % 3) * 12.0),
			Vector2(x + 7.0, 577.0),
		])
		canvas.draw_polyline(root, _paint(ROOT, light), 3.0)


static func _underground(canvas: CanvasItem, width: float, light: Color) -> void:
	var top := WorldPalette.ground_of(int(Band.Kind.UNDERGROUND))
	canvas.draw_rect(
		Rect2(0.0, top, width, float(Band.SCREEN_BOTTOM) - top),
		_paint(ROCK, light)
	)
	var ceiling := PackedVector2Array([
		Vector2(0.0, top + 8.0),
		Vector2(width * 0.16, top + 25.0),
		Vector2(width * 0.31, top + 12.0),
		Vector2(width * 0.46, top + 34.0),
		Vector2(width * 0.62, top + 15.0),
		Vector2(width * 0.81, top + 30.0),
		Vector2(width, top + 10.0),
		Vector2(width, top + 64.0),
		Vector2(0.0, top + 64.0),
	])
	canvas.draw_colored_polygon(ceiling, _paint(ROCK_LIGHT, light))

	# A câmara central e os contrafortes fazem a ligação visual entre raiz e vila.
	var chamber := Rect2(width * 0.36, top + 38.0, width * 0.28, 68.0)
	canvas.draw_rect(chamber, _paint(Color(0.08, 0.08, 0.11), light))
	canvas.draw_line(
		Vector2(chamber.position.x, chamber.position.y),
		Vector2(chamber.end.x, chamber.position.y),
		_paint(ROOT, light), 7.0
	)
	for i in 6:
		var x := width * (0.06 + float(i) * 0.18)
		var h := 22.0 + float(i % 3) * 13.0
		canvas.draw_colored_polygon(
			PackedVector2Array([
				Vector2(x, Band.SCREEN_BOTTOM),
				Vector2(x + 10.0, top + h),
				Vector2(x + 29.0, top + h + 8.0),
				Vector2(x + 42.0, Band.SCREEN_BOTTOM),
			]),
			_paint(ROCK_LIGHT, light)
		)
	for i in 5:
		var y := top + 86.0 + float(i) * 22.0
		canvas.draw_line(
			Vector2(0.0, y), Vector2(width, y + float((i % 2) * 5)),
			_paint(ROOT, light), 2.0
		)
	_stairs(canvas, Vector2(width * 0.22, top + 22.0), 1.0, light)
	_stairs(canvas, Vector2(width * 0.78, top + 22.0), -1.0, light)
	canvas.draw_circle(Vector2(width * 0.50, top + 74.0), 5.0, _paint(WINDOW, light))


static func _stairs(canvas: CanvasItem, origin: Vector2, direction: float, light: Color) -> void:
	for i in 5:
		var y := origin.y + float(i) * 11.0
		var x := origin.x + direction * float(i) * 8.0
		canvas.draw_line(
			Vector2(x, y), Vector2(x + direction * 38.0, y),
			_paint(PATH, light), 4.0
		)


static func _tree(
	canvas: CanvasItem, base: Vector2, scale: float, leaf: Color, trunk: Color
) -> void:
	var h := 46.0 * scale
	canvas.draw_rect(Rect2(base.x - 5.0 * scale, base.y - h, 10.0 * scale, h), trunk)
	canvas.draw_circle(base + Vector2(-13.0 * scale, -h * 0.72), 17.0 * scale, leaf)
	canvas.draw_circle(base + Vector2(13.0 * scale, -h * 0.70), 18.0 * scale, leaf)
	canvas.draw_circle(base + Vector2(0.0, -h * 0.98), 21.0 * scale, leaf)
	canvas.draw_line(
		base + Vector2(-15.0 * scale, -h * 0.36),
		base + Vector2(17.0 * scale, -h * 0.63),
		trunk, 3.0 * scale
	)


static func _house(canvas: CanvasItem, base: Vector2, scale: float, light: Color) -> void:
	var body := Rect2(base.x - 25.0 * scale, base.y - 24.0 * scale, 50.0 * scale, 24.0 * scale)
	canvas.draw_rect(body, _paint(HOUSE, light))
	canvas.draw_colored_polygon(
		PackedVector2Array([
			Vector2(base.x - 32.0 * scale, base.y - 24.0 * scale),
			Vector2(base.x, base.y - 46.0 * scale),
			Vector2(base.x + 32.0 * scale, base.y - 24.0 * scale),
		]),
		_paint(ROOF, light)
	)
	canvas.draw_rect(
		Rect2(base.x - 13.0 * scale, base.y - 16.0 * scale, 9.0 * scale, 8.0 * scale),
		_paint(WINDOW, light)
	)
	canvas.draw_rect(
		Rect2(base.x + 8.0 * scale, base.y - 16.0 * scale, 9.0 * scale, 8.0 * scale),
		_paint(WINDOW, light)
	)
	canvas.draw_rect(
		Rect2(base.x - 4.0 * scale, base.y - 15.0 * scale, 8.0 * scale, 15.0 * scale),
		_paint(TRUNK, light)
	)


static func _paint(base: Color, light: Color) -> Color:
	return WorldPalette.tint(base, light)
