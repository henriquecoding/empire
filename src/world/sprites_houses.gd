# src/world/sprites_houses.gd — as casas e as obras de oficio sem arte do dono (ADR 0051).
#
# A casa do herdeiro e a embaixada sao um solar de dois pisos, no enxaimel da casa de
# treino do dono, com o estandarte do reino a porta (§15). A casa de quem vem dos
# acampamentos e uma casa terrea (Q-110). A mina e uma boca na rocha com a vagoneta; a
# fundicao, a fornalha e a chamine; o altar, pedra com velas e raizes; a banca do arco,
# um cavalete com arcos. Tracos do PixelPainter, com a origem nos pes.
class_name HouseSprites
extends RefCounted

const MANOR := [
	["o", -46, -6, 92, 6, "stone_shade"],
	["o", -44, -96, 88, 91, "plaster"],
	["r", -43, -95, 86, 4, "plaster_shade"],
	["o", -46, -52, 92, 5, "timber"],
	["r", -43, -95, 3, 43, "timber"],
	["r", 40, -95, 3, 43, "timber"],
	["r", -43, -47, 3, 42, "timber"],
	["r", 40, -47, 3, 42, "timber"],
	["l", -40, -56, -36, -92, "timber"],
	["l", 39, -56, 35, -92, "timber"],
	["a", -11, -44, 22, 39, "timber_dark"],
	["a", -9, -42, 18, 37, "timber"],
	["v", -6, -30, 14, 25, 4, "timber_dark"],
	["r", 4, -22, 2, 2, "gold"],
	["o", -36, -38, 16, 18, "timber_dark"],
	["r", -34, -36, 12, 14, "glass"],
	["r", -33, -35, 2, 3, "glass_light"],
	["r", -29, -36, 2, 14, "timber_dark"],
	["r", -34, -30, 12, 2, "timber_dark"],
	["o", 20, -38, 16, 18, "timber_dark"],
	["r", 22, -36, 12, 14, "glass"],
	["r", 23, -35, 2, 3, "glass_light"],
	["r", 27, -36, 2, 14, "timber_dark"],
	["r", 22, -30, 12, 2, "timber_dark"],
	["a", -32, -88, 14, 24, "timber_dark"],
	["a", -30, -86, 10, 20, "glass"],
	["r", -26, -80, 2, 14, "timber_dark"],
	["a", 18, -88, 14, 24, "timber_dark"],
	["a", 20, -86, 10, 20, "glass"],
	["r", 24, -80, 2, 14, "timber_dark"],
	["p", [-7, -92, 7, -92, 7, -64, 0, -69, -7, -64], "banner"],
	["r", -9, -93, 18, 2, "timber_dark"],
	["r", -4, -84, 9, 3, "gold"],
	["r", -4, -87, 1, 3, "gold"],
	["r", 0, -88, 1, 4, "gold"],
	["r", 4, -87, 1, 3, "gold"],
	["p", [-56, -94, 0, -140, 55, -94], "roof"],
	["l", -48, -100, 48, -100, "roof_dark"],
	["l", -41, -106, 41, -106, "roof_light"],
	["l", -33, -112, 33, -112, "roof_dark"],
	["l", -26, -118, 26, -118, "roof_light"],
	["l", -19, -124, 19, -124, "roof_dark"],
	["l", -12, -130, 12, -130, "roof_light"],
	["o", -57, -96, 114, 4, "roof_dark"],
	["E", 0, -112, 5, 5, "timber_dark"],
	["E", 0, -112, 3, 3, "glass"],
	["o", 26, -142, 12, 28, "stone"],
	["b", 27, -141, 10, 26, 4, 6, "mortar"],
	["o", 24, -144, 16, 4, "stone_shade"],
]
const COTTAGE := [
	["o", -38, -4, 76, 4, "stone_shade"],
	["o", -36, -58, 72, 55, "plaster"],
	["r", -35, -57, 3, 54, "timber"],
	["r", 32, -57, 3, 54, "timber"],
	["o", -37, -58, 74, 4, "timber"],
	["a", -8, -36, 16, 33, "timber_dark"],
	["a", -6, -34, 12, 31, "timber"],
	["v", -4, -26, 10, 22, 3, "timber_dark"],
	["r", 3, -17, 1, 2, "gold"],
	["o", -28, -42, 14, 14, "timber_dark"],
	["r", -26, -40, 10, 10, "glass"],
	["r", -22, -40, 2, 10, "timber_dark"],
	["r", -26, -36, 10, 2, "timber_dark"],
	["o", 14, -42, 14, 14, "timber_dark"],
	["r", 16, -40, 10, 10, "glass"],
	["r", 20, -40, 2, 10, "timber_dark"],
	["r", 16, -36, 10, 2, "timber_dark"],
	["o", 13, -28, 16, 4, "timber"],
	["r", 15, -30, 2, 2, "comb"],
	["r", 20, -30, 2, 2, "gold"],
	["r", 25, -30, 2, 2, "comb"],
	["p", [-46, -56, 0, -92, 46, -56], "roof"],
	["l", -39, -61, 39, -61, "roof_dark"],
	["l", -31, -67, 31, -67, "roof_light"],
	["l", -24, -73, 24, -73, "roof_dark"],
	["l", -16, -79, 16, -79, "roof_light"],
	["l", -9, -85, 9, -85, "roof_dark"],
	["o", -48, -59, 96, 4, "roof_dark"],
]
const MINE := [
	["p", [-60, 0, -50, -30, -26, -52, 8, -58, 38, -44, 58, -14, 60, 0], "grey"],
	["l", -44, -28, -30, -40, "grey_dark"],
	["l", 24, -46, 40, -34, "grey_dark"],
	["l", 46, -20, 54, -10, "grey_dark"],
	["E", -40, -12, 6, 3, "stone_shade"],
	["E", 30, -30, 5, 3, "stone_shade"],
	["a", -16, -46, 32, 46, "opening"],
	["o", -22, -44, 6, 44, "timber"],
	["o", 16, -44, 6, 44, "timber"],
	["o", -26, -50, 52, 7, "timber_dark"],
	["r", -14, -2, 74, 2, "iron_light"],
	["p", [24, -22, 50, -22, 46, -8, 28, -8], "iron"],
	["E", 37, -22, 10, 4, "ore"],
	["r", 34, -24, 1, 1, "gold"],
	["r", 40, -23, 1, 1, "gold"],
	["E", 31, -6, 3, 3, "grey_dark"],
	["E", 43, -6, 3, 3, "grey_dark"],
]
const FURNACE := [
	["o", 20, -108, 16, 60, "stone"],
	["b", 21, -107, 14, 58, 5, 8, "mortar"],
	["o", 18, -110, 20, 5, "stone_shade"],
	["o", -46, -62, 92, 62, "stone"],
	["r", -45, -14, 90, 13, "stone_shade"],
	["b", -45, -61, 90, 60, 6, 12, "mortar"],
	["p", [-52, -60, -34, -80, 34, -80, 52, -60], "roof"],
	["l", -47, -65, 47, -65, "roof_dark"],
	["l", -43, -70, 43, -70, "roof_light"],
	["l", -38, -75, 38, -75, "roof_dark"],
	["o", -54, -62, 108, 3, "roof_dark"],
	["a", -16, -38, 32, 37, "grey_dark"],
	["a", -12, -34, 24, 33, "opening"],
	["q", [-10, -2, -6, -14, -2, -8, 2, -18, 6, -8, 10, -2], "fire"],
	["q", [-5, -2, 0, -11, 5, -2], "gold"],
	["o", 26, -8, 14, 5, "ore"],
	["o", 28, -12, 10, 5, "ore"],
	["p", [-40, -14, -24, -14, -26, -10, -30, -10, -30, -4, -34, -4, -34, -10, -38, -10], "iron"],
]
const ALTAR := [
	["o", -40, -8, 80, 8, "stone_shade"],
	["o", -32, -16, 64, 9, "stone"],
	["o", -24, -36, 48, 21, "stone"],
	["b", -23, -35, 46, 19, 5, 12, "mortar"],
	["o", -28, -40, 56, 5, "stone_shade"],
	["o", -20, -48, 4, 9, "hen"],
	["q", [-20, -49, -18, -54, -16, -49], "fire"],
	["o", 16, -48, 4, 9, "hen"],
	["q", [16, -49, 18, -54, 20, -49], "fire"],
	["E", 0, -26, 5, 5, "gold"],
	["E", 0, -26, 2, 2, "banner"],
	["l", -24, -30, -30, -14, "root"],
	["l", -30, -14, -38, -9, "root"],
	["l", 24, -24, 32, -12, "root"],
	["r", -31, -18, 3, 2, "leaf"],
	["r", 31, -16, 3, 2, "leaf"],
]
const BOW_RACK := [
	["o", -20, -42, 4, 42, "timber"],
	["o", 16, -42, 4, 42, "timber"],
	["o", -23, -44, 46, 4, "timber_dark"],
	["o", -23, -18, 46, 3, "timber_dark"],
]
## Os arcos encostados: x de cada um, e a curva — topo, barriga, ponta de baixo.
const ARCOS := [-12, -1, 10]
const ARCO := {"topo": -40, "barriga": -32, "fim": -16, "baixo": -8, "curva": 3}

## O tamanho de cada sprite, em px de mundo: os pes ficam no meio de baixo.
const TAMANHOS := {
	&"manor": Vector2i(116, 144),
	&"cottage": Vector2i(96, 96),
	&"mine": Vector2i(120, 60),
	&"furnace": Vector2i(120, 110),
	&"altar": Vector2i(96, 56),
	&"bow_rack": Vector2i(52, 48),
}

const MARTELO := [
	["o", -1, -35, 3, 26, "log_light"],
	["o", -5, -39, 11, 7, "iron"],
	["r", -4, -39, 9, 2, "iron_light"],
]


static func all() -> Dictionary:
	return {
		&"manor": {"size": TAMANHOS[&"manor"], "strokes": MANOR},
		&"cottage": {"size": TAMANHOS[&"cottage"], "strokes": COTTAGE},
		&"mine": {"size": TAMANHOS[&"mine"], "strokes": MINE},
		&"furnace": {"size": TAMANHOS[&"furnace"], "strokes": FURNACE},
		&"altar": {"size": TAMANHOS[&"altar"], "strokes": ALTAR},
		&"bow_rack": {"size": TAMANHOS[&"bow_rack"], "strokes": BOW_RACK + _arcos()},
		&"hammer_rack":
		{
			"size": TAMANHOS[&"bow_rack"],
			"strokes": BOW_RACK + _martelos(),
		},
	}


static func _martelos() -> Array:
	var tracos := []
	for x in ARCOS:
		for traco in MARTELO:
			var novo: Array = traco.duplicate()
			novo[1] += x
			tracos.append(novo)
	return tracos


static func _arcos() -> Array:
	var tracos := []
	var a := ARCO
	for x: int in ARCOS:
		var c: int = x - a.curva
		tracos.append(["l", x, a.topo, c, a.barriga, "log_light"])
		tracos.append(["l", c, a.barriga, c, a.fim, "log_light"])
		tracos.append(["l", c, a.fim, x, a.baixo, "log_light"])
		tracos.append(["l", x, a.topo, x, a.baixo, "rope"])
	return tracos
