# src/world/terrain_art.gd — o cenario de cada faixa, e so o cenario (§11, §22).
#
# E o fundo por onde tudo o resto passa: ceu e montanhas em cima, campo e solo ao
# meio, rocha e camara em baixo. Nao le uma unica coluna da simulacao — recebe a
# largura da regiao e a luz da faixa, e desenha. E por isso que o
# TerrainBackdrop o pode chamar so quando a luz muda, em vez de a cada frame.
#
# Cada perfil e uma LISTA DE NUMEROS aos pares, como no Outline: fraccao da
# LARGURA, e y em pixeis. Escrever assim custa um terco das linhas e deixa a
# forma ler-se de uma vez — e uma montanha que desce abaixo do horizonte da-se a
# ver no proprio numero, sem se abrir o jogo.
class_name TerrainArt
extends RefCounted

const SKY_TOP := Color(0.15, 0.24, 0.34)
const SKY_BOTTOM := Color(0.76, 0.67, 0.49)
const FAR_MOUNTAIN := Color(0.18, 0.22, 0.27)
const NEAR_MOUNTAIN := Color(0.25, 0.28, 0.28)
const MEADOW := Color(0.32, 0.39, 0.29)
const FIELD := Color(0.39, 0.45, 0.25)
const FIELD_LIGHT := Color(0.57, 0.56, 0.30)
const PATH := Color(0.65, 0.49, 0.29)
const SOIL := Color(0.34, 0.21, 0.13)
const SOIL_LIGHT := Color(0.48, 0.29, 0.16)
const ROCK := Color(0.13, 0.12, 0.15)
const ROCK_LIGHT := Color(0.22, 0.19, 0.19)
const CHAMBER := Color(0.08, 0.08, 0.11)
const ROOT := Color(0.30, 0.18, 0.11)
const WINDOW := Color(0.95, 0.66, 0.28)

## De quantos em quantos a variacao de cada fila se repete. Tres chega para o
## olho nao dar pelo padrao, e e pouco para se ver que ha um.
const CICLO := 3

## A regiao nunca e mais estreita do que um ecra: o cenario e desenhado a todo o
## comprimento dela, e um mundo curto deixava o ceu a acabar a meio.
const ECRA := 1280.0

## O ceu em faixas horizontais, do topo ao horizonte. Oito chegam: com menos
## ve-se a banda, com mais nao se ve a diferenca.
const CEU := {"faixas": 8, "folga": 2.0}
const SOL := {"x": 0.79, "y": 112.0, "raio": 38.0}

## Os dois perfis de montanha da §11. Como as formas do Outline, sao pares: x em
## CENTESIMOS da largura da regiao, y em pixeis do ecra. So o cimo esta escrito —
## a base de cada massa e a linha em que ela fecha, e essa tem nome.
const SERRA_LONGE := [
	0, 365, 12, 320, 22, 350, 36, 274, 50, 346, 64, 290, 79, 344, 91, 305, 100, 350
]
const SERRA_PERTO := [0, 407, 16, 363, 30, 392, 47, 330, 61, 397, 76, 351, 100, 391]

## A colina da superficie fecha na linha de chao do §11 — e nao num numero solto.
const SERRA_FECHO := {"longe": Band.HORIZON, "perto": 446.0}
const COLINA := [0, 494, 16, 454, 31, 480, 49, 438, 67, 477, 84, 447, 100, 474]
const CAMINHO := [0, 505, 19, 498, 37, 511, 55, 491, 73, 505, 100, 493]
const CAMINHO_TRACO := {"largo": 18.0, "risco": 2.0, "clarear": 0.18}

## O tecto da camara, em pares (fraccao da largura, y A CONTAR DO TOPO da faixa).
const TECTO_FECHO := 64.0
const TECTO := [0, 8, 16, 25, 31, 12, 46, 34, 62, 15, 81, 30, 100, 10]

## As arvores e as casas de cada faixa, em (fraccao da largura, y, escala).
const ARVORES_AR := {"quantas": 9, "x": 0.035, "passo": 0.117, "y": 420.0, "escala": 0.72}
const ARVORES_CHAO := [0.09, 517.0, 1.1, 0.91, 517.0, 0.88]
const CASAS_AR := [0.23, 420.0, 0.72, 0.88, 420.0, 0.58]
const CASAS_CHAO := [0.18, 517.0, 1.0, 0.77, 517.0, 0.92]

## Os sulcos do campo e as hastes que ficam por ceifar.
const SULCO := {"quantos": 5, "y": 462.0, "passo": 10.0, "alto": 5.0, "traco": 3.0}
const SULCO_X := {"de": 0.04, "salto": 0.12, "ate": 0.42, "leque": 0.14}
const HASTE := {"quantas": 4, "x": 0.52, "passo": 0.095, "topo": 467.0, "fundo": 505.0, "dx": 16.0}

## O solo: as veias por onde ele se le, e as raizes que descem da superficie.
const VEIA := {"quantas": 6, "fundo": 18.0, "passo": 28.0, "onda": 2.1, "alto": 5.0, "traco": 2.0}
const RAIZ := {"quantas": 7, "x": 0.07, "passo": 0.139, "traco": 3.0}
const RAIZ_Y := {
	"topo": 517.0, "meio": 548.0, "degrau": 12.0, "fundo": 577.0, "dx": 12.0, "pe": 7.0
}

## A camara subterranea do §11, a escada que desce ate ela e a candeia que la vive.
const CAMARA := {"x": 0.36, "y": 38.0, "w": 0.28, "h": 68.0, "traco": 7.0}
const ESCADA := {
	"degraus": 5, "topo": 22.0, "alto": 11.0, "recuo": 8.0, "largo": 38.0, "traco": 4.0
}
const ESCADAS_X := [0.22, 1.0, 0.78, -1.0]
const CANDEIA := {"x": 0.50, "y": 74.0, "raio": 5.0}

## Os dentes de rocha que sobem do fundo, e as veias que atravessam a rocha.
const DENTE := {"quantos": 6, "x": 0.06, "passo": 0.18, "alto": 22.0, "degrau": 13.0}
const DENTE_X := {"cume": 10.0, "ombro": 29.0, "ombro_y": 8.0, "pe": 42.0}
const VEIA_ROCHA := {"quantas": 5, "y": 86.0, "passo": 22.0, "alto": 5.0, "traco": 2.0}


static func draw_on(canvas: CanvasItem, faixa: Band.Kind, width: float, light: Color) -> void:
	var largura := maxf(width, ECRA)
	match faixa:
		Band.Kind.AERIAL:
			_aerial(canvas, largura, light)
		Band.Kind.SURFACE:
			_surface(canvas, largura, light)
		Band.Kind.UNDERGROUND:
			_underground(canvas, largura, light)


static func _aerial(canvas: CanvasItem, width: float, light: Color) -> void:
	var faixa := float(Band.GROUND_LINE) / float(CEU.faixas)
	for i in CEU.faixas:
		var t := float(i) / float(CEU.faixas - 1)
		var caixa := Rect2(0.0, faixa * float(i), width, faixa + CEU.folga)
		canvas.draw_rect(caixa, _paint(SKY_TOP.lerp(SKY_BOTTOM, t), light))
	canvas.draw_circle(Vector2(width * SOL.x, SOL.y), SOL.raio, _paint(WINDOW, light))
	var longe := _massa(SERRA_LONGE, width, SERRA_FECHO.longe)
	canvas.draw_colored_polygon(longe, _paint(FAR_MOUNTAIN, light))
	var perto := _massa(SERRA_PERTO, width, SERRA_FECHO.perto)
	canvas.draw_colored_polygon(perto, _paint(NEAR_MOUNTAIN, light))
	for i in ARVORES_AR.quantas:
		var x := width * (ARVORES_AR.x + float(i) * ARVORES_AR.passo)
		PropArt.tree(canvas, Vector2(x, ARVORES_AR.y), ARVORES_AR.escala, light)
	PropArt.houses(canvas, CASAS_AR, width, light)


static func _surface(canvas: CanvasItem, width: float, light: Color) -> void:
	var alto := float(Band.GROUND_LINE - Band.HORIZON)
	canvas.draw_rect(Rect2(0.0, float(Band.HORIZON), width, alto), _paint(MEADOW, light))
	var colina := _massa(COLINA, width, float(Band.GROUND_LINE))
	canvas.draw_colored_polygon(colina, _paint(FIELD, light))
	_field_rows(canvas, width, light)
	var caminho := _perfil(CAMINHO, width)
	canvas.draw_polyline(caminho, _paint(PATH, light), CAMINHO_TRACO.largo)
	var clara := PATH.lightened(CAMINHO_TRACO.clarear)
	canvas.draw_polyline(caminho, _paint(clara, light), CAMINHO_TRACO.risco)
	PropArt.trees(canvas, ARVORES_CHAO, width, light)
	PropArt.houses(canvas, CASAS_CHAO, width, light)
	_soil(canvas, width, light)
	var chao := float(Band.GROUND_LINE)
	var cor := _paint(WorldPalette.LINHA, light)
	canvas.draw_line(Vector2(0.0, chao), Vector2(width, chao), cor, WorldPalette.CONTORNO)


static func _field_rows(canvas: CanvasItem, width: float, light: Color) -> void:
	var cor := _paint(FIELD_LIGHT, light)
	for i in SULCO.quantos:
		var y := SULCO.y + float(i) * SULCO.passo
		var de := width * (SULCO_X.de + float(i % 2) * SULCO_X.salto)
		var ate := width * (SULCO_X.ate + float(i % CICLO) * SULCO_X.leque)
		canvas.draw_line(Vector2(de, y), Vector2(ate, y - SULCO.alto), cor, SULCO.traco)
	for i in HASTE.quantas:
		var x := width * (HASTE.x + float(i) * HASTE.passo)
		var pe := Vector2(x + HASTE.dx, HASTE.fundo)
		canvas.draw_line(Vector2(x, HASTE.topo), pe, cor, SULCO.traco)


static func _soil(canvas: CanvasItem, width: float, light: Color) -> void:
	var chao := float(Band.GROUND_LINE)
	canvas.draw_rect(Rect2(0.0, chao, width, float(Band.SOIL_CUT)), _paint(SOIL, light))
	for i in VEIA.quantas:
		var y := chao + VEIA.fundo + float(i) * VEIA.passo
		var fim := Vector2(width, y + sin(float(i) * VEIA.onda) * VEIA.alto)
		canvas.draw_line(Vector2(0.0, y), fim, _paint(SOIL_LIGHT, light), VEIA.traco)
	for i in RAIZ.quantas:
		var x := width * (RAIZ.x + float(i) * RAIZ.passo)
		var raiz := PackedVector2Array(
			[
				Vector2(x, RAIZ_Y.topo),
				Vector2(x - RAIZ_Y.dx, RAIZ_Y.meio + float(i % CICLO) * RAIZ_Y.degrau),
				Vector2(x + RAIZ_Y.pe, RAIZ_Y.fundo),
			]
		)
		canvas.draw_polyline(raiz, _paint(ROOT, light), RAIZ.traco)


static func _underground(canvas: CanvasItem, width: float, light: Color) -> void:
	var top := WorldPalette.ground_of(int(Band.Kind.UNDERGROUND))
	var fundo := float(Band.SCREEN_BOTTOM)
	canvas.draw_rect(Rect2(0.0, top, width, fundo - top), _paint(ROCK, light))
	var tecto := _massa(TECTO, width, TECTO_FECHO, top)
	canvas.draw_colored_polygon(tecto, _paint(ROCK_LIGHT, light))
	var camara := Rect2(width * CAMARA.x, top + CAMARA.y, width * CAMARA.w, CAMARA.h)
	canvas.draw_rect(camara, _paint(CHAMBER, light))
	var verga := Vector2(camara.end.x, camara.position.y)
	canvas.draw_line(camara.position, verga, _paint(ROOT, light), CAMARA.traco)
	for i in DENTE.quantos:
		var x := width * (DENTE.x + float(i) * DENTE.passo)
		var h := DENTE.alto + float(i % CICLO) * DENTE.degrau
		var dente := PackedVector2Array(
			[
				Vector2(x, fundo),
				Vector2(x + DENTE_X.cume, top + h),
				Vector2(x + DENTE_X.ombro, top + h + DENTE_X.ombro_y),
				Vector2(x + DENTE_X.pe, fundo),
			]
		)
		canvas.draw_colored_polygon(dente, _paint(ROCK_LIGHT, light))
	for i in VEIA_ROCHA.quantas:
		var y := top + VEIA_ROCHA.y + float(i) * VEIA_ROCHA.passo
		var fim := Vector2(width, y + float(i % 2) * VEIA_ROCHA.alto)
		canvas.draw_line(Vector2(0.0, y), fim, _paint(ROOT, light), VEIA_ROCHA.traco)
	for i in range(0, ESCADAS_X.size(), 2):
		var origem := Vector2(width * float(ESCADAS_X[i]), top + ESCADA.topo)
		_stairs(canvas, origem, float(ESCADAS_X[i + 1]), light)
	var lume := Vector2(width * CANDEIA.x, top + CANDEIA.y)
	canvas.draw_circle(lume, CANDEIA.raio, _paint(WINDOW, light))


static func _stairs(canvas: CanvasItem, origin: Vector2, sentido: float, light: Color) -> void:
	for i in ESCADA.degraus:
		var y := origin.y + float(i) * ESCADA.alto
		var x := origin.x + sentido * float(i) * ESCADA.recuo
		var fim := Vector2(x + sentido * ESCADA.largo, y)
		canvas.draw_line(Vector2(x, y), fim, _paint(PATH, light), ESCADA.traco)


## Um perfil escrito em pares — x em centesimos da largura, y em pixeis — ja na
## largura da regiao. `desvio` e para os perfis que contam o y a partir do topo
## da faixa, e nao do topo do ecra.
static func _perfil(pontos: Array, width: float, desvio: float = 0.0) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(0, pontos.size(), 2):
		var x := width * float(pontos[i]) / Outline.CENTO
		out.append(Vector2(x, float(pontos[i + 1]) + desvio))
	return out


## A mesma coisa, fechada em baixo na linha `fecho`: e o que faz de um cimo de
## montanha uma massa.
static func _massa(
	pontos: Array, width: float, fecho: float, desvio: float = 0.0
) -> PackedVector2Array:
	var out := _perfil(pontos, width, desvio)
	out.append(Vector2(width, fecho + desvio))
	out.append(Vector2(0.0, fecho + desvio))
	return out


static func _paint(base: Color, light: Color) -> Color:
	return WorldPalette.tint(base, light)
