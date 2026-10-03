# src/world/sprites_seat.gd — a sede em cada estagio, e a carroca da chegada (ADR 0059).
#
# O plano do reino (§22): cada estagio guarda rastos do anterior — a fogueira continua no
# sitio, a tenda vira abrigo, a bancada ganha teto — e a sede cresce para os lados, nao
# para cima. O Acampamento sao duas tendas, a fogueira em brasa baixa (a chama de
# proteger e a lareira paga, Q-190) e a bancada; o Povoado, duas cabanas de troncos e o
# sino; a Vila, as casas de reboco a volta do salao; a Vila Fortificada, a mesma vila
# entre duas palicadas, com a guarita. A Fortaleza e o castelo-arvore do dono
# (art/export), e por isso nao esta aqui. Tracos do PixelPainter, com a origem nos pes.
class_name SeatSprites
extends RefCounted

## O sprite de cada estagio, do Acampamento a Fortaleza.
const POR_ESTAGIO := [
	&"seat_encampment", &"seat_hamlet", &"seat_village", &"seat_walled_village", &"tree_castle"
]
const CARROCA := &"provisions_cart"
const PALETA := {"tent": Color("d8c8a0"), "tent_dark": Color("a8956a")}

const ENCAMPMENT := [
	["E", 0, -2, 80, 3, "soil"],
	["p", [-78, 0, -52, -46, -26, 0], "tent"],
	["q", [-52, -45, -42, -1, -60, -1], "tent_dark"],
	["p", [-58, 0, -52, -18, -46, 0], "opening"],
	["l", -52, -50, -52, -46, "timber_dark"],
	["o", -24, -14, 12, 4, "timber"],
	["r", -23, -10, 2, 10, "timber_dark"],
	["r", -15, -10, 2, 10, "timber_dark"],
	["l", -22, -16, -14, -22, "log_light"],
	["E", -8, -3, 4, 3, "stone_shade"],
	["E", 8, -3, 4, 3, "stone_shade"],
	["E", 0, -2, 4, 2, "stone"],
	["l", -7, -6, 7, -9, "log"],
	["l", -7, -9, 7, -6, "log"],
	["E", 0, -8, 3, 2, "ember"],
	["o", 14, -52, 3, 52, "timber"],
	["p", [17, -50, 28, -46, 17, -42], "banner"],
	["p", [24, 0, 50, -54, 76, 0], "tent"],
	["q", [50, -53, 62, -1, 40, -1], "tent_dark"],
	["p", [43, 0, 50, -22, 57, 0], "opening"],
	["l", 50, -58, 50, -54, "timber_dark"],
]
const HAMLET := [
	["E", 0, -2, 118, 3, "soil"],
	["o", -112, -40, 56, 40, "log"],
	["h", -111, -39, 54, 38, 6, "log_light"],
	["a", -90, -26, 12, 26, "opening"],
	["p", [-118, -38, -84, -66, -50, -38], "straw"],
	["l", -110, -42, -58, -42, "straw_dark"],
	["l", -100, -50, -68, -50, "straw_dark"],
	["o", 56, -40, 56, 40, "log"],
	["h", 57, -39, 54, 38, 6, "log_light"],
	["a", 78, -26, 12, 26, "opening"],
	["p", [50, -38, 84, -66, 118, -38], "straw"],
	["l", 58, -42, 110, -42, "straw_dark"],
	["l", 68, -50, 100, -50, "straw_dark"],
	["E", -40, -3, 4, 3, "stone_shade"],
	["E", -24, -3, 4, 3, "stone_shade"],
	["l", -38, -6, -26, -8, "log"],
	["E", -32, -7, 3, 2, "ember"],
	["o", -14, -72, 4, 72, "timber"],
	["o", 10, -72, 4, 72, "timber"],
	["o", -16, -76, 32, 5, "timber_dark"],
	["p", [-6, -70, 6, -70, 9, -54, -9, -54], "bell"],
	["E", 0, -53, 2, 2, "bell_dark"],
	["E", 30, -5, 4, 4, "log_end"],
	["E", 40, -5, 4, 4, "log_end"],
	["E", 35, -12, 4, 4, "log_end"],
]
const VILLAGE := [
	["E", 0, -2, 160, 3, "soil"],
	["o", -156, -46, 72, 46, "plaster"],
	["r", -155, -45, 3, 44, "timber"],
	["r", -87, -45, 3, 44, "timber"],
	["a", -126, -30, 14, 30, "timber_dark"],
	["o", -148, -36, 12, 12, "timber_dark"],
	["r", -146, -34, 8, 8, "glass"],
	["p", [-164, -44, -120, -78, -76, -44], "roof"],
	["l", -154, -50, -86, -50, "roof_dark"],
	["l", -144, -58, -96, -58, "roof_light"],
	["o", 84, -46, 72, 46, "plaster"],
	["r", 85, -45, 3, 44, "timber"],
	["r", 153, -45, 3, 44, "timber"],
	["a", 112, -30, 14, 30, "timber_dark"],
	["o", 136, -36, 12, 12, "timber_dark"],
	["r", 138, -34, 8, 8, "glass"],
	["p", [76, -44, 120, -78, 164, -44], "roof"],
	["l", 86, -50, 154, -50, "roof_dark"],
	["l", 96, -58, 144, -58, "roof_light"],
	["r", -82, -14, 20, 2, "timber"],
	["r", -80, -16, 2, 16, "timber_dark"],
	["r", -66, -16, 2, 16, "timber_dark"],
	["r", 62, -14, 20, 2, "timber"],
	["r", 64, -16, 2, 16, "timber_dark"],
	["r", 78, -16, 2, 16, "timber_dark"],
	["o", 30, -116, 12, 34, "stone"],
	["b", 31, -115, 10, 32, 4, 6, "mortar"],
	["o", -60, -66, 120, 66, "plaster"],
	["r", -59, -65, 3, 64, "timber"],
	["r", -2, -65, 3, 30, "timber"],
	["r", 56, -65, 3, 64, "timber"],
	["o", -61, -36, 122, 4, "timber"],
	["a", -12, -32, 24, 32, "timber_dark"],
	["a", -10, -30, 20, 30, "timber"],
	["v", -7, -22, 15, 22, 4, "timber_dark"],
	["o", -46, -60, 16, 18, "timber_dark"],
	["r", -44, -58, 12, 14, "glass"],
	["o", 30, -60, 16, 18, "timber_dark"],
	["r", 32, -58, 12, 14, "glass"],
	["p", [-70, -64, 0, -110, 70, -64], "roof"],
	["l", -60, -70, 60, -70, "roof_dark"],
	["l", -48, -78, 48, -78, "roof_light"],
	["l", -36, -86, 36, -86, "roof_dark"],
	["l", -24, -94, 24, -94, "roof_light"],
	["p", [-6, -100, 6, -100, 6, -84, 0, -88, -6, -84], "banner"],
	["r", -2, -96, 4, 3, "gold"],
]
const GUARITA := [
	["o", 96, -132, 28, 132, "stone"],
	["b", 97, -131, 26, 130, 6, 10, "mortar"],
	["o", 92, -138, 36, 8, "stone_shade"],
	["r", 92, -144, 6, 6, "stone_shade"],
	["r", 107, -144, 6, 6, "stone_shade"],
	["r", 122, -144, 6, 6, "stone_shade"],
	["a", 104, -112, 12, 18, "opening"],
	["l", 110, -160, 110, -144, "timber_dark"],
	["p", [111, -160, 124, -155, 111, -150], "banner"],
]
## As estacas da palicada de cada ponta: o x de cada uma, a largura e a altura.
const ESTACAS := [-204, -196, -188, -180, 174, 182, 190, 198]
const ESTACA := {"largura": 7, "alto": 58, "bico": 6}
const TAMANHOS := {
	&"seat_encampment": Vector2i(168, 64),
	&"seat_hamlet": Vector2i(248, 80),
	&"seat_village": Vector2i(328, 120),
	&"seat_walled_village": Vector2i(412, 164),
	&"provisions_cart": Vector2i(72, 48),
}
const CART := [
	["o", -30, -30, 52, 16, "timber"],
	["v", -29, -29, 50, 14, 6, "timber_dark"],
	["l", 22, -22, 34, -16, "timber_dark"],
	["E", -16, -26, 9, 8, "straw"],
	["E", 4, -30, 11, 10, "tent"],
	["r", 0, -40, 8, 3, "rope"],
	["E", 4, -30, 3, 3, "gold"],
	["E", -18, -10, 9, 9, "timber_dark"],
	["E", -18, -10, 6, 6, "log"],
	["E", -18, -10, 2, 2, "timber_dark"],
	["E", 12, -10, 9, 9, "timber_dark"],
	["E", 12, -10, 6, 6, "log"],
	["E", 12, -10, 2, 2, "timber_dark"],
]


## O sprite da sede no estagio `nivel` (1 e o Acampamento).
static func profile(nivel: int) -> StringName:
	return POR_ESTAGIO[clampi(nivel, RealmLadder.FUNDADO, POR_ESTAGIO.size()) - 1]


static func all() -> Dictionary:
	return {
		&"seat_encampment": _def(&"seat_encampment", ENCAMPMENT),
		&"seat_hamlet": _def(&"seat_hamlet", HAMLET),
		&"seat_village": _def(&"seat_village", VILLAGE),
		&"seat_walled_village": _def(&"seat_walled_village", _palicada() + GUARITA + VILLAGE),
		CARROCA: _def(CARROCA, CART),
	}


static func _def(id: StringName, tracos: Array) -> Dictionary:
	return {"size": TAMANHOS[id], "strokes": tracos, "palette": PALETA}


## As duas palicadas das pontas da Vila Fortificada: estacas de bico, como as do muro.
static func _palicada() -> Array:
	var tracos := []
	var e := ESTACA
	for x: int in ESTACAS:
		var pontas := [x, 0, x, -e.alto, x + e.largura / 2, -e.alto - e.bico]
		pontas.append_array([x + e.largura, -e.alto, x + e.largura, 0])
		tracos.append(["p", pontas, "log"])
	return tracos
