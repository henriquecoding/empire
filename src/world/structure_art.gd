class_name StructureArt
extends RefCounted

const STONE := Color(0.27, 0.28, 0.30)
const STONE_LIGHT := Color(0.52, 0.49, 0.40)
const WOOD := Color(0.43, 0.25, 0.13)
const WOOD_LIGHT := Color(0.68, 0.41, 0.19)
const LEAF := Color(0.18, 0.34, 0.22)
const BARK := Color(0.25, 0.14, 0.08)
const GOLD := Color(0.92, 0.59, 0.20)
const WINDOW := Color(0.98, 0.72, 0.30)


static func draw_on(
	canvas: CanvasItem, forma: Silhouette.Form, caixa: Rect2, vaga: BuildSlot, cor: Color
) -> void:
	if vaga.state == BuildSlot.State.EMPTY:
		return
	match forma:
		Silhouette.Form.COPA:
			_core(canvas, caixa, cor, vaga.level)
		Silhouette.Form.AMEIA:
			_wall(canvas, caixa, cor, vaga.level)
		Silhouette.Form.TORRE, Silhouette.Form.MASTRO:
			_tower(canvas, caixa, cor, forma == Silhouette.Form.MASTRO)
		_:
			_house(canvas, caixa, cor, forma)
	_outline(canvas, forma, caixa, vaga, cor)


static func _core(canvas: CanvasItem, box: Rect2, cor: Color, level: int) -> void:
	var center := box.get_center().x
	var trunk_w := maxf(22.0, box.size.x * 0.18)
	var trunk := Rect2(
		center - trunk_w * 0.5,
		box.position.y + box.size.y * 0.34,
		trunk_w,
		box.size.y * 0.66
	)
	var bark := _mix(BARK, cor, 0.40)
	canvas.draw_rect(trunk, bark)
	var root_left := Vector2(trunk.position.x, trunk.end.y - 2.0)
	var root_left_end := Vector2(trunk.position.x - 56.0, trunk.end.y + 4.0)
	var root_right := Vector2(trunk.end.x, trunk.end.y - 2.0)
	var root_right_end := Vector2(trunk.end.x + 56.0, trunk.end.y + 4.0)
	canvas.draw_line(root_left, root_left_end, bark, 6.0)
	canvas.draw_line(root_right, root_right_end, bark, 6.0)
	var leaf := _mix(LEAF, cor, 0.42)
	var crown_y := box.position.y + box.size.y * 0.28
	canvas.draw_circle(Vector2(center - box.size.x * 0.27, crown_y), box.size.x * 0.18, leaf)
	canvas.draw_circle(Vector2(center + box.size.x * 0.27, crown_y), box.size.x * 0.18, leaf)
	canvas.draw_circle(Vector2(center, box.position.y + box.size.y * 0.11), box.size.x * 0.23, leaf)
	for i in 3:
		var x := box.position.x + box.size.x * (0.31 + float(i) * 0.19)
		var window_box := Rect2(
			x,
			box.position.y + box.size.y * 0.40,
			box.size.x * 0.07,
			box.size.y * 0.10
		)
		canvas.draw_rect(window_box, _mix(WINDOW, cor, 0.25))
	canvas.draw_rect(Rect2(center - 15.0, box.end.y - 38.0, 30.0, 38.0), _mix(WOOD, cor, 0.35))
	var door_start := Vector2(center, box.end.y - 34.0)
	var door_end := Vector2(center, box.end.y)
	canvas.draw_line(door_start, door_end, _mix(GOLD, cor, 0.35), 3.0)
	if level > 1:
		var bridge_start := Vector2(
			box.position.x + 22.0,
			box.position.y + box.size.y * 0.53
		)
		var bridge_end := Vector2(
			box.end.x - 22.0,
			box.position.y + box.size.y * 0.53
		)
		canvas.draw_line(bridge_start, bridge_end, _mix(WOOD_LIGHT, cor, 0.38), 5.0)


static func _wall(canvas: CanvasItem, box: Rect2, cor: Color, level: int) -> void:
	var ink := _mix(STONE, cor, 0.42)
	var highlight := _mix(STONE_LIGHT, cor, 0.38)
	var rows := maxi(2, level + 1)
	for row in rows:
		var y := box.position.y + box.size.y * (0.20 + float(row) * 0.70 / float(rows))
		var row_start := Vector2(box.position.x, y)
		var row_end := Vector2(box.end.x, y)
		canvas.draw_line(row_start, row_end, highlight, 2.0)
		for col in 6:
			var x := box.position.x + float(col) * box.size.x / 5.0 + float(row % 2) * 8.0
			var seam_start := Vector2(x, y - box.size.y * 0.10)
			var seam_end := Vector2(x, y + box.size.y * 0.08)
			canvas.draw_line(seam_start, seam_end, ink, 2.0)
	for col in 6:
		var x := box.position.x + float(col) * box.size.x / 5.0
		var merlon := Rect2(x - 4.0, box.position.y - 5.0, 8.0, 5.0)
		canvas.draw_rect(merlon, ink)
	var ledge_y := box.position.y + box.size.y * 0.20
	canvas.draw_line(
		Vector2(box.position.x, ledge_y),
		Vector2(box.end.x, ledge_y),
		_mix(GOLD, cor, 0.45),
		2.0
	)


static func _tower(canvas: CanvasItem, box: Rect2, cor: Color, high: bool) -> void:
	var ink := _mix(STONE, cor, 0.42)
	var platform := Rect2(
		box.position.x - 4.0,
		box.position.y + box.size.y * 0.18,
		box.size.x + 8.0,
		box.size.y * 0.12
	)
	canvas.draw_rect(platform, _mix(STONE_LIGHT, cor, 0.38))
	for i in 5:
		var x := platform.position.x + float(i) * platform.size.x / 4.0
		var merlon := Rect2(x - 3.0, platform.position.y - 8.0, 6.0, 8.0)
		canvas.draw_rect(merlon, ink)
	for i in 3:
		var y := box.position.y + box.size.y * (0.38 + float(i) * 0.18)
		var window_box := Rect2(box.get_center().x - 5.0, y, 10.0, 18.0)
		canvas.draw_rect(window_box, _mix(WINDOW, cor, 0.35))
	var base_start := Vector2(box.position.x + 4.0, box.end.y - 3.0)
	var base_end := Vector2(box.end.x - 4.0, box.end.y - 3.0)
	canvas.draw_line(base_start, base_end, ink, 4.0)
	if high:
		var mast_x := box.get_center().x
		var mast_start := Vector2(mast_x, box.position.y)
		var mast_end := Vector2(mast_x, box.position.y - 34.0)
		canvas.draw_line(mast_start, mast_end, ink, 3.0)
		var pennant_start := Vector2(mast_x, box.position.y - 32.0)
		var pennant_end := Vector2(mast_x + 27.0, box.position.y - 24.0)
		canvas.draw_line(
			pennant_start,
			pennant_end,
			_mix(GOLD, cor, 0.30),
			4.0
		)


static func _house(
	canvas: CanvasItem, box: Rect2, cor: Color, forma: Silhouette.Form
) -> void:
	var body := Rect2(
		box.position.x + box.size.x * 0.10,
		box.position.y + box.size.y * 0.38,
		box.size.x * 0.80,
		box.size.y * 0.62
	)
	var roof := _mix(STONE, cor, 0.40)
	canvas.draw_rect(body, _mix(WOOD, cor, 0.42))
	var roof_left := Vector2(box.position.x, body.position.y)
	var roof_peak := box.get_center()
	var roof_right := Vector2(box.end.x, body.position.y)
	canvas.draw_line(roof_left, roof_peak, roof, 5.0)
	canvas.draw_line(roof_peak, roof_right, roof, 5.0)
	for i in 2:
		var x := body.position.x + body.size.x * (0.18 + float(i) * 0.48)
		var window_box := Rect2(
			x,
			body.position.y + body.size.y * 0.25,
			body.size.x * 0.18,
			body.size.y * 0.18
		)
		canvas.draw_rect(window_box, _mix(WINDOW, cor, 0.34))
	var door := Rect2(
		body.get_center().x - body.size.x * 0.11,
		body.end.y - body.size.y * 0.42,
		body.size.x * 0.22,
		body.size.y * 0.42
	)
	canvas.draw_rect(door, _mix(BARK, cor, 0.42))
	if forma == Silhouette.Form.CHAMINE:
		var chimney := Rect2(
			box.position.x + box.size.x * 0.70,
			box.position.y,
			box.size.x * 0.13,
			box.size.y * 0.34
		)
		canvas.draw_rect(chimney, _mix(BARK, cor, 0.35))
	elif forma == Silhouette.Form.ESTANDARTE:
		var mast_x := box.position.x + box.size.x * 0.18
		var mast_start := Vector2(mast_x, box.position.y)
		var mast_end := Vector2(mast_x, body.end.y)
		canvas.draw_line(mast_start, mast_end, _mix(BARK, cor, 0.35), 3.0)
		var flag_start := Vector2(mast_x, box.position.y + 3.0)
		var flag_end := Vector2(
			mast_x + box.size.x * 0.28,
			box.position.y + box.size.y * 0.10
		)
		canvas.draw_line(flag_start, flag_end, _mix(GOLD, cor, 0.34), 4.0)
	elif forma == Silhouette.Form.ABOBADA:
		var arch_center := Vector2(body.get_center().x, body.end.y)
		var arch_radius := body.size.x * 0.25
		canvas.draw_arc(arch_center, arch_radius, PI, TAU, 12, _mix(GOLD, cor, 0.30), 3.0)


static func _outline(
	canvas: CanvasItem, forma: Silhouette.Form, box: Rect2, vaga: BuildSlot, cor: Color
) -> void:
	var pontos := Outline.shape(forma, box, _dentes(vaga))
	if pontos.size() < 2:
		return
	pontos.append(pontos[0])
	canvas.draw_polyline(pontos, _mix(WorldPalette.CONTORNO, cor, 0.20), WorldPalette.CONTORNO)


static func _dentes(vaga: BuildSlot) -> int:
	if vaga.level > 0:
		return vaga.contact_slots()
	return vaga.contacts[0] if not vaga.contacts.is_empty() else 0


static func _mix(base: Color, cor: Color, amount: float) -> Color:
	return base.lerp(cor, clampf(amount, 0.0, 1.0))