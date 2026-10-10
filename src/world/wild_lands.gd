# src/world/wild_lands.gd — o limiar e a terra de outro povo, com a fortaleza dele (o
# pedido do dono de 30/09/2026; §21 Limiar; ADR 0038).
#
# §21: "a fronteira entre povos nunca e um fade: e um portao, uma ponte, uma falha na
# rocha, uma muralha em ruinas." Cada limiar leva a bandeira do povo do lado de la, e a
# bandeira passa a tua quando o povo e teu vassalo (Q-103) — como a da fortaleza.
#
# Formas lisas escritas como dados (ShapeArt), a espera de arte (art/ nao se toca
# daqui). Em px a contar do pe; o limiar vira-se para o lado de fora, para a bandeira
# ficar sempre do lado de la. A ponte assenta na linha onde se anda, que e onde se passa.
class_name WildLands
extends RefCounted

## A paleta de cada coisa, dada na hora: as quatro cores do bioma ali (as do WildGround,
## pela mesma ordem), tres mais escuras e a bandeira do povo.
enum Tinta { CAMPO, CAMINHO, TERRA, ROCHA, CAMPO_ESCURO, TERRA_ESCURA, ROCHA_ESCURA, BANDEIRA }

const R := ShapeArt.Forma.RECT
const P := ShapeArt.Forma.POLY
const L := ShapeArt.Forma.LINE

const PE := WildSubjects.PE
const PEDRA := WildSubjects.PEDRA
const PEDRA_CLARA := WildSubjects.PEDRA_CLARA
const MADEIRA := WildSubjects.MADEIRA
const ESTACA := WildSubjects.MADEIRA_ESCURA
const ESCURO := WildSubjects.ESCURO
const VERGA := Color("563b25")
const TORRE := Color("999384")
const AGUA := Color("4f6a72")
const INIMIGO := Color("8e3b2e")
const TEU := Color("d9a53a")
const ESCURECE := {"campo": 0.25, "terra": 0.4, "rocha": 0.2}
const BANDEIRA := Tinta.BANDEIRA

## O portao numa palicada (§21: "um portao").
const PORTAO := [
	[P, ESTACA, -92, 0, -92, -40, -88, -46, -84, -40, -84, 0],
	[P, ESTACA, -82, 0, -82, -40, -78, -46, -74, -40, -74, 0],
	[P, ESTACA, -72, 0, -72, -40, -68, -46, -64, -40, -64, 0],
	[P, ESTACA, -62, 0, -62, -40, -58, -46, -54, -40, -54, 0],
	[P, ESTACA, -52, 0, -52, -40, -48, -46, -44, -40, -44, 0],
	[R, ESTACA, -92, -30, 48, 5],
	[P, ESTACA, 44, 0, 44, -40, 48, -46, 52, -40, 52, 0],
	[P, ESTACA, 54, 0, 54, -40, 58, -46, 62, -40, 62, 0],
	[P, ESTACA, 64, 0, 64, -40, 68, -46, 72, -40, 72, 0],
	[P, ESTACA, 74, 0, 74, -40, 78, -46, 82, -40, 82, 0],
	[P, ESTACA, 84, 0, 84, -40, 88, -46, 92, -40, 92, 0],
	[R, ESTACA, 44, -30, 48, 5],
	[R, MADEIRA, -42, -78, 10, 78],
	[R, MADEIRA, 32, -78, 10, 78],
	[R, VERGA, -48, -86, 96, 9],
	[L, MADEIRA, 2, 0, -86, 0, -112],
	[P, BANDEIRA, 1, -112, 22, -105, 1, -98],
]
## A ponte sobre a ribeira, com o tabuleiro na linha onde se anda (§21: "uma ponte").
const PONTE := [
	[R, Tinta.TERRA_ESCURA, -90, 21, 180, 28],
	[R, AGUA, -84, 37, 168, 8],
	[R, MADEIRA, -96, 15, 192, 6],
	[L, MADEIRA, 2, -90, 15, -90, -7],
	[L, MADEIRA, 2, -45, 15, -45, -7],
	[L, MADEIRA, 2, 0, 15, 0, -7],
	[L, MADEIRA, 2, 45, 15, 45, -7],
	[L, MADEIRA, 2, 90, 15, 90, -7],
	[L, MADEIRA, 2, -90, -5, 90, -5],
	[L, MADEIRA, 2, 104, 21, 104, -20],
	[P, BANDEIRA, 105, -20, 126, -13, 105, -6],
]
## Duas lajes de rocha e o caminho pelo meio (§21: "uma falha na rocha").
const FALHA := [
	[P, Tinta.ROCHA, -100, 0, -92, -96, -62, -128, -30, -92, -18, 0],
	[P, Tinta.ROCHA_ESCURA, 18, 0, 26, -104, 52, -138, 90, -112, 104, 0],
	[L, Tinta.ROCHA_ESCURA, 2, -62, -128, -52, -70],
	[L, Tinta.ROCHA_ESCURA, 2, -80, -60, -70, -20],
	[L, Tinta.ROCHA, 2, 52, -138, 62, -76],
	[R, PEDRA, 112, -10, 20, 10],
	[R, PEDRA_CLARA, 115, -18, 14, 8],
	[L, MADEIRA, 2, 122, -18, 122, -46],
	[P, BANDEIRA, 123, -46, 144, -39, 123, -32],
]
## Os panos que ficaram de pe de uma muralha antiga (§21: "uma muralha em ruinas").
const MURALHA := [
	[R, PEDRA, -70, -60, 30, 60],
	[R, PEDRA_CLARA, -70, -60, 30, 4],
	[R, PEDRA, -34, -38, 30, 38],
	[R, PEDRA_CLARA, -34, -38, 30, 4],
	[R, PEDRA, 2, -84, 30, 84],
	[R, PEDRA_CLARA, 2, -84, 30, 4],
	[R, PEDRA, 2, -92, 8, 8],
	[R, PEDRA, 22, -92, 8, 8],
	[R, PEDRA, 38, -24, 30, 24],
	[R, PEDRA_CLARA, 38, -24, 30, 4],
	[R, PEDRA, 74, -6, 12, 6],
	[R, PEDRA_CLARA, -86, -5, 10, 5],
	[L, MADEIRA, 2, 17, -92, 17, -118],
	[P, BANDEIRA, 18, -118, 39, -111, 18, -104],
]
## A seara e a cerca do casal.
const SEARA := [
	[R, Tinta.CAMPO_ESCURO, 10, -8, 8, 8],
	[R, Tinta.CAMPO_ESCURO, 24, -8, 8, 8],
	[R, Tinta.CAMPO_ESCURO, 38, -8, 8, 8],
	[R, Tinta.CAMPO_ESCURO, 52, -8, 8, 8],
	[R, Tinta.CAMPO_ESCURO, 66, -8, 8, 8],
	[R, Tinta.CAMPO_ESCURO, 80, -8, 8, 8],
	[L, MADEIRA, 2, 6, -12, 96, -12],
	[L, MADEIRA, 2, 6, -14, 6, 0],
	[L, MADEIRA, 2, 51, -14, 51, 0],
	[L, MADEIRA, 2, 96, -14, 96, 0],
]
## A fortaleza do povo, na ponta da terra dele (§21: "uma nas extremidades").
const FORTALEZA := [
	[R, PEDRA, -90, -40, 180, 40],
	[R, TORRE, -26, -96, 52, 96],
	[R, TORRE, -26, -104, 8, 8],
	[R, TORRE, -14, -104, 8, 8],
	[R, TORRE, -2, -104, 8, 8],
	[R, TORRE, 10, -104, 8, 8],
	[R, TORRE, 22, -104, 8, 8],
	[R, PEDRA, -90, -46, 12, 6],
	[R, PEDRA, -67, -46, 12, 6],
	[R, PEDRA, -44, -46, 12, 6],
	[R, PEDRA, -21, -46, 12, 6],
	[R, PEDRA, 2, -46, 12, 6],
	[R, PEDRA, 25, -46, 12, 6],
	[R, PEDRA, 48, -46, 12, 6],
	[R, PEDRA, 71, -46, 12, 6],
	[R, ESCURO, -5, -80, 3, 10],
	[R, ESCURO, 2, -80, 3, 10],
	[R, ESCURO, -10, -26, 20, 26],
	[L, MADEIRA, 2, 0, -104, 0, -130],
	[P, BANDEIRA, 1, -130, 22, -123, 1, -116],
]
## So a bandeira do limiar, para quando o marco e o da transicao pintada (ADR 0081).
const MASTRO := [
	[L, MADEIRA, 2, 0, 0, 0, -112],
	[P, BANDEIRA, 1, -112, 22, -105, 1, -98],
]
const FORMAS := {
	&"gate": PORTAO,
	&"bridge": PONTE,
	&"rock_fault": FALHA,
	&"ruined_wall": MURALHA,
	&"farmsteads": SEARA,
	&"enemy_keep": FORTALEZA,
}
## As casas de uma aldeia e a do casal: onde, de quanto em quanto e a que escala.
const CASAS := {"quantas": 3, "de": -90.0, "passo": 90.0, "escala": 1.1}
const CASAL := {"x": -40.0, "escala": 1.2}


static func draw(
	canvas: CanvasItem, registo: Dictionary, x: float, tinta: Array[Color], lado: int
) -> void:
	if not established(registo):
		return
	var assunto: StringName = registo.get(WildSegments.ASSUNTO, &"")
	var pe := Vector2(x, PE)
	match assunto:
		&"houses":
			for i in CASAS.quantas:
				var casa := pe + Vector2(CASAS.de + float(i) * CASAS.passo, 0.0)
				PropArt.house(canvas, casa, CASAS.escala, Color.WHITE)
		&"farmsteads":
			PropArt.house(canvas, pe + Vector2(CASAL.x, 0.0), CASAL.escala, Color.WHITE)
	var limiar := int(registo.get(WildSegments.ZONA, -1)) == WorldPlan.Zone.THRESHOLD
	ShapeArt.draw(canvas, FORMAS.get(assunto, []), pe, tinta, float(lado) if limiar else 1.0)


## A bandeira do povo do lado de la, virada para fora, sem o marco por baixo.
static func flag(canvas: CanvasItem, x: float, tinta: Array[Color], lado: int) -> void:
	ShapeArt.draw(canvas, MASTRO, Vector2(x, PE), tinta, float(lado))


## A paleta de uma coisa: as cores do bioma ali, as mais escuras e a bandeira do povo.
static func paint(cores: Array[Color], registo: Dictionary) -> Array[Color]:
	var tinta: Array[Color] = cores.duplicate()
	tinta.append(cores[Tinta.CAMPO].darkened(ESCURECE.campo))
	tinta.append(cores[Tinta.TERRA].darkened(ESCURECE.terra))
	tinta.append(cores[Tinta.ROCHA].darkened(ESCURECE.rocha))
	tinta.append(_cor_do_povo(registo))
	return tinta


## A cor da bandeira: a tua se o povo ja e teu vassalo, a dele se nao.
static func _cor_do_povo(registo: Dictionary) -> Color:
	var bioma := (
		Registry.entry(&"biomes", StringName(registo.get(WildSegments.PARA, &""))) as BiomeData
	)
	if bioma != null and SimLoop.field != null and SimLoop.field.realm.vassals.has(bioma.people):
		return TEU
	return INIMIGO


static func established(registo: Dictionary) -> bool:
	if SimLoop.field == null:
		return true
	var id := int(registo.get(WildSegments.POVO, -1))
	var record: Dictionary = SimLoop.field.settlements.records.get(id, {})
	if record.is_empty():
		return false
	for site in record[&"sites"]:
		var index := SimLoop.builds.index_of(site)
		if index >= 0 and SimLoop.builds.slots[index].standing():
			return true
	return false
