class_name PauseLayout
extends Control

const HOME_SIZE := Vector2(480, 590)
const WIDE_SIZE := Vector2(860, 590)
const FRAME_MARGIN := 24
const HALF := 0.5
const ACTION_WIDTH := 340
const WIDE_WIDTH := 760
const PAGE_WIDTH := 800
const COMPACT_MARGIN := 20
const WIDE_MARGIN := 48
const SHORT_HEIGHT := 500
const SHORT_MARGIN := 8
const FOOTER_HEIGHT := 430
const REALM_GAP := 64
const SCROLL_DEADZONE := 8

var header: VBoxContainer
var actions: VBoxContainer
var pages: Control
var home: ScrollContainer
var footer: Label
var realm: VBoxContainer
var status: Label
var context: Label
var _margin: MarginContainer
var _row: VBoxContainer
var _aspect: Window.ContentScaleAspect
var _entered := false


func _ready() -> void:
	theme = PauseTheme.make()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_margin = MarginContainer.new()
	_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", PauseTheme.PANEL_PADDING)
	_margin.add_child(column)
	header = VBoxContainer.new()
	column.add_child(header)
	header.add_child(CrownBanner.new())
	context = PauseTheme.label(header)
	context.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	context.add_theme_color_override("font_color", PauseTheme.MUTED)
	pages = Control.new()
	pages.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(pages)
	pages.resized.connect(_fit_pages)
	home = scroll(pages)
	_row = VBoxContainer.new()
	_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_row.add_theme_constant_override("separation", SHORT_MARGIN)
	home.add_child(_row)
	actions = VBoxContainer.new()
	actions.custom_minimum_size.x = ACTION_WIDTH
	actions.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_row.add_child(actions)
	realm = VBoxContainer.new()
	realm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	realm.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_row.add_child(realm)
	status = PauseTheme.label(realm)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	PauseTheme.title(status, PauseTheme.STATUS_SIZE)
	footer = PauseTheme.label(column, &"UI_MENU_HINT")
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", PauseTheme.SMALL_SIZE)
	footer.add_theme_color_override("font_color", PauseTheme.MUTED)
	get_viewport().size_changed.connect(fit)
	fit()


## A interface compensa o canvas reduzido: num telefone os alvos continuam a 52 px.
func fit() -> void:
	var ui_scale := HudLayout.zoom(get_viewport())
	scale = Vector2.ONE * ui_scale
	var screen := get_viewport_rect().size / ui_scale
	var is_home := home.visible
	size = Vector2(
		minf(HOME_SIZE.x if is_home else WIDE_SIZE.x, screen.x - FRAME_MARGIN),
		minf(HOME_SIZE.y, screen.y - FRAME_MARGIN)
	)
	position = ((screen - size) * HALF * ui_scale).round()
	var margin := FRAME_MARGIN if size.y >= SHORT_HEIGHT else SHORT_MARGIN
	for side: String in ["left", "top", "right", "bottom"]:
		_margin.add_theme_constant_override("margin_" + side, margin)
	actions.custom_minimum_size.x = 0
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	realm.hide()
	footer.visible = size.y >= SHORT_HEIGHT
	context.visible = size.y >= SHORT_HEIGHT
	header.get_child(0).visible = size.y >= SHORT_HEIGHT
	_row.queue_sort()
	_fit_pages()
	queue_redraw()


func _draw() -> void:
	CrownSkin.frame(self, Rect2(Vector2.ZERO, size))


func _fit_pages() -> void:
	for child: Control in pages.get_children():
		if child != home:
			child.add_theme_constant_override(
				"separation", SHORT_MARGIN if size.y < SHORT_HEIGHT else PauseTheme.COLUMN_GAP
			)
			for panel in child.get_children():
				if panel is PanelContainer:
					var box := panel.get_theme_stylebox(&"panel").duplicate() as StyleBox
					box.set_content_margin_all(
						SHORT_MARGIN if size.y < SHORT_HEIGHT else PauseTheme.PANEL_PADDING
					)
					panel.add_theme_stylebox_override(&"panel", box)
			var inset := maxf(0, (pages.size.x - PAGE_WIDTH) / 2)
			child.offset_left = inset
			child.offset_right = -inset


func enter() -> void:
	if not _entered:
		_aspect = get_tree().root.content_scale_aspect
		_entered = true
		get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	fit()


func leave() -> void:
	if _entered:
		get_tree().root.content_scale_aspect = _aspect
		_entered = false


func _exit_tree() -> void:
	leave()


static func scroll(parent: Node) -> ScrollContainer:
	var scroll := TouchScroll.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	scroll.scroll_deadzone = SCROLL_DEADZONE
	parent.add_child(scroll)
	return scroll


func page() -> VBoxContainer:
	var page := VBoxContainer.new()
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	page.add_theme_constant_override("separation", PauseTheme.COLUMN_GAP)
	pages.add_child(page)
	page.hide()
	return page


func switch_to(page: Control) -> void:
	var focus := get_viewport().gui_get_focus_owner()
	if focus != null and is_ancestor_of(focus):
		focus.release_focus()
	for child: Control in pages.get_children():
		child.visible = child == page
	header.visible = page == home
	fit()
