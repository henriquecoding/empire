# src/world/prop_art.gd — a arvore e a casa, as duas coisas que o cenario repete.
#
# Nao sao obras (§25): uma obra tem estado, nivel e vida, e quem a desenha e o
# BuildView. Isto e povoado — o que enche a faixa aerea e a superficie e diz,
# sem nada por cima, que aquele sitio e habitado.
#
# Vivem fora do TerrainArt pela razao de sempre: sao a unica parte do cenario
# que se desenha muitas vezes e em sitios diferentes, e um ficheiro onde se
# muda a casa sem se mexer na montanha e um ficheiro que se muda sem medo.
class_name PropArt
extends RefCounted

const LEAF := Color(0.20, 0.31, 0.23)
const TRUNK := Color(0.25, 0.16, 0.10)
const HOUSE := Color(0.28, 0.22, 0.20)
const ROOF := Color(0.16, 0.14, 0.17)
const WINDOW := Color(0.95, 0.66, 0.28)

## A arvore, em pixeis a partir do pe e a multiplicar pela escala: tronco fino e
## copa larga, que e a proporcao que a §11 lhe da.
const ARVORE := {"alto": 46.0, "tronco_x": 5.0, "tronco_w": 10.0, "ramo": 3.0}

## As tres copas, em triplos (x, fraccao da altura, raio).
const COPA := [-13.0, 0.72, 17.0, 13.0, 0.70, 18.0, 0.0, 0.98, 21.0]
const RAMO := {"de_x": -15.0, "de_y": 0.36, "ate_x": 17.0, "ate_y": 0.63}

## A casa: corpo, duas aguas, duas janelas e uma porta. "A silhueta do telhado
## nao muda nunca" (§22), e e por ela que uma casa se le a qualquer distancia.
const CASA := {"x": 25.0, "y": 24.0, "w": 50.0, "beiral": 32.0, "cume": 46.0, "traco": 5.0}
const JANELA := {"quantas": 2, "x": 13.0, "passo": 21.0, "y": 16.0, "w": 9.0, "h": 8.0}
const PORTA := {"x": 4.0, "y": 15.0, "w": 8.0}

## Cada coisa do povoado escreve-se em tres numeros — x, y e escala — e cada copa
## tambem: x, altura e raio.
const TRIPLO := 3


## Uma fila escrita em triplos: x em fraccao da largura, y em pixeis, e escala.
static func trees(canvas: CanvasItem, fila: Array, width: float, light: Color) -> void:
	for i in range(0, fila.size(), TRIPLO):
		var base := Vector2(width * float(fila[i]), float(fila[i + 1]))
		tree(canvas, base, float(fila[i + TRIPLO - 1]), light)


static func houses(canvas: CanvasItem, fila: Array, width: float, light: Color) -> void:
	for i in range(0, fila.size(), TRIPLO):
		var base := Vector2(width * float(fila[i]), float(fila[i + 1]))
		house(canvas, base, float(fila[i + TRIPLO - 1]), light)


static func tree(canvas: CanvasItem, base: Vector2, escala: float, light: Color) -> void:
	var folha := _paint(LEAF, light)
	var tronco := _paint(TRUNK, light)
	var h := ARVORE.alto * escala
	var pe := Vector2(base.x - ARVORE.tronco_x * escala, base.y - h)
	canvas.draw_rect(Rect2(pe, Vector2(ARVORE.tronco_w * escala, h)), tronco)
	for i in range(0, COPA.size(), TRIPLO):
		var meio := Vector2(float(COPA[i]) * escala, -h * float(COPA[i + 1]))
		canvas.draw_circle(base + meio, float(COPA[i + TRIPLO - 1]) * escala, folha)
	canvas.draw_line(
		base + Vector2(RAMO.de_x * escala, -h * RAMO.de_y),
		base + Vector2(RAMO.ate_x * escala, -h * RAMO.ate_y),
		tronco,
		ARVORE.ramo * escala
	)


static func house(canvas: CanvasItem, base: Vector2, escala: float, light: Color) -> void:
	var corpo := Rect2(
		base.x - CASA.x * escala, base.y - CASA.y * escala, CASA.w * escala, CASA.y * escala
	)
	canvas.draw_rect(corpo, _paint(HOUSE, light))
	var cume := Vector2(base.x, base.y - CASA.cume * escala)
	var telhado := _paint(ROOF, light)
	var beiral := CASA.beiral * escala
	canvas.draw_line(Vector2(base.x - beiral, corpo.position.y), cume, telhado, CASA.traco)
	canvas.draw_line(cume, Vector2(base.x + beiral, corpo.position.y), telhado, CASA.traco)
	for i in JANELA.quantas:
		var x := base.x - JANELA.x * escala + float(i) * JANELA.passo * escala
		var vao := Rect2(x, base.y - JANELA.y * escala, JANELA.w * escala, JANELA.h * escala)
		canvas.draw_rect(vao, _paint(WINDOW, light))
	var porta := Rect2(
		base.x - PORTA.x * escala, base.y - PORTA.y * escala, PORTA.w * escala, PORTA.y * escala
	)
	canvas.draw_rect(porta, _paint(TRUNK, light))


static func _paint(base: Color, light: Color) -> Color:
	return WorldPalette.tint(base, light)
