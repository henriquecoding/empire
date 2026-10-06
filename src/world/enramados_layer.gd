class_name EnramadosLayer
extends Node2D

## Authored world coordinates. Parallax affects scenery only, never passages.
const WIDTH := 3840
const SKY_TOP := Color("74b1c3")
const SKY_BOTTOM := Color("d4dfbd")
const FAR := Color("94b9ac")
const NEAR := Color("557d64")
const GROVE := Color("88a578")
const FIELD := Color("789553")
const PATH := Color("c1a77c")
const SOIL := Color("483b2a")
const ROCK := Color("65543a")
const MOSS := Color("505433")
const LAYERS := 6
const LAST_PLANE := 5
const GROVE_PLANE := 3
const GROUND_PLANE := 4
const LAST_X := -2
const SKY_BANDS := 48
const TWO := 2.0
const HALF := 0.5
const CELL := 64
const DETAIL := 4
const MID_GROUND := 490.0
const BACK_GROUND := 421.0
const FOREST_SCALE := 1.0
const LANDMARKS := [340.0, 1110.0, 2770.0, 3510.0]
const VALLEY := preload("res://art/export/renewal/valley.png")
const PANORAMA_WIDTH := 1536
const MIRROR := -1.0
const RIDGE := [0, 374, 140, 350, 252, 361, 396, 322, 528, 348, 664, 329, 804, 366, 960, 343]

## Que luz leva cada plano (SceneryLight): o ceu, os dois fundos, o bosque, o chao
## e o subsolo, pela ordem do `plane`.
const LUZ_DO_PLANO := [
	SceneryLight.Depth.SKY,
	SceneryLight.Depth.FAR,
	SceneryLight.Depth.FAR,
	SceneryLight.Depth.MID,
	SceneryLight.Depth.GROUND,
	SceneryLight.Depth.BELOW,
]

@export_range(0, LAST_PLANE) var plane := 0
var _clock: ClockData
var _art := OriginalArt.new()
var _revisao := Vector2i(-1, -1)  # das terras (Q-173) e dos sitios do subsolo (Q-186)


func _ready() -> void:
	_clock = Registry.entry(&"economy", &"clock") as ClockData
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	material = SceneryLight.material(LUZ_DO_PLANO[plane])
	queue_redraw()


func _process(_delta: float) -> void:
	if _clock == null or ClockService.clock == null:
		return
	SceneryLight.refresh(self)  # a luz ja nao e o `modulate`: e o shader (ADR 0048)
	if SimLoop.field != null:
		var revisao := Vector2i(SimLoop.field.wilds.revision, SimLoop.field.under.revision)
		if revisao != _revisao:
			_revisao = revisao
			queue_redraw()


func _draw() -> void:
	match plane:
		0:
			_sky()
		1:
			_panorama()
		2:
			_distance()
		GROVE_PLANE:
			_grove()
		GROUND_PLANE:
			_ground()
		LAST_PLANE:
			_underground()


func _sky() -> void:
	var height := float(Band.GROUND_LINE) / SKY_BANDS
	var alcance := _alcance()
	for i in SKY_BANDS:
		var color := SKY_TOP.lerp(SKY_BOTTOM, float(i) / SKY_BANDS)
		var faixa := Rect2(alcance.x, floorf(i * height), alcance.y - alcance.x, ceilf(height))
		draw_rect(faixa, color)


## De onde a onde este plano tem de estar desenhado: o mundo que ja foi gerado, visto
## ao ritmo do parallax em que o plano vive (Q-173).
func _alcance() -> Vector2:
	var mundo := Vector2(0.0, float(WIDTH))
	if SimLoop.field != null:
		mundo = SimLoop.field.wilds.extent(SimLoop.world_width)
	var pai := get_parent() as Parallax2D
	var escala := pai.scroll_scale.x if pai != null else 1.0
	return Vector2(
		minf(-WIDTH, mundo.x * escala - WIDTH), maxf(WIDTH * 2, mundo.y * escala + WIDTH)
	)


func _ridge(color: Color, offset: Vector2) -> void:
	var alcance := _alcance()
	var passo := int(RIDGE[LAST_X])
	for start in range(floori(alcance.x / passo) * passo, int(alcance.y), passo):
		var points := PackedVector2Array([Vector2(start, Band.GROUND_LINE) + offset])
		for i in range(0, RIDGE.size(), int(TWO)):
			points.append(Vector2(start + RIDGE[i], RIDGE[i + 1]) + offset)
		points.append(Vector2(start + RIDGE[LAST_X], Band.GROUND_LINE) + offset)
		draw_colored_polygon(points, color)


func _distance() -> void:
	# Distant vegetation belongs to the panorama; keep the lake visible.
	pass


## Os vizinhos espelhados partilham a borda, sem salto na junta. O espelho e uma
## transformada e nunca uma largura negativa: com ela o Godot cortava o painel pelo
## retangulo errado, e a paisagem abria buracos ao andar a camara (PR #91).
func _panorama() -> void:
	var extent := _alcance()
	var box := Rect2(Vector2.ZERO, VALLEY.get_size())
	for tile in range(floori(extent.x / PANORAMA_WIDTH), ceili(extent.y / PANORAMA_WIDTH)):
		var mirrored := posmod(tile, 2) == 1
		var left := (tile + int(mirrored)) * PANORAMA_WIDTH
		draw_set_transform(Vector2(left, 0.0), 0.0, Vector2(MIRROR if mirrored else 1.0, 1.0))
		draw_texture_rect(VALLEY, box, false)
	draw_set_transform(Vector2.ZERO)


func _grove() -> void:
	var texture := _art.texture(&"royal_oak")
	var size := texture.get_size() * FOREST_SCALE
	for x in LANDMARKS:
		draw_texture_rect(
			texture,
			Rect2(Vector2(x, MID_GROUND) - Vector2(size.x * HALF, size.y), size),
			false,
			Color.WHITE
		)


func _ground() -> void:
	draw_rect(Rect2(0, BACK_GROUND, WIDTH, Band.GROUND_LINE - BACK_GROUND), FIELD)
	draw_rect(Rect2(0, MID_GROUND, WIDTH, Band.GROUND_LINE - MID_GROUND), PATH)
	for x in range(0, WIDTH, CELL):
		draw_rect(Rect2(x, MID_GROUND + DETAIL, CELL * HALF, DETAIL), ROCK)
		draw_rect(Rect2(x + CELL * HALF, Band.GROUND_LINE - DETAIL, CELL * HALF, DETAIL), SOIL)
	draw_rect(Rect2(0, Band.GROUND_LINE, WIDTH, Band.SOIL_CUT), SOIL)
	for x in range(0, WIDTH, CELL):
		for y in range(Band.GROUND_LINE + CELL, Band.SCREEN_BOTTOM, CELL):
			draw_rect(Rect2(x + (y % CELL), y, CELL - DETAIL, DETAIL), ROCK)
			draw_rect(Rect2(x, y - DETAIL, DETAIL, DETAIL), MOSS)
	if SimLoop.field != null:  # e o chao das terras geradas, onde tambem se anda (Q-173)
		WildGround.draw_ground(self, SimLoop.field.wilds, SimLoop.world_width)


func _underground() -> void:
	RootCellars.draw(self, WIDTH)
	if SimLoop.field != null:
		WildGround.draw_underground(self, SimLoop.field.wilds, SimLoop.world_width)
		UnderArt.draw(self, SimLoop.field.under)  # so onde ha sitio, e acaba (Q-186)
