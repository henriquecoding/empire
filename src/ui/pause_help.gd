class_name PauseHelp
extends VBoxContainer

const ROW_HEIGHT := 48
const KEY_WIDTH := 110

var _names: Array[Label] = []
var _keys: Array[Label] = []
## Os gestos do toque, que uma tabela de botoes nao diz: arrastar, manter, largar (ADR 0047).
var _gestos: Label


static func hint(device: Glyphs.Device) -> String:
	if device == Glyphs.Device.KEYBOARD:
		return TranslationServer.translate(&"UI_MENU_HINT")
	if device == Glyphs.Device.TOUCH:
		return TranslationServer.translate(&"UI_MENU_HINT_TOUCH")
	var accept := "A"
	var cancel := "B"
	if device == Glyphs.Device.PLAYSTATION:
		accept = TranslationServer.translate(&"PAD_CROSS")
		cancel = TranslationServer.translate(&"PAD_CIRCLE")
	return TranslationServer.translate(&"UI_MENU_HINT_PAD").format(
		{"accept": accept, "cancel": cancel}
	)


static func current_device() -> Glyphs.Device:
	return Glyphs.initial()


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
	_gestos = PauseTheme.label(self, &"UI_TOUCH_HELP")
	_gestos.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	refresh(Glyphs.Device.KEYBOARD)


func refresh(device: Glyphs.Device) -> void:
	for i in _keys.size():
		_names[i].text = tr(Glyphs.ACCOES[i])
		var value: Variant = Glyphs.BOTOES[device][i]
		_keys[i].text = tr(value) if value is StringName else String(value)
	_gestos.text = tr(&"UI_TOUCH_HELP")
	_gestos.visible = device == Glyphs.Device.TOUCH
