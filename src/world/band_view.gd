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

@export var band: Band.Kind = Band.Kind.SURFACE

var _tropas: Dictionary = {}
var _bichos: Dictionary = {}
var _edificios: Dictionary = {}
var _relogio: ClockData
var _podre: RotProfile
var _luz := Lighting.new()
## O tempo do ECRA, e nao o do jogo. Serve o baloico de quem anda e o respirar
## de um bicho — e por isso conta com o frame e nao com o tick (§45: o que esta
## num no e derivado e descartavel).
var _visual_time := 0.0


func _ready() -> void:
	_tropas = SimFactory.by_id(&"units")
	_bichos = SimFactory.by_id(&"creatures")
	_edificios = SimFactory.by_id(&"buildings")
	_relogio = Registry.entry(&"economy", &"clock") as ClockData
	_podre = SimFactory.rot_profile()


## O ambiente vinha no `modulate` do no, e um `modulate` multiplica tudo o que o
## no desenha. Multiplicava tres coisas que nao sao a mesma — o cenario, os
## corpos e as LUZES — e a terceira era um defeito: medida numa captura, a
## candeia saia com luminancia 26 contra um ceu de 34, ou seja, a fonte de luz
## ficava mais escura do que o fundo. Agora a luz vive no `Lighting` e cada coisa
## recebe a que lhe pertence (§80).
func _process(delta: float) -> void:
	_visual_time += delta
	var relogio := ClockService.clock
	_luz.set_phase(_relogio, int(relogio.current_phase()), relogio.phase_progress())
	var rot := SimLoop.night.rot if SimLoop.state != null else null
	if rot != null and rot.active():
		var raio := WorldLight.radius(_podre, SimLoop.state.day)
		_luz.set_lamp(rot.position_x(), raio, WorldLight.stops(_podre)[WorldLight.PARAGENS - 1])
	else:
		_luz.clear_lamp()
	queue_redraw()


func _draw() -> void:
	if SimLoop.state == null:
		return
	if band == Band.Kind.SURFACE:
		_passagens()
		_podridao()
	_fogueiras()
	SiteView.draw_on(self, band, _luz)
	BuildView.draw_on(self, band, _edificios, _luz)
	AmargueiroView.draw_on(self, band, _luz)
	_moedas()
	_criaturas()
	_tropa()
	# Por ultimo, e de proposito: o preco pousa EM CIMA do que descreve, e um
	# corpo desenhado depois dele tapava-o.
	PriceTag.draw_on(self, band, _tropas, _edificios)
	if band == Band.Kind.SURFACE:
		OfferView.draw_on(self, _luz)


## §11: onde se muda de faixa. Desenhada na superficie porque e de la que se
## desce — e o minuto 10:00 do §25, "o mundo tem um andar de baixo".
func _passagens() -> void:
	var topo := WorldPalette.ground_of(int(Band.Kind.SURFACE))
	var fundo := WorldPalette.ground_of(int(Band.Kind.UNDERGROUND))
	var largura := WorldPalette.PASSAGEM_W
	for x in SimLoop.passages:
		var canto := Vector2(x - largura * WorldPalette.MEIA, topo)
		var cor := WorldPalette.tint(WorldPalette.PASSAGEM, _luz.scenery(1.0))
		draw_rect(Rect2(canto, Vector2(largura, fundo - topo)), cor)


## A arte da mancha vive no RotView: a massa, o rasto e a candeia sao um assunto
## so e nao cabiam aqui sem passar as 250 linhas do §28 (F1-17).
func _podridao() -> void:
	RotView.draw_on(self, SimLoop.night.rot, _podre, SimLoop.state.day, _luz)


## As luzes que sao tuas (§10, coluna `light_radius`). Hoje so o farol tem uma, e
## ele e da Fase 6 — por isso isto e um ciclo sobre um conjunto vazio, que e a
## ausencia dele e nao um esquecimento. Levam as MESMAS tres paragens: o §80 da
## uma regra de luz ao jogo inteiro, e nao uma por fonte.
func _fogueiras() -> void:
	var cores := WorldLight.stops(_podre)
	for vaga in SimLoop.builds.slots:
		var raio := WorldLight.hearth_radius(vaga)
		if vaga.band != band or raio <= 0.0:
			continue
		RotView.lamp(self, Vector2(vaga.x, WorldPalette.ground_of(int(vaga.band))), raio, cores)


## §24: "Moeda largada — arco parabolico, pequeno bounce e sombra. Isto acontece
## milhares de vezes por partida: e a animacao mais importante do jogo." O arco
## ja ca estava; a sombra e o que faz dele um arco e nao dois circulos.
func _moedas() -> void:
	var moedas := SimLoop.coins
	var apice := moedas.apex_px()
	for i in moedas.count():
		if moedas.bands[i] != int(band):
			continue
		Shadow.drop(self, moedas.xs[i], int(band), WorldPalette.MOEDA_R, moedas.heights[i], apice)
		var y := WorldPalette.ground_of(int(band)) - moedas.heights[i] - WorldPalette.MOEDA_R
		var cor := _luz.body(WorldPalette.MOEDA, moedas.xs[i])
		draw_circle(Vector2(moedas.xs[i], y), WorldPalette.MOEDA_R, cor)


## §74, a frase que faz da candeia mecanica e nao decoracao: "dentro do raio
## ve-se o que a Podridao invocou; fora, nao". Fora dela o corpo e silhueta — a
## mesma cor com a luz que chega ao chao (§80), e nao uma cor nova.
func _criaturas() -> void:
	var bichos := SimLoop.creatures
	var candeia := _candeeiro()
	var chao := BandLight.ground_ratio(_relogio)
	for i in bichos.count():
		if bichos.bands[i] != int(band):
			continue
		var dados: CreatureData = _bichos.get(bichos.data_ids[i])
		if dados == null:
			continue
		# A forma e o porte sao a diferenca entre "vem ai uma coisa" e "vem ai um
		# Ariete de lodo, e eu tenho o muro do lado errado" (§07, §51).
		var forma := Silhouette.of_creature(dados)
		var alto := WorldPalette.DEGRAU * maxi(1, dados.scale_tier)
		var caixa := Silhouette.body_box(forma, bichos.xs[i], int(band), alto)
		var aceso := WorldLight.lit(bichos.xs[i], candeia.x, candeia.y)
		var corpo := _luz.body(WorldPalette.BICHO, bichos.xs[i])
		var cor := WorldLight.reveal(corpo, aceso, chao)
		draw_colored_polygon(Outline.shape(forma, caixa, 0), cor)
		CreatureArt.draw_on(self, caixa, forma, cor, _visual_time)
		if aceso:
			Gauge.health(
				self, caixa, float(bichos.healths[i]) / maxf(1.0, float(bichos.max_healths[i]))
			)


## Onde esta a candeia e que raio tem, em (x, raio). Com a mancha recuada nao ha
## luz nenhuma no campo — e entao esta tudo aceso, porque e dia.
func _candeeiro() -> Vector2:
	var rot := SimLoop.night.rot
	if not rot.active():
		return Vector2(0.0, INF)
	return Vector2(rot.position_x(), WorldLight.radius(_podre, SimLoop.state.day))


## O corpo de uma tropa e o mesmo rectangulo de sempre — uma pessoa e uma
## pessoa. O que a distingue de outra e a ARMA, e e de proposito: o §08 diz que
## os arquetipos sao "mesma funcao, corpo e silhueta diferentes" por POVO, e nao
## por classe. Aqui ha um povo so, e por isso o que resta e o que ela leva.
## A tropa. A caixa continua a ser a do §22 — e dela que sai a silhueta — e o
## que a enche e o ActorArt: corpo, cara, chapeu e a marca da mao, na COR DO
## CORPO. O §80 quer que a meio de uma noite o contorno chegue, e um corpo
## desenhado com uma cor propria deixava de ser o mesmo corpo.
func _tropa() -> void:
	var unidades := SimLoop.units
	for i in unidades.count():
		if unidades.bands[i] != int(band):
			continue
		var dados: UnitData = _tropas.get(unidades.data_ids[i])
		if dados == null:
			continue
		var alto := WorldPalette.DEGRAU * maxi(1, dados.scale_tier)
		var caixa := Silhouette.body_box(Silhouette.Form.CAIXA, unidades.xs[i], int(band), alto)
		var cor := _luz.body(WorldPalette.unit_color(unidades, i), unidades.xs[i])
		ActorArt.draw_unit(self, caixa, dados, unidades, i, cor, _visual_time)
		NameView.draw_on(self, caixa, unidades.ids[i])
		_saco(caixa, unidades, i)
		if unidades.alive(i):
			Gauge.health(
				self, caixa, float(unidades.healths[i]) / maxf(1.0, float(unidades.max_healths[i]))
			)


## O saco do §24. Quem morreu nao leva nada: §50 manda largar, e um corpo com o
## saco cheio dizia que ainda havia ali dinheiro para apanhar.
func _saco(caixa: Rect2, unidades: UnitSystem, i: int) -> void:
	if not unidades.alive(i):
		return
	Gauge.purse(self, caixa, unidades.carried_coins[i], unidades.coin_capacities[i])
