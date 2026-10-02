# src/world/hearth_art.gd — a fogueira e o farol, que sao luz (§05, §10, Q-029).
#
# As duas obras com `light_radius` desenhavam-se pela categoria delas — defesa —,
# e por isso eram TORRES: uma fogueira de 32 px de largo saia como uma torre de
# arqueiros de 80 px de alto, e o fogo era um disco pintado por cima de tudo.
# Aqui sao o que sao. A fogueira e um anel de pedras com lenha e uma chama; o
# farol e uma torre de pedra com um braseiro no topo. A chama e emissiva (§80):
# nao leva luz, e ela que a da (flames, num canvas sem luz). A luz que ela da ao
# mundo esta no LightField.
#
# Sem estar de pe nao ha fogo: o sitio vazio e o convite (as pedras e a lenha por
# acender, em fantasma), e a ruina e cinza.
class_name HearthArt
extends RefCounted

const FOGUEIRA := &"campfire"
const PEDRA := Color(0.46, 0.42, 0.37)
const LENHA := Color(0.36, 0.24, 0.14)
const CINZA := Color(0.24, 0.22, 0.2)
const FANTASMA := 0.3
## As pedras do anel, (x, y, largo, alto) a contar do pe, e os dois toros.
const PEDRAS := [
	Rect2(-16, -4, 6, 4),
	Rect2(-10, -6, 6, 6),
	Rect2(-3, -5, 6, 5),
	Rect2(4, -6, 6, 6),
	Rect2(10, -4, 6, 4),
]
const TOROS := [[Vector2(-11, -3), Vector2(9, -10)], [Vector2(11, -3), Vector2(-9, -10)]]
const TORO := 4.0
## O farol: largura da base e do topo, altura, e o braseiro. Greybox (Q-079).
const FAROL := {"base": 44.0, "topo": 28.0, "alto": 118.0, "galeria": 8.0, "braseiro": 14.0}
## O tamanho de cada chama, em vezes a de uma fogueira; a que altura do chao arde a
## da fogueira, e quanto a chama se enterra no braseiro.
const CHAMA := {"fogueira": 1.0, "farol": 1.5, "alto": 6.0, "enterra": 2.0}
## A caixa da fogueira, a contar do pe: e onde pousa o preco.
const CAIXA_FOGUEIRA := Rect2(-16, -24, 32, 24)
## A porta do farol, a contar do pe dele, e quanto a galeria e a porta escurecem.
const PORTA := Rect2(-5, -16, 10, 16)
const SOMBRA := {"galeria": 0.25, "porta": 0.55}
const MEIA := 0.5


static func handles(kind: StringName) -> bool:
	return kind == FOGUEIRA or kind == Lume.FAROL


## A caixa que a obra ocupa no ecra: o preco pousa em cima dela (PriceTag).
static func box(vaga: BuildSlot) -> Rect2:
	var pe := Vector2(vaga.x, WorldPalette.ground_of(int(vaga.band)))
	if vaga.kind == FOGUEIRA:
		return Rect2(pe + CAIXA_FOGUEIRA.position, CAIXA_FOGUEIRA.size)
	var alto: float = FAROL.alto + FAROL.braseiro
	return Rect2(pe + Vector2(-FAROL.base * MEIA, -alto), Vector2(FAROL.base, alto))


## A que altura do chao arde o fogo: e dali que a luz parte (LightField).
static func flame_height(kind: StringName) -> float:
	return FAROL.alto + FAROL.galeria if kind == Lume.FAROL else CHAMA.alto


static func draw_on(canvas: CanvasItem, vaga: BuildSlot, luz: Lighting, tempo: float) -> void:
	var pe := Vector2(vaga.x, WorldPalette.ground_of(int(vaga.band)))
	var aceso := vaga.standing()
	var alfa := 1.0 if aceso or vaga.state == BuildSlot.State.RUIN else FANTASMA
	if vaga.kind == FOGUEIRA:
		_fogueira(canvas, pe, vaga, luz, alfa)
	else:
		_farol(canvas, pe, vaga.x, luz, alfa)
	if aceso:
		Gauge.health(canvas, box(vaga), float(vaga.health) / maxf(1.0, float(vaga.max_health())))
	var etapa := SiteStage.of(vaga, SiteMarks.working(vaga, tempo))
	if etapa in [SiteStage.Stage.WAITING, SiteStage.Stage.WORKING]:
		var lit := luz.body(Color.WHITE, vaga.x)
		var trabalho := SiteMarks.working(vaga, tempo)
		SiteMarks.scaffold(canvas, box(vaga), SiteStage.built(vaga), lit, tempo, trabalho)
	SiteMarks.coins(canvas, pe, vaga.paid, SiteStage.cost_now(vaga), luz.body(Color.WHITE, vaga.x))


## O fogo das que estao de pe nesta faixa. A parte, e num canvas sem luz: as
## obras levam a luz do cenario (BandView), e uma chama nao leva luz nenhuma.
static func flames(canvas: CanvasItem, faixa: int, tempo: float) -> void:
	var cores := WorldLight.fire_stops(SimFactory.rot_profile())
	for vaga in SimLoop.builds.slots:
		if vaga.band != faixa or not handles(vaga.kind) or not vaga.standing():
			continue
		var escala: float = CHAMA.fogueira if vaga.kind == FOGUEIRA else CHAMA.farol
		var pe := Vector2(vaga.x, WorldPalette.ground_of(faixa))
		FlameArt.draw_on(
			canvas, pe - Vector2(0.0, flame_height(vaga.kind) - CHAMA.enterra), escala, cores, tempo
		)


static func _fogueira(
	canvas: CanvasItem, pe: Vector2, vaga: BuildSlot, luz: Lighting, alfa: float
) -> void:
	var ruina := vaga.state == BuildSlot.State.RUIN
	var pedra := luz.body(PEDRA, vaga.x)
	pedra.a *= alfa
	for p: Rect2 in PEDRAS:
		canvas.draw_rect(Rect2(pe + p.position, p.size), pedra)
	var madeira := luz.body(CINZA if ruina else LENHA, vaga.x)
	madeira.a *= alfa
	for toro: Array in TOROS:
		var de: Vector2 = toro[0]
		var ate: Vector2 = toro[1]
		if ruina:
			ate.y = de.y  # a lenha caida, rente ao chao
		canvas.draw_line(pe + de, pe + ate, madeira, TORO)


static func _farol(canvas: CanvasItem, pe: Vector2, x: float, luz: Lighting, alfa: float) -> void:
	var pedra := luz.body(PEDRA, x)
	pedra.a *= alfa
	var meia_base: float = FAROL.base * MEIA
	var meia_topo: float = FAROL.topo * MEIA
	var topo: float = pe.y - FAROL.alto
	var torre := PackedVector2Array(
		[
			Vector2(x - meia_base, pe.y),
			Vector2(x - meia_topo, topo),
			Vector2(x + meia_topo, topo),
			Vector2(x + meia_base, pe.y),
		]
	)
	canvas.draw_colored_polygon(torre, pedra)
	var galeria := Rect2(x - meia_base, topo - FAROL.galeria, FAROL.base, FAROL.galeria)
	canvas.draw_rect(galeria, pedra.darkened(SOMBRA.galeria))
	canvas.draw_rect(
		Rect2(Vector2(x, pe.y) + PORTA.position, PORTA.size), pedra.darkened(SOMBRA.porta)
	)
