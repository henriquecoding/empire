class_name ClassSelection
extends Control

const WIDTH := 760.0
const MAX_WIDTH := 1000.0
const MARGIN := 28
const CARD_HEIGHT := 212
const OVERLAY := Color("161917")
const SELECTION := Color("ead0a0")
const PERCENT := 100.0
const HALF := 0.5
static var active := false
static var release_pending := false

var selected: StringName = &"monarch"
var cards: Array[Button] = []
var start_button: Button
var _choose: Callable
var _grid: GridContainer
var _layout: VBoxContainer
var _scroll: ScrollContainer
var _margin: MarginContainer
var _title: Label
var _base: Label
var _evolved: Label
var _controls: Label
var _aspect: Window.ContentScaleAspect


func _init(choose: Callable = Callable()) -> void:
	_choose = choose


func _ready() -> void:
	active = true
	_aspect = get_tree().root.content_scale_aspect
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	theme = PauseTheme.make()
	var bg := ColorRect.new()
	bg.color = OVERLAY
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_margin = MarginContainer.new()
	_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_margin)
	_layout = VBoxContainer.new()
	_margin.add_child(_layout)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_layout.add_child(_scroll)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(body)
	var brand := PauseTheme.label(body, &"UI_MENU_TITLE")
	PauseTheme.title(brand, PauseTheme.BRAND_SIZE)
	var heading := PauseTheme.label(body, &"CLASS_CHOOSE_TITLE")
	PauseTheme.title(heading)
	PauseTheme.label(body, &"CLASS_CHOOSE_INTRO")
	_grid = GridContainer.new()
	_grid.columns = Roster.STARTERS.size()
	_grid.add_theme_constant_override("h_separation", PauseTheme.COLUMN_GAP)
	_grid.add_theme_constant_override("v_separation", PauseTheme.ROW_GAP)
	body.add_child(_grid)
	for id in Roster.STARTERS:
		_card(id)
	var profile := PanelContainer.new()
	body.add_child(profile)
	var details := VBoxContainer.new()
	profile.add_child(details)
	_title = PauseTheme.label(details)
	PauseTheme.title(_title)
	_base = PauseTheme.label(details)
	_evolved = PauseTheme.label(details)
	_controls = PauseTheme.label(details)
	_controls.add_theme_color_override("font_color", PauseTheme.GOLD)
	PauseTheme.label(
		body, &"CLASS_CHOOSE_RULE_TOUCH" if TouchControls.active else &"CLASS_CHOOSE_RULE"
	)
	start_button = PauseTheme.button(_layout, &"CLASS_BEGIN", begin)
	PauseTheme.primary(start_button)
	get_viewport().size_changed.connect(fit)
	fit()
	select(selected)
	get_tree().process_frame.connect(_initial_focus, CONNECT_ONE_SHOT)


func _initial_focus() -> void:
	cards[0].grab_focus()
	_scroll.set_deferred(&"follow_focus", true)
	_scroll.set_deferred(&"scroll_vertical", 0)


func _card(id: StringName) -> void:
	var data := Registry.entry(&"classes", id) as ClassData
	var card := Button.new()
	card.toggle_mode = true
	card.custom_minimum_size.y = CARD_HEIGHT
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.pressed.connect(select.bind(id))
	_grid.add_child(card)
	cards.append(card)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.offset_top = PauseTheme.ROW_GAP
	column.offset_left = PauseTheme.ROW_GAP
	column.offset_right = -PauseTheme.ROW_GAP
	card.add_child(column)
	var portrait := ClassPortrait.new()
	portrait.class_id = id
	column.add_child(portrait)
	var name := PauseTheme.label(column, StringName(data.display_key))
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	PauseTheme.title(name, PauseTheme.ACTION_SIZE)
	var role := PauseTheme.label(column, StringName("CLASS_ROLE_" + String(id).to_upper()))
	role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	role.mouse_filter = Control.MOUSE_FILTER_IGNORE
	role.add_theme_font_size_override("font_size", PauseTheme.SMALL_SIZE)


func select(id: StringName) -> void:
	if not Roster.STARTERS.has(id):
		return
	selected = id
	for i in cards.size():
		cards[i].modulate = SELECTION if Roster.STARTERS[i] == id else Color.WHITE
		cards[i].button_pressed = Roster.STARTERS[i] == id
	var data := Registry.entry(&"classes", id) as ClassData
	_title.text = tr(StringName(data.display_key))
	_base.text = tr(StringName("CLASS_BASE_" + String(id).to_upper())).format(
		{"defense": roundi(float(data.phase1_params.get(&"defense", 0.0)) * PERCENT)}
	)
	_evolved.text = (
		tr(StringName("CLASS_EVOLVED_" + String(id).to_upper()))
		. format(
			{
				"defense": roundi(float(data.phase2_params.get(&"defense", 0.0)) * PERCENT),
				"seeds": data.evolve_seed_cost,
				"feat": data.evolve_condition_value,
			}
		)
	)
	var mao := "CLASS_CONTROLS_TOUCH_" if TouchControls.active else "CLASS_CONTROLS_"  # ADR 0047
	_controls.text = tr(StringName(mao + String(id).to_upper()))
	start_button.text = tr(&"CLASS_BEGIN").format({"name": _title.text})


func begin() -> void:
	if _choose.is_valid():
		release_pending = Input.is_action_pressed(&"verb_drop")
		_choose.call(selected)


func fit() -> void:
	var factor := maxf(PauseLayout.MIN_SCALE, get_viewport().get_final_transform().get_scale().x)
	var ui_scale := maxf(1.0, 1.0 / factor)
	scale = Vector2.ONE * ui_scale
	size = get_viewport_rect().size / ui_scale
	var inset := maxf(MARGIN, (size.x - MAX_WIDTH) * HALF)
	for side: String in ["left", "right"]:
		_margin.add_theme_constant_override("margin_" + side, int(inset))
	for side: String in ["top", "bottom"]:
		_margin.add_theme_constant_override("margin_" + side, MARGIN)
	_grid.columns = Roster.STARTERS.size() if size.x >= WIDTH else 1


func _exit_tree() -> void:
	active = false
	get_tree().root.content_scale_aspect = _aspect
