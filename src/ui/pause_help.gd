class_name PauseHelp
extends VBoxContainer

const ROW_HEIGHT := 48
const KEY_WIDTH := 110

var _names: Array[Label] = []
var _keys: Array[Label] = []


static func hint(device: Glyphs.Device) -> String:
	if device == Glyphs.Device.KEYBOARD:
		return TranslationServer.translate(&"UI_MENU_HINT")
	var accept := "A"
	var cancel := "B"
	if device == Glyphs.Device.PLAYSTATION:
		accept = TranslationServer.translate(&"PAD_CROSS")
		cancel = TranslationServer.translate(&"PAD_CIRCLE")
	return TranslationServer.translate(&"UI_MENU_HINT_PAD").format(
		{"accept": accept, "cancel": cancel}
	)


static func current_device() -> Glyphs.Device:
	var pads := Input.get_connected_joypads()
	return Glyphs.Device.KEYBOARD if pads.is_empty() else Glyphs.pad_of(Input.get_joy_name(pads[0]))


func _ready() -> void:
	for action: StringName in Glyphs.ACCOES:
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = ROW_HEIGHT
		add_child(row)
		_names.append(PauseTheme.label(row, action))
		var key := Label.new()
		key.custom_minimum_size.x = KEY_WIDTH
		key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key.add_theme_font_size_override("font_size", PauseTheme.STATUS_SIZE)
		row.add_child(key)
		_keys.append(key)
	refresh(Glyphs.Device.KEYBOARD)


func refresh(device: Glyphs.Device) -> void:
	for i in _keys.size():
		_names[i].text = tr(Glyphs.ACCOES[i])
		var value: Variant = Glyphs.BOTOES[device][i]
		_keys[i].text = tr(value) if value is StringName else String(value)
