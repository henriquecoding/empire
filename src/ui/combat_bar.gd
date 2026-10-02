class_name CombatBar
extends PanelContainer

const PANEL_COLOR := Color(0.10, 0.08, 0.07, 0.94)
const HALF := 0.5
const FOOTER_GAP := 58.0
const MIN_SCALE := 0.1
const SCREEN_MARGIN := 24.0
const CORNER := 6
const PADDING := 10
const FONT_SIZE := 14
const META_SIZE := 13
const TRACK_SIZE := 3
const BUTTON_HEIGHT := 44
const BUTTON_CORNER := 4
const MIN_INTERVAL := 0.01

const WIDTH := 450.0
const HEIGHT := 104.0
const GAP := 8
const INK := Color("201b19")
const GOLD := Color("efc278")
const GREEN := Color("97d1ab")
const TEXT := Color("f4ebd6")

var _attack: Button
var _skill: Button
var _title: Label
var _state: Label
var _attack_progress: ProgressBar
var _skill_progress: ProgressBar
var _feedback_serial := 0


func _ready() -> void:
	var panel := StyleBoxFlat.new()
	panel.bg_color = PANEL_COLOR
	panel.border_color = Color("745738")
	panel.set_border_width_all(1)
	panel.set_corner_radius_all(CORNER)
	panel.set_content_margin_all(PADDING)
	add_theme_stylebox_override("panel", panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", GAP)
	add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	_title = Label.new()
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.add_theme_color_override("font_color", TEXT)
	_title.add_theme_font_size_override("font_size", FONT_SIZE)
	header.add_child(_title)
	_state = Label.new()
	_state.add_theme_color_override("font_color", GOLD)
	_state.add_theme_font_size_override("font_size", META_SIZE)
	header.add_child(_state)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", GAP)
	column.add_child(row)
	var primary := _column(row)
	var secondary := _column(row)
	_attack = _button(primary, GOLD)
	_skill = _button(secondary, GREEN)
	_attack_progress = _progress(primary, GOLD)
	_skill_progress = _progress(secondary, GREEN)
	_attack.pressed.connect(_press_attack)
	_skill.pressed.connect(_press_skill)
	_feedback_serial = HeroWatch.feedback_serial
	get_viewport().size_changed.connect(_fit)
	call_deferred(&"_fit")


func _fit() -> void:
	var factor := maxf(MIN_SCALE, get_viewport().get_final_transform().get_scale().x)
	var ui_scale := maxf(1.0, 1.0 / factor)
	scale = Vector2.ONE * ui_scale
	var area := get_viewport_rect().size
	var width := minf(WIDTH, area.x / ui_scale - SCREEN_MARGIN)
	size = Vector2(width, HEIGHT)
	position = Vector2(
		(area.x - width * ui_scale) * HALF, area.y - (HEIGHT + FOOTER_GAP) * ui_scale
	)


func _column(parent: Control) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", TRACK_SIZE)
	parent.add_child(column)
	return column


func _button(parent: Control, color: Color) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, BUTTON_HEIGHT)
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	button.add_theme_color_override("font_color", TEXT)
	var style := StyleBoxFlat.new()
	style.bg_color = INK
	style.border_color = color
	style.set_border_width_all(1)
	style.set_corner_radius_all(BUTTON_CORNER)
	button.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = Color("443522")
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	parent.add_child(button)
	return button


func _progress(parent: Control, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = 1.0
	bar.custom_minimum_size.y = TRACK_SIZE
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	bar.add_theme_stylebox_override("fill", fill)
	var background := StyleBoxFlat.new()
	background.bg_color = INK
	bar.add_theme_stylebox_override("background", background)
	parent.add_child(bar)
	return bar


func _process(_delta: float) -> void:
	_fit()
	visible = SimLoop.field != null and not ClassSelection.active and not TravelPanel.active
	if not visible:
		return
	var who := Assume.driven()
	var i := SimLoop.units.index_of(who)
	if i < 0:
		return
	var current := HeroWatch.current()
	var stats := SimLoop.combat.manual.profile(SimLoop.units, who)
	var can_attack: bool = stats.get(&"damage", 0) > 0 and SimLoop.units.alive(i)
	_attack.disabled = not SimLoop.running() or not can_attack
	_skill.disabled = (
		not SimLoop.running()
		or not SimLoop.units.alive(i)
		or current not in [&"monarch", &"archer", &"bard"]
	)
	var keys := CombatGlyphs.buttons(CombatInput.device)
	_attack.text = "%s · %s" % [keys[0], tr(CombatGlyphs.attack_name(current))]
	_skill.text = "%s · %s" % [keys[1], tr(CombatGlyphs.skill_name(current))]
	_attack.tooltip_text = tr(&"COMBAT_ATTACK_HELP")
	_skill.tooltip_text = tr(CombatGlyphs.skill_help(current))
	var data := Registry.entry(&"classes", current) as ClassData
	_title.text = tr(StringName(data.display_key)) if data != null else tr(&"COMBAT_TITLE")
	var cooldown := SimLoop.units.cooldowns[i]
	_state.text = (
		tr(&"COMBAT_RECOVERING").format({"seconds": "%.1f" % cooldown})
		if cooldown > 0
		else tr(&"COMBAT_READY")
	)
	_attack_progress.value = 1.0 - cooldown / maxf(MIN_INTERVAL, float(stats.get(&"interval", 1.0)))
	var skill_cooldown := (
		float(SimLoop.field.song.cooldowns.get(who, 0.0)) if current == &"bard" else 0.0
	)
	var body := Registry.entry(&"units", SimLoop.units.data_ids[i]) as UnitData
	_skill_progress.value = 1.0 - skill_cooldown / maxf(MIN_INTERVAL, body.attack_interval)
	if current == &"monarch":
		var refusal := InputRouter.impulse_refusal(&"vigil")
		var price := SimLoop.field.crown.price(
			&"vigil", ClockService.clock.day, RulesFactory.impulse_cost_mult(SimLoop.state.greed)
		)
		_skill.tooltip_text += (
			"\n"
			+ tr(&"TOAST_IMPULSE_NEEDS_COINS").format({"name": tr(&"IMPULSE_VIGIL"), "cost": price})
		)
		if not refusal.is_empty():
			_skill.tooltip_text += "\n" + refusal
		_skill_progress.value = 1.0 if refusal.is_empty() else 0.0
	if HeroWatch.feedback_serial != _feedback_serial:
		_feedback_serial = HeroWatch.feedback_serial
		get_tree().call_group(&"painel", &"say", tr(HeroWatch.feedback))


func _press_attack() -> void:
	CombatInput.cursor_aim = false
	CombatInput.queue_attack(CombatInput.facing)


func _press_skill() -> void:
	CombatInput.cursor_aim = false
	CombatInput.queue_skill(CombatInput.aim_x())
