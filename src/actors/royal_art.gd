class_name RoyalArt
extends RefCounted

const ROOT := "res://art/export/royals/"
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
