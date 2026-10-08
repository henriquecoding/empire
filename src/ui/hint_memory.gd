class_name HintMemory
extends RefCounted

const PATH := "user://hints.cfg"

static var _shared: HintMemory

var path: String
var _read: Dictionary = {}


func _init(file_path: String = PATH) -> void:
	path = file_path
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var data: Variant = file.get_var(false)
	if data is Dictionary:
		for key: Variant in data:
			if key is String and data[key] is bool and data[key]:
				_read[key] = true


static func shared() -> HintMemory:
	if _shared == null:
		_shared = HintMemory.new()
	return _shared


static func set_shared(memory: HintMemory) -> void:
	_shared = memory


func seen(key: StringName) -> bool:
	return _read.has(String(key))


func remember(key: StringName) -> void:
	if key == &"" or seen(key):
		return
	_read[String(key)] = true
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		return
	file.store_var(_read, false)
	file.close()
	DirAccess.rename_absolute(
		ProjectSettings.globalize_path(path + ".tmp"), ProjectSettings.globalize_path(path)
	)
