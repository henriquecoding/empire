class_name OriginalArt
extends RefCounted

const ROOT := "res://art/export/enramados/"
const MILLISECONDS := 1000.0
static var _manifest: Dictionary = {}
static var _textures: Dictionary = {}


func entry(id: StringName) -> Dictionary:
	if _manifest.is_empty():
		_manifest = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "manifest.json"))
	return _manifest.assets.get(String(id), {})


func texture(id: StringName) -> Texture2D:
	if not _textures.has(id):
		_textures[id] = load(ROOT + String(entry(id).texture))
	return _textures[id]


func frame_at(id: StringName, time: float) -> int:
	var durations: Array = entry(id).durations_ms
	var total := 0.0
	for duration in durations:
		total += float(duration)
	var cursor := fposmod(time * MILLISECONDS, total)
	for i in durations.size():
		cursor -= float(durations[i])
		if cursor < 0.0:
			return i
	return 0


func box(id: StringName, foot: Vector2) -> Rect2:
	var item := entry(id)
	return Rect2(foot - Vector2(item.foot[0], item.foot[1]), Vector2(item.size[0], item.size[1]))


func draw_on(
	canvas: CanvasItem,
	id: StringName,
	foot: Vector2,
	tint: Color,
	time: float = 0.0,
	facing: float = 1.0
) -> void:
	var item := entry(id)
	var size := Vector2(item.size[0], item.size[1])
	var source := Rect2(Vector2(size.x * frame_at(id, time), 0.0), size)
	var sheet := texture(id)
	if item.has("atlas_origin"):
		source.position += Vector2(item.atlas_origin[0], item.atlas_origin[1])
		if not _textures.has(&"actors"):
			_textures[&"actors"] = load(ROOT + "actors.png")
		sheet = _textures[&"actors"]
	canvas.draw_set_transform(foot.floor(), 0.0, Vector2(facing, 1.0))
	canvas.draw_texture_rect_region(sheet, box(id, Vector2.ZERO), source, tint)
	canvas.draw_set_transform(Vector2.ZERO)


static func unit_profile(data_id: StringName) -> StringName:
	match data_id:
		&"monarch":
			return &"monarch"
		&"archer", &"canopy_archer":
			return &"archer"
		&"vagrant", &"builder":
			return &"vagrant"
		&"cook":
			return &"cook"
		&"squire", &"buried_knight", &"sealed_knight", &"mercenary":
			return &"knight"
	return &""
