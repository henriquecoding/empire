# src/world/root_cellars.gd — o corte do subsolo dos Enramados (§11, §25 10:00).
#
# "A maior parte do corte e terra" (§11), e o dono a 02/10/2026: "o subsolo nao e
# infinito acompanhando o piso de cima, e sempre algo delimitado" (Q-186, ADR 0046).
# Por isso a regiao, por baixo, e terra maciça: as raizes do castelo-arvore a descer no
# meio, arcos de pedra antiga meio enterrados (os segredos do §17) e a rocha de baixo
# em estratos. As salas so existem onde ha um sitio (UndergroundSites), e quem as
# escava e a UnderArt, com as pecas daqui: a abobada, o pilar, o chao, a escora e o
# lume de cogumelos.
#
# Coordenadas de mundo, como o resto do segmento autorado.
class_name RootCellars
extends RefCounted

const WALL := Color("463b2b")
const WALL_FAR := Color("1c1813")
const VAULT := Color("8a734f")
const ROCK := Color("6a583d")
const ROCK_LIGHT := Color("9a8360")
const FLOOR := Color("8b7552")
const PEBBLE := Color("8a7757")
const STRATA := [Color("3a3024"), Color("30281e"), Color("281f17")]
const ROOT := Color("5c4128")
const ROOT_LIGHT := Color("7a5936")
const TIMBER := Color("6e4a2a")
const LANTERN := Color("f2b35a")
const GLOW := Color(0.95, 0.70, 0.35, 0.18)
const SHROOM := Color("9fd4c3")
const SHROOM_GLOW := Color(0.62, 0.86, 0.78, 0.16)
const STONE := Color("8b8570")
const STONE_DARK := Color("5d594a")

## A faixa: do tecto da cave ao chao onde se anda, e dai ao fundo do ecra.
const TOP := 524.0
const FLOOR_Y := 620.0
const BOTTOM := 720.0
const HALF := 0.5

## A terra maciça e os torroes dela: de quantos em quantos px, o ciclo e o tamanho.
const EARTH := Color("4a3b29")
const CLOD := Color("3e3222")
const CLODS := {"passo": 53.0, "ciclo": 7, "w": 9.0, "h": 4.0, "alto": 11.0}
const VAULT_RISE := 30.0
const VAULT_POINTS := 10
## As pedras da parede do fundo, em cada abobada: onde (fraccao da largura e px
## acima do chao) e de que tamanho. Poucas, e diferentes umas das outras.
const STONES := [0.18, 22.0, 18.0, 9.0, 0.46, 44.0, 24.0, 11.0, 0.71, 17.0, 14.0, 8.0]
const STONE_WALL := Color("544834")
## Cada pedra sao quatro numeros: x, altura, largura, alto.
const STONE_FIELDS := 4
const STONE_H := 3
const DOUBLE := 2.0
const SIDES := [-1.0, 1.0]
## O chao da cave aquece perto do chao, onde o lume bate.
const WARM := Color(0.85, 0.60, 0.32, 0.10)
const WARM_H := 26.0
const PILLAR := {"w": 14.0, "cap": 22.0, "cap_h": 6.0, "edge": 3.0}

## As raizes do castelo: quantas, quanto se abrem a partir do nucleo, e o traco.
const CORE_ROOTS := {"quantas": 7, "leque": 260.0, "fundo": 600.0, "traco": 9.0, "fino": 4.0}
const CORE_ROOT_BEND := [0.0, 0.35, 0.7, 1.0]
const STRAY_ROOTS := [120.0, 540.0, 1310.0, 2480.0, 3120.0, 3660.0]
const STRAY_DROP := [34.0, 22.0, 40.0, 28.0, 46.0, 24.0]

## A escora de cada passagem e a lanterna pendurada nela.
const SHORING := {"meia": 34.0, "poste": 8.0, "verga": 10.0, "lanterna": 5.0, "halo": 26.0}

## Os arcos de pedra antiga, afastados do nucleo (em px a contar dele).
const RUINS := [-1500.0, 1380.0]
const RUIN := {"meia": 30.0, "alto": 62.0, "traco": 6.0, "chave": 9.0}

## O cogumelo que da o lume da cave.
const CAP := {"raio": 4.0, "haste": 5.0, "irmao": 7.0, "halo": 18.0}

## O chao da cave e as pedras soltas nele: de quantos em quantos px, e o salto.
const PEBBLES := {"passo": 37.0, "ciclo": 5, "w": 5.0, "h": 3.0, "alto": 2.0}
const FLOOR_H := 5.0
const STRATA_H := [22.0, 30.0, 48.0]
const STRATA_WAVE := {"passo": 64.0, "alto": 4.0}


static func draw(canvas: CanvasItem, width: float) -> void:
	var core := width * HALF
	canvas.draw_rect(Rect2(0.0, TOP, width, FLOOR_Y - TOP), EARTH)
	_clods(canvas, width)
	for x in RUINS:
		_ruin(canvas, core + x)
	_core_roots(canvas, core)
	_stray_roots(canvas)
	bedrock(canvas, Vector2(0.0, width))


## Uma sala escavada de `a` a `b`: a parede do fundo com o arco da abobada e as pedras.
## A UnderArt chama-a por sala; `wall` e `edge` sao as cores do sitio (porao ou masmorra).
static func vault(canvas: CanvasItem, a: float, b: float, wall: Color, edge: Color) -> void:
	var w := b - a
	canvas.draw_rect(Rect2(a, TOP, w, FLOOR_Y - TOP), WALL_FAR)
	var arco := PackedVector2Array([Vector2(a, FLOOR_Y)])
	for p in VAULT_POINTS + 1:
		var t := float(p) / VAULT_POINTS
		arco.append(Vector2(a + w * t, TOP + VAULT_RISE * (1.0 - sin(t * PI))))
	arco.append(Vector2(b, FLOOR_Y))
	canvas.draw_colored_polygon(arco, wall)
	for s in range(0, STONES.size(), STONE_FIELDS):
		var pedra := Rect2(
			a + w * float(STONES[s]),
			FLOOR_Y - float(STONES[s + 1]),
			STONES[s + 2],
			STONES[s + STONE_H]
		)
		canvas.draw_rect(pedra, STONE_WALL)
	canvas.draw_polyline(arco.slice(1, arco.size() - 1), edge, PILLAR.edge)


## O pilar de pedra entre duas salas, ou na boca de uma.
static func pillar(canvas: CanvasItem, x: float) -> void:
	var corpo := Rect2(x - PILLAR.w * HALF, TOP, PILLAR.w, FLOOR_Y - TOP)
	canvas.draw_rect(corpo, ROCK)
	canvas.draw_rect(Rect2(corpo.position, Vector2(PILLAR.edge, corpo.size.y)), ROCK_LIGHT)
	var capitel := Rect2(x - PILLAR.cap * HALF, TOP, PILLAR.cap, PILLAR.cap_h)
	canvas.draw_rect(capitel, ROCK_LIGHT)
	canvas.draw_rect(
		Rect2(capitel.position.x, FLOOR_Y - PILLAR.cap_h, PILLAR.cap, PILLAR.cap_h), ROCK
	)


## As raizes do castelo-arvore: grossas, em leque a partir do nucleo, ate ao chao.
static func _core_roots(canvas: CanvasItem, core: float) -> void:
	var n: int = CORE_ROOTS.quantas
	for i in n:
		var t := float(i) / float(n - 1) - HALF
		var pe := core + t * CORE_ROOTS.leque * DOUBLE
		var raiz := PackedVector2Array()
		for b in CORE_ROOT_BEND:
			var s := float(b)
			raiz.append(
				Vector2(
					lerpf(core + t * CORE_ROOTS.leque * HALF, pe, s),
					lerpf(TOP, CORE_ROOTS.fundo, s)
				)
			)
		var traco := lerpf(CORE_ROOTS.traco, CORE_ROOTS.fino, absf(t) * DOUBLE)
		canvas.draw_polyline(raiz, ROOT, traco)
		canvas.draw_polyline(raiz, ROOT_LIGHT, maxf(1.0, traco * HALF * HALF))


static func _stray_roots(canvas: CanvasItem) -> void:
	for i in STRAY_ROOTS.size():
		var x: float = STRAY_ROOTS[i]
		var fundo := TOP + float(STRAY_DROP[i])
		canvas.draw_line(Vector2(x, TOP), Vector2(x + CAP.irmao, fundo), ROOT, CORE_ROOTS.fino)


## Uma escora de mina a volta da passagem, e a lanterna que a mostra de longe.
static func shoring(canvas: CanvasItem, x: float) -> void:
	var meia: float = SHORING.meia
	for lado in SIDES:
		var poste := Rect2(
			x + lado * meia - SHORING.poste * HALF, TOP, SHORING.poste, FLOOR_Y - TOP
		)
		canvas.draw_rect(poste, TIMBER)
	canvas.draw_rect(
		Rect2(x - meia - SHORING.poste, TOP, (meia + SHORING.poste) * DOUBLE, SHORING.verga), TIMBER
	)
	var lume := Vector2(x + meia, TOP + SHORING.verga * DOUBLE)
	canvas.draw_circle(lume, SHORING.halo, GLOW)
	canvas.draw_circle(lume, SHORING.lanterna, LANTERN)


## Um arco de pedra antiga, meio enterrado: nao e obra tua, e e por isso que tem
## outra pedra e outra forma (§17: "ha coisas escondidas").
static func _ruin(canvas: CanvasItem, x: float) -> void:
	var meia: float = RUIN.meia
	var topo := FLOOR_Y - RUIN.alto
	var arco := PackedVector2Array()
	for p in VAULT_POINTS + 1:
		var a := PI + PI * float(p) / VAULT_POINTS
		arco.append(Vector2(x + cos(a) * meia, topo + meia + sin(a) * meia))
	canvas.draw_line(
		Vector2(x - meia, topo + meia), Vector2(x - meia, FLOOR_Y), STONE_DARK, RUIN.traco
	)
	canvas.draw_line(
		Vector2(x + meia, topo + meia), Vector2(x + meia, FLOOR_Y), STONE_DARK, RUIN.traco
	)
	canvas.draw_polyline(arco, STONE, RUIN.traco)
	canvas.draw_rect(
		Rect2(x - RUIN.chave * HALF, topo - RUIN.chave * HALF, RUIN.chave, RUIN.chave), STONE
	)


## Um par de cogumelos com o lume deles, no chao de uma sala.
static func shroom(canvas: CanvasItem, x: float) -> void:
	var pe := Vector2(x, FLOOR_Y)
	canvas.draw_circle(pe - Vector2(0.0, CAP.haste), CAP.halo, SHROOM_GLOW)
	for dx in [0.0, CAP.irmao]:
		var chapeu := pe + Vector2(dx, -CAP.haste - float(dx) * HALF)
		canvas.draw_line(pe + Vector2(dx, 0.0), chapeu, PEBBLE, 1.0)
		canvas.draw_circle(chapeu, CAP.raio, SHROOM)


## O chao de uma sala, de `a` a `b`, com o lume a aquece-lo e pedra solta: e a linha
## que se pisa la em baixo (§11).
static func floor_strip(canvas: CanvasItem, a: float, b: float) -> void:
	canvas.draw_rect(Rect2(a, FLOOR_Y - WARM_H, b - a, WARM_H), WARM)
	canvas.draw_rect(Rect2(a, FLOOR_Y - FLOOR_H * HALF, b - a, FLOOR_H), FLOOR)
	var x := a
	var k := 0
	while x < b - PEBBLES.w:
		var y := FLOOR_Y + float(k % PEBBLES.ciclo) * PEBBLES.alto
		canvas.draw_rect(Rect2(x, y, PEBBLES.w, PEBBLES.h), PEBBLE)
		x += PEBBLES.passo + float(k % PEBBLES.ciclo) * PEBBLES.w
		k += 1


## A rocha de baixo, em estratos com onda — e o fundo que diz que isto e fundo.
static func bedrock(canvas: CanvasItem, span: Vector2) -> void:
	var y := FLOOR_Y + FLOOR_H * HALF
	for i in STRATA.size():
		var h: float = STRATA_H[i] if i < STRATA_H.size() - 1 else BOTTOM - y
		canvas.draw_rect(Rect2(span.x, y, span.y - span.x, h), STRATA[i])
		var onda := PackedVector2Array()
		var x := span.x
		var k := 0
		while x <= span.y:
			onda.append(Vector2(x, y + float(k % 2) * STRATA_WAVE.alto))
			x += STRATA_WAVE.passo
			k += 1
		canvas.draw_polyline(onda, ROCK, 1.0)
		y += h


## Os torroes da terra maciça: e o que a faz ler-se como terra e nao como uma parede.
static func _clods(canvas: CanvasItem, width: float) -> void:
	var x := 0.0
	var k := 0
	while x < width:
		var ciclo: int = CLODS.ciclo
		var y := TOP + CLODS.alto * float(1 + k % ciclo)
		canvas.draw_rect(Rect2(x, y, CLODS.w, CLODS.h), CLOD)
		x += CLODS.passo + float(k % ciclo) * CLODS.w
		k += 1
