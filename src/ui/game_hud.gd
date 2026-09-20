class_name GameHud
extends Control

const PHASES := ["HUD_DAWN", "HUD_MORNING", "HUD_NOON", "HUD_AFTERNOON", "HUD_DUSK", "HUD_DARK"]
const REFRESH := 0.1
const NOTICE_SECONDS := 3.0
const MARGIN := 24.0
const TOP_WIDTH := 312.0
const RIGHT_WIDTH := 272.0
const FOOT_HEIGHT := 68.0
const TITLE_SIZE := 22
const SMALL_SIZE := 16
const MODAL_WIDTH := 520.0
const MODAL_HEIGHT := 250.0
const HALF := 0.5
const OVERLAY := Color(0.02, 0.03, 0.02, 0.72)

var _day: Label
var _purse: Label
var _context: Label
var _keys: Label
var _notice: Label
var _title: Label
var _description: Label
var _modal: Control
var _resume: Button
var _restart: Button
var _age := 0.0
var _notice_left := 0.0
var _gamepad := false
var _mode := &"playing"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var left := HudStyle.panel(self)
	left.get_parent().position = Vector2(MARGIN, MARGIN)
	left.get_parent().custom_minimum_size.x = TOP_WIDTH
	HudStyle.label(left, TITLE_SIZE, HudStyle.GOLD).text = tr("HUD_REALM")
	_day = HudStyle.label(left, SMALL_SIZE, HudStyle.MUTED)
	var right := HudStyle.panel(self)
	var right_panel := right.get_parent() as Control
	right_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	right_panel.offset_left = -RIGHT_WIDTH - MARGIN
	right_panel.offset_right = -MARGIN
	right_panel.offset_top = MARGIN
	right_panel.custom_minimum_size.x = RIGHT_WIDTH
	_purse = HudStyle.label(right, TITLE_SIZE, HudStyle.GOLD)
	var footer := HudStyle.panel(self)
	var foot_panel := footer.get_parent() as Control
	foot_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	foot_panel.offset_left = MARGIN
	foot_panel.offset_right = -MARGIN
	foot_panel.offset_top = -FOOT_HEIGHT - MARGIN
	foot_panel.offset_bottom = -MARGIN
	_context = HudStyle.label(footer, HudStyle.FONT)
	_keys = HudStyle.label(footer, SMALL_SIZE, HudStyle.MUTED)
	_notice = HudStyle.label(self, HudStyle.FONT, HudStyle.GOLD)
	_notice.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_notice.position.y = MARGIN
	_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notice.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_create_modal()
	for control in [left.get_parent(), right_panel, foot_panel, _notice, _modal]:
		control.add_to_group(&"instrumentos")
	EventBus.build_completed.connect(_built)
	EventBus.wall_breached.connect(_breached)
	_refresh()


func _create_modal() -> void:
	_modal = Control.new()
	add_child(_modal)
	_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = OVERLAY
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_modal.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column := HudStyle.panel(_modal)
	var panel := column.get_parent() as Control
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.position -= Vector2(MODAL_WIDTH, MODAL_HEIGHT) * HALF
	panel.custom_minimum_size = Vector2(MODAL_WIDTH, MODAL_HEIGHT)
	_title = HudStyle.label(column, TITLE_SIZE, HudStyle.GOLD)
	_description = HudStyle.label(column, HudStyle.FONT)
	_resume = HudStyle.button(column, tr("HUD_RESUME"), _continue_game)
	_restart = HudStyle.button(column, tr("HUD_RESTART"), _new_game)
	_modal.hide()


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		_gamepad = true
	elif event is InputEventKey or event is InputEventMouseButton:
		_gamepad = false


func _process(delta: float) -> void:
	_notice_left = maxf(0.0, _notice_left - delta)
	_notice.visible = _notice_left > 0.0
	_age += delta
	if _age >= REFRESH:
		_age = 0.0
		_refresh()


func _refresh() -> void:
	if ClockService.clock == null or SimLoop.state == null:
		return
	var phase := int(ClockService.clock.current_phase())
	_day.text = tr("HUD_DAY") % [SimLoop.state.day, tr(PHASES[phase])]
	var king := SimLoop.units.index_of(SimLoop.king_id)
	var coins := SimLoop.units.carried_coins[king] if king >= 0 else 0
	var capacity := SimLoop.units.coin_capacities[king] if king >= 0 else 0
	_purse.text = tr("HUD_COINS") % [coins, capacity]
	_context.text = tr(HudState.context_key())
	_keys.text = tr("HUD_PAD" if _gamepad else "HUD_KEYBOARD")
	var next := HudState.mode()
	_modal.visible = next != &"playing"
	_resume.visible = next == &"paused"
	_title.text = tr("HUD_DEFEAT" if next == &"defeat" else "HUD_PAUSED")
	_description.text = tr("HUD_DEFEAT_DETAIL" if next == &"defeat" else "HUD_PAUSE_DETAIL")
	if next != _mode and _modal.visible:
		if next == &"defeat":
			_restart.grab_focus()
		else:
			_resume.grab_focus()
	_mode = next


func _continue_game() -> void:
	if HudState.mode() == &"paused":
		SimLoop.set_paused(false)
	_refresh()


func _new_game() -> void:
	var game := get_parent().get_parent() as Game
	game.restart()


func _built(_id: int) -> void:
	_notice.text = tr("HUD_BUILT")
	_notice_left = NOTICE_SECONDS


func _breached(_id: int) -> void:
	_notice.text = tr("HUD_BREACHED")
	_notice_left = NOTICE_SECONDS
