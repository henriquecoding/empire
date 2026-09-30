# src/world/crown_view.gd — a coroa no chao, ao pe do rei caido (Q-167). Uma forma lisa,
# a espera de arte (art/ nao se toca daqui): o aro, as tres pontas e as pedras, a brilhar
# devagar para se ver de longe que esta ali a espera de alguem.
class_name CrownView
extends RefCounted

const OURO := Color("d9a53a")
const OURO_ESCURO := Color("9c6f22")
const PEDRA := Color("8e3b2e")
const ARO := Rect2(-9, -5, 18, 5)
const PONTAS := [
	[Vector2(-9, -5), Vector2(-7, -12), Vector2(-4, -5)],
	[Vector2(-3, -5), Vector2(0, -14), Vector2(3, -5)],
	[Vector2(4, -5), Vector2(7, -12), Vector2(9, -5)],
]
const PEDRAS := [Vector2(-5, -3), Vector2(0, -3), Vector2(5, -3)]
const PEDRA_LADO := Vector2(2, 2)
const BRILHO := 3.0
const TOM := 0.15


static func draw_on(canvas: CanvasItem, faixa: Band.Kind, luz: Lighting, tempo: float) -> void:
	var coroa: CrownDrop = SimLoop.field.crown_drop if SimLoop.field != null else null
	if coroa == null or not coroa.down or coroa.band != int(faixa):
		return
	var pe := Vector2(coroa.x, WorldPalette.ground_of(int(faixa)))
	var vivo := 1.0 + sin(tempo * BRILHO) * TOM
	canvas.draw_set_transform(pe)
	canvas.draw_rect(ARO, luz.body(OURO_ESCURO, coroa.x))
	for ponta: Array in PONTAS:
		canvas.draw_colored_polygon(PackedVector2Array(ponta), luz.body(OURO * vivo, coroa.x))
	for pedra: Vector2 in PEDRAS:
		canvas.draw_rect(Rect2(pedra, PEDRA_LADO), luz.body(PEDRA, coroa.x))
	canvas.draw_set_transform(Vector2.ZERO)
