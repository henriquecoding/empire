class_name ContextPanel
extends Label

const FONT := 16
const TEXTO_S := GameHud.TEXTO_S

var device := Glyphs.Device.KEYBOARD
var _texto_em := 0.0
var _key := &""
var _hint := HintCue.new()


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_font_size_override("font_size", FONT)
	add_theme_font_override("font", HudStyle.font())
	add_theme_color_override("font_color", HudStyle.TEXT)
	var panel := HudStyle.panel()
	panel.set_content_margin_all(HudLayout.GAP)
	add_theme_stylebox_override("normal", panel)
	add_to_group(&"instrumentos")
	add_to_group(&"hud_context")
	device = Glyphs.initial()


func _input(event: InputEvent) -> void:
	var device_name := ""
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		device_name = Input.get_joy_name(event.device)
	device = Glyphs.device_of(event, device, device_name)


func _process(delta: float) -> void:
	if SimLoop.state == null:
		return
	var zoom := HudLayout.zoom(get_viewport())
	var area := get_viewport_rect().size / zoom
	scale = Vector2.ONE * zoom
	_texto_em -= delta
	if _texto_em <= 0.0:
		_texto_em = TEXTO_S
		var message := GuideHints.context(device)
		text = message.text
		_key = message.key
		if text.is_empty() and area.x < HudLayout.GOAL_MIN_WIDTH:
			message = GuideHints.goal()
			text = message.text
			_key = message.key
	# Com a ficha do sitio aberta a linha curta repetia-a (ADR 0078).
	visible = _hint.present(_key, InteractionFocus.still() and not SiteSheet.active, delta)
	var available := area
	if not TouchControls.active and area.x >= HudLayout.COMBAT_MIN_WIDTH:
		available.x -= CombatBar.WIDTH + HudLayout.COMBAT_GAP
	var frame := HudLayout.context(available, 0)
	if not TouchControls.active and area.x < HudLayout.COMBAT_MIN_WIDTH:
		frame.position.y = CombatBar.TOP + CombatBar.HEIGHT + HudLayout.PADDING
	for header: Control in get_tree().get_nodes_in_group(&"hud_header"):
		frame.position.y = maxf(
			frame.position.y, header.get_global_rect().end.y / zoom + HudLayout.PADDING
		)
	if TouchControls.active:
		HudLayout.fit_label(self, area * zoom, zoom, frame.size.x, frame.position.y * zoom)
		return
	size = Vector2(frame.size.x, 0)
	position = frame.position * zoom
