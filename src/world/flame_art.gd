# src/world/flame_art.gd — a chama, em pixeis (§80, ADR 0034, ADR 0048).
#
# A chama e a unica coisa do ecra que nao leva luz nenhuma: e ela a luz (§80,
# "ambar e luz"). Desenha-se com as tres paragens da propria luz — bordo por
# fora, meio, nucleo por dentro —, ambar se e tua e roxa se e do Lume.
#
# E pixel a pixel na grelha de 2 px do dither: linhas de baixo para cima, cada
# uma com a sua meia largura, e a chama baloica mais em cima do que em baixo,
# como um fogo de verdade, que e firme na base e solto na ponta. Por cima sobem
# fagulhas. O tempo e o do ecra; a fase sai do x, para que duas fogueiras nunca
# dancem em uniao (o mesmo que o Flicker faz a luz).
class_name FlameArt
extends RefCounted

## O pixel da chama, em px de mundo: o mesmo passo do dither do §80.
const PIXEL := 2.0
## A meia largura de cada linha, de baixo para cima, em pixeis.
const PERFIL := [3, 4, 4, 4, 4, 3, 3, 3, 2, 2, 1, 1, 0]
## Ate que linha (fraccao da altura) vai o meio, e ate qual o nucleo.
const MEIO_ATE := 0.72
const NUCLEO_ATE := 0.42
## O fogo dancando: o ritmo da largura, do baloico, e quanto a ponta se solta; e
## quanto cada linha anda desfasada da de baixo (a largura e o baloico).
const DANCA := {
	"largura": 11.0, "baloico": 5.3, "solto": 2.2, "ponta": 9.0, "linha": 1.7, "curva": 0.35
}
## As fagulhas: quantas, quanto sobem (px por escala), a que ritmo, quanto derivam, e
## como cada uma se desencontra da outra (a vida, e a curva da deriva).
const FAGULHAS := {
	"quantas": 3,
	"sobe": 30.0,
	"ritmo": 0.55,
	"deriva": 5.0,
	"vez": 0.37,
	"volta": 3.0,
	"ondula": 2.1
}
const DESFASE := 0.031
## Uma chama tem pelo menos tres linhas: bordo, meio e nucleo.
const LINHAS_MIN := 3


## Uma chama assente em `base`, com `escala` vezes o tamanho da de uma fogueira.
## `cores` sao as paragens da luz dela: bordo, meio, nucleo.
static func draw_on(
	canvas: CanvasItem, base: Vector2, escala: float, cores: PackedColorArray, tempo: float
) -> void:
	if cores.size() < WorldLight.PARAGENS:
		return
	var semente := base.x * DESFASE
	var linhas := maxi(LINHAS_MIN, roundi(PERFIL.size() * escala))
	var chao := Vector2(snappedf(base.x, PIXEL), snappedf(base.y, PIXEL))
	for r in linhas:
		var subida := float(r) / float(linhas)
		var meia := roundi(
			float(PERFIL[mini(int(subida * PERFIL.size()), PERFIL.size() - 1)]) * escala
		)
		meia += roundi(sin(tempo * DANCA.largura + float(r) * DANCA.linha + semente) * subida)
		if r == linhas - 1 and sin(tempo * DANCA.ponta + semente) < 0.0:
			continue  # a ponta solta-se e volta: e o que se le como fogo
		var lado := roundi(
			sin(tempo * DANCA.baloico + semente + float(r) * DANCA.curva) * subida * DANCA.solto
		)
		var y := chao.y - float(r + 1) * PIXEL
		_linha(canvas, chao.x, y, lado, meia, cores[0])
		if subida < MEIO_ATE:
			_linha(canvas, chao.x, y, lado, meia - 1, cores[1])
		if subida < NUCLEO_ATE:
			_linha(canvas, chao.x, y, lado, meia - 2, cores[2])
	_fagulhas(canvas, chao - Vector2(0.0, float(linhas) * PIXEL), escala, cores[1], tempo, semente)


## Uma linha da chama: de -meia a +meia pixeis, deslocada `lado` pixeis.
static func _linha(
	canvas: CanvasItem, x: float, y: float, lado: int, meia: int, cor: Color
) -> void:
	if meia < 0:
		return
	var esquerda := x + float(lado - meia) * PIXEL
	canvas.draw_rect(Rect2(esquerda, y, float(meia * 2 + 1) * PIXEL, PIXEL), cor)


## As fagulhas que sobem da ponta e se apagam no ar.
static func _fagulhas(
	canvas: CanvasItem, ponta: Vector2, escala: float, cor: Color, tempo: float, semente: float
) -> void:
	for k in FAGULHAS.quantas:
		var vida := fposmod(tempo * FAGULHAS.ritmo + float(k) * FAGULHAS.vez + semente, 1.0)
		var onda := (vida * FAGULHAS.volta + float(k)) * FAGULHAS.ondula + semente
		var x := ponta.x + sin(onda) * FAGULHAS.deriva * escala
		var y := ponta.y - vida * FAGULHAS.sobe * escala
		var faisca := Vector2(snappedf(x, PIXEL), snappedf(y, PIXEL))
		canvas.draw_rect(Rect2(faisca, Vector2(PIXEL, PIXEL)), Color(cor, 1.0 - vida))
