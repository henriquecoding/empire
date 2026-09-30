# src/world/mount_view.gd — o cavalo de tracao (Q-169). Uma forma lisa, a espera de arte
# (art/ nao se toca daqui): o corpo, o pescoco e a cabeca, quatro patas, a cauda e os
# alforges. Desenha-se por tras de quem o monta — o corpo do cavaleiro vem por cima — ou
# parado no estabulo, a espera de quem o venha buscar.
class_name MountView
extends RefCounted

const PELO := Color("7a5236")
const CRINA := Color("3b2618")
const COURO := Color("a0703c")
const CORPO := Rect2(-22, -30, 44, 15)
const PESCOCO := [Vector2(14, -28), Vector2(24, -44), Vector2(31, -41), Vector2(22, -24)]
const CABECA := [Vector2(24, -44), Vector2(36, -38), Vector2(35, -34), Vector2(26, -37)]
const CAUDA := [Vector2(-22, -29), Vector2(-30, -16), Vector2(-26, -15), Vector2(-21, -24)]
const PATAS := [-19.0, -12.0, 11.0, 18.0]
const PATA := Vector2(4, 16)
const ALFORGE := Rect2(-12, -24, 11, 9)
const PASSO := 2.0  # o baloico das patas, a andar
const DIREITA := 1.0


static func draw_on(canvas: CanvasItem, faixa: Band.Kind, luz: Lighting, tempo: float) -> void:
	var cavalo: Mount = SimLoop.field.mount if SimLoop.field != null else null
	if cavalo == null or cavalo.owned == &"" or faixa != Band.Kind.SURFACE:
		return
	var onde := _onde(cavalo)
	if is_nan(onde.x):
		return
	var pe := Vector2(onde.x, WorldPalette.ground_of(int(faixa)))
	canvas.draw_set_transform(pe, 0.0, Vector2(onde.y, 1.0))
	var anda := 0.0 if cavalo.rider == Mount.NENHUM else sin(tempo * TAU * PASSO)
	for k in PATAS.size():
		var lado := anda if k % 2 == 0 else -anda
		var pata := Rect2(Vector2(PATAS[k] + lado, -PATA.y), PATA)
		canvas.draw_rect(pata, luz.body(CRINA, onde.x))
	canvas.draw_rect(CORPO, luz.body(PELO, onde.x))
	canvas.draw_colored_polygon(PackedVector2Array(PESCOCO), luz.body(PELO, onde.x))
	canvas.draw_colored_polygon(PackedVector2Array(CABECA), luz.body(PELO, onde.x))
	canvas.draw_colored_polygon(PackedVector2Array(CAUDA), luz.body(CRINA, onde.x))
	canvas.draw_rect(ALFORGE, luz.body(COURO, onde.x))
	canvas.draw_set_transform(Vector2.ZERO)


## Onde esta, e para que lado olha: debaixo de quem o monta, ou no estabulo.
static func _onde(cavalo: Mount) -> Vector2:
	var i := SimLoop.units.index_of(cavalo.rider)
	if i != UnitSystem.NENHUM:
		var frente := SimLoop.units.target_xs[i] - SimLoop.units.xs[i]
		return Vector2(SimLoop.units.xs[i], -DIREITA if frente < 0.0 else DIREITA)
	for vaga in SimLoop.builds.standing():
		if vaga.kind == Stables.ESTABULO:
			return Vector2(vaga.x, DIREITA)
	return Vector2(NAN, DIREITA)
