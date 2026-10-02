# src/world/band_view.gd — uma faixa desenhada, e a luz que lhe pertence (§11).
#
# Tres instancias, uma por faixa. E o F1-13: o ticket pede "CanvasModulate por
# faixa" e essa e a unica forma que nao existe — o Godot aceita UM
# CanvasModulate por canvas (Q-069).
#
# A luz ja NAO vem do `modulate` do no, e a razao esta no `lighting.gd`: um
# `modulate` multiplica tudo, e nem tudo leva ambiente. O cenario leva, os
# corpos levam a luz que chega ao sitio deles, as LUZES nao levam nada e os
# instrumentos do greybox tambem nao.
#
# Um _draw() por frame, lido do SimLoop. Nao guarda estado nenhum: se o que se
# ve divergir do que se simula, e defeito da simulacao e nao deste ficheiro. E a
# fronteira do §45 levada a serio — "se esta num no, e derivado e descartavel".
#
# O CENARIO ja nao passa por aqui: mudou-se para o TerrainBackdrop, que so
# redesenha quando a luz muda de fase. Aqui fica o que anda — passagens, mancha,
# fogueiras, obras, moedas, bichos e tropa — e por isso o `_draw()` deste
# ficheiro corre a cada frame e o de la, nao.
class_name BandView
extends Node2D


## As obras desta faixa, num canvas que leva a luz do cenario pixel a pixel
## (SceneryLight, ADR 0048): o castelo-arvore tem 750 px de largo, e uma cor so
## para ele inteiro punha-o todo aceso ou todo apagado. Assim a lareira alumia a
## porta e as torres ficam no escuro. Fica por tras do resto da faixa
## (`show_behind_parent`): o que anda passa a frente das obras.
class Obras:
	extends Node2D

	var band := Band.Kind.SURFACE
	var edificios: Dictionary = {}
	var tempo := 0.0
	## Sem luz nenhuma: e o shader que a poe. O corpo sai na cor dele.
	var neutra := Lighting.new()

	func _draw() -> void:
		if SimLoop.state == null:
			return
		Gauge.adiar = true  # a barra nao leva luz: o BandView pinta-a por cima
		BuildView.draw_on(self, band, edificios, neutra, tempo)
		Gauge.adiar = false


## A chama do archote, em vezes a de uma fogueira: arde numa mao.
const ARCHOTE := 0.55

@export var band: Band.Kind = Band.Kind.SURFACE

var _tropas: Dictionary = {}
var _edificios: Dictionary = {}
var _relogio: ClockData
var _podre: RotProfile
var _luz := Lighting.new()
## O tempo do ECRA, e nao o do jogo. Serve o baloico de quem anda e o respirar
## de um bicho — e por isso conta com o frame e nao com o tick (§45: o que esta
## num no e derivado e descartavel).
var _visual_time := 0.0
## O pequeno bounce do §24 (GB-19), criado a pedido: precisa da gravidade do arco.
var _salto: CoinBounce
var _actors: UnitCanvas
var _bichos_vista := CreatureView.new()
var _obras := Obras.new()


func _ready() -> void:
	_tropas = SimFactory.by_id(&"units")
	_edificios = SimFactory.by_id(&"buildings")
	_relogio = Registry.entry(&"economy", &"clock") as ClockData
	_podre = SimFactory.rot_profile()
	_actors = UnitCanvas.new()
	_actors.band = band
	_actors.light = _luz
	_obras.band = band
	_obras.edificios = _edificios
	_obras.show_behind_parent = true
	_obras.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_obras.material = SceneryLight.material(SceneryLight.Depth.GROUND)
	add_child(_obras)
	add_child(_actors)


## O ambiente vinha no `modulate` do no, e um `modulate` multiplica tudo o que o
## no desenha. Multiplicava tres coisas que nao sao a mesma — o cenario, os
## corpos e as LUZES — e a terceira era um defeito: medida numa captura, a
## candeia saia com luminancia 26 contra um ceu de 34, ou seja, a fonte de luz
## ficava mais escura do que o fundo. Agora a luz vive no `Lighting` e cada coisa
## recebe a que lhe pertence (§80).
func _process(delta: float) -> void:
	_visual_time += delta
	var relogio := ClockService.clock
	_luz.light(_relogio, int(band), int(relogio.current_phase()), relogio.phase_progress())
	SceneryLight.refresh(self)
	_obras.tempo = _visual_time
	_obras.queue_redraw()  # antes do pai: as barras que adia sao pintadas por ele
	queue_redraw()
	_actors.time = _visual_time
	_actors.queue_redraw()


func _draw() -> void:
	if SimLoop.state == null:
		return
	if band == Band.Kind.SURFACE:
		_passagens()
		_podridao()
		OfferView.draw_on(self, _luz, _visual_time)  # §75: o prato, a frase e o Zelador
	_fogueiras()
	SiteView.draw_on(self, band, _luz)
	AmargueiroView.draw_on(self, band, _luz)  # §74: o que a noite deixou
	_moedas()
	_criaturas()
	if band == Band.Kind.SURFACE:
		HuntView.draw_on(self, _luz, _visual_time)
	CrownView.draw_on(self, band, _luz, _visual_time)  # a coroa no chao (Q-167)
	MountView.draw_on(self, band, _luz, _visual_time)  # o cavalo de tracao (Q-169)
	# Por ultimo, e de proposito: o preco pousa EM CIMA do que descreve, e um
	# corpo desenhado depois dele tapava-o.
	PriceTag.draw_on(self, band, _tropas, _edificios)
	PassageCue.draw_on(self, band, _visual_time)
	Gauge.flush(self)  # as barras das obras, que nao levam luz (Q-080)


## §11: onde se muda de faixa. Desenhada na superficie porque e de la que se
## desce — e o minuto 10:00 do §25, "o mundo tem um andar de baixo".
func _passagens() -> void:
	PassageArt.draw_on(self, _luz)


## A arte da mancha vive no RotView: a massa, o rasto e a candeia sao um assunto
## so e nao cabiam aqui sem passar as 250 linhas do §28 (F1-17).
func _podridao() -> void:
	RotView.draw_on(self, SimLoop.night.rot, _podre, SimLoop.state.day, _luz, _visual_time)
	RotView.draw_on(self, SimLoop.night.other_rot, _podre, SimLoop.state.day, _luz, _visual_time)
	for record: Dictionary in SimLoop.field.settlements.records.values():
		for x: float in record[&"rifts"]:
			RotView.fissure(self, x, WorldLight.stops(_podre)[2])


## O fogo que e teu: a chama da fogueira e do farol (HearthArt) e a do archote na
## mao de quem se conduz (Q-029). So a chama — a luz que dao ao mundo esta no
## LightField —, e aqui, num canvas sem luz, porque a chama e ela a luz (§80).
func _fogueiras() -> void:
	HearthArt.flames(self, int(band), _visual_time)
	var rei := SimLoop.units.index_of(Assume.driven())
	if rei < 0 or not SimLoop.night.dark.torch.lit() or SimLoop.units.bands[rei] != int(band):
		return
	var mao := Vector2(SimLoop.units.xs[rei], WorldPalette.ground_of(int(band)) - LightField.MAO)
	FlameArt.draw_on(self, mao, ARCHOTE, WorldLight.fire_stops(_podre), _visual_time)


## §24: "Moeda largada — arco parabolico, pequeno bounce e sombra. Isto acontece
## milhares de vezes por partida: e a animacao mais importante do jogo." O arco e
## da simulacao; o que o ecra lhe acrescenta — sair da mao, girar, ressaltar,
## balancar e subir quando e levada — e do CoinBounce, e a moeda (ou a pilha, ou o
## saco) e do CoinArt. O x e sempre o da simulacao (§55).
func _moedas() -> void:
	var moedas := SimLoop.coins
	var curva := SimFactory.curve()
	if _salto == null:
		_salto = CoinBounce.new(curva.coin_gravity_px_s2)
	_salto.forget_except(moedas.ids, _visual_time)
	var chao := WorldPalette.ground_of(int(band))
	var queda := moedas.apex_px() + CoinBounce.MAO
	for i in moedas.count():
		if moedas.bands[i] != int(band):
			continue
		var id := moedas.ids[i]
		var onde := Smoothing.coin(id, moedas.xs[i], moedas.heights[i])
		_salto.observe(id, onde.y, _visual_time, Vector2(onde.x, chao))
		var acima := onde.y + _salto.offset(id, _visual_time)
		if moedas.settled[i] == 0:  # sai da mao e desce ate ao arco (CoinBounce.hand)
			acima += CoinBounce.MAO * CoinBounce.hand(moedas.vys[i], curva.coin_drop_speed_px_s)
		var largo := CoinArt.size_of(moedas.amounts[i]).x
		Shadow.drop(self, onde.x, int(band), largo * WorldPalette.MEIA, acima, queda)
		var brilho := CoinArt.glint(id, _visual_time) if moedas.settled[i] == 1 else 0.0
		var face := _salto.face(id, _visual_time)
		var pe := Vector2(onde.x, chao - acima)
		CoinArt.draw_on(self, pe, moedas.amounts[i], face, CoinArt.lit(_luz, onde.x), brilho)
	for levada: Array in _salto.taken(_visual_time):  # apanhada, ou paga a uma obra
		var subiu: float = levada[1]
		var pe: Vector2 = levada[0] - Vector2(0.0, CoinBounce.LEVADA.sobe * subiu)
		var some := func(c: Color) -> Color: return Color(c, 1.0 - subiu)
		CoinArt.draw_on(self, pe, 1, 1.0, some, 0.0)


## O que a noite traz so se ve dentro de uma luz (ADR 0034); quem o desenha, com
## o golpe, a pele e o contorno, e o CreatureView.
func _criaturas() -> void:
	var luzes := _luzes_da_noite()
	_bichos_vista.draw_on(self, band, _luz, luzes, BandLight.ground_ratio(_relogio), _visual_time)
	ClassEffects.draw_on(self, band)


## As luzes em que se ve, em (x, raio): as tuas e o Lume (LightField). Com a
## mancha recuada e dia, e esta tudo aceso.
func _luzes_da_noite() -> Array[Vector2]:
	if not SimLoop.night.rot.active():
		return [Vector2(0.0, INF)]
	var luzes: Array[Vector2] = []
	for luz in _luz.glows:
		luzes.append(Vector2(luz.center.x, luz.radius))
	return luzes
