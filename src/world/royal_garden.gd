class_name RoyalGarden
extends RefCounted

const DURATION := 12.0
const RISE_AT := 8.2
const CELL := Vector2(24, 28)
const ROOT := Vector2(12, 25)
const FIELD_PIVOT := Vector2(80, 38)
const GROW_STAGES := 8
const WITHER_STAGES := 6
const COLUMNS := 8
const JITTER := 2
const GROW_RANGE := Vector2i(740, 1370)
const WITHER_RANGE := Vector2i(8360, 9450)
const EXIT_RANGE := Vector2i(650, 1240)
var plants: Array = []
var _textures: Dictionary = {}


func begin(fixed: bool = false) -> void:
	var pattern: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(RoyalArt.ROOT + "garden.json")
	)
	plants = pattern.plants.duplicate(true)
	if fixed:
		return
	var variants := [
		"ivory-7",
		"ivory-10",
		"ivory-14",
		"rose-7",
		"rose-10",
		"rose-14",
		"yellow-7",
		"yellow-10",
		"yellow-14"
	]
	var starts: Array = plants.map(func(plant: Dictionary) -> int: return int(plant.startMs))
	for i in range(starts.size() - 1, 0, -1):
		var other := RngService.int_range(RngService.VISUAL, 0, i)
		var held: int = starts[i]
		starts[i] = starts[other]
		starts[other] = held
	for i in plants.size():
		var plant: Dictionary = plants[i]
		plant.startMs = starts[i]
		plant.variant = RngService.escolher(RngService.VISUAL, variants)
		plant.x = int(plant.x) + RngService.int_range(RngService.VISUAL, -JITTER, JITTER)
		plant.growMs = RngService.int_range(RngService.VISUAL, GROW_RANGE.x, GROW_RANGE.y)
		plant.witherMs = RngService.int_range(RngService.VISUAL, WITHER_RANGE.x, WITHER_RANGE.y)
		plant.exitMs = RngService.int_range(RngService.VISUAL, EXIT_RANGE.x, EXIT_RANGE.y)


static func stage(plant: Dictionary, elapsed: float) -> int:
	var ms := elapsed * OriginalArt.MILLISECONDS
	if ms < float(plant.startMs):
		return -1
	if ms < float(plant.witherMs):
		return mini(
			GROW_STAGES - 1, int((ms - float(plant.startMs)) / float(plant.growMs) * GROW_STAGES)
		)
	var fading := int((ms - float(plant.witherMs)) / float(plant.exitMs) * WITHER_STAGES)
	return GROW_STAGES + fading if fading < WITHER_STAGES else -1


func draw_on(
	canvas: CanvasItem, foot: Vector2, elapsed: float, front: bool, zoom: float = 1.0
) -> void:
	for plant: Dictionary in plants:
		if (String(plant.layer) == "front") != front:
			continue
		var frame := stage(plant, elapsed)
		if frame < 0:
			continue
		var variant := String(plant.variant)
		if not _textures.has(variant):
			_textures[variant] = load(RoyalArt.ROOT + "plants/" + variant + ".png")
		var root := Vector2(plant.x, plant.y) - FIELD_PIVOT
		var target := Rect2((foot + (root - ROOT) * zoom).floor(), CELL * zoom)
		var source := Rect2(
			Vector2((frame % COLUMNS) * CELL.x, floorf(float(frame) / COLUMNS) * CELL.y), CELL
		)
		canvas.draw_texture_rect_region(_textures[variant], target, source)


static func body(elapsed: float) -> Dictionary:
	var art := OriginalArt.new()
	if elapsed < art.action_seconds(&"royal_shadow", &"sit"):
		return {"action": &"sit", "elapsed": elapsed}
	if elapsed < RISE_AT:
		return {"action": &"heal", "elapsed": elapsed - art.action_seconds(&"royal_shadow", &"sit")}
	return {"action": &"stand", "elapsed": elapsed - RISE_AT}
