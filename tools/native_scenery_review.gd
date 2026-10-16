extends Node2D

var _index := 0
var _stage: NativeSceneryStage
var _walker: NativeSceneryWalker


func _ready() -> void:
	_show()


func _show() -> void:
	if _stage != null:
		_stage.free()
	if _walker != null:
		_walker.free()
	_stage = NativeSceneryStage.new()
	_stage.view_id = NativeSceneryCatalog.ids()[_index]
	add_child(_stage)
	_walker = NativeSceneryWalker.new()
	_walker.family_id = _stage.family_id
	_walker.position = Vector2(640.0, WorldPalette.ground_of(Band.Kind.SURFACE))
	add_child(_walker)
	print(_stage.view_id)


func _physics_process(_delta: float) -> void:
	_walker.direction = Input.get_axis("king_left", "king_right")


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event is InputEventKey:
		if event.keycode == KEY_PAGEUP or event.keycode == KEY_PAGEDOWN:
			_index = posmod(
				_index + (1 if event.keycode == KEY_PAGEDOWN else -1),
				NativeSceneryCatalog.ids().size()
			)
			_show()
		elif event.keycode == KEY_E:
			_walker.use_passage()
		elif event.keycode == KEY_B:
			_stage.set_constructed(not _stage.constructed)
