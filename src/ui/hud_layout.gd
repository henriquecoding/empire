class_name HudLayout
extends RefCounted

const MARGIN := 16.0
const HEADER_BOTTOM := 68.0
const CONTEXT_TOP := 80.0
const GOAL_MIN_WIDTH := 760.0
const CONTEXT_WIDTH := 520.0
const PADDING := 12.0
const GAP := 8.0
const HALF := 0.5
const MIN_SCALE := 0.01
const COMBAT_MIN_WIDTH := 960.0
const COMBAT_GAP := 40.0
const PURSE := Rect2(16, 12, 132, 56)
const CLOCK := Rect2(160, 12, 244, 56)
const GOAL := {"max_width": 520.0, "reserved": 492.0, "right": 76.0, "top": 12.0, "height": 56.0}


static func header(area: Vector2) -> Dictionary:
	var goal := Rect2()
	if area.x >= GOAL_MIN_WIDTH:
		var width := minf(GOAL.max_width, area.x - GOAL.reserved)
		goal = Rect2(area.x - GOAL.right - width, GOAL.top, width, GOAL.height)
	return {
		&"purse": PURSE,
		&"clock": CLOCK,
		&"goal": goal,
	}


static func context(area: Vector2, text_height: float) -> Rect2:
	var width := minf(CONTEXT_WIDTH, area.x - MARGIN * 2)
	return Rect2((area.x - width) * HALF, CONTEXT_TOP, width, text_height + PADDING * 2)


static func scale_for(factor: float) -> float:
	return maxf(1.0, 1.0 / maxf(MIN_SCALE, factor))
