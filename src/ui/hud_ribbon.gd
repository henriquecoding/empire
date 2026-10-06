class_name HudRibbon
extends Control

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
	_coins = HudStyle.label(self, 22, HudStyle.GOLD)
	_purse_title = HudStyle.label(self, 13, HudStyle.MUTED)
	_clock = HudStyle.label(self, 17)
	_season = HudStyle.label(self, 14, HudStyle.MUTED)
	_goal = HudStyle.label(self, 14)
	_goal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_goal.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fit()


func fit() -> void:
	var factor := get_viewport().get_final_transform().get_scale().x
	var zoom := HudLayout.scale_for(factor)
	scale = Vector2.ONE * zoom
	size = Vector2(get_viewport_rect().size.x / zoom, HudLayout.HEADER_BOTTOM)
	_cards = HudLayout.header(size)
	_coins.position = Vector2(49, 17)
	_coins.size = Vector2(92, 28)
	_purse_title.position = Vector2(49, 43)
	_purse_title.size = Vector2(92, 20)
	_clock.position = Vector2(173, 19)
	_clock.size = Vector2(218, 24)
	_season.position = Vector2(173, 42)
	_season.size = Vector2(218, 20)
	_goal.visible = (_cards[&"goal"] as Rect2).has_area()
	if _goal.visible:
		var box: Rect2 = _cards[&"goal"]
		_goal.position = box.position + Vector2(12, 4)
		_goal.size = box.size - Vector2(24, 8)
		box.size.y = maxf(box.size.y, _goal.get_combined_minimum_size().y + 8)
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
	TouchArt.icon(self, &"moeda", Vector2(33, 39), 9, HudStyle.GOLD)
	var clock: Rect2 = _cards.get(&"clock", Rect2())
	var track := Rect2(clock.position + Vector2(12, 53), Vector2(clock.size.x - 24, 2))
	draw_rect(track, HudStyle.BORDER)
	track.size.x *= _progress
	draw_rect(track, HudStyle.GOLD)
