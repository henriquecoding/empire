# src/world/sprites_towers.gd — a torre, a torre alta, o sino e o barril (ADR 0051).
#
# A torre de arqueiros e de madeira: pernas de tronco, escada, plataforma com parapeito e
# telhado azul. A torre alta e de pedra e chega ao Alado (§10): o dobro da altura, com
# ameias e o estandarte. O Sino de Vigia (§75) e um portico com o sino; o barril de fogo,
# um barril com a chama em cima. Tracos do PixelPainter, com a origem nos pes.
class_name TowerSprites
extends RefCounted

const DEGRAU := {"de": -8, "ate": -118, "passo": -8, "x": -3, "largo": 7}
const MISULA := {"de": -26, "ate": 23, "passo": 7, "y": -198, "lado": 5, "alto": 7}

const ARCHER_TOWER := [
	["p", [-28, 0, -22, 0, -15, -120, -20, -120], "log"],
	["p", [22, 0, 28, 0, 20, -120, 15, -120], "log"],
	["l", -24, -12, 20, -50, "timber_dark"],
	["l", -24, -11, 20, -49, "timber_dark"],
	["l", 24, -12, -20, -50, "timber_dark"],
	["l", 24, -11, -20, -49, "timber_dark"],
	["l", -20, -60, 17, -100, "timber_dark"],
	["l", -20, -59, 17, -99, "timber_dark"],
	["l", 20, -60, -17, -100, "timber_dark"],
	["l", 20, -59, -17, -99, "timber_dark"],
	["o", -25, -56, 50, 5, "timber"],
	["r", -5, -120, 2, 120, "timber_dark"],
	["r", 4, -120, 2, 120, "timber_dark"],
	["o", -30, -127, 60, 7, "timber"],
	["r", -28, -121, 56, 2, "timber_dark"],
	["o", -30, -143, 60, 17, "timber_light"],
	["v", -24, -142, 50, 15, 6, "timber_dark"],
	["o", -32, -146, 64, 4, "timber_dark"],
	["r", -27, -160, 3, 15, "timber_dark"],
	["r", 24, -160, 3, 15, "timber_dark"],
	["p", [-36, -157, 0, -177, 36, -157], "roof"],
	["l", -28, -161, 28, -161, "roof_dark"],
	["l", -21, -165, 21, -165, "roof_light"],
	["l", -14, -169, 14, -169, "roof_dark"],
	["l", -7, -173, 7, -173, "roof_light"],
	["o", -38, -158, 76, 3, "roof_dark"],
	["r", -1, -180, 2, 4, "timber_dark"],
]
const HIGH_TOWER := [
	["o", -27, -20, 54, 20, "stone_shade"],
	["b", -26, -19, 52, 18, 5, 10, "mortar"],
	["o", -22, -192, 44, 173, "stone"],
	["r", 12, -191, 9, 171, "stone_shade"],
	["b", -21, -191, 42, 171, 7, 14, "mortar"],
	["o", -2, -70, 5, 16, "opening"],
	["o", -2, -130, 5, 16, "opening"],
	["a", -7, -176, 14, 22, "opening"],
	["r", -9, -155, 18, 2, "stone_shade"],
	["o", -30, -206, 60, 9, "stone"],
	["c", -30, -206, 60, 8, 5, 10, "stone"],
	["r", -1, -236, 3, 30, "timber_dark"],
	["p", [2, -236, 24, -230, 2, -224], "banner"],
	["r", 8, -231, 3, 2, "gold"],
]
const BELL := [
	["E", -15, -2, 6, 2, "grey"],
	["E", 15, -2, 6, 2, "grey"],
	["o", -18, -82, 5, 82, "timber"],
	["o", 13, -82, 5, 82, "timber"],
	["l", -13, -70, -6, -80, "timber_dark"],
	["l", 12, -70, 5, -80, "timber_dark"],
	["o", -22, -86, 44, 6, "timber_dark"],
	["p", [-24, -85, 0, -96, 23, -85], "roof"],
	["l", -12, -89, 12, -89, "roof_dark"],
	["r", -1, -80, 2, 6, "timber_dark"],
	["p", [-6, -75, 6, -75, 9, -58, -9, -58], "bell"],
	["l", -3, -72, -5, -61, "gold"],
	["o", -11, -59, 22, 3, "bell_dark"],
	["E", 0, -54, 2, 2, "bell_dark"],
	["l", 5, -56, 5, -24, "rope"],
]
const BARREL := [
	["p", [-10, -28, 10, -28, 13, -14, 10, 0, -10, 0, -13, -14], "timber"],
	["l", -4, -27, -5, -1, "timber_dark"],
	["l", 4, -27, 5, -1, "timber_dark"],
	["o", -13, -23, 26, 3, "iron"],
	["o", -13, -7, 26, 3, "iron"],
	["E", 0, -28, 10, 2, "timber_dark"],
	["q", [-7, -29, -4, -37, -1, -32, 2, -40, 5, -32, 8, -29], "fire"],
	["q", [-3, -29, 0, -35, 3, -29], "hen"],
]

## O tamanho de cada sprite, em px de mundo: os pes ficam no meio de baixo.
const TAMANHOS := {
	&"archer_tower": Vector2i(80, 180),
	&"high_tower": Vector2i(72, 236),
	&"bell": Vector2i(48, 96),
	&"barrel": Vector2i(32, 40),
}


static func all() -> Dictionary:
	return {
		&"archer_tower": {"size": TAMANHOS[&"archer_tower"], "strokes": ARCHER_TOWER + _degraus()},
		&"high_tower": {"size": TAMANHOS[&"high_tower"], "strokes": HIGH_TOWER + _misulas()},
		&"bell": {"size": TAMANHOS[&"bell"], "strokes": BELL},
		&"barrel": {"size": TAMANHOS[&"barrel"], "strokes": BARREL},
	}


## Os degraus da escada, entre as duas pernas dela.
static func _degraus() -> Array:
	var tracos := []
	for y in range(DEGRAU.de, DEGRAU.ate, DEGRAU.passo):
		tracos.append(["r", DEGRAU.x, y, DEGRAU.largo, 1, "timber_light"])
	return tracos


## As misulas por baixo da plataforma: o que segura as ameias por fora do fuste.
static func _misulas() -> Array:
	var tracos := []
	for x in range(MISULA.de, MISULA.ate, MISULA.passo):
		tracos.append(["o", x, MISULA.y, MISULA.lado, MISULA.alto, "stone_shade"])
	return tracos
