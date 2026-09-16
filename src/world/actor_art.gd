class_name ActorArt
extends RefCounted

const SKIN := Color(0.78, 0.55, 0.38)
const SKIN_LIGHT := Color(0.95, 0.72, 0.48)
const CLOTH := Color(0.20, 0.35, 0.48)
const CLOTH_LIGHT := Color(0.32, 0.54, 0.61)
const METAL := Color(0.68, 0.70, 0.72)
const INK := Color(0.08, 0.07, 0.08)
const EYE := Color(0.98, 0.88, 0.59)


static func draw_unit(
	canvas: CanvasItem, box: Rect2, data: UnitData, units, index: int, cor: Color, time: float
) -> void:
	if data == null:
		return
	var alive := units.alive(index)
	var scale := maxf(0.55, box.size.y / 48.0)
	var moving := not is_zero_approx(units.target_xs[index] - units.xs[index])
	var bob := sin(time * 5.0 + box.position.x * 0.025) * 0.9 if moving else 0.0
	var ground := box.end.y + 1.0
	var center_x := box.get_center().x
	var ink := cor.darkened(0.38)
	var cloth := cor.lerp(CLOTH, 0.38)
	var cloth_light := cor.lerp(CLOTH_LIGHT, 0.28)
	var skin := cor.lerp(SKIN, 0.32)

	canvas.draw_colored_polygon(
		PackedVector2Array([
			Vector2(center_x - box.size.x * 0.45, ground + 2.0),
			Vector2(center_x - box.size.x * 0.12, ground - 1.0),
			Vector2(center_x + box.size.x * 0.40, ground + 2.0),
		]),
		Color(0.03, 0.03, 0.04, 0.30)
	)
	if not alive:
		canvas.draw_line(
			Vector2(box.position.x, box.position.y + box.size.y * 0.48),
			Vector2(box.end.x, box.position.y + box.size.y * 0.48),
			ink, maxf(2.0, scale * 2.0)
		)
		return

	var leg_y := ground - box.size.y * 0.24 + bob
	var hip_y := ground - box.size.y * 0.39 + bob
	canvas.draw_line(
		Vector2(center_x - box.size.x * 0.16, hip_y),
		Vector2(center_x - box.size.x * 0.20, leg_y),
		ink, maxf(2.0, scale * 2.0)
	)
	canvas.draw_line(
		Vector2(center_x + box.size.x * 0.16, hip_y),
		Vector2(center_x + box.size.x * 0.20, leg_y),
		ink, maxf(2.0, scale * 2.0)
	)
	canvas.draw_line(
		Vector2(center_x - box.size.x * 0.20, leg_y),
		Vector2(center_x - box.size.x * 0.07, ground),
		SKIN, maxf(2.0, scale * 2.0)
	)
	canvas.draw_line(
		Vector2(center_x + box.size.x * 0.20, leg_y),
		Vector2(center_x + box.size.x * 0.34, ground),
		SKIN, maxf(2.0, scale * 2.0)
	)

	var torso := Rect2(
		center_x - box.size.x * 0.34,
		box.position.y + box.size.y * 0.36 + bob,
		box.size.x * 0.68,
		box.size.y * 0.37
	)
	canvas.draw_rect(torso, cloth)
	canvas.draw_rect(
		Rect2(torso.position.x, torso.position.y, torso.size.x, maxf(2.0, torso.size.y * 0.14)),
		cloth_light
	)
	canvas.draw_line(
		Vector2(torso.get_center().x, torso.position.y + 3.0),
		Vector2(torso.get_center().x, torso.end.y - 2.0),
		ink, maxf(1.0, scale)
	)

	var head := Vector2(center_x, box.position.y + box.size.y * 0.25 + bob)
	canvas.draw_circle(head, maxf(4.0, box.size.x * 0.30), skin)
	canvas.draw_rect(
		Rect2(head.x - box.size.x * 0.26, head.y + box.size.y * 0.07, box.size.x * 0.52, maxf(2.0, scale)),
		SKIN_LIGHT.lerp(cor, 0.35)
	)
	var facing := 1.0 if units.target_xs[index] >= units.xs[index] else -1.0
	var eye_x := head.x + facing * box.size.x * 0.13
	canvas.draw_rect(Rect2(eye_x - 1.5, head.y - 1.0, 3.0, 3.0), EYE)
	if units.states[index] == UnitFsm.State.FIGHT:
		canvas.draw_line(
			Vector2(head.x - box.size.x * 0.13, head.y + box.size.y * 0.16),
			Vector2(head.x + box.size.x * 0.13, head.y + box.size.y * 0.16),
			ink, maxf(1.0, scale)
		)
	else:
		canvas.draw_line(
			Vector2(head.x - box.size.x * 0.08, head.y + box.size.y * 0.14),
			Vector2(head.x + box.size.x * 0.08, head.y + box.size.y * 0.14),
			ink, maxf(1.0, scale)
		)

	_hat(canvas, head, box, units, index, cor, scale)
	_weapon(canvas, box, data, units, index, cor, scale)


static func draw_creature(
	canvas: CanvasItem, box: Rect2, forma: Silhouette.Form, cor: Color, time: float
) -> void:
	var scale := maxf(0.55, box.size.y / 42.0)
	var pulse := sin(time * 4.0 + box.position.x * 0.018) * 1.2
	var ink := cor.darkened(0.42)
	var eye := EYE.lerp(cor, 0.45)
	var center := box.get_center() + Vector2(0.0, pulse * 0.25)
	match forma:
		Silhouette.Form.ASA:
			canvas.draw_line(Vector2(box.position.x, center.y), Vector2(box.position.x - 24.0 * scale, box.position.y + 8.0), ink, 3.0)
			canvas.draw_line(Vector2(box.end.x, center.y), Vector2(box.end.x + 24.0 * scale, box.position.y + 8.0), ink, 3.0)
			canvas.draw_circle(center + Vector2(-box.size.x * 0.18, 0.0), 3.0 * scale, eye)
			canvas.draw_circle(center + Vector2(box.size.x * 0.18, 0.0), 3.0 * scale, eye)
		Silhouette.Form.RASTEJO:
			for i in 3:
				var x := box.position.x + box.size.x * (0.18 + float(i) * 0.30)
				canvas.draw_line(Vector2(x, box.end.y - 3.0), Vector2(x - 4.0, box.end.y + 5.0), ink, 2.0)
			canvas.draw_circle(Vector2(center.x + box.size.x * 0.27, center.y), 3.0 * scale, eye)
		Silhouette.Form.ARIETE:
			canvas.draw_line(
				Vector2(box.position.x, center.y),
				Vector2(box.end.x, center.y),
				ink, maxf(2.0, scale * 2.0)
			)
			canvas.draw_circle(Vector2(box.position.x + box.size.x * 0.18, center.y - 3.0), 3.0 * scale, eye)
		_:
			canvas.draw_circle(center + Vector2(-box.size.x * 0.17, -box.size.y * 0.12), 4.0 * scale, eye)
			canvas.draw_circle(center + Vector2(box.size.x * 0.17, -box.size.y * 0.12), 4.0 * scale, eye)
			canvas.draw_line(
				Vector2(box.position.x + box.size.x * 0.18, box.end.y),
				Vector2(box.position.x + box.size.x * 0.10, box.end.y + 6.0),
				ink, maxf(2.0, scale * 2.0)
			)
			canvas.draw_line(
				Vector2(box.end.x - box.size.x * 0.18, box.end.y),
				Vector2(box.end.x - box.size.x * 0.10, box.end.y + 6.0),
				ink, maxf(2.0, scale * 2.0)
			)


static func _hat(
	canvas: CanvasItem, head: Vector2, box: Rect2, units, index: int, cor: Color, scale: float
) -> void:
	var king := units.ids[index] == SimLoop.king_id
	var owned := units.owners[index] != RecruitSystem.SEM_DONO
	if king:
		canvas.draw_colored_polygon(
			PackedVector2Array([
				Vector2(head.x - box.size.x * 0.32, head.y - 4.0 * scale),
				Vector2(head.x - box.size.x * 0.12, head.y - 13.0 * scale),
				Vector2(head.x, head.y - 7.0 * scale),
				Vector2(head.x + box.size.x * 0.12, head.y - 13.0 * scale),
				Vector2(head.x + box.size.x * 0.32, head.y - 4.0 * scale),
			]),
			WorldPalette.REI
		)
	elif owned:
		canvas.draw_rect(
			Rect2(head.x - box.size.x * 0.34, head.y - 4.0 * scale, box.size.x * 0.68, 5.0 * scale),
			WorldPalette.CHAPEU
		)


static func _weapon(
	canvas: CanvasItem, box: Rect2, data: UnitData, units, index: int, cor: Color, scale: float
) -> void:
	if not units.alive(index):
		return
	var mark := Silhouette.of_unit(data)
	var side := 1.0 if units.target_xs[index] >= units.xs[index] else -1.0
	var hand := Vector2(box.get_center().x + side * box.size.x * 0.26, box.position.y + box.size.y * 0.56)
	var tip := hand
	match mark:
		Silhouette.Mark.ARCO:
			canvas.draw_arc(hand + Vector2(side * 7.0, -4.0), 10.0 * scale, -1.1, 1.1, 8, cor, 2.0)
			canvas.draw_line(hand, hand + Vector2(side * 7.0, -4.0), cor, 1.0)
		Silhouette.Mark.HASTE:
			tip = hand + Vector2(side * 22.0, -18.0)
			canvas.draw_line(hand, tip, METAL.lerp(cor, 0.45), maxf(1.5, scale * 1.5))
		Silhouette.Mark.LAMINA:
			tip = hand + Vector2(side * 18.0, -13.0)
			canvas.draw_line(hand, tip, METAL.lerp(cor, 0.35), maxf(2.0, scale * 2.0))
		Silhouette.Mark.FERRAMENTA:
			tip = hand + Vector2(side * 15.0, -11.0)
			canvas.draw_line(hand, tip, WOOD_LIGHT.lerp(cor, 0.35), maxf(2.0, scale * 2.0))
			canvas.draw_line(tip + Vector2(-side * 5.0, -3.0), tip + Vector2(side * 5.0, 3.0), METAL, 2.0)
		Silhouette.Mark.MACA:
			canvas.draw_line(hand, hand + Vector2(side * 14.0, -11.0), WOOD, maxf(2.0, scale * 2.0))
			canvas.draw_circle(hand + Vector2(side * 16.0, -13.0), 4.0 * scale, WOOD_LIGHT.lerp(cor, 0.35))
		Silhouette.Mark.VIGA:
			canvas.draw_line(hand + Vector2(-side * 14.0, 0.0), hand + Vector2(side * 25.0, 0.0), WOOD_LIGHT.lerp(cor, 0.35), 5.0)
		_:
			return
