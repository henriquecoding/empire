class_name RoyalStage
extends Control

const MINIMUM := Vector2(260, 250)
const FIT := Vector2(260, 105)
const GROUND_FRACTION := 0.8
const HALF := 0.5
const MIN_DURATION := 0.001
const LINE_ALPHA := 0.45
const EDGE := 20
const OFFSETS := [-45.0, 65.0]
const COMPOSITE_STEP := 0.08
const BOUNDARY_EPSILON := 0.00001
const PAIRS := [
	[&"royal_king", &"royal_squire"],
	[&"royal_nia", &"royal_bard"],
	[&"royal_archer", &"royal_quiver"],
	[&"royal_shadow", &"royal_dancer"]
]
const PRIMARY := {
	&"royal_king": &"attack",
	&"royal_squire": &"block",
	&"royal_nia": &"attack",
	&"royal_bard": &"play",
	&"royal_archer": &"shoot",
	&"royal_quiver": &"deliver",
	&"royal_shadow": &"heal_sequence",
	&"royal_dancer": &"dance"
}
var profile: StringName = &"royal_king"
var action: StringName = &"attack"
var elapsed := 0.0
var playing := true
var facing := 1.0
var _art := OriginalArt.new()
var _garden := RoyalGarden.new()


func _ready() -> void:
	custom_minimum_size = MINIMUM
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_garden.begin(true)


func _process(delta: float) -> void:
	if playing:
		var cycle_duration := maxf(duration(), MIN_DURATION)
		if elapsed + delta >= cycle_duration and action == &"heal_sequence":
			_garden.begin()
		elapsed = fposmod(elapsed + delta, cycle_duration)
	queue_redraw()


func restart() -> void:
	elapsed = 0.0
	_garden.begin()
	queue_redraw()


func duration() -> float:
	return (
		RoyalGarden.DURATION if action == &"heal_sequence" else _art.action_seconds(profile, action)
	)


func _draw() -> void:
	var pair: Array = []
	for candidates: Array in PAIRS:
		if profile in candidates:
			pair = candidates
	if pair.is_empty():
		return
	var zoom := maxf(1.0, floorf(minf(size.x / FIT.x, size.y / FIT.y)))
	var ground := floorf(size.y * GROUND_FRACTION)
	var center := floorf(size.x * HALF)
	var cycle_duration := maxf(duration(), MIN_DURATION)
	var t := fposmod(elapsed, cycle_duration) if playing else minf(elapsed, cycle_duration)
	var garden := profile == &"royal_shadow" and action == &"heal_sequence"
	var line := Color("75866b")
	line.a = LINE_ALPHA
	draw_line(Vector2(EDGE, ground), Vector2(size.x - EDGE, ground), line)
	for k in pair.size():
		var id: StringName = pair[k]
		var chosen := action if id == profile else &"idle"
		if garden and id == &"royal_dancer":
			chosen = &"dance"
		var foot := Vector2(center + float(OFFSETS[k]) * zoom, ground)
		var since := t
		if id == &"royal_shadow" and garden:
			var body := RoyalGarden.body(t)
			chosen = body.action
			since = body.elapsed
			_garden.draw_on(self, foot, t, false, zoom)
		var frame := _art.frame_at(
			id,
			since,
			chosen,
			chosen in [&"idle", &"walk", &"dance", &"heal", &"play", &"block_hold"]
		)
		RoyalArt.preview(self, id, frame, foot, zoom, facing)
		if id == &"royal_shadow" and garden:
			_garden.draw_on(self, foot, t, true, zoom)


func next_frame() -> void:
	playing = false
	if action == &"heal_sequence":
		elapsed = fposmod(elapsed + COMPOSITE_STEP, RoyalGarden.DURATION)
	else:
		var item := _art.entry(profile)
		var tag: Dictionary = item.tags[String(action)]
		var frame := _art.frame_at(profile, elapsed, action, false)
		elapsed = 0.0
		if frame < int(tag.to_frame):
			for k in range(int(tag.from_frame), frame + 1):
				elapsed += float(item.durations_ms[k]) / OriginalArt.MILLISECONDS
			elapsed += BOUNDARY_EPSILON
	queue_redraw()
