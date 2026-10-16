extends Node

var _shots: Array[Dictionary] = []


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("res://build/scenery-native")
	get_tree().root.size = Vector2i(1280, 720)
	get_tree().root.content_scale_size = Vector2i(1280, 720)
	get_tree().root.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	for id: String in NativeSceneryCatalog.ids():
		await _capture_view(id)
	var record := {
		"engine": Engine.get_version_info().string,
		"renderer": RenderingServer.get_current_rendering_method(),
		"driver": RenderingServer.get_current_rendering_driver_name(),
		"adapter": RenderingServer.get_video_adapter_name(),
		"canvas": [1280, 720],
		"scope": "prepared production review scenes; not a campaign playthrough",
		"sampling": "nearest",
		"captures": _shots,
	}
	var file := FileAccess.open("res://build/scenery-native/captures.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(record, "\t") + "\n")
	get_tree().quit()


func _settle() -> void:
	for _index in 8:
		await get_tree().physics_frame
	await RenderingServer.frame_post_draw


func _capture_view(id: String) -> void:
	var stage := NativeSceneryStage.new()
	stage.view_id = id
	add_child(stage)
	var family := NativeSceneryCatalog.family(stage.family_id)
	var walker := NativeSceneryWalker.new()
	walker.family_id = stage.family_id
	walker.position = Vector2(float(family.passages[0]), 517.0)
	add_child(walker)
	await _settle()
	await _save(stage, walker, "surface")
	walker.use_passage()
	await _settle()
	await _save(stage, walker, "underground")
	if id in ["enramados_base", "porto_crepusculo", "lago_outono", "rio_chuva"]:
		stage.set_constructed(false)
		await _settle()
		await _save(stage, walker, "empty")
	walker.free()
	stage.free()
	await get_tree().process_frame


func _save(stage: NativeSceneryStage, walker: NativeSceneryWalker, state: String) -> void:
	var name := stage.view_id + "_" + state + ".png"
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png("res://build/scenery-native/" + name)
	if error != OK:
		push_error("capture failed: " + name)
		get_tree().quit(1)
	_shots.append({
		"image": name, "id": stage.view_id, "state": state,
		"player": [walker.position.x, walker.position.y],
		"constructed": stage.constructed,
		"texture_bytes": Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
	})
