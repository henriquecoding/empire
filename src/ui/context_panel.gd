class_name ContextPanel
extends Label

const POSITION := Vector2(280, 152)
const BOX := Vector2(720, 56)
const FONT := 16
const EDGE := 8

var device := Glyphs.Device.KEYBOARD


func _ready() -> void:
	position = POSITION
	size = BOX
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_font_size_override("font_size", FONT)
	add_theme_color_override("font_color", GameHud.TEXT)
	var panel := StyleBoxFlat.new()
	panel.bg_color = GameHud.PAPER
	panel.content_margin_left = EDGE
	panel.content_margin_right = EDGE
	add_theme_stylebox_override("normal", panel)
	add_to_group(&"instrumentos")
	var pads := Input.get_connected_joypads()
	if not pads.is_empty():
		device = Glyphs.pad_of(Input.get_joy_name(pads[0]))


func _input(event: InputEvent) -> void:
	var name := ""
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		name = Input.get_joy_name(event.device)
	device = Glyphs.device_of(event, device, name)


func _process(_delta: float) -> void:
	if SimLoop.state == null:
		return
	text = GameplayGuide.context(device)
	visible = not text.is_empty() and SimLoop.running()
