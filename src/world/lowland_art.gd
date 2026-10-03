# src/world/lowland_art.gd — a terra por cima do corte de solo, em pixeis (§11, §22; o
# pedido do dono de 30/09/2026; ADR 0039).
#
# O Lowland diz o que ha e onde; isto diz como e. Tres faixas de erva que escurecem para
# a frente (a rampa da §11: do topo para a base o detalhe adensa e o valor escurece), a
# terra batida da beira da estrada, os caminhos que descem dela com os rodados, os lagos
# com orla de lodo, fundo, reflexos, nenufares e juncos, e as plantas do Wilds a escala
# da fila em que estao. Violeta nao entra — e da Podridao (§80) — e a agua fica fora das
# duas frias (matiz abaixo de 200°, como o mar do WildEdge).
class_name LowlandArt
extends RefCounted

## As partes da terra, pela ordem em que se pintam (parts).
enum Parte { CHAO, AGUA, MATO }

const AGUA := Color("56716f")
const AGUA_FUNDA := Color("3b5153")
const REFLEXO := Color("a3b6ab")
const NENUFAR := Color("5a6a38")
## Quanto do campo tinge a agua (o alagado e mais verde), e o lodo da orla, da terra ao
## caminho.
const TINGE := 0.15
const LODO := 0.4
## As faixas de erva: onde acaba cada uma (y), a onda das fronteiras e de quantos em
## quantos px se desenha, e quanto escurece cada faixa.
const FAIXAS := {"y": [566.0, 626.0], "onda": 5.0, "passo": 32.0, "escuro": [0.04, 0.16, 0.28]}
const ONDA_F := [0.0113, 0.0047]
## A terra batida que a estrada deixa ver por baixo dela.
const BEIRA := {"alto": 4.0, "escuro": 0.2}
## O caminho: em quantos troços se desenha, quanto escurece o chao dele e a borda, quanto
## clareiam os rodados, o traco, e a que fraccao do meio vai cada rodado.
const CAMINHO := {
	"pontos": 16, "escuro": 0.06, "borda": 0.3, "sulco": 0.12, "traco": 2.0, "rodado": 0.4
}
## O lago: a orla, o fundo (fraccao dos eixos, e quanto desce do centro), e os pontos.
const LAGO := {"orla_x": 6.0, "orla_y": 4.0, "fundo": 0.58, "desce": 0.2, "pontos": 28}
const REFLEXOS := {"quantos": 3, "de": 8.0, "ate": 26.0, "traco": 2.0, "largo": 0.6, "alto": 0.5}
const NENUFARES := {"quantos": 2, "rx": 5.0, "ry": 3.0, "longe": 0.55}
## Os juncos, em fraccao de meia volta pela margem de ca: juntos nas duas pontas, para
## nao taparem a agua. Da escala da fila de tras, porque sao finos.
const JUNCOS := [0.03, 0.1, 0.17, 0.83, 0.9, 0.97]
const LADOS := [-1.0, 1.0]
## Os sorteios de um lago: tres por reflexo (sitio, altura, largura), dois por nenufar.
const SORTEIOS := 24
const POR_REFLEXO := 3
const POR_FOLHA := 2
const PIXEL := 2.0
## Quanto do campo entra na cor de uma planta na fila de tras.
const NEVOA := 0.2
const SAL := 101
const MEIO := 0.5


## O que cada talhao da terra desenha, por parte e pela ordem em que as partes se pintam:
## o chao dos trocos, e por cima dele os caminhos e os lagos, e as plantas por ultimo, para
## nenhuma ficar debaixo do chao do troco seguinte. Uma passagem so pelas coisas todas:
## talhao (Vector3: parte, de, ate) -> o que la cai. O SoilCover desenha cada talhao num
## no seu, e o motor deixa de fora os que estao longe da camara (o dono, 03/10/2026:
## "esta muito lento" — eram 220 draw calls por frame, para a regiao inteira).
static func parts(terra: Dictionary, talhao: float) -> Dictionary:
	var saida := {}
	if terra.is_empty():
		return saida
	var trocos: Array = terra[Lowland.TROCOS]
	for s: Dictionary in trocos:
		var x := floorf(float(s[Lowland.A]) / talhao) * talhao
		while x < float(s[Lowland.B]):
			var corte := Vector2(maxf(s[Lowland.A], x), minf(s[Lowland.B], x + talhao))
			_por(saida, Parte.CHAO, x, talhao).append([s, corte])
			x += talhao
	for c: Vector3 in terra[Lowland.CAMINHOS]:
		_por(saida, Parte.AGUA, c.x, talhao).append([c, Lowland.colors_at(trocos, c.x)])
	for l: Vector4 in terra[Lowland.LAGOS]:
		_por(saida, Parte.AGUA, l.x, talhao).append([l, Lowland.colors_at(trocos, l.x)])
	for lista: PackedFloat32Array in terra[Lowland.PLANTAS]:
		var matos := FloraArt.chunks(lista, talhao)
		for de: float in matos:
			_por(saida, Parte.MATO, de, talhao).append(matos[de])
	return saida


## Um talhao: o que o `parts` lhe deu.
static func draw_part(canvas: CanvasItem, parte: Parte, dados: Array) -> void:
	if parte == Parte.MATO:
		for plantas: PackedFloat32Array in dados:
			plants(canvas, plantas)
		return
	for d: Array in dados:
		if parte == Parte.CHAO:
			_chao(canvas, d[0], d[1])
		elif d[0] is Vector3:
			_caminho(canvas, d[0], d[1])
		else:
			_lago(canvas, d[0], d[1])


static func _talhao(parte: Parte, x: float, talhao: float) -> Vector3:
	var de := floorf(x / talhao) * talhao
	return Vector3(parte, de, de + talhao)


static func _por(saida: Dictionary, parte: Parte, x: float, talhao: float) -> Array:
	var chave := _talhao(parte, x, talhao)
	if not saida.has(chave):
		saida[chave] = []
	return saida[chave]


## As plantas de um troco, de tras para a frente, cada uma a escala da fila dela.
static func plants(canvas: CanvasItem, plantas: PackedFloat32Array) -> void:
	for i in range(0, plantas.size(), Wilds.PLANTA):
		var fundo := plantas[i + 2]
		var pe := Lowland.foot(plantas[i + 1], fundo)
		var variante := plantas[i + Wilds.PLANTA - 1]
		var escala := Lowland.scale_of(fundo)
		var nevoa := EnramadosLayer.FIELD
		FloraArt.draw_one(canvas, int(plantas[i]), pe, variante, nevoa, fundo * NEVOA, escala)
	canvas.draw_set_transform(Vector2.ZERO)


## As tres faixas de erva de um troco, e a beira da estrada por cima delas, so entre
## `corte.x` e `corte.y`: as cores vao de uma ponta do troco a outra, cortado ou nao.
static func _chao(canvas: CanvasItem, s: Dictionary, corte: Vector2) -> void:
	var span := Vector2(s[Lowland.A], s[Lowland.B])
	var esq: Array = s[Lowland.ESQ]
	var dir: Array = s[Lowland.DIR]
	var escuro: Array = FAIXAS.escuro
	for i in escuro.size():
		var pontos := _fronteira(corte, i - 1)
		var baixo := _fronteira(corte, i)
		baixo.reverse()
		pontos.append_array(baixo)
		var c0 := (esq[WildGround.CAMPO] as Color).darkened(escuro[i])
		var c1 := (dir[WildGround.CAMPO] as Color).darkened(escuro[i])
		var cores := PackedColorArray()
		for p in pontos:
			cores.append(c0.lerp(c1, clampf(inverse_lerp(span.x, span.y, p.x), 0.0, 1.0)))
		canvas.draw_polygon(pontos, cores)
	var linha := float(Band.GROUND_LINE)
	var t0 := (esq[WildGround.TERRA] as Color).darkened(BEIRA.escuro)
	var t1 := (dir[WildGround.TERRA] as Color).darkened(BEIRA.escuro)
	var de := t0.lerp(t1, clampf(inverse_lerp(span.x, span.y, corte.x), 0.0, 1.0))
	var ate := t0.lerp(t1, clampf(inverse_lerp(span.x, span.y, corte.y), 0.0, 1.0))
	WildGround.band(canvas, corte, Vector2(linha, linha), linha + BEIRA.alto, de, ate)


## A fronteira de cima da faixa `i + 1`: a linha do chao, uma onda, ou o fundo do ecra.
## Presa ao mundo, para nao dar degrau de um troco para o outro.
static func _fronteira(span: Vector2, i: int) -> PackedVector2Array:
	var saida := PackedVector2Array([Vector2(span.x, _y(span.x, i))])
	var passo: float = FAIXAS.passo
	var x := (floorf(span.x / passo) + 1.0) * passo
	while x < span.y:
		saida.append(Vector2(x, _y(x, i)))
		x += passo
	saida.append(Vector2(span.y, _y(span.y, i)))
	return saida


static func _y(x: float, i: int) -> float:
	var ys: Array = FAIXAS.y
	if i < 0:
		return float(Band.GROUND_LINE)
	if i >= ys.size():
		return float(Band.SCREEN_BOTTOM)
	var onda := sin(x * ONDA_F[0] + float(i)) + sin(x * ONDA_F[1] + float(i)) * MEIO
	return floorf((float(ys[i]) + onda * FAIXAS.onda) / PIXEL) * PIXEL


## Um caminho a descer da estrada, mais largo a frente, com borda e dois rodados.
static func _caminho(canvas: CanvasItem, c: Vector3, cores: Array[Color]) -> void:
	var esquerda := PackedVector2Array()
	var direita := PackedVector2Array()
	var n: int = CAMINHO.pontos
	for i in n + 1:
		var y := lerpf(float(Band.GROUND_LINE), float(Band.SCREEN_BOTTOM), float(i) / float(n))
		var x := LowlandLayout.path_x(c, y)
		var h := LowlandLayout.path_half(y)
		esquerda.append(Vector2(x - h, y))
		direita.append(Vector2(x + h, y))
	var contorno := esquerda.duplicate()
	var volta := direita.duplicate()
	volta.reverse()
	contorno.append_array(volta)
	canvas.draw_colored_polygon(contorno, cores[WildGround.CAMINHO].darkened(CAMINHO.escuro))
	var borda := cores[WildGround.CAMPO].darkened(CAMINHO.borda)
	canvas.draw_polyline(esquerda, borda, CAMINHO.traco)
	canvas.draw_polyline(direita, borda, CAMINHO.traco)
	var claro := cores[WildGround.CAMINHO].lightened(CAMINHO.sulco)
	for lado: float in LADOS:
		var sulco := PackedVector2Array()
		for i in esquerda.size():
			sulco.append(esquerda[i].lerp(direita[i], MEIO + lado * CAMINHO.rodado * MEIO))
		canvas.draw_polyline(sulco, claro, CAMINHO.traco)


## Um lago: a orla de lodo, a agua, o fundo mais escuro, os reflexos, os nenufares e os
## juncos da margem de ca.
static func _lago(canvas: CanvasItem, l: Vector4, cores: Array[Color]) -> void:
	var centro := Vector2(l.x, l.y)
	var raio := Vector2(l.z, l.w)
	var orla := raio + Vector2(LAGO.orla_x, LAGO.orla_y)
	var lodo := cores[WildGround.TERRA].lerp(cores[WildGround.CAMINHO], LODO)
	canvas.draw_colored_polygon(_elipse(centro, orla), lodo)
	canvas.draw_colored_polygon(_elipse(centro, raio), AGUA.lerp(cores[WildGround.CAMPO], TINGE))
	var fundo := centro + Vector2(0.0, raio.y * LAGO.desce)
	canvas.draw_colored_polygon(_elipse(fundo, raio * LAGO.fundo), AGUA_FUNDA)
	var d := RngService.scatter(hash([SAL, l.x, l.y]), SORTEIOS)
	var k := 0
	for r in REFLEXOS.quantos:
		var x := centro.x + (d[k] - MEIO) * raio.x * REFLEXOS.largo
		var y := floorf(centro.y + (d[k + 1] - MEIO) * raio.y * REFLEXOS.alto)
		var meia := lerpf(REFLEXOS.de, REFLEXOS.ate, d[k + 2]) * MEIO
		canvas.draw_line(Vector2(x - meia, y), Vector2(x + meia, y), REFLEXO, REFLEXOS.traco)
		k += POR_REFLEXO
	for f in NENUFARES.quantos:
		var sitio := Vector2(d[k] - MEIO, d[k + 1] - MEIO) * raio * NENUFARES.longe + centro
		var folha := Vector2(NENUFARES.rx, NENUFARES.ry)
		canvas.draw_rect(Rect2((sitio / PIXEL).floor() * PIXEL - folha * MEIO, folha), NENUFAR)
		k += POR_FOLHA
	var escala: float = Lowland.ESCALAS[Lowland.ESCALAS.size() - 1]
	for j in JUNCOS.size():
		var a := PI * float(JUNCOS[j])
		var pe := (centro + Vector2(cos(a) * orla.x, sin(a) * orla.y)).floor()
		FloraArt.draw_one(canvas, Wilds.Plant.REED, pe, d[k + j], EnramadosLayer.FIELD, 0.0, escala)
	canvas.draw_set_transform(Vector2.ZERO)


## Uma elipse em pixeis de arte: os pontos caem na grelha de 2 px, sem repetidos.
static func _elipse(c: Vector2, r: Vector2) -> PackedVector2Array:
	var saida := PackedVector2Array()
	var n: int = LAGO.pontos
	for i in n:
		var a := TAU * float(i) / float(n)
		var p := ((c + Vector2(cos(a) * r.x, sin(a) * r.y)) / PIXEL).floor() * PIXEL
		if saida.is_empty() or p != saida[saida.size() - 1]:
			saida.append(p)
	if saida.size() > 1 and saida[0] == saida[saida.size() - 1]:
		saida.remove_at(saida.size() - 1)
	return saida
