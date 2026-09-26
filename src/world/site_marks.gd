# src/world/site_marks.gd — as marcas que dizem em que ponto esta uma obra.
#
# Formas, e nao so cor (planejamento 26/09, §6 lote 3; 19/09, §7.5): as moedas
# ja pagas sao discos cheios e as que faltam sao aneis, pousados na base — que e
# onde a moeda cai (§55); o que falta erguer leva andaime; quem trabalha levanta
# lascas no topo do que ja esta de pe; o dano sao fissuras, mais quanto mais
# fundo. O SiteStage diz o ponto; isto desenha-o, igual para qualquer obra.
class_name SiteMarks
extends RefCounted

## Mais moedas do que isto e cada disco passa a valer varias.
const MAX_DISCOS := 12
const PASSO_DISCO := 8.0
const ALTURA_DISCOS := 6.0
const VIGA := 3.0
const ESPACO_VIGA := 32.0
const FISSURAS := [Vector2(0.30, 0.35), Vector2(0.66, 0.52), Vector2(0.44, 0.72)]
const FISSURA := 0.12
const FISSURA_MIN := 6.0
const LASCAS := 3
const LASCA := Vector2(3.0, 3.0)
const LASCA_S := 0.25
const MADEIRA := Color("776343")
const PEDRA_ESCURA := Color("3b3326")
const LASCA_COR := Color("e7c587")
## O emblema de uma casa de conversao, por cima dela: um disco de moeda quando
## vende, uma seta quando da capacidade — cheia a correr, vazia a espera.
const EMBLEMA_ALTURA := 14.0
const EMBLEMA := 5.0
## Quanto tempo o progresso parado ainda conta como trabalho: o tick e 30 Hz e o
## ecra 60, e sem folga a obra piscava entre "a trabalhar" e "a espera".
const FOLGA_TRABALHO := 0.5

static var _visto: Dictionary = {}


## Se alguem trabalhou esta obra ha menos de FOLGA_TRABALHO: o progresso ou a
## vida subiram desde o ultimo frame. Le o slot; nao o muda.
static func working(vaga: BuildSlot, tempo: float) -> bool:
	var marca := Vector3(vaga.level, vaga.progress, vaga.health)
	var antes: Array = _visto.get(vaga.id, [marca, -INF])
	var ate: float = antes[1]
	if marca.x > antes[0].x or marca.y > antes[0].y or marca.z > antes[0].z:
		ate = tempo + FOLGA_TRABALHO
	_visto[vaga.id] = [marca, ate]
	return tempo < ate


## As moedas do degrau (ou da reparacao) que se paga agora, na base da obra.
static func coins(canvas: CanvasItem, pe: Vector2, pagas: int, custo: int, luz: Color) -> void:
	if custo <= 0 or pagas <= 0:
		return
	var valor := ceili(float(custo) / MAX_DISCOS)
	var discos := ceili(float(custo) / valor)
	var cheios := mini(discos, floori(float(pagas) / valor))
	var inicio := pe.x - (discos - 1) * PASSO_DISCO * WorldPalette.MEIA
	for k in discos:
		var centro := Vector2(inicio + k * PASSO_DISCO, pe.y - ALTURA_DISCOS)
		if k < cheios:
			canvas.draw_circle(centro, WorldPalette.MOEDA_R, WorldPalette.MOEDA * luz)
		else:
			canvas.draw_arc(
				centro, WorldPalette.MOEDA_R, 0.0, TAU, 12, WorldPalette.MOEDA * luz, 1.0
			)


## Andaime sobre o que falta erguer: `erguido` (0..1) da caixa, de baixo para
## cima, esta feito; o resto leva prumos, a travessa do ponto a que se chegou e
## uma diagonal. Com `a_trabalhar`, lascas no topo do que ja esta de pe.
static func scaffold(
	canvas: CanvasItem, caixa: Rect2, erguido: float, luz: Color, tempo: float, a_trabalhar: bool
) -> void:
	var cor := MADEIRA * luz
	var nivel := caixa.end.y - caixa.size.y * clampf(erguido, 0.0, 1.0)
	for x in range(int(caixa.position.x), int(caixa.end.x) + 1, int(ESPACO_VIGA)):
		canvas.draw_line(Vector2(x, caixa.end.y), Vector2(x, caixa.position.y), cor, VIGA)
	canvas.draw_line(Vector2(caixa.position.x, nivel), Vector2(caixa.end.x, nivel), cor, VIGA)
	canvas.draw_line(
		Vector2(caixa.position.x, caixa.position.y),
		Vector2(caixa.end.x, caixa.position.y),
		cor,
		VIGA
	)
	canvas.draw_line(
		Vector2(caixa.position.x, nivel), Vector2(caixa.end.x, caixa.position.y), cor, VIGA
	)
	if a_trabalhar:
		_lascas(canvas, Vector2(caixa.position.x, nivel), caixa.size.x, luz, tempo)


## Fissuras pela fraccao da vida perdida: uma ate um terco, tres a partir de dois.
static func cracks(canvas: CanvasItem, caixa: Rect2, perdida: float, luz: Color) -> void:
	if perdida <= 0.0:
		return
	var quantas := clampi(ceili(perdida * FISSURAS.size()), 1, FISSURAS.size())
	var tamanho := maxf(FISSURA_MIN, minf(caixa.size.x, caixa.size.y) * FISSURA)
	for k in quantas:
		var p: Vector2 = caixa.position + caixa.size * FISSURAS[k]
		var linha := PackedVector2Array(
			[
				p - Vector2(tamanho * WorldPalette.MEIA, tamanho),
				p,
				p + Vector2(-tamanho * WorldPalette.MEIA, tamanho),
				p + Vector2(tamanho * WorldPalette.MEIA, tamanho * 1.5),
			]
		)
		canvas.draw_polyline(linha, PEDRA_ESCURA * luz, VIGA)


## Reparo de uma obra de pe: dois prumos encostados aos lados e a travessa na
## altura da vida que ja tem — sobe a medida que a obra e reparada.
static func braces(
	canvas: CanvasItem, caixa: Rect2, vida: float, luz: Color, tempo: float, a_trabalhar: bool
) -> void:
	var cor := MADEIRA * luz
	var nivel := caixa.end.y - caixa.size.y * clampf(vida, 0.0, 1.0)
	for x in [caixa.position.x, caixa.end.x]:
		canvas.draw_line(Vector2(x, caixa.end.y), Vector2(x, caixa.position.y), cor, VIGA)
	canvas.draw_line(Vector2(caixa.position.x, nivel), Vector2(caixa.end.x, nivel), cor, VIGA)
	if a_trabalhar:
		_lascas(canvas, Vector2(caixa.position.x, nivel), caixa.size.x, luz, tempo)


static func _lascas(
	canvas: CanvasItem, canto: Vector2, largura: float, luz: Color, t: float
) -> void:
	var fase := int(t / LASCA_S)
	for k in LASCAS:
		var x := canto.x + largura * (float(k) + 0.5) / LASCAS
		var salto := float((fase + k) % 2) * LASCA.y
		canvas.draw_rect(Rect2(Vector2(x, canto.y - LASCA.y - salto), LASCA), LASCA_COR * luz)


## O que uma casa de conversao faz agora (ConversionSystem.status), por forma:
## disco = vende; seta cheia = capacidade a correr; seta vazia = escolhida e sem
## efeito. Sem oficio, vende e mostra a seta vazia ao lado do disco.
static func emblem(
	canvas: CanvasItem, caixa: Rect2, estado: ConversionSystem.Status, luz: Color
) -> void:
	if estado == ConversionSystem.Status.NONE:
		return
	var centro := Vector2(caixa.get_center().x, caixa.position.y - EMBLEMA_ALTURA)
	var vende := estado in [ConversionSystem.Status.COIN, ConversionSystem.Status.WANTS_CRAFT]
	var seta := centro
	if vende:
		canvas.draw_circle(centro, EMBLEMA, WorldPalette.MOEDA * luz)
		seta += Vector2(EMBLEMA * 3.0, 0.0)
	if estado == ConversionSystem.Status.COIN:
		return
	var pontos := PackedVector2Array(
		[
			seta + Vector2(-EMBLEMA, EMBLEMA),
			seta + Vector2(0.0, -EMBLEMA),
			seta + Vector2(EMBLEMA, EMBLEMA),
		]
	)
	if estado == ConversionSystem.Status.ACTIVE:
		canvas.draw_colored_polygon(pontos, WorldPalette.VIDA * luz)
	else:
		pontos.append(pontos[0])
		canvas.draw_polyline(pontos, WorldPalette.VIDA * luz, 1.0)
