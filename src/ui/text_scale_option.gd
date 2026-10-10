class_name TextScaleOption
extends VBoxContainer

const SIZES := [1.0, 1.25, 1.5]
const PERCENT := 100.0
var _label: Label
var _choice: OptionButton


func _ready() -> void:
	_label = PauseTheme.label(self, &"OPT_TEXT_SCALE")
	_choice = OptionButton.new()
	_choice.custom_minimum_size.y = PauseTheme.BUTTON_HEIGHT
	PauseTheme.follow_pointer(_choice)
	for factor: float in SIZES:
		_choice.add_item("%d%%" % roundi(factor * PERCENT))
	add_child(_choice)
	_choice.select(maxi(0, SIZES.find(Preferences.shared().number(Preferences.TEXT_SCALE))))
	_choice.item_selected.connect(_select)


func _select(index: int) -> void:
	Preferences.shared().set_number(Preferences.TEXT_SCALE, SIZES[index])
	get_tree().root.size_changed.emit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and _label != null:
		_label.text = tr(&"OPT_TEXT_SCALE")
