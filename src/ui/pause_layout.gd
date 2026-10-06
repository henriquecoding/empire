class_name PauseLayout
extends Control

const ACTION_WIDTH := 340
const WIDE_WIDTH := 760
const PAGE_WIDTH := 800
const COMPACT_MARGIN := 20
const WIDE_MARGIN := 48
const SHORT_HEIGHT := 500
const FOOTER_HEIGHT := 430
const REALM_GAP := 64

var header: VBoxContainer
var actions: VBoxContainer
var pages: Control
var home: ScrollContainer
var footer: Label
var realm: VBoxContainer
var status: Label
var context: Label
var _margin: MarginContainer
var _row: HBoxContainer
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
	var brand := PauseTheme.label(header, &"UI_MENU_TITLE")
	PauseTheme.title(brand, PauseTheme.BRAND_SIZE)
	context = PauseTheme.label(header)
	context.add_theme_color_override("font_color", PauseTheme.MUTED)
	pages = Control.new()
	pages.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(pages)
	pages.resized.connect(_fit_pages)
	home = scroll(pages)
	_row = HBoxContainer.new()
	_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_row.add_theme_constant_override("separation", REALM_GAP)
	home.add_child(_row)
	actions = VBoxContainer.new()
	actions.custom_minimum_size.x = ACTION_WIDTH
	actions.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_row.add_child(actions)
	realm = VBoxContainer.new()
	realm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	realm.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_row.add_child(realm)
	var crest := PauseCrest.new()
	realm.add_child(crest)
	status = PauseTheme.label(realm)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	PauseTheme.title(status, PauseTheme.STATUS_SIZE)
	footer = PauseTheme.label(column, &"UI_MENU_HINT")
	footer.add_theme_font_size_override("font_size", PauseTheme.SMALL_SIZE)
	footer.add_theme_color_override("font_color", PauseTheme.MUTED)
	get_viewport().size_changed.connect(fit)
	fit()


## A interface compensa o canvas reduzido: num telefone os alvos continuam a 52 px.
func fit() -> void:
	var ui_scale := HudLayout.zoom(get_viewport())
	scale = Vector2.ONE * ui_scale
	size = get_viewport_rect().size / ui_scale
	var compact := size.x < WIDE_WIDTH
	var margin := COMPACT_MARGIN if compact or size.y < SHORT_HEIGHT else WIDE_MARGIN
	for side: String in ["left", "top", "right", "bottom"]:
		_margin.add_theme_constant_override("margin_" + side, margin)
	actions.custom_minimum_size.x = minf(ACTION_WIDTH, size.x - margin * 2)
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL if compact else Control.SIZE_FILL
	realm.visible = not compact
	footer.visible = not compact and size.y >= FOOTER_HEIGHT
	context.visible = compact
	_row.queue_sort()
	_fit_pages()


func _fit_pages() -> void:
	for child: Control in pages.get_children():
		if child != home:
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
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
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
