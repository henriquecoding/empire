# src/world/pixel_painter.gd — o pincel das obras: tracos escritos como dados, pintados
# numa imagem a 1 px de mundo por pixel (§22, ADR 0051).
#
# A arte do dono (art/export/enramados) e pixel a pixel, com contorno preto de um pixel,
# reboco creme, madeira castanha e telhado azul. As obras que nao tem arte dele pintam-se
# aqui, uma vez, numa Image — e o mesmo caminho do bestiario (ADR 0049), mas para coisas
# que nao mexem: em vez de mil draw_rect por frame, uma textura que se desenha como as
# outras (BuildingSkins).
#
# Um sprite e uma lista de tracos com a origem nos PES: x para a direita a contar do meio,
# y negativo para cima, como as constantes do resto do mundo. Cada traco e
# [tipo, numeros..., tom]; o tom e um nome da paleta. O contorno e sempre a tinta.
class_name PixelPainter
extends RefCounted

## r rect · o rect com contorno · p poligono com contorno · q poligono sem contorno ·
## l linha · e elipse · E elipse com contorno · a arco (porta, janela) · b tijolos ·
## v tabuas na vertical · h riscas na horizontal · c ameias. O tom e sempre o ultimo, e
## um poligono e uma lista chata de numeros, x e y alternados: cabe numa linha.
const TINTA := "ink"
const MEIO := 0.5
## Os numeros de um traco, pela ordem em que se escrevem: x e y (ou o primeiro ponto), a
## largura e a altura (ou o segundo ponto, ou os raios), e os dois que alguns tem a mais
## (o passo das tabuas, a fiada e a pedra dos tijolos, o merlao e o vao das ameias).
const X := 1
const Y := 2
const W := 3
const H := 4
const K := 5
const L := 6
const QUADRADO := 2.0


## Pinta os tracos numa imagem `tamanho`, com os pes no meio de baixo.
static func paint(tamanho: Vector2i, tracos: Array, paleta: Dictionary) -> Image:
	var img := Image.create_empty(tamanho.x, tamanho.y, false, Image.FORMAT_RGBA8)
	var pes := Vector2i(tamanho.x / 2, tamanho.y)
	for traco: Array in tracos:
		_traco(img, pes, traco, paleta)
	return img


static func _traco(img: Image, pes: Vector2i, t: Array, paleta: Dictionary) -> void:
	var cor: Color = paleta.get(t.back(), Color.MAGENTA)
	var tinta: Color = paleta.get(TINTA, Color.BLACK)
	match String(t[0]):
		"r":
			img.fill_rect(_caixa(pes, t), cor)
		"o":
			var caixa := _caixa(pes, t)
			img.fill_rect(caixa, tinta)
			img.fill_rect(caixa.grow(-1), cor)
		"p", "q":
			var pontos := PackedVector2Array()
			var n: Array = t[X]
			for i in range(0, n.size() - 1, 2):
				pontos.append(Vector2(n[i], n[i + 1]) + Vector2(pes))
			_poligono(img, pontos, cor)
			if t[0] == "p":
				for i in pontos.size():
					_linha(img, pontos[i], pontos[(i + 1) % pontos.size()], tinta)
		"l":
			var de := Vector2(t[X], t[Y]) + Vector2(pes)
			_linha(img, de, Vector2(t[W], t[H]) + Vector2(pes), cor)
		"e", "E":
			var c := Vector2(t[X], t[Y]) + Vector2(pes)
			if t[0] == "E":
				_elipse(img, c, float(t[W]) + 1.0, float(t[H]) + 1.0, tinta)
			_elipse(img, c, t[W], t[H], cor)
		"a":
			var caixa := _caixa(pes, t)
			_arco(img, caixa, tinta)
			_arco(img, caixa.grow(-1), cor)
		"b":
			_tijolos(img, _caixa(pes, t), int(t[K]), int(t[L]), cor)
		"v":
			var caixa := _caixa(pes, t)
			for x in range(caixa.position.x, caixa.end.x, int(t[K])):
				img.fill_rect(Rect2i(x, caixa.position.y, 1, caixa.size.y), cor)
		"h":
			var caixa := _caixa(pes, t)
			for y in range(caixa.position.y, caixa.end.y, int(t[K])):
				img.fill_rect(Rect2i(caixa.position.x, y, caixa.size.x, 1), cor)
		"c":
			_ameias(img, pes, t, cor, tinta)


## [tipo, x, y, largura, altura, ...] em px de imagem.
static func _caixa(pes: Vector2i, t: Array) -> Rect2i:
	return Rect2i(pes.x + int(t[X]), pes.y + int(t[Y]), int(t[W]), int(t[H]))


## Linha a linha, pelo meio de cada pixel: o que fica dentro do poligono pinta-se.
static func _poligono(img: Image, pontos: PackedVector2Array, cor: Color) -> void:
	var cima := INF
	var baixo := -INF
	for p in pontos:
		cima = minf(cima, p.y)
		baixo = maxf(baixo, p.y)
	for y in range(floori(cima), ceili(baixo)):
		var meio := float(y) + MEIO
		var cortes: Array[float] = []
		for i in pontos.size():
			var a := pontos[i]
			var b := pontos[(i + 1) % pontos.size()]
			if (a.y <= meio) != (b.y <= meio):
				cortes.append(a.x + (meio - a.y) / (b.y - a.y) * (b.x - a.x))
		cortes.sort()
		for k in range(0, cortes.size() - 1, 2):
			var de := ceili(cortes[k] - MEIO)
			var ate := floori(cortes[k + 1] - MEIO)
			if ate >= de:
				img.fill_rect(Rect2i(de, y, ate - de + 1, 1), cor)


## Bresenham: um pixel por passo, sem buracos nem pixeis dobrados.
static func _linha(img: Image, de: Vector2, ate: Vector2, cor: Color) -> void:
	var a := Vector2i(de.floor())
	var b := Vector2i(ate.floor())
	var dx := absi(b.x - a.x)
	var dy := -absi(b.y - a.y)
	var sx := 1 if a.x < b.x else -1
	var sy := 1 if a.y < b.y else -1
	var erro := dx + dy
	while true:
		_pixel(img, a, cor)
		if a == b:
			return
		var e2 := erro * 2
		if e2 >= dy:
			erro += dy
			a.x += sx
		if e2 <= dx:
			erro += dx
			a.y += sy


static func _elipse(img: Image, c: Vector2, rx: float, ry: float, cor: Color) -> void:
	for y in range(floori(c.y - ry), ceili(c.y + ry)):
		var v := (float(y) + MEIO - c.y) / ry
		var meia := rx * sqrt(maxf(0.0, 1.0 - v * v))
		var de := roundi(c.x - meia)
		var ate := roundi(c.x + meia)
		if ate > de:
			img.fill_rect(Rect2i(de, y, ate - de, 1), cor)


## Um vao de porta ou janela: um rectangulo com um meio circulo em cima.
static func _arco(img: Image, caixa: Rect2i, cor: Color) -> void:
	var raio := float(caixa.size.x) * MEIO
	for y in caixa.size.y:
		var meia := raio
		if float(y) < raio:
			var d := raio - float(y) - MEIO
			meia = sqrt(maxf(0.0, raio * raio - d * d))
		var de := roundi(float(caixa.position.x) + raio - meia)
		var ate := roundi(float(caixa.position.x) + raio + meia)
		if ate > de:
			img.fill_rect(Rect2i(de, caixa.position.y + y, ate - de, 1), cor)


## As juntas de uma parede de pedra: uma fiada a cada `fiada` px, as juntas desencontradas.
static func _tijolos(img: Image, caixa: Rect2i, fiada: int, pedra: int, cor: Color) -> void:
	var n := 0
	for y in range(caixa.position.y, caixa.end.y, fiada):
		img.fill_rect(Rect2i(caixa.position.x, y, caixa.size.x, 1), cor)
		var desvio := (pedra / 2) * (n % 2)
		for x in range(caixa.position.x + desvio, caixa.end.x, pedra):
			img.fill_rect(Rect2i(x, y, 1, mini(fiada, caixa.end.y - y)), cor)
		n += 1


## [c, x, y, largura, merlao, vao, altura, tom]: os dentes de cima de um muro ou torre.
static func _ameias(img: Image, pes: Vector2i, t: Array, cor: Color, tinta: Color) -> void:
	var x := pes.x + int(t[X])
	var fim := x + int(t[W])
	var merlao := int(t[H])
	var passo := merlao + int(t[K])
	var caixa := Rect2i(0, pes.y + int(t[Y]) - int(t[L]), merlao, int(t[L]) + 1)
	while x + merlao <= fim:
		caixa.position.x = x
		img.fill_rect(caixa, tinta)
		img.fill_rect(caixa.grow(-1), cor)
		x += passo


static func _pixel(img: Image, p: Vector2i, cor: Color) -> void:
	if p.x >= 0 and p.y >= 0 and p.x < img.get_width() and p.y < img.get_height():
		img.set_pixelv(p, cor)
