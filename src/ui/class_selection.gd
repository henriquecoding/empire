# src/ui/class_selection.gd — a escolha do monarca, numa partida nova (§08; ADR 0052).
#
# "A interface inicial precisa mostrar a dupla, nao apenas tres retratos de classes"
# (plano §6.1): cada cartao diz o papel, o companheiro, a base, a evolucao e os controlos.
# O tempo fica parado ate confirmar, e a escolha usa-se com rato, comando ou toque.
class_name ClassSelection
extends Control

const WIDTH := 760.0
const MAX_WIDTH := 1080.0
const MARGIN := 24
const CARD_HEIGHT := 240
const OVERLAY := Color("161917")
const SELECTION := Color("ead0a0")
const PERCENT := 100.0
const BODY_GAP := 8
const DETAIL_GAP := 4
const HALF := 0.5
static var active := false
static var release_pending := false

var selected: StringName = &"monarch"
var succession_mode := false
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
var _companion: Label
var _controls: Label
var _choices: Array[StringName] = []
var _aspect: Window.ContentScaleAspect


func _init(choose: Callable = Callable()) -> void:
	_choose = choose
	for dados in MonarchWatch.choices():
		_choices.append(dados.id)


func _ready() -> void:
	active = true
	_aspect = get_tree().root.content_scale_aspect
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	theme = PauseTheme.make()
	add_child(RoyalBackdrop.new())
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
	body.add_theme_constant_override("separation", BODY_GAP)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(body)
	var brand := PauseTheme.label(body, &"UI_MENU_TITLE")
	PauseTheme.title(brand, PauseTheme.BRAND_SIZE)
	var heading := PauseTheme.label(
		body, &"HEIR_EXCHANGE_TITLE" if succession_mode else &"MONARCH_CHOOSE_TITLE"
	)
	PauseTheme.title(heading)
	PauseTheme.label(body, &"HEIR_EXCHANGE_NOTE" if succession_mode else &"ARRIVAL_CHOOSE_INTRO")
	_grid = GridContainer.new()
	_grid.columns = _choices.size()
	_grid.add_theme_constant_override("h_separation", PauseTheme.COLUMN_GAP)
	_grid.add_theme_constant_override("v_separation", PauseTheme.ROW_GAP)
	body.add_child(_grid)
	for id in _choices:
		_card(id)
	var profile := PanelContainer.new()
	body.add_child(profile)
	var details := VBoxContainer.new()
	details.add_theme_constant_override("separation", DETAIL_GAP)
	profile.add_child(details)
	_title = PauseTheme.label(details)
	PauseTheme.title(_title, PauseTheme.ACTION_SIZE)
	_companion = PauseTheme.label(details)
	_base = PauseTheme.label(details)
	_evolved = PauseTheme.label(details)
	_controls = PauseTheme.label(details)
	_controls.add_theme_color_override("font_color", PauseTheme.GOLD)
	PauseTheme.label(
		body, &"MONARCH_CHOOSE_RULE_TOUCH" if TouchControls.active else &"MONARCH_CHOOSE_RULE"
	)
	start_button = PauseTheme.button(_layout, &"CLASS_BEGIN", begin)
	PauseTheme.primary(start_button)
	if succession_mode:
		PauseTheme.button(_layout, &"UI_MENU_BACK", func() -> void: _choose.call(&""))
	get_viewport().size_changed.connect(fit)
	fit()
	select(selected)
	get_tree().process_frame.connect(_initial_focus, CONNECT_ONE_SHOT)


func _initial_focus() -> void:
	cards[0].grab_focus()
	_scroll.set_deferred(&"follow_focus", true)
	_scroll.set_deferred(&"scroll_vertical", 0)


func _card(id: StringName) -> void:
	var data := Registry.entry(&"monarchs", id) as MonarchData
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
	portrait.monarch_id = id
	column.add_child(portrait)
	var name := PauseTheme.label(column, StringName(data.display_key))
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	PauseTheme.title(name, PauseTheme.ACTION_SIZE)
	var role := PauseTheme.label(column, _key("ROLE", id))
	role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	role.mouse_filter = Control.MOUSE_FILTER_IGNORE
	role.add_theme_font_size_override("font_size", PauseTheme.SMALL_SIZE)


func select(id: StringName) -> void:
	if not _choices.has(id):
		return
	selected = id
	for i in cards.size():
		cards[i].modulate = Color.WHITE if _choices[i] == id else Color("b2c3bc")
		cards[i].button_pressed = _choices[i] == id
	var monarca := Registry.entry(&"monarchs", id) as MonarchData
	var data := Registry.entry(&"classes", monarca.skill_class) as ClassData
	_title.text = tr(StringName(monarca.display_key))
	_companion.text = tr(_key("COMPANION", id))
	_base.text = tr(_key("BASE", id)).format(
		{"defense": roundi(float(data.phase1_params.get(&"defense", 0.0)) * PERCENT)}
	)
	_evolved.text = (
		tr(_key("ARRIVAL_EVOLVED", id))
		. format(
			{
				"defense": roundi(float(data.phase2_params.get(&"defense", 0.0)) * PERCENT),
				"seeds": data.evolve_seed_cost,
				"feat": data.evolve_condition_value,
				"wins": LastCartWatch.rules().battle_evolve_count,
			}
		)
	)
	_controls.text = tr(_key("CONTROLS_TOUCH" if TouchControls.active else "CONTROLS", id))
	start_button.text = tr(&"CLASS_BEGIN").format({"name": _title.text})
	if succession_mode:
		start_button.text = tr(&"HEIR_EXCHANGE_CONFIRM").format({"name": _title.text})
		start_button.disabled = selected == MonarchWatch.data().id


func begin() -> void:
	if _choose.is_valid():
		release_pending = Input.is_action_pressed(&"verb_drop")
		_choose.call(selected)


func fit() -> void:
	var ui_scale := HudLayout.zoom(get_viewport())
	scale = Vector2.ONE * ui_scale
	size = get_viewport_rect().size / ui_scale
	var inset := maxf(MARGIN, (size.x - MAX_WIDTH) * HALF)
	for side: String in ["left", "right"]:
		_margin.add_theme_constant_override("margin_" + side, int(inset))
	for side: String in ["top", "bottom"]:
		_margin.add_theme_constant_override("margin_" + side, MARGIN)
	_grid.columns = _choices.size() if size.x >= WIDTH else 1


func _unhandled_input(event: InputEvent) -> void:
	if succession_mode and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_choose.call(&"")


func _exit_tree() -> void:
	active = false
	get_tree().root.content_scale_aspect = _aspect


## A chave de texto de um pedaco do cartao: MONARCH_<pedaco>_<ID> (ADR 0052).
static func _key(pedaco: String, id: StringName) -> StringName:
	return StringName("MONARCH_%s_%s" % [pedaco, String(id).to_upper()])
