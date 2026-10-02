# src/world/shape_art.gd — formas lisas escritas como dados e desenhadas por um so
# interprete (o pedido do dono de 30/09/2026; ADR 0038).
#
# As coisas das terras geradas — o poco, as tendas, o portao, a fortaleza — sao formas
# simples a espera de arte a serio (art/ nao se toca daqui). Escritas em codigo eram
# centenas de numeros soltos, e o portao G4 quer os numeros em constantes (§47): aqui
# cada coisa e uma lista de formas numa constante, e este ficheiro desenha-as todas.
#
# Cada forma e [tipo, cor, numeros...], em px a contar do pe da coisa:
#   RECT   x, y, largura, altura
#   POLY   x0, y0, x1, y1, ...
#   LINE   traco, x0, y0, x1, y1
#   CIRCLE x, y, raio
# A cor e uma Color, ou um inteiro: o indice numa paleta dada na hora (as cores do
# bioma ali, a bandeira do povo).
class_name ShapeArt
extends RefCounted

enum Forma { RECT, POLY, LINE, CIRCLE }

## Onde comecam os numeros de cada forma: depois do tipo e da cor.
const NUMEROS := 2
## Os campos de um RECT e de um CIRCLE, pela ordem em que se escrevem.
const X := 0
const Y := 1
const LARGO := 2
const ALTO := 3
const RAIO := 2


## Desenha `formas` com o pe em `pe`. `espelho` -1 vira-as da direita para a esquerda.
static func draw(
	canvas: CanvasItem, formas: Array, pe: Vector2, paleta: Array[Color] = [], espelho := 1.0
) -> void:
	for forma: Array in formas:
		var cor: Color = paleta[forma[1]] if forma[1] is int else forma[1]
		var n := PackedFloat32Array(forma.slice(NUMEROS))
		match int(forma[0]):
			Forma.RECT:
				var canto := pe + Vector2(n[X] * espelho, n[Y])
				canvas.draw_rect(Rect2(canto, Vector2(n[LARGO] * espelho, n[ALTO])).abs(), cor)
			Forma.POLY:
				canvas.draw_colored_polygon(_pontos(n, pe, espelho), cor)
			Forma.LINE:
				var p := _pontos(n.slice(1), pe, espelho)
				canvas.draw_line(p[0], p[1], cor, n[0])
			Forma.CIRCLE:
				canvas.draw_circle(pe + Vector2(n[X] * espelho, n[Y]), n[RAIO], cor)


static func _pontos(n: PackedFloat32Array, pe: Vector2, espelho: float) -> PackedVector2Array:
	var saida := PackedVector2Array()
	for i in range(0, n.size() - 1, 2):
		saida.append(pe + Vector2(n[i] * espelho, n[i + 1]))
	return saida
