# src/world/wild_edge.gd — a borda do mundo (o pedido do dono de 30/09/2026: "coloque
# um limite saudavel de ate quanto pode se expandir e com algo ao fim como e em
# kingdom"; §21 Bordo; ADR 0038).
#
# §21: "uma regiao tem de terminar em alguma coisa: falesia, mar, muralha, desfiladeiro.
# Nunca em mais terreno igual que desaparece fora do ecra." O Kingdom acaba cada ilha
# na praia, com o cais; o Two Crowns tem o portal na face da falesia, na ponta da terra.
# Aqui o chao acaba na beira e, para la dela, fica o que o bioma do ultimo povo pede
# (biomes.csv, edge_subject): o mar ate ao horizonte, o desfiladeiro com a outra parede
# ao longe, a falesia sobre a nevoa, ou a muralha de rocha que nao se sobe.
#
# Formas lisas escritas como dados (ShapeArt), em px a contar da beira na linha do chao
# e viradas para fora: a oeste, espelhadas.
class_name WildEdge
extends RefCounted

const R := ShapeArt.Forma.RECT
const P := ShapeArt.Forma.POLY
const L := ShapeArt.Forma.LINE
const T := WildLands.Tinta

const MADEIRA := WildSubjects.MADEIRA
const ESPUMA := Color("c9d4cf")
const AREIA := Color("d2bf8e")
const NEVOA := Color(0.93, 0.84, 0.66, 0.45)
const VALE := Color("7a735a")
## O que se ve para la da beira, do horizonte ao fundo do ecra, nas tres alturas de
## ALTURAS. Em cima e o ceu junto ao horizonte (o do EnramadosLayer): a nevoa nao tem
## aresta.
const FUNDO := {
	&"sea": [Color("b9ae8e"), Color("5d7a80"), Color("2c3e45")],
	&"gorge": [Color("d2b37e"), Color("7d6a55"), Color("241d16")],
	&"cliff": [Color("d2b37e"), Color("a08a6c"), Color("5a4b3c")],
	&"wall": [Color("d2b37e"), Color("7d6a55"), Color("241d16")],
}
## O horizonte, o nivel do mar e o fundo do ecra.
const ALTURAS := [WildGround.TOPO_CAMPO, 542.0, Band.SCREEN_BOTTOM]
## O mar: a espuma (mais curta ao longe), a praia a descer para a agua, o fundo que desce
## debaixo dela e o cais do Kingdom — a unica coisa feita por gente no fim do mundo.
const MAR := [
	[L, ESPUMA, 1, 70, -84, 86, -84],
	[L, ESPUMA, 1, 200, -76, 220, -76],
	[L, ESPUMA, 1, 130, -52, 160, -52],
	[L, ESPUMA, 1, 270, -34, 306, -34],
	[L, ESPUMA, 1, 90, -10, 134, -10],
	[L, ESPUMA, 1, 220, 8, 270, 8],
	[P, AREIA, -24, -96, 18, -96, 64, 25, -24, 25],
	[P, T.TERRA_ESCURA, 0, 25, 64, 25, 170, 203, 0, 203],
	[R, MADEIRA, 20, 12, 170, 5],
	[L, MADEIRA, 3, 40, 17, 40, 50],
	[L, MADEIRA, 3, 90, 17, 90, 50],
	[L, MADEIRA, 3, 140, 17, 140, 50],
	[L, MADEIRA, 3, 186, 17, 186, 50],
]
## O desfiladeiro: a outra parede, ao longe, com a erva do outro lado por cima.
const DESFILADEIRO := [
	[P, T.ROCHA_ESCURA, 280, 203, 280, -47, 312, -77, 420, -66, 420, 203],
	[P, T.CAMPO, 280, -47, 312, -77, 420, -66, 420, -60, 312, -71, 280, -41],
	[L, T.ROCHA, 2, 300, -20, 340, -10],
	[L, T.ROCHA, 2, 330, 60, 380, 72],
	[L, NEVOA, 3, 16, -30, 170, -30],
	[L, NEVOA, 2, 90, 40, 250, 40],
	[L, NEVOA, 2, 30, 120, 190, 120],
]
## A falesia: la em baixo, na nevoa, um vale que nao e de ninguem.
const FALESIA_VALE := [
	[P, VALE, 0, 124, 70, 100, 150, 112, 230, 92, 330, 106, 420, 96, 420, 203, 0, 203],
	[L, NEVOA, 3, 20, 60, 190, 60],
	[L, NEVOA, 2, 120, 150, 300, 150],
]
## A muralha de rocha, que sobe para la do ceu que se ve.
const MURALHA := [
	[P, T.ROCHA_ESCURA, 0, 203, 0, -337, 40, -397, 420, -427, 420, 203],
	[L, T.ROCHA, 2, 8, -300, 60, -312],
	[L, T.ROCHA, 2, 20, -180, 90, -170],
	[L, T.ROCHA, 2, 6, -60, 70, -72],
]
## A face da falesia, da beira do campo ao fundo do ecra.
const FACE := [
	[P, T.ROCHA_ESCURA, -4, -96, 10, -66, 6, -30, 18, 6, 6, 42, -4, 42],
	[P, T.ROCHA_ESCURA, -4, 42, 6, 42, 18, 78, 6, 114, 18, 150, 6, 186, 18, 203, -4, 203],
]
const FORMAS := {&"sea": MAR, &"gorge": DESFILADEIRO, &"cliff": FALESIA_VALE, &"wall": MURALHA}
## As bordas que caem a pique: tem face na beira.
const A_PIQUE := [&"gorge", &"cliff"]
const FALESIA := &"cliff"


## O chao acaba na beira; para la dela, a nevoa (ou o mar) e o que o bioma pede.
static func draw(
	canvas: CanvasItem, registo: Dictionary, lado: int, x0: float, w: float, tinta: Array[Color]
) -> void:
	var dentro := WildSegments.BORDO_PX if lado == WorldPlan.LESTE else w - WildSegments.BORDO_PX
	var beira := x0 + dentro
	var fim := x0 + w if lado == WorldPlan.LESTE else x0
	var assunto: StringName = registo.get(WildSegments.ASSUNTO, &"")
	_fundo(canvas, beira, fim, FUNDO.get(assunto, FUNDO[FALESIA]))
	var pe := Vector2(beira, Band.GROUND_LINE)
	ShapeArt.draw(canvas, FORMAS.get(assunto, []), pe, tinta, float(lado))
	if A_PIQUE.has(assunto):
		ShapeArt.draw(canvas, FACE, pe, tinta, float(lado))


## A nevoa ou o mar, da beira ao fim do segmento, em faixas que passam de cor sem aresta.
static func _fundo(canvas: CanvasItem, beira: float, fim: float, cores: Array) -> void:
	var span := Vector2(minf(beira, fim), maxf(beira, fim))
	for i in ALTURAS.size() - 1:
		var pontos := PackedVector2Array(
			[
				Vector2(span.x, ALTURAS[i]),
				Vector2(span.y, ALTURAS[i]),
				Vector2(span.y, ALTURAS[i + 1]),
				Vector2(span.x, ALTURAS[i + 1]),
			]
		)
		var c0: Color = cores[i]
		var c1: Color = cores[i + 1]
		canvas.draw_polygon(pontos, PackedColorArray([c0, c0, c1, c1]))
