# src/world/under_art.gd — os sitios do subsolo, escavados na terra (o pedido do dono de
# 02/10/2026; §11; Q-186, ADR 0046).
#
# Por baixo da regiao e das terras ha terra maciça (RootCellars, WildTunnel). Isto
# escava nela os sitios que ja nasceram (UndergroundSites): cada sala com a abobada, o
# chao e o recheio do tipo dela (UnderProps), um pilar entre cada duas, e nas pontas uma
# parede de rocha — e o que diz, sem palavras, que o sitio acaba ali. A entrada leva o
# que a boca pede: a escora com a lanterna no porao de uma passagem, a camara do arco
# caido na masmorra. O poco ate a superficie e da PassageArt.
class_name UnderArt
extends RefCounted

## A parede e a aresta da abobada de cada tipo de sitio.
const PAREDES := {
	UndergroundSites.CELLAR: [RootCellars.WALL, RootCellars.VAULT],
	UndergroundSites.HATCH: [Color("4b3a2c"), Color("b08a4a")],
	UndergroundSites.DUNGEON: [Color("3f3e39"), Color("85826f")],
}
## A parede de rocha que fecha o sitio: a grossura, quanto o dente entra e quantos dentes.
const FECHO := {"largo": 16.0, "dente": 6.0, "dentes": 6}
const PAR := 2
## De que lado da parede fica o sitio: a direita dela na ponta de la, a esquerda na de ca.
const DIREITA := 1.0
const ESQUERDA := -1.0


## Os sitios gerados, por cima da terra.
static func draw(canvas: CanvasItem, sitios: UndergroundSites) -> void:
	var chao := WorldPalette.ground_of(int(Band.Kind.UNDERGROUND))
	for i in sitios.count():
		if not sitios.generated(i):
			continue
		var cores: Array = PAREDES.get(sitios.kind_of(i), PAREDES[UndergroundSites.CELLAR])
		var salas := sitios.rooms(i)
		for sala: Dictionary in salas:
			var a: float = sala[UndergroundSites.A]
			var b: float = sala[UndergroundSites.B]
			RootCellars.vault(canvas, a, b, cores[0], cores[1])
			RootCellars.floor_strip(canvas, a, b)
			UnderProps.draw(canvas, sala, chao)
		for k in range(1, salas.size()):
			RootCellars.pillar(canvas, salas[k][UndergroundSites.A])
		_entrada(canvas, sitios, i, chao)
		var lim := sitios.span(i)
		_fecho(canvas, lim.x, DIREITA)
		_fecho(canvas, lim.y, ESQUERDA)


static func _entrada(canvas: CanvasItem, sitios: UndergroundSites, i: int, chao: float) -> void:
	var boca := sitios.mouth_of(i)
	match sitios.kind_of(i):
		UndergroundSites.CELLAR:
			RootCellars.shoring(canvas, boca)
		UndergroundSites.DUNGEON:
			ShapeArt.draw(canvas, WildTunnel.CAMARA, Vector2(boca, chao))


## A parede de rocha numa ponta do sitio. `dentro` e +1 se o sitio fica a direita de `x`.
static func _fecho(canvas: CanvasItem, x: float, dentro: float) -> void:
	var topo := RootCellars.TOP
	var fundo := RootCellars.FLOOR_Y
	var largo: float = FECHO.largo
	var n: int = FECHO.dentes
	var face := PackedVector2Array([Vector2(x - dentro * largo, topo), Vector2(x, topo)])
	for k in range(1, n):
		var y := lerpf(topo, fundo, float(k) / float(n))
		var dente := FECHO.dente * dentro if k % PAR == 1 else 0.0
		face.append(Vector2(x + dente, y))
	face.append(Vector2(x, fundo))
	face.append(Vector2(x - dentro * largo, fundo))
	canvas.draw_colored_polygon(face, RootCellars.ROCK)
	canvas.draw_polyline(face.slice(1, face.size() - 1), RootCellars.ROCK_LIGHT, 1.0)
