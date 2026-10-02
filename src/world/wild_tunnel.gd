# src/world/wild_tunnel.gd — o subsolo das terras geradas: terra maciça, e a camara de
# cada masmorra (o pedido do dono de 30/09/2026, ADR 0038; e o de 02/10/2026, ADR 0046).
#
# Ate 02/10 o subsolo seguia num tunel velho de mina por baixo de todas as terras. O
# dono: "o subsolo nao e infinito acompanhando o piso de cima, e sempre algo
# delimitado" (Q-186). Agora as terras tem por baixo terra, com as cores do sitio, as
# raizes que descem do chao e os estratos de rocha; a masmorra do §21 (a ruina com
# passagem) e um sitio que so se escava na primeira descida (UnderArt), e a CAMARA
# daqui e a sala de entrada dela, com a escada que desce do arco caido.
#
# Formas lisas escritas como dados (ShapeArt), em px a contar do chao do subsolo.
class_name WildTunnel
extends RefCounted

const R := ShapeArt.Forma.RECT
const P := ShapeArt.Forma.POLY
const L := ShapeArt.Forma.LINE

const MADEIRA := WildSubjects.MADEIRA
const MADEIRA_ESCURA := WildSubjects.MADEIRA_ESCURA
const PEDRA := WildSubjects.PEDRA
const PEDRA_ESCURA := WildSubjects.PEDRA_ESCURA
const SALA := Color("2a2520")
const LAJE := Color("6d6556")
const MEIO := 0.5
## A terra: o tecto do subsolo, o chao (a linha onde se anda la em baixo, e onde os
## estratos comecam), quanto escurece a terra do sitio, e a grossura da linha do chao.
const TUNEL := {"topo": 548.0, "chao": 620.0, "fundo": 0.2, "piso": 5.0}
## A camara da masmorra: a sala abobadada, as colunas, as lajes e a escada que desce do
## arco caido (103 px: da linha do chao ao chao do tunel).
const CAMARA := [
	[P, SALA, -88, 0, -88, -84, -60, -96, 0, -102, 60, -96, 88, -84, 88, 0],
	[L, PEDRA, 3, -88, -84, -60, -96],
	[L, PEDRA, 3, -60, -96, 0, -102],
	[L, PEDRA, 3, 0, -102, 60, -96],
	[L, PEDRA, 3, 60, -96, 88, -84],
	[R, PEDRA_ESCURA, -94, -86, 12, 86],
	[R, PEDRA_ESCURA, 82, -86, 12, 86],
	[R, PEDRA, -98, -92, 20, 6],
	[R, PEDRA, 78, -92, 20, 6],
	[R, LAJE, -88, -3, 176, 5],
	[L, MADEIRA, 2, -6, -103, -6, 0],
	[L, MADEIRA, 2, 6, -103, 6, 0],
	[L, MADEIRA, 2, -6, -93, 6, -93],
	[L, MADEIRA, 2, -6, -81, 6, -81],
	[L, MADEIRA, 2, -6, -69, 6, -69],
	[L, MADEIRA, 2, -6, -57, 6, -57],
	[L, MADEIRA, 2, -6, -45, 6, -45],
	[L, MADEIRA, 2, -6, -33, 6, -33],
	[L, MADEIRA, 2, -6, -21, 6, -21],
	[L, MADEIRA, 2, -6, -9, 6, -9],
]
## Os estratos debaixo do chao, como os da cave: quanto escurece a terra em cada um, a
## altura dos de cima (o ultimo vai ate ao fundo) e a onda.
const ESTRATOS := {"escuro": [0.2, 0.33, 0.45], "alto": [22.0, 30.0], "onda": 4.0}
## As raizes que descem do chao ate ao tecto do tunel.
const RAIZES := 5
const RAIZ := {"desvio": 12.0, "traco": 2.0}
const SAL := 71


## A terra de `span.x` a `span.y`, com as cores a passar de `esq` a `dir`.
static func draw(
	canvas: CanvasItem, span: Vector2, esq: Array[Color], dir: Array[Color], semente: int
) -> void:
	_estratos(canvas, span, esq, dir)
	var terra := WildGround.TERRA
	var cheia := [esq[terra].darkened(TUNEL.fundo), dir[terra].darkened(TUNEL.fundo)]
	var tecto := Vector2(TUNEL.topo, TUNEL.topo)
	var ate := TUNEL.chao + TUNEL.piso * MEIO
	WildGround.band(canvas, span, tecto, ate, cheia[0], cheia[1])
	_raizes(canvas, span, esq, dir, semente)


## A rocha de baixo, em estratos com onda: os da cave da regiao (RootCellars), nas cores
## do sitio e com a onda presa ao mundo, para nao mudarem de um lado para o outro do pilar.
static func _estratos(
	canvas: CanvasItem, span: Vector2, esq: Array[Color], dir: Array[Color]
) -> void:
	var y: float = TUNEL.chao + TUNEL.piso * MEIO
	var escuro: Array = ESTRATOS.escuro
	var altos: Array = ESTRATOS.alto
	var terra := WildGround.TERRA
	for i in escuro.size():
		var alto: float = altos[i] if i < altos.size() else Band.SCREEN_BOTTOM - y
		var c0 := esq[terra].darkened(escuro[i])
		var c1 := dir[terra].darkened(escuro[i])
		WildGround.band(canvas, span, Vector2(y, y), y + alto, c0, c1)
		var passo := WildGround.CELULA
		var onda := PackedVector2Array()
		var cores := PackedColorArray()
		for n in range(floori(span.x / passo), ceili(span.y / passo) + 1):
			var x := clampf(float(n) * passo, span.x, span.y)
			onda.append(Vector2(x, y + float(posmod(n, 2)) * ESTRATOS.onda))
			var rocha := WildGround.ROCHA
			cores.append(esq[rocha].lerp(dir[rocha], inverse_lerp(span.x, span.y, x)))
		canvas.draw_polyline_colors(onda, cores, 1.0)
		y += alto


static func _raizes(
	canvas: CanvasItem, span: Vector2, esq: Array[Color], dir: Array[Color], semente: int
) -> void:
	var linha := float(Band.GROUND_LINE)
	var d := RngService.scatter(hash([SAL, semente]), RAIZES)
	for i in RAIZES:
		var rx := lerpf(span.x, span.y, d[i])
		var cor := esq[WildGround.ROCHA].lerp(dir[WildGround.ROCHA], d[i])
		var ponta := Vector2(rx + RAIZ.desvio, lerpf(linha, TUNEL.topo, d[i]))
		canvas.draw_line(Vector2(rx, linha), ponta, cor, RAIZ.traco)
