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
class_name BandView
extends Node2D

@export var band: Band.Kind = Band.Kind.SURFACE

var _tropas: Dictionary = {}
var _bichos: Dictionary = {}
var _edificios: Dictionary = {}
var _relogio: ClockData
var _podre: RotProfile
var _luz := Lighting.new()


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
func _process(_delta: float) -> void:
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
	_terreno()
	if SimLoop.state == null:
		return
	if band == Band.Kind.SURFACE:
		_passagens()
		_podridao()
	_fogueiras()
	BuildView.draw_on(self, band, _edificios, _luz)
	_moedas()
	_criaturas()
	_tropa()
	# Por ultimo, e de proposito: o preco pousa EM CIMA do que descreve, e um
	# corpo desenhado depois dele tapava-o.
	PriceTag.draw_on(self, band, _tropas, _edificios)


## O plano de cada faixa (§11). A aerea leva o ceu porque vive nele; a
## superficie leva o corte de solo; o subsolo leva a metade de baixo dele.
func _terreno() -> void:
	var largura := maxf(SimLoop.world_width, float(Band.SCREEN_BOTTOM))
	var luz := _luz.scenery(BandLight.plane(_relogio, band))
	match band:
		Band.Kind.AERIAL:
			var ceu := Rect2(0.0, 0.0, largura, float(Band.GROUND_LINE))
			draw_rect(ceu, WorldPalette.tint(WorldPalette.CEU, luz))
			var ar := Rect2(0.0, 0.0, largura, float(Band.AERIAL_BOTTOM))
			draw_rect(ar, WorldPalette.tint(WorldPalette.AR, luz))
		Band.Kind.SURFACE:
			var corte := Rect2(0.0, float(Band.GROUND_LINE), largura, float(Band.SOIL_CUT))
			draw_rect(corte, WorldPalette.tint(WorldPalette.SOLO, luz))
		Band.Kind.UNDERGROUND:
			var fundo := WorldPalette.ground_of(int(Band.Kind.UNDERGROUND))
			draw_rect(
				Rect2(0.0, fundo, largura, float(Band.SOIL_CUT) * WorldPalette.MEIA),
				WorldPalette.tint(WorldPalette.SUBSOLO, luz)
			)
	var y := WorldPalette.ground_of(int(band))
	var linha := WorldPalette.tint(WorldPalette.LINHA, luz)
	draw_line(Vector2(0.0, y), Vector2(largura, y), linha, WorldPalette.CONTORNO)


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


func _moedas() -> void:
	var moedas := SimLoop.coins
	for i in moedas.count():
		if moedas.bands[i] != int(band):
			continue
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
		# A forma e o porte sao a diferenca entre "vem ai uma coisa" e "vem ai um
		# Ariete de lodo, e eu tenho o muro do lado errado" (§07, §51).
		var forma := Silhouette.of_creature(dados)
		var alto := WorldPalette.DEGRAU * maxi(1, dados.scale_tier)
		var caixa := Silhouette.body_box(forma, bichos.xs[i], int(band), alto)
		var aceso := WorldLight.lit(bichos.xs[i], candeia.x, candeia.y)
		var corpo := _luz.body(WorldPalette.BICHO, bichos.xs[i])
		var cor := WorldLight.reveal(corpo, aceso, chao)
		draw_colored_polygon(Outline.shape(forma, caixa, 0), cor)
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
func _tropa() -> void:
	var unidades := SimLoop.units
	for i in unidades.count():
		if unidades.bands[i] != int(band):
			continue
		var dados: UnitData = _tropas.get(unidades.data_ids[i])
		var alto := WorldPalette.DEGRAU * maxi(1, dados.scale_tier)
		var caixa := Silhouette.body_box(Silhouette.Form.CAIXA, unidades.xs[i], int(band), alto)
		var cor := _luz.body(WorldPalette.unit_color(unidades, i), unidades.xs[i])
		draw_rect(caixa, cor)
		_arma(caixa, dados, unidades, i, cor)
		_saco(caixa, unidades, i)
		_cabeca(caixa, unidades, i)
		if unidades.alive(i):
			Gauge.health(
				self, caixa, float(unidades.healths[i]) / maxf(1.0, float(unidades.max_healths[i]))
			)


## O que ela leva na mao, do lado para onde vai. Na COR DO CORPO e nao numa cor
## propria: e a mesma silhueta, e o §80 quer que a meio de uma noite o contorno
## chegue. Quem morreu nao leva nada — §50: "toda a morte larga: arma, moedas
## transportadas, ou corpo. Nada desaparece em silencio."
func _arma(caixa: Rect2, dados: UnitData, unidades: UnitSystem, i: int, cor: Color) -> void:
	if not unidades.alive(i):
		return
	var pontos := Outline.mark(Silhouette.of_unit(dados), caixa, _sentido(unidades, i))
	if pontos.size() < 2:
		return
	draw_polyline(pontos, cor, WorldPalette.CONTORNO)


## O saco do §24. Quem morreu nao leva nada: §50 manda largar, e um corpo com o
## saco cheio dizia que ainda havia ali dinheiro para apanhar.
func _saco(caixa: Rect2, unidades: UnitSystem, i: int) -> void:
	if not unidades.alive(i):
		return
	Gauge.purse(self, caixa, unidades.carried_coins[i], unidades.coin_capacities[i])


## Para onde ela esta virada. O alvo e onde ela quer chegar — de um posto, de uma
## moeda ou de quem ela vai atacar —, e sem isto uma noite inteira de tropas
## parecia parada mesmo com toda a gente a andar.
func _sentido(unidades: UnitSystem, i: int) -> float:
	var frente := signf(unidades.target_xs[i] - unidades.xs[i])
	# Quem esta parada fica virada para a direita, e nao sem lado nenhum: um
	# sentido zero punha a arma dentro do corpo.
	return frente if not is_zero_approx(frente) else 1.0


## A coroa, ou o chapeu. "Ele apanha-a e ganha um chapeu. Nada mais e preciso
## dizer." (§25) — e nao ha mesmo mais nada a dizer sobre ter dono.
func _cabeca(caixa: Rect2, unidades: UnitSystem, i: int) -> void:
	var cor := WorldPalette.CHAPEU
	if unidades.ids[i] == SimLoop.king_id:
		cor = WorldPalette.REI
	elif unidades.owners[i] == RecruitSystem.SEM_DONO:
		return
	var aba := Vector2(caixa.size.x, WorldPalette.BARRA)
	var canto := caixa.position - Vector2(0.0, WorldPalette.BARRA)
	draw_rect(Rect2(canto, aba), cor)
