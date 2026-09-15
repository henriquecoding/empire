# src/world/band_view.gd — uma faixa desenhada, e a luz que lhe pertence (§11).
#
# Tres instancias, uma por faixa, e cada uma com o seu `modulate`. E o F1-13: o
# ticket pede "CanvasModulate por faixa" e essa e a unica forma que nao existe —
# o Godot aceita UM CanvasModulate por canvas. O `modulate` de um no faz a mesma
# multiplicacao e pode existir tres vezes na mesma arvore (Q-069).
#
# Um _draw() por frame, lido do SimLoop. Nao guarda estado nenhum: se o que se
# ve divergir do que se simula, e defeito da simulacao e nao deste ficheiro. E a
# fronteira do §45 levada a serio — "se esta num no, e derivado e descartavel".
class_name BandView
extends Node2D

@export var band: Band.Kind = Band.Kind.SURFACE

var _tropas: Dictionary = {}
var _bichos: Dictionary = {}
var _relogio: ClockData


func _ready() -> void:
	_tropas = SimFactory.by_id(&"units")
	_bichos = SimFactory.by_id(&"creatures")
	_relogio = Registry.entry(&"economy", &"clock") as ClockData


func _process(_delta: float) -> void:
	var relogio := ClockService.clock
	# O `modulate` leva o AMBIENTE, que e igual nas tres faixas: e o LUT de hora
	# do dia da §22, e ele vale para tudo. O que distingue uma faixa da outra e o
	# TERRENO dela, e isso aplica-se por baixo, na cor de cada rectangulo.
	modulate = BandLight.ambient(_relogio, int(relogio.current_phase()), relogio.phase_progress())
	queue_redraw()


func _draw() -> void:
	_terreno()
	if SimLoop.state == null:
		return
	if band == Band.Kind.SURFACE:
		_passagens()
		_podridao()
	_obras()
	_moedas()
	_criaturas()
	_tropa()


## O plano de cada faixa (§11). A aerea leva o ceu porque vive nele; a
## superficie leva o corte de solo; o subsolo leva a metade de baixo dele.
func _terreno() -> void:
	var largura := maxf(SimLoop.world_width, float(Band.SCREEN_BOTTOM))
	var luz := BandLight.plane(_relogio, band)
	match band:
		Band.Kind.AERIAL:
			draw_rect(Rect2(0.0, 0.0, largura, float(Band.GROUND_LINE)), WorldPalette.CEU * luz)
			draw_rect(Rect2(0.0, 0.0, largura, float(Band.AERIAL_BOTTOM)), WorldPalette.AR)
		Band.Kind.SURFACE:
			var corte := Rect2(0.0, float(Band.GROUND_LINE), largura, float(Band.SOIL_CUT))
			draw_rect(corte, WorldPalette.SOLO * luz)
		Band.Kind.UNDERGROUND:
			var fundo := WorldPalette.ground_of(int(Band.Kind.UNDERGROUND))
			draw_rect(
				Rect2(0.0, fundo, largura, float(Band.SOIL_CUT) * WorldPalette.MEIA),
				WorldPalette.SUBSOLO * luz
			)
	var y := WorldPalette.ground_of(int(band))
	draw_line(Vector2(0.0, y), Vector2(largura, y), WorldPalette.LINHA, WorldPalette.CONTORNO)


## §11: onde se muda de faixa. Desenhada na superficie porque e de la que se
## desce — e o minuto 10:00 do §25, "o mundo tem um andar de baixo".
func _passagens() -> void:
	var topo := WorldPalette.ground_of(int(Band.Kind.SURFACE))
	var fundo := WorldPalette.ground_of(int(Band.Kind.UNDERGROUND))
	var largura := WorldPalette.PASSAGEM_W
	for x in SimLoop.passages:
		var canto := Vector2(x - largura * WorldPalette.MEIA, topo)
		draw_rect(Rect2(canto, Vector2(largura, fundo - topo)), WorldPalette.PASSAGEM)


func _podridao() -> void:
	var rot := SimLoop.night.rot
	if not rot.active():
		return
	var largura := maxf(rot.state.width, WorldPalette.DEGRAU)
	var canto := Vector2(rot.position_x() - largura * WorldPalette.MEIA, 0.0)
	draw_rect(Rect2(canto, Vector2(largura, float(Band.SCREEN_BOTTOM))), WorldPalette.MANCHA)


## §25: "a silhueta e o convite. Nao ha botao construir." Um sitio por construir
## desenha-se a altura do que la vai caber — um muro de cinco niveis e cinco
## vezes mais alto do que um canteiro — e o que ja esta pago enche-o por baixo.
func _obras() -> void:
	for vaga in SimLoop.builds.slots:
		if vaga.band != band:
			continue
		var chao := WorldPalette.ground_of(int(vaga.band))
		var altura := WorldPalette.ALTURA_OBRA * maxi(1, vaga.level)
		var canto := Vector2(vaga.x - vaga.width * WorldPalette.MEIA, chao - altura)
		var caixa := Rect2(canto, Vector2(vaga.width, altura))
		if vaga.standing():
			draw_rect(caixa, WorldPalette.OBRA)
			_barra(caixa, float(vaga.health) / maxf(1.0, float(vaga.max_health())))
			continue
		if vaga.state != BuildSlot.State.EMPTY and vaga.state != BuildSlot.State.RUIN:
			draw_rect(caixa, WorldPalette.ANDAIME)
			continue
		var silhueta := WorldPalette.ALTURA_OBRA * maxi(1, vaga.costs.size())
		var fantasma := Rect2(caixa.position.x, chao - silhueta, vaga.width, silhueta)
		draw_rect(fantasma, WorldPalette.VAZIO, false, WorldPalette.CONTORNO)
		_pago(fantasma, vaga)


## Quanto do degrau seguinte ja esta pago. Sem isto nao ha maneira de saber se
## faltam cinco moedas ou uma, e o §55 nao tem contador nenhum para o dizer.
func _pago(fantasma: Rect2, vaga: BuildSlot) -> void:
	var custo := vaga.next_cost()
	if custo <= 0 or vaga.paid <= 0:
		return
	var racio := clampf(float(vaga.paid) / float(custo), 0.0, 1.0)
	var alto := fantasma.size.y * racio
	draw_rect(
		Rect2(fantasma.position.x, fantasma.end.y - alto, fantasma.size.x, alto),
		WorldPalette.ANDAIME
	)


func _moedas() -> void:
	var moedas := SimLoop.coins
	for i in moedas.count():
		if moedas.bands[i] != int(band):
			continue
		var y := WorldPalette.ground_of(int(band)) - moedas.heights[i] - WorldPalette.MOEDA_R
		draw_circle(Vector2(moedas.xs[i], y), WorldPalette.MOEDA_R, WorldPalette.MOEDA)


func _criaturas() -> void:
	var bichos := SimLoop.creatures
	for i in bichos.count():
		if bichos.bands[i] != int(band):
			continue
		var dados: CreatureData = _bichos.get(bichos.data_ids[i])
		var alto := WorldPalette.DEGRAU * maxi(1, dados.scale_tier)
		var caixa := WorldPalette.body(bichos.xs[i], int(band), alto)
		draw_rect(caixa, WorldPalette.BICHO)
		_barra(caixa, float(bichos.healths[i]) / maxf(1.0, float(bichos.max_healths[i])))


func _tropa() -> void:
	var unidades := SimLoop.units
	for i in unidades.count():
		if unidades.bands[i] != int(band):
			continue
		var dados: UnitData = _tropas.get(unidades.data_ids[i])
		var alto := WorldPalette.DEGRAU * maxi(1, dados.scale_tier)
		var caixa := WorldPalette.body(unidades.xs[i], int(band), alto)
		draw_rect(caixa, WorldPalette.unit_color(unidades, i))
		_cabeca(caixa, unidades, i)
		if unidades.alive(i):
			_barra(caixa, float(unidades.healths[i]) / maxf(1.0, float(unidades.max_healths[i])))


## A coroa, ou o chapeu. "Ele apanha-a e ganha um chapeu. Nada mais e preciso
## dizer." (§25) — e nao ha mesmo mais nada a dizer sobre ter dono.
func _cabeca(caixa: Rect2, unidades: UnitSystem, i: int) -> void:
	var cor := WorldPalette.CHAPEU
	if unidades.ids[i] == SimLoop.king_id:
		cor = WorldPalette.REI
	elif unidades.owners[i] == RecruitSystem.SEM_DONO:
		return
	var aba := Vector2(caixa.size.x, WorldPalette.BARRA)
	draw_rect(Rect2(caixa.position - Vector2(0.0, WorldPalette.BARRA), aba), cor)


## A vida por cima da cabeca. E HUD e o §24 quer a vida no rosto do sprite — mas
## nao ha rosto ainda, e uma barra e o que deixa medir uma noite (GB-03).
func _barra(caixa: Rect2, racio: float) -> void:
	if racio >= 1.0 or racio <= WorldPalette.VIVO_MIN:
		return
	var topo := caixa.position - Vector2(0.0, WorldPalette.BARRA * WorldPalette.CONTORNO)
	var largo := caixa.size.x * clampf(racio, 0.0, 1.0)
	draw_rect(Rect2(topo, Vector2(largo, WorldPalette.BARRA)), WorldPalette.VIDA)
