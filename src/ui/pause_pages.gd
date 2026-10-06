class_name PausePages
extends RefCounted

var options: VBoxContainer
var controls: VBoxContainer
var realm: VBoxContainer
var overview: Label
var reset: VBoxContainer
var option_panel: OptionsPanel
var help: PauseHelp
var _titles: Array[Label] = []
var _backs: Array[Button] = []
var _tips: Array[Label] = []


func build(layout: PauseLayout, back: Callable, zero: FreshStartPanel) -> void:
	options = _page(layout, &"UI_OPTIONS", back)
	var area := options.get_child(1).get_child(0) as ScrollContainer
	option_panel = OptionsPanel.new()
	option_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(option_panel)
	_tips.append(PauseTheme.label(options, &"UI_MENU_OPTIONS_SAVED"))
	options.move_child(_tips[0], 2)
	controls = _page(layout, &"UI_CONTROLS", back)
	help = PauseHelp.new()
	help.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.get_child(1).get_child(0).add_child(help)
	reset = _page(layout, &"UI_FRESH_START", back)
	zero.confirmation.reparent(reset.get_child(1).get_child(0))
	realm = _page(layout, &"UI_REALM_STATUS", back)
	overview = PauseTheme.label(realm.get_child(1).get_child(0))
	overview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overview.add_theme_constant_override("line_spacing", PauseTheme.ROW_GAP)
	refresh()


func refresh() -> void:
	if overview != null:
		overview.text = RealmReadout.overview()
	var keys := [&"UI_OPTIONS", &"UI_CONTROLS", &"UI_FRESH_START", &"UI_REALM_STATUS"]
	for i in _titles.size():
		_titles[i].text = TranslationServer.translate(keys[i])
	for button: Button in _backs:
		button.text = TranslationServer.translate(&"UI_MENU_BACK")
	for tip: Label in _tips:
		tip.text = TranslationServer.translate(&"UI_MENU_OPTIONS_SAVED")


func _page(layout: PauseLayout, key: StringName, back: Callable) -> VBoxContainer:
	var page := layout.page()
	var title := PauseTheme.label(page, key)
	PauseTheme.title(title)
	_titles.append(title)
	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(panel)
	PauseLayout.scroll(panel)
	_backs.append(PauseTheme.button(page, &"UI_MENU_BACK", back))
	return page
