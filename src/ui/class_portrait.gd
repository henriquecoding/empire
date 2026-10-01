class_name ClassPortrait
extends Control

const HEIGHT := 116
const FOOT := 98.0
const FLOOR := Color("74614b")
const HALF := 0.5
const FLOOR_HALF_WIDTH := 40
const STROKE := 2.0
const BODY_HALF := 0.3
const BODY_WIDTH := 0.6
const COLORS := {&"monarch": Color("d9b46b"), &"archer": Color("9db589"), &"bard": Color("aaa0ce")}
var class_id: StringName = &"monarch"
var _art := OriginalArt.new()
var _units := UnitSystem.new()
var _data: UnitData


func _ready() -> void:
	custom_minimum_size.y = HEIGHT
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var data := Registry.entry(&"classes", class_id) as ClassData
	_data = Registry.entry(&"units", data.base_unit) as UnitData
	_units.spawn(GameState.new(), _data, 1, 0.0)


func _draw() -> void:
	if _data == null:
		return
	var foot := Vector2(floorf(size.x * HALF), FOOT)
	draw_line(
		foot + Vector2(-FLOOR_HALF_WIDTH, STROKE),
		foot + Vector2(FLOOR_HALF_WIDTH, STROKE),
		FLOOR,
		STROKE
	)
	var profile := OriginalArt.unit_profile(_data.id)
	if profile != &"":
		_art.draw_on(self, profile, foot, Color.WHITE)
	else:
		var height := WorldPalette.DEGRAU * _data.scale_tier
		var box := Rect2(
			foot - Vector2(height * BODY_HALF, height), Vector2(height * BODY_WIDTH, height)
		)
		ActorArt.draw_unit(self, box, _data, _units, 0, COLORS.get(class_id, Color.WHITE), 0.0)
		BardArt.draw_on(self, box, 0.0)
