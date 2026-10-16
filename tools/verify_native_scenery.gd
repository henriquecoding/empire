extends Node

var _errors: PackedStringArray = PackedStringArray()
var _results: Array[Dictionary] = []


func _ready() -> void:
	get_tree().create_timer(120.0).timeout.connect(_timed_out)
	await _run()


func _timed_out() -> void:
	push_error("native scenery verification exceeded its deadline")
	get_tree().quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
		push_error(message)


func _frames(count: int) -> void:
	for _index in count:
		await get_tree().physics_frame


func _run() -> void:
	var count := NativeSceneryCatalog.ids().size()
	_check(count == 24, "The compiled catalog must contain all 24 views")
	for id: String in NativeSceneryCatalog.ids():
		await _view(id)
	var report := {
		"engine": Engine.get_version_info().string,
		"renderer": RenderingServer.get_current_rendering_method(),
		"scope": "production review scenes with actual art and CharacterBody2D traversal",
		"views": _results,
		"errors": Array(_errors),
		"passed": _errors.is_empty(),
	}
	var file := FileAccess.open("res://docs/art/scenery_native_validation.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "\t") + "\n")
	print(JSON.stringify({"native_views": _results.size(), "errors": Array(_errors)}))
	get_tree().quit(0 if _errors.is_empty() else 1)


func _view(id: String) -> void:
	var stage := NativeSceneryStage.new()
	stage.view_id = id
	add_child(stage)
	var family := NativeSceneryCatalog.family(stage.family_id)
	var walker := NativeSceneryWalker.new()
	walker.family_id = stage.family_id
	walker.position = Vector2(float(family.passages[0]), 517.0)
	add_child(walker)
	await _frames(8)
	_check(walker.is_on_floor() and absf(walker.position.y - 517.0) < 0.1, id + ": upper floor")
	var start := walker.position.x
	walker.direction = 1.0
	await _frames(8)
	walker.direction = 0.0
	_check(walker.position.x > start + 16.0, id + ": upper walking")
	_check(not walker.use_passage(), id + ": no unregistered passage")
	for mouth: float in family.passages:
		walker.position = Vector2(mouth, 517.0)
		walker.band = Band.Kind.SURFACE
		walker.velocity = Vector2.ZERO
		_check(walker.use_passage(), id + ": descend")
		await _frames(8)
		_check(walker.is_on_floor() and absf(walker.position.y - 618.5) < 0.1, id + ": lower floor")
		var before := walker.position.x
		walker.direction = -1.0
		await _frames(5)
		walker.direction = 0.0
		_check(walker.position.x < before - 8.0, id + ": lower walking")
		if family.lower_spans.size() > 1:
			walker.direction = 1.0 if mouth < 640.0 else -1.0
			await _frames(48)
			walker.direction = 0.0
			_check(
				(
					NativeSceneryCatalog.supports(
						stage.family_id, walker.position.x, Band.Kind.UNDERGROUND, 16.0
					)
					and walker.is_on_floor()
				),
				id + ": water gap blocks walking"
			)
		walker.position.x = mouth
		_check(walker.use_passage(), id + ": ascend")
		await _frames(4)
		_check(absf(walker.position.y - 517.0) < 0.1, id + ": upper return")
	_check(not stage.functional.get_parent() is Parallax2D, id + ": functional placement")
	var position_before := stage.structures.global_position
	for child in stage.get_children():
		if child is Parallax2D:
			child.scroll_offset.x = 80.0
	_check(stage.structures.global_position == position_before, id + ": buildings fixed")
	stage.set_constructed(false)
	_check(not stage.structures.visible and not stage.workers.visible, id + ": empty foundation")
	_check(stage.functional.visible, id + ": access remains")
	stage.set_constructed(true)
	_check(stage.structures.visible and stage.workers.visible, id + ": built state")
	var tiles := (
		load("res://art/export/scenery_native/" + stage.family_id + "/modules_64.tres") as TileSet
	)
	_check(tiles != null and tiles.tile_size == Vector2i(64, 64), id + ": native modules")
	_results.append(
		{
			"id": id,
			"family": stage.family_id,
			"surface_y": walker.position.y,
			"passages": family.passages.size(),
			"lower_spans": family.lower_spans.size(),
			"built_and_empty": true
		}
	)
	walker.free()
	stage.free()
	await _frames(1)
