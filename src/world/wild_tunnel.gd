# src/world/wild_tunnel.gd — o subsolo das terras geradas: o tunel e a camara de cada
# masmorra (o pedido do dono de 30/09/2026; ADR 0038).
#
# A regiao tem por baixo a cave das raizes (RootCellars). Para la dela o subsolo segue
# num tunel velho de mina, da altura da cave e com o chao na linha onde se anda la em
# baixo (WorldPalette.ground_of), com escoras de madeira de tantos em tantos passos. A
# cave fecha num pilar e o tunel sai dele — antes, a cave era cortada a meio de uma
# abobada, e a terra do lado de la era outra coisa. Na masmorra do §21 (a ruina com
# passagem) o tunel abre-se numa camara abobadada, com a escada que desce do arco caido.
#
# Formas lisas escritas como dados (ShapeArt), em px a contar do chao do tunel.
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
## O tunel: o tecto, o chao (a linha do subsolo), quanto escurece a terra ao fundo, a
## grossura do piso e quanto escurece o caminho para o fazer.
const TUNEL := {"topo": 548.0, "chao": 620.0, "fundo": 0.55, "piso": 5.0, "pedra": 0.3}
## Uma escora de mina, com o pe no chao do tunel: tem os 72 px da altura dele.
const ESCORA := [
	[R, MADEIRA, -24, -72, 6, 72],
	[R, MADEIRA, 18, -72, 6, 72],
	[R, MADEIRA_ESCURA, -28, -72, 56, 7],
]
## As escoras, presas ao mundo e nao ao segmento: de quanto em quanto px, quanto cada
## uma foge desse passo, e a folga a volta de uma camara.
const ESCORAS := {"passo": 200.0, "fuga": 0.35, "camara": 110.0}
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
const SAL_ESCORAS := 79


## O subsolo de `span.x` a `span.y`, com as cores a passar de `esq` a `dir`; `boca` e o
## x da masmorra (NAN se o segmento nao tem nenhuma).
static func draw(
	canvas: CanvasItem,
	span: Vector2,
	esq: Array[Color],
	dir: Array[Color],
	semente: int,
	boca: float
) -> void:
	_estratos(canvas, span, esq, dir)
	var terra := WildGround.TERRA
	var fundo := [esq[terra].darkened(TUNEL.fundo), dir[terra].darkened(TUNEL.fundo)]
	var tecto := Vector2(TUNEL.topo, TUNEL.topo)
	WildGround.band(canvas, span, tecto, TUNEL.chao, fundo[0], fundo[1])
	var caminho := WildGround.CAMINHO
	var piso := [esq[caminho].darkened(TUNEL.pedra), dir[caminho].darkened(TUNEL.pedra)]
	var topo_piso := TUNEL.chao - TUNEL.piso * MEIO
	var faixa := Vector2(topo_piso, topo_piso)
	WildGround.band(canvas, span, faixa, topo_piso + TUNEL.piso, piso[0], piso[1])
	_escoras(canvas, span, boca)
	_raizes(canvas, span, esq, dir, semente)
	if not is_nan(boca):
		ShapeArt.draw(canvas, CAMARA, Vector2(boca, TUNEL.chao))


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


## As escoras no sitio que o mundo lhes da, fora da camara da masmorra.
static func _escoras(canvas: CanvasItem, span: Vector2, boca: float) -> void:
	var passo: float = ESCORAS.passo
	for n in range(floori(span.x / passo) - 1, ceili(span.y / passo) + 1):
		var u := RngService.scatter(hash([SAL_ESCORAS, n]), 1)[0]
		var sx := (float(n) + (u - MEIO) * ESCORAS.fuga) * passo
		var longe := is_nan(boca) or absf(sx - boca) > ESCORAS.camara
		if sx >= span.x and sx < span.y and longe:
			ShapeArt.draw(canvas, ESCORA, Vector2(sx, TUNEL.chao))


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
