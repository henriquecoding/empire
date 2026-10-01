class_name TravelPanel
extends PanelContainer
const PLACE := Vector2(410, 170)
const WIDTH := 460.0
const EDGE := 24
const FONT := 22
const GAP := 12
const TEXT_WIDTH := 412.0
const LIST_HEIGHT := 280.0

static var active := false
var _rows: VBoxContainer
var _buttons: Array[Button] = []


func _ready() -> void:
	position = PLACE
	custom_minimum_size.x = WIDTH
	var style := StyleBoxFlat.new()
	style.bg_color = GameHud.PAPER
	style.content_margin_left = EDGE
	style.content_margin_right = EDGE
	style.content_margin_top = EDGE
	style.content_margin_bottom = EDGE
	add_theme_stylebox_override("panel", style)
	add_theme_font_size_override("font_size", FONT)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", GAP)
	add_child(_rows)
	add_to_group(&"travel_menu")
	visible = false


func open() -> void:
	if not TravelWatch.at_gate():
		return
	for row in _rows.get_children():
		_rows.remove_child(row)
		row.queue_free()
	_buttons.clear()
	_label(tr(&"TRAVEL_TITLE"))
	_label(tr(&"TRAVEL_HINT"))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(TEXT_WIDTH, LIST_HEIGHT)
	_rows.add_child(scroll)
	var choices := VBoxContainer.new()
	choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choices.add_theme_constant_override("separation", GAP)
	scroll.add_child(choices)
	for id in TravelWatch.destinations():
		var button := Button.new()
		button.text = (
			tr(&"TRAVEL_HOME")
			if id == 0
			else tr(
				(
					(
						Registry.entry(&"biomes", StringName(SimLoop.state.chapters.regions[id]))
						as BiomeData
					)
					. display_key
				)
			)
		)
		button.disabled = not TravelWatch.daylight()
		button.pressed.connect(_go.bind(id))
		choices.add_child(button)
		_buttons.append(button)
	var cancel := Button.new()
	cancel.text = tr(&"TRAVEL_CANCEL")
	cancel.pressed.connect(close)
	_rows.add_child(cancel)
	active = true
	visible = true
	cancel.grab_focus()


func close() -> void:
	active = false
	visible = false


func _go(id: int) -> void:
	SimLoop.intents.queue(IntentQueue.Kind.TRAVEL, {&"realm": id})
	close()


func _label(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size.x = TEXT_WIDTH
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rows.add_child(label)


func _input(event: InputEvent) -> void:
	if active and (event.is_action_pressed(&"pause") or event.is_action_pressed(&"verb_assume")):
		close()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if active:
		for button in _buttons:
			button.disabled = not TravelWatch.daylight()


func _exit_tree() -> void:
	active = false
