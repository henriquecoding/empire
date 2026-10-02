# src/world/sprites_farmstead.gd — o canteiro, o galinheiro, o pesqueiro, o estabulo e o
# acampamento de lenha (ADR 0051).
#
# O que rende por fase (§06): o canteiro e terra lavrada com trigo e um espantalho; o
# galinheiro, uma capoeira em estacas com as galinhas ca fora — sao elas que o Alado vem
# roubar (§07); o pesqueiro, a cabana, o cais e a rede a secar. Tracos do PixelPainter,
# com a origem nos pes.
class_name FarmSprites
extends RefCounted

## O trigo: de onde a onde, o passo, a base, a altura e o que cresce a mais um sim um nao.
const TRIGO := {"de": -42, "ate": 43, "passo": 6, "chao": -8, "alto": 20, "mais": 3}
const FOLHA := {"y": -12, "lado": 2, "sobe": 3}
const ESPIGA := {"lado": 1, "largo": 3, "alto": 6}

const FARM := [
	["p", [-48, 0, -44, -8, 44, -8, 48, 0], "soil"],
	["l", -45, -3, 45, -3, "soil_dark"],
	["l", -44, -6, 44, -6, "soil_dark"],
]
const SCARECROW := [
	["o", -48, -22, 4, 22, "timber"],
	["o", 44, -22, 4, 22, "timber"],
	["r", -1, -42, 2, 40, "timber_dark"],
	["r", -10, -33, 20, 2, "timber_dark"],
	["r", -11, -34, 1, 3, "straw"],
	["r", 10, -34, 1, 3, "straw"],
	["o", -5, -34, 10, 10, "banner"],
	["E", 0, -40, 3, 3, "straw"],
	["p", [-6, -42, 0, -48, 6, -42], "straw_dark"],
]
const HENHOUSE := [
	["o", 44, -20, 3, 20, "timber"],
	["o", 30, -20, 3, 20, "timber"],
	["r", 14, -17, 33, 2, "timber_light"],
	["r", 14, -9, 33, 2, "timber_light"],
	["r", -31, -12, 3, 12, "timber_dark"],
	["r", 7, -12, 3, 12, "timber_dark"],
	["r", -34, -3, 46, 3, "straw"],
	["o", -34, -48, 46, 37, "timber"],
	["v", -30, -47, 42, 35, 5, "timber_dark"],
	["o", -28, -40, 9, 9, "timber_dark"],
	["r", -27, -39, 7, 7, "glass"],
	["a", -2, -36, 11, 22, "opening"],
	["p", [0, -14, 8, -14, 24, -1, 16, -1], "timber_light"],
	["p", [-40, -46, -11, -68, 18, -46], "roof"],
	["l", -34, -50, 12, -50, "roof_dark"],
	["l", -28, -55, 6, -55, "roof_light"],
	["l", -21, -60, -1, -60, "roof_dark"],
	["l", -16, -64, -6, -64, "roof_light"],
	["o", -42, -48, 62, 3, "roof_dark"],
	["q", [29, -8, 25, -13, 31, -6], "hen"],
	["E", 34, -5, 5, 4, "hen"],
	["E", 39, -11, 2, 3, "hen"],
	["r", 38, -15, 3, 2, "comb"],
	["r", 42, -11, 2, 1, "beak"],
	["r", 39, -11, 1, 1, "ink"],
	["E", -40, -5, 5, 4, "hen"],
	["E", -45, -11, 2, 3, "hen"],
	["r", -47, -15, 3, 2, "comb"],
	["r", -49, -11, 2, 1, "beak"],
	["r", -46, -11, 1, 1, "ink"],
]
const FISHERY := [
	["E", 22, -2, 34, 3, "water"],
	["l", 4, -2, 18, -2, "water_light"],
	["l", 28, -3, 40, -3, "water_light"],
	["o", -56, -42, 38, 42, "timber"],
	["v", -52, -41, 34, 40, 5, "timber_dark"],
	["a", -44, -28, 12, 28, "opening"],
	["p", [-60, -40, -37, -60, -14, -40], "roof"],
	["l", -54, -45, -20, -45, "roof_dark"],
	["l", -48, -50, -26, -50, "roof_light"],
	["l", -43, -55, -31, -55, "roof_dark"],
	["o", -61, -42, 48, 3, "roof_dark"],
	["r", -10, -14, 3, 14, "timber_dark"],
	["r", 14, -14, 3, 14, "timber_dark"],
	["r", 38, -14, 3, 14, "timber_dark"],
	["o", -14, -17, 62, 4, "timber_light"],
	["r", 16, -54, 3, 38, "timber_dark"],
	["r", 46, -54, 3, 38, "timber_dark"],
	["p", [19, -51, 46, -51, 43, -30, 22, -30], "rope"],
	["l", 20, -44, 27, -51, "timber_dark"],
	["l", 21, -37, 35, -51, "timber_dark"],
	["l", 23, -31, 43, -51, "timber_dark"],
	["l", 31, -31, 45, -45, "timber_dark"],
	["l", 26, -51, 40, -31, "timber_dark"],
	["l", 34, -51, 44, -37, "timber_dark"],
	["o", 14, -56, 38, 4, "timber_dark"],
	["o", -6, -24, 12, 7, "straw"],
	["E", -2, -25, 3, 1, "grey"],
	["E", 3, -26, 3, 1, "water_light"],
]
const STABLE := [
	["o", -50, -60, 100, 60, "timber"],
	["v", -46, -59, 94, 58, 6, "timber_dark"],
	["r", -49, -4, 98, 3, "timber_dark"],
	["o", -18, -48, 36, 48, "timber_light"],
	["o", -16, -46, 32, 46, "timber"],
	["l", -15, -45, 15, -1, "timber_light"],
	["l", 15, -45, -15, -1, "timber_light"],
	["r", -1, -46, 2, 46, "timber_dark"],
	["o", -44, -44, 18, 14, "opening"],
	["q", [-42, -36, -36, -42, -30, -40, -29, -36, -35, -34, -38, -31], "log"],
	["l", -37, -42, -41, -37, "timber_dark"],
	["r", -33, -39, 1, 1, "ink"],
	["o", 28, -14, 22, 14, "straw"],
	["h", 29, -12, 20, 11, 3, "straw_dark"],
	["p", [-58, -58, -46, -80, 0, -94, 46, -80, 58, -58], "roof"],
	["l", -53, -66, 53, -66, "roof_dark"],
	["l", -49, -74, 49, -74, "roof_light"],
	["l", -32, -84, 32, -84, "roof_dark"],
	["l", -16, -89, 16, -89, "roof_light"],
	["o", -60, -60, 120, 3, "roof_dark"],
	["o", -8, -78, 16, 13, "opening"],
	["r", -7, -69, 14, 3, "straw"],
]
const LUMBER := [
	["o", -50, -66, 5, 66, "timber"],
	["o", 6, -56, 5, 56, "timber"],
	["p", [-56, -64, 14, -54, 14, -50, -56, -60], "roof"],
	["l", -52, -62, 12, -53, "roof_light"],
	["l", -40, 0, -30, -16, "timber_dark"],
	["l", -30, 0, -40, -16, "timber_dark"],
	["l", -10, 0, 0, -16, "timber_dark"],
	["l", 0, 0, -10, -16, "timber_dark"],
	["o", -46, -22, 52, 8, "log"],
	["l", -44, -19, 4, -19, "log_light"],
	["E", -46, -18, 3, 4, "log_end"],
	["o", 18, -12, 14, 12, "log"],
	["E", 25, -12, 7, 2, "log_end"],
	["l", 26, -12, 32, -26, "timber_dark"],
	["q", [30, -28, 37, -27, 36, -22, 31, -24], "iron_light"],
]
## A pilha de lenha: os topos dos troncos, de baixo para cima.
const PILHA := [[38, -5], [47, -5], [56, -5], [42, -13], [51, -13], [47, -21]]
const TORA := 4

## O tamanho de cada sprite, em px de mundo: os pes ficam no meio de baixo.
const TAMANHOS := {
	&"farm": Vector2i(96, 48),
	&"henhouse": Vector2i(100, 70),
	&"fishery": Vector2i(120, 64),
	&"stable": Vector2i(120, 96),
	&"lumber": Vector2i(120, 70),
}


static func all() -> Dictionary:
	return {
		&"farm": {"size": TAMANHOS[&"farm"], "strokes": FARM + _trigo() + SCARECROW},
		&"henhouse": {"size": TAMANHOS[&"henhouse"], "strokes": HENHOUSE},
		&"fishery": {"size": TAMANHOS[&"fishery"], "strokes": FISHERY},
		&"stable": {"size": TAMANHOS[&"stable"], "strokes": STABLE},
		&"lumber": {"size": TAMANHOS[&"lumber"], "strokes": LUMBER + _pilha()},
	}


## Uma fila de trigo: o caule, duas folhas e a espiga, um mais alto e um mais baixo.
static func _trigo() -> Array:
	var tracos := []
	var i := 0
	for x in range(TRIGO.de, TRIGO.ate, TRIGO.passo):
		var topo: int = TRIGO.chao - TRIGO.alto - TRIGO.mais * (i % 2)
		var lado: int = FOLHA.lado
		tracos.append(["l", x, TRIGO.chao, x, topo, "wheat_dark"])
		tracos.append(["l", x, FOLHA.y, x - lado, FOLHA.y - FOLHA.sobe, "crop"])
		tracos.append(["l", x, FOLHA.y - lado, x + lado, FOLHA.y - lado - FOLHA.sobe, "crop"])
		var espiga := ["r", x - ESPIGA.lado, topo - ESPIGA.alto, ESPIGA.largo, ESPIGA.alto]
		tracos.append(espiga + ["wheat"])
		i += 1
	return tracos


static func _pilha() -> Array:
	var tracos := []
	for c: Array in PILHA:
		tracos.append(["E", c[0], c[1], TORA, TORA, "log_end"])
		tracos.append(["r", c[0], c[1], 1, 1, "log"])
	return tracos
