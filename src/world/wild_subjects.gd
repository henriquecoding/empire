# src/world/wild_subjects.gd — o assunto de cada segmento de trilho (o pedido do dono de
# 30/09/2026: "nesses caminhos se encontra acampamentos de mendigos, mercenarios,
# dungeons"; §21 regra 2: um segmento, uma coisa em que o olho pousa; ADR 0038).
#
# Formas lisas escritas como dados (ShapeArt), a espera de arte a serio (art/ nao se
# toca daqui): o poco, a carroca partida e a pedra de pe dos vazios, o gigante caido do
# bosque, o arco caido que e a boca da masmorra, as tendas dos mendigos e a tenda
# listada dos mercenarios. Em px a contar do pe do assunto.
class_name WildSubjects
extends RefCounted

const R := ShapeArt.Forma.RECT
const P := ShapeArt.Forma.POLY
const L := ShapeArt.Forma.LINE
const C := ShapeArt.Forma.CIRCLE

## O pe das coisas: logo atras da linha por onde se anda.
const PE := 496.0
const MADEIRA := Color("6b4a2e")
const MADEIRA_ESCURA := Color("3f2a1a")
const PEDRA := Color("8a8374")
const PEDRA_CLARA := Color("aaa393")
const PEDRA_ESCURA := Color("534f46")
const ESCURO := Color("1c1612")
const LONA := Color("9c8a6a")
const LONA_VELHA := Color("7d6e55")
const LONA_REMENDADA := Color("8e7c5e")
const LONA_SOMBRA := Color("75674f")
const VELHA_SOMBRA := Color("5e5240")
const REMENDADA_SOMBRA := Color("6a5d46")
const LISTA := Color("8e3b2e")
const FOGO := Color("e8a33c")
const BRASA := Color("f6d27a")
const CASCA := Color("4a3a28")
const CASCA_CLARA := Color("6e6153")
const CASCA_ESCURA := Color("34291c")

const POCO := [
	[R, PEDRA, -18, -14, 36, 14],
	[R, PEDRA_CLARA, -20, -17, 40, 4],
	[R, MADEIRA, -17, -42, 3, 26],
	[R, MADEIRA, 14, -42, 3, 26],
	[L, MADEIRA, 3, -20, -42, 20, -42],
	[L, MADEIRA_ESCURA, 1, 0, -42, 0, -26],
	[R, MADEIRA_ESCURA, -3, -27, 6, 5],
]
const CARROCA := [
	[P, MADEIRA, -30, -8, 18, -15, 20, -27, -28, -20],
	[C, MADEIRA_ESCURA, 10, -7, 8],
	[C, MADEIRA, 10, -7, 3],
	[R, MADEIRA_ESCURA, -44, -3, 16, 3],
	[L, MADEIRA, 3, 18, -15, 40, -4],
]
const MENIR := [
	[P, PEDRA, -9, 0, -11, -40, -3, -58, 8, -50, 10, 0],
	[R, PEDRA_CLARA, -5, -36, 4, 4],
	[R, PEDRA_CLARA, 2, -22, 3, 3],
]
const GIGANTE := [
	[R, CASCA, -70, -22, 120, 20],
	[R, CASCA_CLARA, -70, -22, 120, 3],
	[C, CASCA_ESCURA, 52, -14, 22],
	[L, CASCA_ESCURA, 3, 52, -14, 80, -33],
	[L, CASCA_ESCURA, 3, 52, -14, 86, -19],
	[L, CASCA_ESCURA, 3, 52, -14, 84, -4],
	[L, CASCA_ESCURA, 3, 52, -14, 77, 6],
	[L, CASCA, 3, -40, -22, -52, -40],
]
## O arco caido: a boca da masmorra, com a porta escura e os degraus a descer.
const ARCO := [
	[R, PEDRA, -42, -58, 14, 58],
	[R, PEDRA, 28, -36, 14, 36],
	[P, PEDRA_CLARA, -42, -58, -10, -70, 6, -66, -6, -58, -28, -50],
	[R, ESCURO, -12, -26, 24, 26],
	[L, PEDRA_ESCURA, 2, -10, -20, 10, -20],
	[L, PEDRA_ESCURA, 2, -10, -13, 10, -13],
	[L, PEDRA_ESCURA, 2, -10, -6, 10, -6],
	[R, PEDRA, 44, -6, 10, 6],
	[R, PEDRA_CLARA, -58, -5, 12, 5],
]
## Tres tendas remendadas a volta de uma fogueira: o acampamento dos mendigos (Q-110).
const TENDAS := [
	[P, LONA, -64, 0, -42, -30, -20, 0],
	[P, LONA_SOMBRA, -42, -30, -20, 0, -42, 0],
	[R, ESCURO, -45, -11, 6, 11],
	[P, LONA_VELHA, -4, 0, 16, -26, 36, 0],
	[P, VELHA_SOMBRA, 16, -26, 36, 0, 16, 0],
	[R, ESCURO, 13, -10, 6, 10],
	[P, LONA_REMENDADA, 50, 0, 68, -22, 86, 0],
	[P, REMENDADA_SOMBRA, 68, -22, 86, 0, 68, 0],
	[R, ESCURO, 65, -9, 6, 9],
	[R, MADEIRA_ESCURA, -16, -3, 12, 3],
	[P, FOGO, -15, -3, -10, -16, -5, -3],
	[P, BRASA, -12, -3, -10, -9, -8, -3],
]
## A tenda listada, as lancas encostadas e a bandeira: ali espera um mercenario.
const MERCENARIOS := [
	[P, LONA, -42, 0, -42, -24, -11, -42, 20, -24, 20, 0],
	[L, LISTA, 3, -34, 0, -30, -30],
	[L, LISTA, 3, -16, 0, -12, -30],
	[L, LISTA, 3, 2, 0, 6, -30],
	[R, ESCURO, -16, -16, 10, 16],
	[L, MADEIRA, 2, 36, 0, 36, -58],
	[P, LISTA, 37, -58, 58, -52, 37, -45],
	[L, MADEIRA_ESCURA, 1, 26, 0, 34, -34],
	[L, MADEIRA_ESCURA, 1, 31, 0, 39, -34],
	[L, MADEIRA_ESCURA, 1, 36, 0, 44, -34],
]
const ASSUNTOS := {
	&"well": POCO,
	&"broken_cart": CARROCA,
	&"standing_stone": MENIR,
	&"fallen_giant": GIGANTE,
	&"collapsed_arch": ARCO,
	&"vagrant_tents": TENDAS,
	&"mercenary_tents": MERCENARIOS,
}
## O bosque a volta do gigante caido: quantas arvores, a margem, a escala e o pe.
const BOSQUE := &"fallen_giant"
const ARVORES := {"quantas": 5, "margem": 24.0, "de": 1.1, "ate": 1.7, "pe": 494.0}
const SAL := 73


static func draw(canvas: CanvasItem, registo: Dictionary, x: float, x0: float, w: float) -> void:
	var assunto: StringName = registo.get(WildSegments.ASSUNTO, &"")
	if assunto == BOSQUE:
		_bosque(canvas, int(registo[WildSegments.SEMENTE]), x0, w)
	ShapeArt.draw(canvas, ASSUNTOS.get(assunto, []), Vector2(x, PE))


static func _bosque(canvas: CanvasItem, semente: int, x0: float, w: float) -> void:
	var d := RngService.scatter(hash([SAL, semente]), ARVORES.quantas * 2)
	for i in ARVORES.quantas:
		var tx := lerpf(x0 + ARVORES.margem, x0 + w - ARVORES.margem, d[i * 2])
		var escala := lerpf(ARVORES.de, ARVORES.ate, d[i * 2 + 1])
		PropArt.tree(canvas, Vector2(tx, ARVORES.pe), escala, Color.WHITE)
