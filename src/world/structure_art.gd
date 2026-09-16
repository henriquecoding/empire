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
	var trunk_w := maxf(22.0, box.size.x * 0.18)
	var trunk := Rect2(box.get_center().x - trunk_w * 0.5, box.position.y + box.size.y * 0.34, trunk_w, box.size.y * 0.66)
	canvas.draw_rect(trunk, _mix(BARK, cor, 0.40))
	canvas.draw_colored_polygon(
		PackedVector2Array([
			Vector2(trunk.position.x, trunk.end.y),
			Vector2(trunk.position.x - 42.0, trunk.end.y + 4.0),
			Vector2(trunk.position.x - 68.0, trunk.end.y),
			Vector2(trunk.position.x - 30.0, trunk.end.y - 15.0),
			Vector2(trunk.position.x, trunk.end.y - 6.0),
			Vector2(trunk.end.x + 30.0, trunk.end.y - 15.0),
			Vector2(trunk.end.x + 68.0, trunk.end.y),
			Vector2(trunk.end.x + 42.0, trunk.end.y + 4.0),
		]),
		_mix(BARK, cor, 0.40)
	)
	var crown_y := box.position.y + box.size.y * 0.28
	canvas.draw_circle(Vector2(box.get_center().x - box.size.x * 0.27, crown_y), box.size.x * 0.18, _mix(LEAF, cor, 0.42))
	canvas.draw_circle(Vector2(box.get_center().x + box.size.x * 0.27, crown_y), box.size.x * 0.18, _mix(LEAF, cor, 0.42))
	canvas.draw_circle(Vector2(box.get_center().x, box.position.y + box.size.y * 0.11), box.size.x * 0.23, _mix(LEAF, cor, 0.42))
	for i in 3:
		var x := box.position.x + box.size.x * (0.31 + float(i) * 0.19)
		canvas.draw_rect(
			Rect2(x, box.position.y + box.size.y * 0.40, box.size.x * 0.07, box.size.y * 0.10),
			_mix(WINDOW, cor, 0.25)
		)
	canvas.draw_rect(
		Rect2(box.get_center().x - 15.0, box.end.y - 38.0, 30.0, 38.0),
		_mix(WOOD, cor, 0.35)
	)
	canvas.draw_line(
		Vector2(box.get_center().x, box.end.y - 34.0),
		Vector2(box.get_center().x, box.end.y),
		_mix(GOLD, cor, 0.35), 3.0
	)
	if level > 1:
		canvas.draw_line(
			Vector2(box.position.x + 22.0, box.position.y + box.size.y * 0.53),
			Vector2(box.end.x - 22.0, box.position.y + box.size.y * 0.53),
			_mix(WOOD_LIGHT, cor, 0.38), 5.0
		)


static func _wall(canvas: CanvasItem, box: Rect2, cor: Color, level: int) -> void:
	var ink := _mix(STONE, cor, 0.42)
	var highlight := _mix(STONE_LIGHT, cor, 0.38)
	var rows := maxi(2, level + 1)
	for row in rows:
		var y := box.position.y + box.size.y * (0.20 + float(row) * 0.70 / float(rows))
		canvas.draw_line(Vector2(box.position.x, y), Vector2(box.end.x, y), highlight, 2.0)
		for col in 7:
			var x := box.position.x + box.size.x * (float(col) + float(row % 2) * 0.5) / 7.0
			canvas.draw_line(
				Vector2(x, y - box.size.y * 0.10),
				Vector2(x, y + box.size.y * 0.08),
				ink, 2.0
			)
	canvas.draw_line(
		Vector2(box.position.x, box.position.y + box.size.y * 0.20),
		Vector2(box.end.x, box.position.y + box.size.y * 0.20),
		_mix(GOLD, cor, 0.45), 2.0
	)


static func _tower(canvas: CanvasItem, box: Rect2, cor: Color, high: bool) -> void:
	var ink := _mix(STONE, cor, 0.42)
	var highlight := _mix(STONE_LIGHT, cor, 0.38)
	var platform := Rect2(box.position.x - 4.0, box.position.y + box.size.y * 0.18, box.size.x + 8.0, box.size.y * 0.12)
	canvas.draw_rect(platform, highlight)
	for i in 5:
		var x := platform.position.x + float(i) * platform.size.x / 4.0
		canvas.draw_rect(Rect2(x - 3.0, platform.position.y - 8.0, 6.0, 8.0), ink)
	for i in 3:
		var y := box.position.y + box.size.y * (0.38 + float(i) * 0.18)
		canvas.draw_rect(Rect2(box.get_center().x - 5.0, y, 10.0, 18.0), _mix(WINDOW, cor, 0.35))
	canvas.draw_line(
		Vector2(box.position.x + 4.0, box.end.y - 3.0),
		Vector2(box.end.x - 4.0, box.end.y - 3.0),
		ink, 4.0
	)
	if high:
		var mast_x := box.get_center().x
		canvas.draw_line(Vector2(mast_x, box.position.y), Vector2(mast_x, box.position.y - 34.0), ink, 3.0)
		canvas.draw_colored_polygon(
			PackedVector2Array([
				Vector2(mast_x, box.position.y - 32.0),
				Vector2(mast_x + 27.0, box.position.y - 24.0),
				Vector2(mast_x, box.position.y - 15.0),
			]),
			_mix(GOLD, cor, 0.30)
		)


static func _house(canvas: CanvasItem, box: Rect2, cor: Color, forma: Silhouette.Form) -> void:
	var body := Rect2(box.position.x + box.size.x * 0.10, box.position.y + box.size.y * 0.38, box.size.x * 0.80, box.size.y * 0.62)
	var wood := _mix(WOOD, cor, 0.42)
	canvas.draw_rect(body, wood)
	var roof := _mix(STONE, cor, 0.40)
	canvas.draw_colored_polygon(
		PackedVector2Array([
			Vector2(box.position.x, body.position.y),
			Vector2(box.get_center().x, box.position.y + box.size.y * 0.08),
			Vector2(box.end.x, body.position.y),
		]),
		roof
	)
	for i in 2:
		canvas.draw_rect(
			Rect2(body.position.x + body.size.x * (0.18 + float(i) * 0.48), body.position.y + body.size.y * 0.25, body.size.x * 0.18, body.size.y * 0.18),
			_mix(WINDOW, cor, 0.34)
		)
	canvas.draw_rect(
		Rect2(body.get_center().x - body.size.x * 0.11, body.end.y - body.size.y * 0.42, body.size.x * 0.22, body.size.y * 0.42),
		_mix(BARK, cor, 0.42)
	)
	if forma == Silhouette.Form.CHAMINE:
		canvas.draw_rect(
			Rect2(box.position.x + box.size.x * 0.70, box.position.y, box.size.x * 0.13, box.size.y * 0.34),
			_mix(BARK, cor, 0.35)
		)
		canvas.draw_circle(
			Vector2(box.position.x + box.size.x * 0.765, box.position.y - 4.0), 6.0,
			_mix(WINDOW, cor, 0.25)
		)
	elif forma == Silhouette.Form.ESTANDARTE:
		var mast_x := box.position.x + box.size.x * 0.18
		canvas.draw_line(Vector2(mast_x, box.position.y), Vector2(mast_x, body.end.y), _mix(BARK, cor, 0.35), 3.0)
		canvas.draw_colored_polygon(
			PackedVector2Array([
				Vector2(mast_x, box.position.y + 3.0),
				Vector2(mast_x + box.size.x * 0.28, box.position.y + box.size.y * 0.10),
				Vector2(mast_x, box.position.y + box.size.y * 0.20),
			]),
			_mix(GOLD, cor, 0.34)
		)
	elif forma == Silhouette.Form.ABOBADA:
		canvas.draw_arc(
			Vector2(body.get_center().x, body.end.y),
			body.size.x * 0.25, PI, TAU, 12, _mix(GOLD, cor, 0.30), 3.0
		)


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
