class_name HudRibbon
extends Control

const FONTS := Vector2i(19, 16)
const PAUSE_ICON := 28
const TEXT_OFFSET := Vector2(36, 6)
const TEXT_INSET := Vector2(42, 12)
const PAUSE_OFFSET := Vector2(60, 12)
const PAUSE_SIZE := Vector2(44, 40)
const ICON_OFFSET := Vector2(20, 20)
const TRACK_OFFSET := Vector2(36, 33)
const TRACK_INSET := 48

var _coins: Label
var _clock: Label
var _pause: Button
var _cards := {}
var _progress := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_to_group(&"instrumentos")
	add_to_group(&"hud_header")
	_coins = HudStyle.label(self, FONTS.x, HudStyle.GOLD)
	_coins.mouse_filter = Control.MOUSE_FILTER_PASS
	_clock = HudStyle.label(self, FONTS.y)
	_pause = Button.new()
	_pause.icon = CrownIcons.texture(&"pause")
	_pause.expand_icon = true
	_pause.add_theme_constant_override("icon_max_width", PAUSE_ICON)
	_pause.add_theme_stylebox_override("normal", CrownSkin.plate())
	_pause.add_theme_stylebox_override("hover", CrownSkin.plate(Atlas.RAISED))
	_pause.add_theme_stylebox_override("pressed", CrownSkin.plate(CrownSkin.CLOTH))
	_pause.focus_mode = Control.FOCUS_NONE
	_pause.pressed.connect(func() -> void: SimLoop.set_paused(true))
	add_child(_pause)
	fit()


func fit() -> void:
	var zoom := HudLayout.zoom(get_viewport())
	scale = Vector2.ONE * zoom
	size = Vector2(get_viewport_rect().size.x / zoom, HudLayout.HEADER_BOTTOM)
	_cards = HudLayout.header(size)
	for pair: Array in [[_coins, &"purse"], [_clock, &"clock"]]:
		var box: Rect2 = _cards[pair[1]]
		var label: Label = pair[0]
		label.position = box.position + TEXT_OFFSET
		label.size = box.size - TEXT_INSET
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_pause.position = Vector2(size.x - PAUSE_OFFSET.x, PAUSE_OFFSET.y)
	_pause.size = PAUSE_SIZE
	_pause.visible = not TouchControls.active
	_pause.tooltip_text = tr(&"HINT_PAUSE")
	queue_redraw()


func refresh() -> void:
	if SimLoop.state == null:
		return
	var purse := RealmReadout.purse()
	_coins.tooltip_text = tr(&"HUD_PURSE_TITLE")
	_coins.text = tr(&"HUD_PURSE_VALUE").format({"coins": purse.x, "capacity": purse.y})
	_clock.text = tr(&"HUD_TIME").format(
		{"day": SimLoop.state.day, "phase": HudText.phase(ClockService.clock.current_phase())}
	)
	_progress = ClockService.clock.phase_progress()
	fit()


func _draw() -> void:
	for key: StringName in [&"purse", &"clock"]:
		var box: Rect2 = _cards.get(key, Rect2())
		draw_style_box(CrownSkin.plate(), box)
		CrownIcons.draw(self, &"purse" if key == &"purse" else &"sun", box.position + ICON_OFFSET)
	var clock: Rect2 = _cards.get(&"clock", Rect2())
	var track := Rect2(clock.position + TRACK_OFFSET, Vector2(clock.size.x - TRACK_INSET, 2))
	draw_rect(track, CrownSkin.WOOD)
	track.size.x *= _progress
	draw_rect(track, HudStyle.GOLD)
