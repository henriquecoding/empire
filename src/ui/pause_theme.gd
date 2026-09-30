class_name PauseTheme
extends RefCounted

const PIXELS := preload("res://src/ui/fonts/silkscreen.ttf")
const INK := Color("efe3c5")
const GOLD := Color("e7b665")
const MUTED := Color("c2b398")
const DARK := Color("211d1b")
const BODY_SIZE := 18
const ACTION_SIZE := 20
const TITLE_SIZE := 24
const BRAND_SIZE := 32
const SMALL_SIZE := 14
const STATUS_SIZE := 16
const BUTTON_HEIGHT := 52
const ROW_GAP := 12
const COLUMN_GAP := 16
const PANEL_PADDING := 20
const PLATE_SIZE := 16
const PLATE_EDGE := Rect2i(1, 1, 14, 13)
const PLATE_FACE := Rect2i(2, 2, 12, 11)
const PLATE_TOP := Rect2i(2, 2, 12, 1)
const PLATE_LEFT := Rect2i(2, 3, 1, 9)
const PLATE_BOTTOM := Rect2i(2, 12, 12, 1)
const TOP_LIGHT := 0.25
const SIDE_LIGHT := 0.15
const BOTTOM_SHADE := 0.3
const SLICE_MARGIN := 4
const FOCUS_MARGIN := 3
const ICON_SIZE := 24
const ICON_EDGE := Rect2i(2, 2, 20, 20)
const ICON_FACE := Rect2i(4, 4, 16, 16)
const ICON_MARK := Rect2i(7, 7, 10, 10)


static func make() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = BODY_SIZE
	var body := ThemeDB.fallback_font.duplicate() as FontFile
	body.oversampling = 1.0
	theme.default_font = body
	var pixels := PIXELS.duplicate() as FontFile
	pixels.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	pixels.hinting = TextServer.HINTING_NONE
	pixels.oversampling = 1.0
	for type: StringName in [&"Button", &"OptionButton", &"CheckButton"]:
		theme.set_font(&"font", type, pixels)
		theme.set_font_size(&"font_size", type, ACTION_SIZE)
		for state: StringName in [&"normal", &"hover", &"pressed", &"disabled"]:
			var fill := Color("73543b") if state == &"normal" else Color("956b40")
			if state == &"pressed" or state == &"disabled":
				fill = Color("44382d")
			theme.set_stylebox(state, type, _plate(fill))
		for color: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color"]:
			theme.set_color(color, type, INK)
		theme.set_color(&"font_focus_color", type, GOLD)
		theme.set_stylebox(&"focus", type, _focus())
	theme.set_color(&"font_color", &"Label", INK)
	theme.set_stylebox(&"panel", &"PopupMenu", _plate(Color("332b26")))
	theme.set_stylebox(&"hover", &"PopupMenu", _plate(Color("73543b")))
	theme.set_color(&"font_color", &"PopupMenu", INK)
	theme.set_color(&"font_hover_color", &"PopupMenu", GOLD)
	theme.set_constant(&"v_separation", &"PopupMenu", ROW_GAP)
	theme.set_constant(&"separation", &"VBoxContainer", ROW_GAP)
	theme.set_constant(&"separation", &"HBoxContainer", COLUMN_GAP)
	theme.set_stylebox(&"panel", &"PanelContainer", _plate(Color("332b26"), PANEL_PADDING))
	for state: StringName in [&"slider", &"grabber_area", &"grabber_area_highlight"]:
		theme.set_stylebox(state, &"HSlider", _track(state != &"slider"))
	for state: StringName in [&"grabber", &"grabber_highlight", &"grabber_disabled"]:
		theme.set_icon(state, &"HSlider", _square(GOLD))
	for state: StringName in [&"checked", &"checked_disabled", &"unchecked", &"unchecked_disabled"]:
		theme.set_icon(state, &"CheckButton", _square(GOLD, state.begins_with("checked")))
	return theme


static func title(label: Label, font_size: int = TITLE_SIZE) -> void:
	var pixels := PIXELS.duplicate() as FontFile
	pixels.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	pixels.oversampling = 1.0
	label.add_theme_font_override("font", pixels)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", GOLD)


static func button(parent: Node, key: StringName, action: Callable) -> Button:
	var button := Button.new()
	button.text = TranslationServer.translate(key)
	button.custom_minimum_size.y = BUTTON_HEIGHT
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(action)
	follow_pointer(button)
	parent.add_child(button)
	return button


## O cursor parado ao trocar de página não tira o foco seguro de Cancelar.
static func follow_pointer(control: Control) -> void:
	control.gui_input.connect(
		func(event: InputEvent) -> void:
			if event is InputEventMouseMotion and event.relative != Vector2.ZERO:
				control.grab_focus()
	)


static func primary(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _plate(Color("a07843")))


static func label(parent: Node, key: StringName = &"") -> Label:
	var label := Label.new()
	label.text = TranslationServer.translate(key) if key != &"" else ""
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	parent.add_child(label)
	return label


static func _plate(fill: Color, margin: int = ROW_GAP) -> StyleBoxTexture:
	var image := Image.create(PLATE_SIZE, PLATE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color("161515"))
	image.fill_rect(PLATE_EDGE, Color("46382e"))
	image.fill_rect(PLATE_FACE, fill)
	image.fill_rect(PLATE_TOP, fill.lightened(TOP_LIGHT))
	image.fill_rect(PLATE_LEFT, fill.lightened(SIDE_LIGHT))
	image.fill_rect(PLATE_BOTTOM, fill.darkened(BOTTOM_SHADE))
	var style := StyleBoxTexture.new()
	style.texture = ImageTexture.create_from_image(image)
	for side: Side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_texture_margin(side, SLICE_MARGIN)
		style.set_content_margin(side, margin)
	return style


static func _focus() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = GOLD
	style.set_border_width_all(2)
	style.set_expand_margin_all(FOCUS_MARGIN)
	return style


static func _track(active: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = GOLD if active else DARK
	style.content_margin_top = SLICE_MARGIN
	style.content_margin_bottom = SLICE_MARGIN
	return style


static func _square(color: Color, checked: bool = true) -> Texture2D:
	var image := Image.create(ICON_SIZE, ICON_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color("161515"))
	image.fill_rect(ICON_EDGE, Color("8b6540"))
	image.fill_rect(ICON_FACE, DARK)
	if checked:
		image.fill_rect(ICON_MARK, color)
	return ImageTexture.create_from_image(image)
