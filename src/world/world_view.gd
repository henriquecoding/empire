# src/world/world_view.gd — o mundo em formas simples (GB-01).
#
# Um _draw() por frame, lido do SimLoop. Nao guarda estado nenhum: se o que se
# ve divergir do que se simula, e defeito da simulacao e nao deste ficheiro. E a
# fronteira do §45 levada a serio — "se esta num no, e derivado e descartavel".
#
# Nao ha aqui um sprite, uma cena por unidade, nem um UnitView. E de proposito:
# a arte e o ART-01 e a composicao por slots e a §58. O que isto e e o greybox
# que deixa jogar e medir antes de existir um unico pixel desenhado — e o §67
# diz que o greybox e que fecha os numeros que a arte depois respeita.
#
# As tres faixas tem uma linha de chao cada (§11). A do meio e a GROUND_LINE; as
# outras duas saem das constantes de plano do Band, e nenhuma esta escrita aqui.
class_name WorldView
extends Node2D

const CEU := Color(0.87, 0.92, 0.94)
const SOLO := Color(0.42, 0.29, 0.16)
const SUBSOLO := Color(0.16, 0.12, 0.09)
const AR := Color(0.53, 0.67, 0.76, 0.18)
const LINHA := Color(0.0, 0.0, 0.0, 0.25)

const VAGABUNDO := Color(0.93, 0.85, 0.61)
const MEU := Color(0.45, 0.56, 0.29)
const CHAPEU := Color(0.85, 0.72, 0.28)
const REI := Color(0.82, 0.66, 0.22)
const MORTO := Color(0.35, 0.33, 0.30, 0.6)
const LUTA := Color(0.78, 0.31, 0.24)
const BICHO := Color(0.35, 0.16, 0.22)
const MOEDA := Color(0.96, 0.82, 0.29)
const MANCHA := Color(0.20, 0.13, 0.17, 0.55)
const OBRA := Color(0.55, 0.52, 0.48)
const ANDAIME := Color(0.72, 0.62, 0.42, 0.55)
const VAZIO := Color(0.35, 0.33, 0.30, 0.45)
const PASSAGEM := Color(0.36, 0.55, 0.62, 0.7)
const VIDA := Color(0.35, 0.65, 0.35)

## A escala do §01: um degrau sao 16 px de altura, e a largura e metade.
const DEGRAU := 16.0
const MEIA := 0.5
const MOEDA_R := 3.0
const CONTORNO := 2.0
const BARRA := 3.0
const PASSAGEM_W := 8.0
const ALTURA_OBRA := 14.0
const VIVO_MIN := 0.08

var _tropas: Dictionary = {}
var _bichos: Dictionary = {}


func _ready() -> void:
	_tropas = SimFactory.by_id(&"units")
	_bichos = SimFactory.by_id(&"creatures")


func _process(_delta: float) -> void:
	queue_redraw()


## A linha de chao de cada faixa, em y. A do meio e a do §11; a aerea assenta no
## fundo do plano aereo e a subterranea a meio do corte de solo.
static func ground_of(faixa: int) -> float:
	match faixa:
		int(Band.Kind.AERIAL):
			return float(Band.AERIAL_BOTTOM)
		int(Band.Kind.UNDERGROUND):
			return float(Band.GROUND_LINE + Band.SOIL_CUT * MEIA)
	return float(Band.GROUND_LINE)


func _draw() -> void:
	_faixas()
	if SimLoop.state == null:
		return
	_passagens()
	_obras()
	_podridao()
	_moedas()
	_criaturas()
	_tropa()


func _faixas() -> void:
	var largura := maxf(SimLoop.world_width, float(Band.SCREEN_BOTTOM))
	draw_rect(Rect2(0.0, 0.0, largura, float(Band.GROUND_LINE)), CEU)
	draw_rect(Rect2(0.0, 0.0, largura, float(Band.AERIAL_BOTTOM)), AR)
	draw_rect(
		Rect2(0.0, float(Band.GROUND_LINE), largura, float(Band.SOIL_CUT)),
		SOLO,
	)
	draw_rect(
		Rect2(0.0, ground_of(int(Band.Kind.UNDERGROUND)), largura, float(Band.SOIL_CUT) * MEIA),
		SUBSOLO,
	)
	for faixa in Band.Kind.size():
		var y := ground_of(faixa)
		draw_line(Vector2(0.0, y), Vector2(largura, y), LINHA, CONTORNO)


func _passagens() -> void:
	for x in SimLoop.passages:
		var topo := ground_of(int(Band.Kind.SURFACE))
		var fundo := ground_of(int(Band.Kind.UNDERGROUND))
		draw_rect(Rect2(x - PASSAGEM_W * MEIA, topo, PASSAGEM_W, fundo - topo), PASSAGEM)


## §25: "a silhueta e o convite. Nao ha botao construir." Um sitio por construir
## desenha-se a altura do que la vai caber — um muro de cinco niveis e cinco
## vezes mais alto do que um canteiro — e o que ja esta pago enche-o por baixo.
func _obras() -> void:
	for vaga in SimLoop.builds.slots:
		var chao := ground_of(int(vaga.band))
		var altura := ALTURA_OBRA * maxi(1, vaga.level)
		var caixa := Rect2(vaga.x - vaga.width * MEIA, chao - altura, vaga.width, altura)
		if vaga.standing():
			draw_rect(caixa, OBRA)
			_barra(caixa, float(vaga.health) / maxf(1.0, float(vaga.max_health())))
			continue
		if vaga.state != BuildSlot.State.EMPTY and vaga.state != BuildSlot.State.RUIN:
			draw_rect(caixa, ANDAIME)
			continue
		var silhueta := ALTURA_OBRA * maxi(1, vaga.costs.size())
		var fantasma := Rect2(caixa.position.x, chao - silhueta, vaga.width, silhueta)
		draw_rect(fantasma, VAZIO, false, CONTORNO)
		_pago(fantasma, vaga)


## Quanto do degrau seguinte ja esta pago. Sem isto nao ha maneira de saber se
## faltam cinco moedas ou uma, e o §55 nao tem contador nenhum para o dizer.
func _pago(fantasma: Rect2, vaga: BuildSlot) -> void:
	var custo := vaga.next_cost()
	if custo <= 0 or vaga.paid <= 0:
		return
	var racio := clampf(float(vaga.paid) / float(custo), 0.0, 1.0)
	var alto := fantasma.size.y * racio
	draw_rect(Rect2(fantasma.position.x, fantasma.end.y - alto, fantasma.size.x, alto), ANDAIME)


func _podridao() -> void:
	var rot := SimLoop.night.rot
	if not rot.active():
		return
	var largura := maxf(rot.state.width, DEGRAU)
	draw_rect(
		Rect2(rot.position_x() - largura * MEIA, 0.0, largura, float(Band.SCREEN_BOTTOM)), MANCHA
	)


func _moedas() -> void:
	var moedas := SimLoop.coins
	for i in moedas.count():
		var y := ground_of(int(moedas.bands[i])) - moedas.heights[i] - MOEDA_R
		draw_circle(Vector2(moedas.xs[i], y), MOEDA_R, MOEDA)


func _criaturas() -> void:
	var bichos := SimLoop.creatures
	for i in bichos.count():
		var dados: CreatureData = _bichos.get(bichos.data_ids[i])
		var alto := DEGRAU * maxi(1, dados.scale_tier)
		var caixa := _corpo(bichos.xs[i], int(bichos.bands[i]), alto)
		draw_rect(caixa, BICHO)
		_barra(caixa, float(bichos.healths[i]) / maxf(1.0, float(bichos.max_healths[i])))


func _tropa() -> void:
	var unidades := SimLoop.units
	for i in unidades.count():
		var dados: UnitData = _tropas.get(unidades.data_ids[i])
		var alto := DEGRAU * maxi(1, dados.scale_tier)
		var caixa := _corpo(unidades.xs[i], int(unidades.bands[i]), alto)
		draw_rect(caixa, _cor_da_tropa(unidades, i))
		if unidades.ids[i] == SimLoop.king_id:
			draw_rect(
				Rect2(caixa.position - Vector2(0.0, BARRA), Vector2(caixa.size.x, BARRA)), REI
			)
		elif unidades.owners[i] != RecruitSystem.SEM_DONO:
			# "Ele apanha-a e ganha um chapeu. Nada mais e preciso dizer." (§25)
			var aba := Vector2(caixa.size.x, BARRA)
			draw_rect(Rect2(caixa.position - Vector2(0.0, BARRA), aba), CHAPEU)
		if unidades.alive(i):
			_barra(caixa, float(unidades.healths[i]) / maxf(1.0, float(unidades.max_healths[i])))


func _cor_da_tropa(unidades: UnitSystem, i: int) -> Color:
	if not unidades.alive(i):
		return MORTO
	if unidades.states[i] == UnitFsm.State.FIGHT:
		return LUTA
	return MEU if unidades.owners[i] != RecruitSystem.SEM_DONO else VAGABUNDO


func _corpo(x: float, faixa: int, alto: float) -> Rect2:
	var largo := alto * MEIA
	return Rect2(x - largo * MEIA, ground_of(faixa) - alto, largo, alto)


## A vida por cima da cabeca. E HUD e o §24 quer a vida no rosto do sprite — mas
## nao ha rosto ainda, e uma barra e o que deixa medir uma noite (GB-03).
func _barra(caixa: Rect2, racio: float) -> void:
	if racio >= 1.0 or racio <= VIVO_MIN:
		return
	var topo := caixa.position - Vector2(0.0, BARRA * CONTORNO)
	draw_rect(Rect2(topo, Vector2(caixa.size.x * clampf(racio, 0.0, 1.0), BARRA)), VIDA)
