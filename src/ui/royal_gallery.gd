class_name RoyalGallery
extends Control

const NAMES := [
	&"MONARCH_KING",
	&"UNIT_SQUIRE",
	&"MONARCH_NIA",
	&"UNIT_BARD_BANNER",
	&"MONARCH_ARCHER_EMPEROR",
	&"ANIM_QUARTERMASTER",
	&"ANIM_SHADOW",
	&"ANIM_DANCER"
]
const LAYER := 20
const MARGIN := 18
const GAP := 10
const BUTTON_HEIGHT := 44
const BUTTON_WIDTH := 190
const FUTURE_CAST_FROM := 6
static var active := false
var _stage: RoyalStage
var _actions: OptionButton
var _description: Label
var _return_focus: Control
var _action_ids: Array[StringName] = []


static func open_on(parent: Node) -> void:
	if active:
		return
	var gallery := RoyalGallery.new()
	parent.add_child(gallery)


func _ready() -> void:
	active = true
	_return_focus = get_viewport().gui_get_focus_owner()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = LAYER
	theme = PauseTheme.make()
	var background := ColorRect.new()
	background.color = Color("182b2a")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, MARGIN)
	add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", GAP)
	scroll.add_child(body)
	PauseTheme.title(PauseTheme.label(body, &"ANIM_GALLERY_TITLE"))
	var cast := OptionButton.new()
	cast.custom_minimum_size.y = BUTTON_HEIGHT
	for key: StringName in NAMES:
		cast.add_item(tr(key))
	body.add_child(cast)
	_actions = OptionButton.new()
	_actions.custom_minimum_size.y = BUTTON_HEIGHT
	body.add_child(_actions)
	_stage = RoyalStage.new()
	_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(_stage)
	_description = PauseTheme.label(body)
	var controls := HFlowContainer.new()
	body.add_child(controls)
	PauseTheme.button(controls, &"ANIM_PLAY_PAUSE", _toggle)
	PauseTheme.button(controls, &"ANIM_NEXT_FRAME", _next)
	PauseTheme.button(controls, &"ANIM_DIRECTION", _direction)
	PauseTheme.button(controls, &"ANIM_RESTART", _stage.restart)
	for child: Button in controls.get_children():
		child.autowrap_mode = TextServer.AUTOWRAP_OFF
		child.custom_minimum_size.x = BUTTON_WIDTH
	PauseTheme.button(body, &"UI_MENU_BACK", close)
	cast.item_selected.connect(_select_character)
	_actions.item_selected.connect(_select_action)
	_select_character(0)
	cast.grab_focus()


func _select_character(index: int) -> void:
	_stage.profile = RoyalArt.CAST[index]
	_actions.clear()
	_action_ids.clear()
	var item := RoyalArt.entry(_stage.profile)
	if _stage.profile == &"royal_shadow":
		_action_ids.append(&"heal_sequence")
	for tag: String in item.tags:
		if tag.ends_with("_right"):
			_action_ids.append(StringName(tag.trim_suffix("_right")))
	for action in _action_ids:
		_actions.add_item(tr(StringName("ANIM_ACTION_" + String(action).to_upper())))
	var primary := int(_action_ids.find(RoyalStage.PRIMARY[_stage.profile]))
	_actions.select(maxi(primary, 0))
	_select_action(maxi(primary, 0))
	_description.text = tr(
		&"ANIM_FUTURE_PAIR" if index >= FUTURE_CAST_FROM else &"ANIM_GALLERY_NOTE"
	)


func _select_action(index: int) -> void:
	_stage.action = _action_ids[index]
	_stage.restart()


func _toggle() -> void:
	_stage.playing = not _stage.playing


func _next() -> void:
	_stage.next_frame()


func _direction() -> void:
	_stage.facing = -_stage.facing
	_stage.queue_redraw()


func close() -> void:
	if is_instance_valid(_return_focus):
		_return_focus.grab_focus()
	queue_free()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		close()


func _exit_tree() -> void:
	active = false
