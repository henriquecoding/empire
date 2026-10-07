class_name HudRibbon
extends Control

const FONTS := {"coins": 22, "purse": 13, "clock": 17, "secondary": 14}
const COINS := Rect2(49, 17, 92, 28)
const PURSE := Rect2(49, 43, 92, 20)
const CLOCK := Rect2(173, 19, 218, 24)
const SEASON := Rect2(173, 42, 218, 20)
const GOAL_INSET := Vector2(12, 4)
const COIN_ICON := Vector3(33, 39, 9)
const TRACK_INSET := Vector2(12, 53)

var _coins: Label
var _purse_title: Label
var _clock: Label
var _season: Label
var _goal: Label
var _cards := {}
var _progress := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_to_group(&"instrumentos")
	add_to_group(&"hud_header")
	_coins = HudStyle.label(self, FONTS.coins, HudStyle.GOLD)
	_purse_title = HudStyle.label(self, FONTS.purse, HudStyle.MUTED)
	_clock = HudStyle.label(self, FONTS.clock)
	_season = HudStyle.label(self, FONTS.secondary, HudStyle.MUTED)
	_goal = HudStyle.label(self, FONTS.secondary)
	_goal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_goal.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fit()


func fit() -> void:
	var zoom := HudLayout.zoom(get_viewport())
	scale = Vector2.ONE * zoom
	size = Vector2(get_viewport_rect().size.x / zoom, HudLayout.HEADER_BOTTOM)
	_cards = HudLayout.header(size)
	_coins.position = COINS.position
	_coins.size = COINS.size
	_purse_title.position = PURSE.position
	_purse_title.size = PURSE.size
	_clock.position = CLOCK.position
	_clock.size = CLOCK.size
	_season.position = SEASON.position
	_season.size = SEASON.size
	_goal.visible = (_cards[&"goal"] as Rect2).has_area()
	if _goal.visible:
		var box: Rect2 = _cards[&"goal"]
		_goal.position = box.position + GOAL_INSET
		_goal.size = box.size - GOAL_INSET * 2
		box.size.y = maxf(box.size.y, _goal.get_combined_minimum_size().y + GOAL_INSET.y * 2)
		_cards[&"goal"] = box
		size.y = box.end.y
	queue_redraw()


func refresh() -> void:
	if SimLoop.state == null:
		fit()
		return
	var purse := RealmReadout.purse()
	_coins.text = tr(&"HUD_PURSE_VALUE").format({"coins": purse.x, "capacity": purse.y})
	_purse_title.text = tr(&"HUD_PURSE_TITLE")
	_clock.text = tr(&"HUD_TIME").format(
		{"day": SimLoop.state.day, "phase": HudText.phase(ClockService.clock.current_phase())}
	)
	_season.text = SeasonText.of(SimLoop.field, SimLoop.state.day)
	var ammo := MonarchHud.arrows(Assume.driven()).trim_prefix(" · ")
	if TouchControls.active and not ammo.is_empty():
		_season.text = ammo
	_goal.text = GameplayGuide.goal()
	_progress = ClockService.clock.phase_progress()
	fit()
	queue_redraw()


func _draw() -> void:
	for key: StringName in _cards:
		var box: Rect2 = _cards[key]
		if box.has_area():
			draw_style_box(HudStyle.panel(), box)
	TouchArt.icon(self, &"moeda", Vector2(COIN_ICON.x, COIN_ICON.y), COIN_ICON.z, HudStyle.GOLD)
	var clock: Rect2 = _cards.get(&"clock", Rect2())
	var track := Rect2(clock.position + TRACK_INSET, Vector2(clock.size.x - TRACK_INSET.x * 2, 2))
	draw_rect(track, HudStyle.BORDER)
	track.size.x *= _progress
	draw_rect(track, HudStyle.GOLD)
