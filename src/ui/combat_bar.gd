# src/ui/combat_bar.gd — o ataque e a habilidade de quem se conduz (ADR 0045), no canto.
#
# Estava ao fundo do ecra, ao meio, por cima do rodape — e o fundo do ecra e o corte de
# solo: com o rei la em baixo, os botoes tapavam o sitio onde ele anda. O dono, a
# 02/10/2026: "esses botoes nao devem estar ali na frente atrapalhando, pois ao entrar no
# subsolo eles ficam por cima" (Q-186). Passa ao canto de cima, a direita, logo abaixo do
# painel do objectivo e acima da linha do aviso e das legendas: e ceu, onde nao ha jogo.
class_name CombatBar
extends PanelContainer

const PANEL_COLOR := Color(0.10, 0.08, 0.07, 0.94)
const SCREEN_MARGIN := 24.0
## O canto: a margem da direita do painel do objectivo, e por baixo da faixa de cima.
const RIGHT_MARGIN := 20.0
const TOP := GameHud.FAIXA_TOPO + 8.0
const CORNER := 6
const PADDING := 6
const FONT_SIZE := 12
const META_SIZE := 12
const TRACK_SIZE := 3
const BUTTON_HEIGHT := 28
const BUTTON_CORNER := 4
const MIN_INTERVAL := 0.01

const WIDTH := 340.0
const HEIGHT := 66.0
const GAP := 4
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
	var ui_scale := HudLayout.zoom(get_viewport())
	scale = Vector2.ONE * ui_scale
	var caixa := place(get_viewport_rect().size, ui_scale)
	size = caixa.size
	position = caixa.position


## Onde fica o painel num ecra `area` com a escala `ui_scale`: no canto de cima a direita,
## e o tamanho antes da escala. Estatica para se poder medir sem ecra.
static func place(area: Vector2, ui_scale: float) -> Rect2:
	var width := minf(WIDTH, area.x / ui_scale - SCREEN_MARGIN)
	var x := area.x - (width + RIGHT_MARGIN) * ui_scale
	return Rect2(Vector2(x, TOP * ui_scale), Vector2(width, HEIGHT))


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
	visible = (
		SimLoop.field != null
		and not ClassSelection.active
		and not TravelPanel.active
		and not TouchControls.active
	)
	if HeroWatch.feedback_serial != _feedback_serial:
		_feedback_serial = HeroWatch.feedback_serial
		get_tree().call_group(&"painel", &"say", tr(HeroWatch.feedback))
	if not visible:
		return
	_fit()
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
	_title.text = MonarchHud.title()  # quem reina, ou o herdeiro (ADR 0052)
	var cooldown := SimLoop.units.cooldowns[i]
	_state.text = (
		tr(&"COMBAT_RECOVERING").format({"seconds": "%.1f" % cooldown})
		if cooldown > 0
		else tr(&"COMBAT_READY")
	)
	_state.text += MonarchHud.arrows(who)  # a aljava do Imperador Arqueiro (Q-200)
	_attack_progress.value = 1.0 - cooldown / maxf(MIN_INTERVAL, float(stats.get(&"interval", 1.0)))
	_skill_progress.value = MonarchHud.skill_ready(who)  # o canto e do Bardo da Nia
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


func _press_attack() -> void:
	CombatInput.cursor_aim = false
	CombatInput.queue_attack(CombatInput.facing)


func _press_skill() -> void:
	CombatInput.cursor_aim = false
	CombatInput.queue_skill(CombatInput.aim_x())
