class_name RoyalWheelArt
extends RefCounted

const RADIUS := 126.0
const INNER := 48.0
const STEPS := 8
const SECTOR_GAP := 0.035
const BORDER := 6
const ICON_RADIUS := 86
const ICON_SCALE := 3
const NUMBER_OFFSET := Vector2(-4, 28)
const FONT_SIZE := 14
const CENTER_SIZE := Vector2(72, 72)


static func draw(
	ci: CanvasItem, center: Vector2, selected: int, impulses: bool, count: int
) -> void:
	for i in count:
		var angle := i * TAU / count - PI / 2
		var polygon := PackedVector2Array()
		var half := PI / count - SECTOR_GAP
		for step in STEPS + 1:
			var a := angle - half + 2 * half * step / STEPS
			polygon.append((center + Vector2.from_angle(a) * RADIUS).snapped(Vector2(2, 2)))
		for step in range(STEPS, -1, -1):
			var a := angle - half + 2 * half * step / STEPS
			polygon.append((center + Vector2.from_angle(a) * INNER).snapped(Vector2(2, 2)))
		ci.draw_colored_polygon(polygon, CrownSkin.CLOTH if i == selected else Atlas.FIELD)
		ci.draw_polyline(polygon + PackedVector2Array([polygon[0]]), CrownSkin.WOOD, BORDER)
		ci.draw_polyline(
			polygon + PackedVector2Array([polygon[0]]),
			Atlas.COIN if i == selected else CrownSkin.EDGE,
			2
		)
		var at := center + Vector2.from_angle(angle) * ICON_RADIUS
		CrownIcons.draw(ci, &"crown" if impulses else RoyalCommands.FAMILIES[i], at, ICON_SCALE)
		if impulses:
			ci.draw_string(
				HudStyle.font(),
				at + NUMBER_OFFSET,
				str(i + 1),
				HORIZONTAL_ALIGNMENT_CENTER,
				-1,
				FONT_SIZE,
				Atlas.TEXT
			)
	ci.draw_style_box(
		CrownSkin.plate(CrownSkin.CLOTH), Rect2(center - CENTER_SIZE / 2, CENTER_SIZE)
	)
	CrownIcons.draw(ci, &"crown", center, ICON_SCALE)
