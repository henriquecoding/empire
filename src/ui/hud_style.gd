class_name HudStyle
extends RefCounted

const INK := Color("171b16")
const PAPER := Color(0.07, 0.09, 0.07, 0.94)
const TEXT := Color("f3e8c9")
const MUTED := Color("c2bc9e")
const GOLD := Color("e9bb68")
const EDGE := Color("636249")
const PADDING := 10
const GAP := 8
const FONT := 18


static func label(parent: Node, size: int = FONT, color: Color = TEXT) -> Label:
	var node := Label.new()
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	parent.add_child(node)
	return node


static func panel(parent: Node) -> VBoxContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER
	style.border_color = EDGE
	style.set_border_width_all(1)
	style.set_content_margin_all(PADDING)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", GAP)
	panel.add_child(column)
	return column


static func button(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", FONT)
	button.add_theme_color_override("font_color", TEXT)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button
