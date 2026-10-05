class_name ContextPanel
extends Label

const POSITION := Vector2(24, 104)
const BOX := Vector2(650, 48)
const FONT := 14
const EDGE := 8
## O guia refaz-se dez vezes por segundo, como os textos do GameHud.
const TEXTO_S := GameHud.TEXTO_S

var device := Glyphs.Device.KEYBOARD
var _texto_em := 0.0


func _ready() -> void:
	position = POSITION
	size = BOX
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_font_size_override("font_size", FONT)
	add_theme_color_override("font_color", GameHud.TEXT)
	var panel := StyleBoxFlat.new()
	panel.bg_color = GameHud.PAPER
	panel.content_margin_left = EDGE
	panel.content_margin_right = EDGE
	panel.border_color = GameHud.JADE
	panel.border_width_left = 2
	add_theme_stylebox_override("normal", panel)
	add_to_group(&"instrumentos")
	device = Glyphs.initial()


func _input(event: InputEvent) -> void:
	var name := ""
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		name = Input.get_joy_name(event.device)
	device = Glyphs.device_of(event, device, name)


func _process(delta: float) -> void:
	if SimLoop.state == null:
		return
	_texto_em -= delta
	if _texto_em <= 0.0:
		_texto_em = TEXTO_S
		text = GameplayGuide.context(device)
	visible = not text.is_empty() and SimLoop.running()
