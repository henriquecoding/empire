# src/ui/hud_style.gd — a HUD com as cores e o canto do Atlas do Imperio (ADR 0074, 0078).
class_name HudStyle
extends RefCounted

const BACKGROUND := Color(Atlas.FIELD, Atlas.FIELD_ALPHA)
const BORDER := Atlas.LINE
const TEXT := Atlas.TEXT
const MUTED := Atlas.SECONDARY
const GOLD := Atlas.COIN

static var _font: FontFile


static func font() -> FontFile:
	if _font == null:
		_font = ThemeDB.fallback_font.duplicate() as FontFile
		# A HUD compensa a escala do canvas; a fonte nao deve voltar a encolher.
		_font.oversampling = 1.0
	return _font


static func panel(accent: Color = BORDER) -> StyleBoxFlat:
	var style := Atlas.card(Atlas.FIELD, accent)
	style.set_content_margin_all(HudLayout.PADDING)
	return style


static func label(parent: Node, font_size: int, color: Color = TEXT) -> Label:
	var value := Label.new()
	value.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	value.add_theme_font_override("font", font())
	value.add_theme_font_size_override("font_size", font_size)
	value.add_theme_color_override("font_color", color)
	parent.add_child(value)
	return value
