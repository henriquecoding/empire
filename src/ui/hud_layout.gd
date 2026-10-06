class_name HudLayout
extends RefCounted

const MARGIN := 16.0
const HEADER_BOTTOM := 68.0
const CONTEXT_TOP := 80.0
const GOAL_MIN_WIDTH := 760.0
const CONTEXT_WIDTH := 520.0
const PADDING := 12.0


static func header(area: Vector2) -> Dictionary:
	var goal := Rect2()
	if area.x >= GOAL_MIN_WIDTH:
		var width := minf(520, area.x - 492)
		goal = Rect2(area.x - 76 - width, 12, width, 56)
	return {
		&"purse": Rect2(16, 12, 132, 56),
		&"clock": Rect2(160, 12, 244, 56),
		&"goal": goal,
	}


static func context(area: Vector2, text_height: float) -> Rect2:
	var width := minf(CONTEXT_WIDTH, area.x - MARGIN * 2.0)
	return Rect2((area.x - width) * 0.5, CONTEXT_TOP, width, text_height + PADDING * 2.0)


static func scale_for(factor: float) -> float:
	return maxf(1.0, 1.0 / maxf(0.01, factor))
