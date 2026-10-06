class_name HudStyle
extends RefCounted

const BACKGROUND := Color("191713f2")
const BORDER := Color("665a43")
const TEXT := Color("f4ecd9")
const MUTED := Color("c9bfa8")
const GOLD := Color("efbe70")

static var _font: FontFile


static func font() -> FontFile:
	if _font == null:
		_font = ThemeDB.fallback_font.duplicate() as FontFile
		# A HUD compensa a escala do canvas; a fonte nao deve voltar a encolher.
		_font.oversampling = 1.0
	return _font


static func panel(accent: Color = BORDER) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = BACKGROUND
	style.border_color = accent
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(HudLayout.PADDING)
	style.shadow_color = Color(0, 0, 0, 0.18)
	style.shadow_size = 3
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
