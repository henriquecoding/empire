class_name RoyalArt
extends RefCounted

const ROOT := "res://art/export/royals/"
const EVENT_EPSILON := 0.000000001
const CAST := [
	&"royal_king",
	&"royal_squire",
	&"royal_nia",
	&"royal_bard",
	&"royal_archer",
	&"royal_quiver",
	&"royal_shadow",
	&"royal_dancer"
]
static var _assets: Dictionary = {}
static var _textures: Dictionary = {}
static var _impact_ratios: Dictionary = {}


static func entry(id: StringName) -> Dictionary:
	if not id in CAST:
		return {}
	if _assets.is_empty():
		var manifest: Dictionary = JSON.parse_string(
			FileAccess.get_file_as_string(ROOT + "manifest.json")
		)
		_assets = manifest.assets
	return _assets.get(String(id), {})


## Both directions are delivered drawings, with their own mirrored foot pivot.
static func sample(id: StringName, frame: int, facing: float) -> Dictionary:
	var item := entry(id)
	var index := int(item.mirrors.get(str(frame), frame)) if facing < 0.0 else frame
	var pivot: Array = item.frame_pivots[index]
	return {
		"frame": index,
		"source":
		Rect2(
			Vector2(item.frame_origins[index][0], item.frame_origins[index][1]),
			Vector2(item.size[0], item.size[1])
		),
		"target": Rect2(-Vector2(pivot[0], pivot[1]), Vector2(item.size[0], item.size[1]))
	}


static func draw_on(
	canvas: CanvasItem,
	id: StringName,
	tint: Color,
	frame: int,
	pose: Transform2D,
	channel: String = "texture"
) -> void:
	var item := entry(id)
	var picture := sample(id, frame, pose.x.x)
	var path := ROOT + String(item[channel])
	if not _textures.has(path):
		_textures[path] = load(path)
	# The source already faces left. No second mirror and no procedural body deformation.
	var native := Transform2D(0.0, pose.origin.floor())
	canvas.draw_set_transform_matrix(native)
	canvas.draw_texture_rect_region(_textures[path], picture.target, picture.source, tint)
	canvas.draw_set_transform(Vector2.ZERO)


## Integer zoom is for menus and inspection; the world uses the delivered native grid.
static func preview(
	canvas: CanvasItem, id: StringName, frame: int, foot: Vector2, zoom: float, facing: float = 1.0
) -> void:
	var item := entry(id)
	var picture := sample(id, frame, facing)
	var path := ROOT + String(item.texture)
	if not _textures.has(path):
		_textures[path] = load(path)
	var target: Rect2 = picture.target
	target.position = (foot + target.position * zoom).floor()
	target.size *= zoom
	canvas.draw_texture_rect_region(_textures[path], target, picture.source)


## Map the existing combat release to the authored impact, keeping relative frame timings
## on each side of that event. Markers describe presentation and never apply gameplay.
static func strike_progress(id: StringName, progress: float, release_point: float) -> float:
	var item := entry(id)
	if item.is_empty() or not item.tags.has("attack"):
		return progress
	var events: Array = item.events.get("attack", [])
	if events.is_empty():
		return progress
	if not _impact_ratios.has(id):
		var tag: Dictionary = item.tags.attack
		var marker := int(events[0].frame)
		var before := 0.0
		var total := 0.0
		for frame in range(int(tag.from_frame), int(tag.to_frame) + 1):
			var duration := float(item.durations_ms[frame])
			if frame - int(tag.from_frame) < marker:
				before += duration
			total += duration
		_impact_ratios[id] = before / total
	var impact := float(_impact_ratios[id])
	if progress < release_point:
		return impact * progress / release_point
	var recovery := (progress - release_point) / (1.0 - release_point)
	return minf(1.0, impact + (1.0 - impact) * recovery + EVENT_EPSILON)
