# src/world/sprites_walls.gd — o muro nos cinco niveis do §10, a escora e o fosso (ADR 0051).
#
# O §25 quer que a subida do muro se veja e nao se leia num contador: a estacaria pela
# cintura, a palicada com cintas, a pedra com ameias, o ferro chapeado e o bastiao com o
# estandarte. Tracos do PixelPainter, com a origem nos pes.
class_name WallSprites
extends RefCounted

const NIVEIS := 5
## As estacas: o primeiro x, o passo, a largura, a ponta e as alturas, da esquerda.
const ESTACAS := {"x": -31, "passo": 9, "largo": 8, "ponta": 6}
const ALTURAS_1 := [30, 34, 29, 33, 31, 35, 30]
const ALTURAS_2 := [48, 51, 47, 52, 48, 51, 48]
const LUZ := 2
const PREGO := {"y": [-40, -14], "x": 4}

const WALL_1 := [
	["r", -32, -3, 64, 3, "soil_dark"],
	["o", -32, -23, 64, 4, "rope"],
	["h", -31, -22, 62, 2, 2, "timber_light"],
]
const WALL_2 := [
	["E", -24, -2, 6, 2, "grey"],
	["E", 0, -2, 7, 2, "grey"],
	["E", 22, -2, 6, 2, "grey"],
	["o", -32, -43, 64, 5, "timber"],
	["o", -32, -17, 64, 5, "timber"],
]
const WALL_3 := [
	["o", -30, -66, 60, 66, "stone"],
	["r", -29, -12, 58, 11, "stone_shade"],
	["b", -29, -65, 58, 64, 6, 12, "mortar"],
	["o", -33, -70, 66, 6, "stone"],
	["r", -32, -66, 64, 1, "stone_shade"],
	["c", -33, -70, 66, 10, 4, 9, "stone"],
	["o", -2, -52, 4, 14, "opening"],
]
const WALL_4 := [
	["o", -31, -80, 62, 80, "stone"],
	["r", -30, -14, 60, 13, "stone_shade"],
	["b", -30, -79, 60, 78, 6, 12, "mortar"],
	["o", -31, -80, 62, 28, "iron"],
	["v", -19, -79, 50, 26, 12, "grey_dark"],
	["o", -31, -55, 62, 4, "iron_light"],
	["o", -14, -46, 4, 12, "opening"],
	["o", 10, -46, 4, 12, "opening"],
	["o", -34, -84, 68, 5, "iron_light"],
	["c", -33, -84, 66, 10, 4, 10, "iron"],
]
const REBITES := {"y": [-76, -60], "de": -27, "ate": 28, "passo": 6}
const WALL_5 := [
	["o", -38, -16, 76, 16, "stone_shade"],
	["b", -37, -15, 74, 14, 5, 10, "mortar"],
	["o", -34, -96, 68, 81, "stone"],
	["r", -33, -30, 66, 15, "stone_shade"],
	["b", -33, -95, 66, 79, 6, 12, "mortar"],
	["o", -16, -74, 4, 16, "opening"],
	["o", 12, -74, 4, 16, "opening"],
	["p", [-7, -62, 7, -62, 7, -50, 0, -43, -7, -50], "banner"],
	["r", -1, -60, 2, 13, "gold"],
	["r", -5, -56, 10, 2, "gold"],
	["o", -38, -106, 76, 7, "stone"],
	["c", -37, -106, 74, 9, 4, 10, "stone"],
	["r", -1, -132, 3, 26, "timber_dark"],
	["p", [2, -132, 22, -126, 2, -120], "banner"],
]
const MISULAS := {"y": -100, "de": -36, "ate": 33, "passo": 8, "lado": 5}
const SEAL := [
	["r", -24, -58, 48, 2, "timber_dark"],
	["o", -21, -58, 6, 58, "timber"],
	["o", 15, -58, 6, 58, "timber"],
	["o", -24, -52, 48, 8, "timber_light"],
	["o", -24, -36, 48, 8, "timber_light"],
	["o", -24, -20, 48, 8, "timber_light"],
	["l", -19, -54, 19, -4, "timber_dark"],
	["l", 19, -54, -19, -4, "timber_dark"],
	["o", -24, -60, 48, 5, "timber_dark"],
]
const SPIKES := [
	["p", [-48, 0, -40, -8, 40, -8, 48, 0], "soil"],
	["l", -44, -4, -30, -12, "root"],
	["l", 26, -10, 44, -3, "root"],
	["l", -6, -8, 4, -14, "root"],
]
const PUAS := {"de": -40, "passo": 10, "n": 9, "base": 3, "alto": 30, "inclina": 6, "chao": -4}

## O tamanho de cada sprite, em px de mundo: os pes ficam no meio de baixo.
const TAMANHOS := {
	&"wall_1": Vector2i(64, 44),
	&"wall_2": Vector2i(64, 62),
	&"wall_3": Vector2i(68, 80),
	&"wall_4": Vector2i(70, 96),
	&"wall_5": Vector2i(76, 132),
	&"seal": Vector2i(48, 62),
	&"spikes": Vector2i(96, 34),
}


static func all() -> Dictionary:
	return {
		&"wall_1": {"size": TAMANHOS[&"wall_1"], "strokes": _estacas(ALTURAS_1) + WALL_1},
		&"wall_2": {"size": TAMANHOS[&"wall_2"], "strokes": _palicada()},
		&"wall_3": {"size": TAMANHOS[&"wall_3"], "strokes": WALL_3},
		&"wall_4": {"size": TAMANHOS[&"wall_4"], "strokes": WALL_4 + _rebites()},
		&"wall_5": {"size": TAMANHOS[&"wall_5"], "strokes": WALL_5 + _misulas()},
		&"seal": {"size": TAMANHOS[&"seal"], "strokes": SEAL},
		&"spikes": {"size": TAMANHOS[&"spikes"], "strokes": SPIKES + _puas()},
	}


## Uma fila de troncos aguçados, com a luz do lado esquerdo e a sombra do direito.
static func _estacas(alturas: Array) -> Array:
	var tracos := []
	var w: int = ESTACAS.largo
	for i in alturas.size():
		var x: int = ESTACAS.x + i * ESTACAS.passo
		var h: int = alturas[i]
		var ponta: int = h + ESTACAS.ponta
		tracos.append(["p", [x, 0, x, -h, x + w / 2, -ponta, x + w, -h, x + w, 0], "log"])
		tracos.append(["l", x + LUZ, -h + 1, x + LUZ, -LUZ, "log_light"])
		tracos.append(["l", x + w - LUZ, -h + 1, x + w - LUZ, -LUZ, "timber_dark"])
	return tracos


static func _palicada() -> Array:
	var tracos := _estacas(ALTURAS_2) + WALL_2
	for i in ALTURAS_2.size():
		var x: int = ESTACAS.x + i * ESTACAS.passo + PREGO.x
		for y: int in PREGO.y:
			tracos.append(["r", x, y, 1, 1, "iron_light"])
	return tracos


static func _rebites() -> Array:
	var tracos := []
	for y: int in REBITES.y:
		for x in range(REBITES.de, REBITES.ate, REBITES.passo):
			tracos.append(["r", x, y, 1, 1, "iron_light"])
	return tracos


static func _misulas() -> Array:
	var tracos := []
	for x in range(MISULAS.de, MISULAS.ate, MISULAS.passo):
		tracos.append(["o", x, MISULAS.y, MISULAS.lado, MISULAS.lado + 1, "stone_shade"])
	return tracos


static func _puas() -> Array:
	var tracos := []
	for i in PUAS.n:
		var x: int = PUAS.de + i * PUAS.passo
		var lado: int = PUAS.inclina if i % 2 == 0 else -PUAS.inclina
		var b: int = PUAS.base
		var y: int = PUAS.chao
		tracos.append(["p", [x - b, y, x + b, y, x + lado, -PUAS.alto], "log"])
	return tracos
