# src/world/build_view.gd — obras legiveis por forma, estado e detalhes.
class_name BuildView
extends RefCounted

## Uma ruina conserva apenas a base da forma original para continuar reconhecivel.
const RUINA := 0.30
const MEIA := 0.5


static func draw_on(
	canvas: CanvasItem, faixa: Band.Kind, edificios: Dictionary, luz: Lighting
) -> void:
	for vaga in SimLoop.builds.slots:
		if vaga.band != faixa:
			continue
		_obra(canvas, vaga, Silhouette.of_slot(vaga, edificios), luz, vaga.x)


static func _obra(
	canvas: CanvasItem, vaga: BuildSlot, forma: Silhouette.Form, luz: Lighting, x: float
) -> void:
	if vaga.standing():
		var caixa := _caixa(vaga, forma, vaga.level)
		_massa(canvas, forma, caixa, vaga, luz.body(WorldPalette.OBRA, x))
		Gauge.health(canvas, caixa, float(vaga.health) / maxf(1.0, float(vaga.max_health())))
		return
	if vaga.state == BuildSlot.State.RUIN:
		_ruina(canvas, vaga, forma, luz, x)
		return
	if vaga.state != BuildSlot.State.EMPTY:
		var proxima := _caixa(vaga, forma, vaga.level + 1)
		_massa(canvas, forma, proxima, vaga, luz.body(WorldPalette.ANDAIME, x))
		return
	_convite(canvas, vaga, forma, luz, x)


static func _convite(
	canvas: CanvasItem, vaga: BuildSlot, forma: Silhouette.Form, luz: Lighting, x: float
) -> void:
	var fantasma := _caixa(vaga, forma, maxi(1, vaga.costs.size()))
	var pontos := Outline.shape(forma, fantasma, _dentes(vaga))
	pontos.append(pontos[0])
	var cor := luz.body(WorldPalette.VAZIO, x)
	canvas.draw_polyline(pontos, cor, WorldPalette.CONTORNO)
	Gauge.paid(canvas, fantasma, vaga)


static func _ruina(
	canvas: CanvasItem, vaga: BuildSlot, forma: Silhouette.Form, luz: Lighting, x: float
) -> void:
	var inteira := _caixa(vaga, forma, maxi(1, vaga.level))
	var alto := inteira.size.y * RUINA
	var caixa := Rect2(
		Vector2(inteira.position.x, inteira.end.y - alto), Vector2(inteira.size.x, alto)
	)
	_massa(canvas, forma, caixa, vaga, luz.body(WorldPalette.VAZIO, x))


static func _massa(
	canvas: CanvasItem, forma: Silhouette.Form, caixa: Rect2, vaga: BuildSlot, cor: Color
) -> void:
	canvas.draw_colored_polygon(Outline.shape(forma, caixa, _dentes(vaga)), cor)
	StructureArt.draw_on(canvas, forma, caixa, vaga, cor)


static func _caixa(vaga: BuildSlot, forma: Silhouette.Form, nivel: int) -> Rect2:
	var alto := Silhouette.height(forma, nivel)
	var chao := WorldPalette.ground_of(int(vaga.band))
	return Rect2(Vector2(vaga.x - vaga.width * MEIA, chao - alto), Vector2(vaga.width, alto))


static func _dentes(vaga: BuildSlot) -> int:
	if vaga.level > 0:
		return vaga.contact_slots()
	return vaga.contacts[0] if not vaga.contacts.is_empty() else 0
