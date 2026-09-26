class_name OriginalArt
extends RefCounted

const ROOT := "res://art/export/enramados/"
const MILLISECONDS := 1000.0
const BODY_HEIGHT_INDEX := 3
const IDLE := &"idle"
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


## O frame de `id` ao fim de `time` segundos de `action`. Sem essa tag no
## manifesto, percorre os frames todos (o que as exportacoes de um frame so
## tem). `loop` falso fica no ultimo frame em vez de recomecar.
func frame_at(id: StringName, time: float, action: StringName = IDLE, loop: bool = true) -> int:
	var item := entry(id)
	var durations: Array = item.durations_ms
	var tag: Dictionary = item.get("tags", {}).get(String(action), {})
	var first := int(tag.get("from_frame", 0))
	var last := int(tag.get("to_frame", durations.size() - 1))
	return frame_in(durations, first, last, time * MILLISECONDS, loop)


## Se a arte de `id` tem a tag `action` no manifesto.
func has_action(id: StringName, action: StringName) -> bool:
	return entry(id).get("tags", {}).has(String(action))


## O indice do frame, entre `first` e `last`, ao fim de `ms` milissegundos.
static func frame_in(durations: Array, first: int, last: int, ms: float, loop: bool) -> int:
	var total := 0.0
	for i in range(first, last + 1):
		total += float(durations[i])
	if total <= 0.0:
		return first
	if not loop and ms >= total:
		return last
	var cursor := fposmod(ms, total)
	for i in range(first, last + 1):
		cursor -= float(durations[i])
		if cursor < 0.0:
			return i
	return first


func box(id: StringName, foot: Vector2) -> Rect2:
	var item := entry(id)
	return Rect2(foot - Vector2(item.foot[0], item.foot[1]), Vector2(item.size[0], item.size[1]))


func body_box(id: StringName, foot: Vector2) -> Rect2:
	var bounds: Array = entry(id).body_bounds
	return Rect2(
		foot + Vector2(bounds[0], bounds[1]), Vector2(bounds[2], bounds[BODY_HEIGHT_INDEX])
	)


## Desenha o frame `frame` de `id` com os pes em `foot`. Quem escolhe o frame e
## quem sabe a accao (UnitArtBatch, ActorAction); as obras tem um frame so.
func draw_on(
	canvas: CanvasItem,
	id: StringName,
	foot: Vector2,
	tint: Color,
	frame: int = 0,
	facing: float = 1.0,
) -> void:
	var item := entry(id)
	var size := Vector2(item.size[0], item.size[1])
	var source := Rect2(Vector2(size.x * frame, 0.0), size)
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
			# Rejected concept is archived; the reference troop body is a temporary proxy.
			return &"vagrant"
		&"vagrant", &"builder", &"spearman":
			return &"vagrant"
		&"cook":
			return &"cook"
		&"squire", &"buried_knight", &"sealed_knight", &"mercenary":
			return &"knight"
	return &""
