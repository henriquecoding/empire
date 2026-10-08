class_name TowerPreview
extends RefCounted

const LINE := Color(0.8, 0.9, 0.7, 0.75)
const FILL := Color(0.8, 0.9, 0.7, 0.15)
const RULER_Y := 8.0
const FILL_Y := 6.0
const FILL_H := 5.0
const CAP_Y := Vector2(3, 14)
const CAP_W := 2.0
const LABEL_Y := 30.0
const FONT_PX := 13
const SIDES := [-1.0, 1.0]


static func range_of(slot: BuildSlot) -> float:
	var archer := Registry.entry(&"units", &"archer") as UnitData
	return archer.range_px * (1.0 + float(SlotVariant.effects(slot).get(&"range_bonus", 0.0)))


static func draw(canvas: CanvasItem, band: int) -> void:
	if not InteractionFocus.still():
		return
	var units := SimLoop.units
	var r := units.index_of(SimLoop.king_id)
	if r < 0 or units.bands[r] != band:
		return
	for slot in SimLoop.builds.slots:
		if slot.band != band or slot.kind not in [&"archer_tower", &"high_tower"]:
			continue
		if not RealmGrowth.visible(SimLoop.builds, slot, SimLoop.state):
			continue
		if absf(units.xs[r] - slot.x) > SimFactory.curve().recruit_notice_px:
			continue
		var reach := range_of(slot)
		var ground := WorldPalette.ground_of(band)
		var color := LINE
		canvas.draw_rect(Rect2(slot.x - reach, ground + FILL_Y, reach * 2, FILL_H), FILL)
		canvas.draw_line(
			Vector2(slot.x - reach, ground + RULER_Y),
			Vector2(slot.x + reach, ground + RULER_Y),
			color,
			1.0
		)
		for side: float in SIDES:
			canvas.draw_line(
				Vector2(slot.x + side * reach, ground + CAP_Y.x),
				Vector2(slot.x + side * reach, ground + CAP_Y.y),
				color,
				CAP_W
			)
		var text := TranslationServer.translate(&"ARRIVAL_TOWER_RANGE").format(
			{"range": roundi(reach)}
		)
		canvas.draw_string(
			ThemeDB.fallback_font,
			Vector2(slot.x - reach, ground + LABEL_Y),
			text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			WorldText.px(canvas, FONT_PX),
			color
		)
