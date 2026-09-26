# src/world/sky_view.gd — as horas no ceu (§24; GB-18).
#
# O HUD diegetico do §24 da a hora ao mundo e a nada mais: "Hora do dia — cor da
# luz ambiente + posicao do sol/lua no ceu". A cor ja mudava (§80). O sol estava
# pintado no cenario num ponto FIXO da regiao — a 79% dela, 3033 px do principio
# —, e por isso nao se via do castelo; e lua nao havia.
#
# Um astro esta no infinito: nao tem paralaxe, e fica no ceu do ECRA enquanto a
# camara anda. Este no acompanha a camara e pinta o ceu e o astro; o cenario da
# faixa aerea vem a seguir na arvore e tapa-o com as montanhas, e e isso que o
# faz nascer e por-se atras delas.
#
# O dia (alvorada ao crepusculo) e do sol; a noite e da lua. Os dois fazem o
# mesmo arco, da esquerda para a direita, como o varrimento do amanhecer: o sol
# vem de onde a luz veio. As duracoes sao as do clock.csv — nada aqui sabe
# quanto dura uma fase.
class_name SkyView
extends Node2D

## Onde o arco comeca e acaba, em fraccao da largura do ecra, e o topo dele, em
## y de ecra — o y do sol que o cenario tinha. Geometria de greybox.
const MARGEM := 0.1
const TOPO := 112.0
const SOL_RAIO := 38.0
const LUA_RAIO := 24.0
## Osso e nao branco: o §80 da a noite duas cores que nao sao terra, e nenhuma
## delas e a lua. Pintada com a luz da faixa, fica uma silhueta clara e quente.
const LUA := Color(0.86, 0.82, 0.70)
const MEIA := 0.5

@export var paint_sky := true
var view_width: float = 0.0
var _relogio: ClockData


func _ready() -> void:
	_relogio = Registry.entry(&"economy", &"clock") as ClockData
	view_width = get_viewport_rect().size.x


## Em que ponto do percurso vai o astro: `t` de 0 a 1, e `moon` se e a noite.
static func course(decorrido: float, duracoes: PackedFloat32Array) -> Dictionary:
	var dia := 0.0
	for i in duracoes.size() - 1:
		dia += duracoes[i]
	if decorrido < dia:
		return {"t": decorrido / maxf(dia, 1.0), "moon": false}
	var noite := duracoes[duracoes.size() - 1]
	return {"t": clampf((decorrido - dia) / maxf(noite, 1.0), 0.0, 1.0), "moon": true}


## O ponto do arco no ecra: nasce no horizonte do §11 a esquerda, sobe ao TOPO
## a meio, poe-se no horizonte a direita.
static func arc(t: float, largura: float) -> Vector2:
	var x := lerpf(largura * MARGEM, largura * (1.0 - MARGEM), t)
	var y := lerpf(float(Band.HORIZON), TOPO, sin(PI * clampf(t, 0.0, 1.0)))
	return Vector2(x, y)


func _process(_delta: float) -> void:
	var camara := get_viewport().get_camera_2d()
	if camara != null:
		global_position.x = camara.get_screen_center_position().x - view_width * MEIA
	queue_redraw()


func _draw() -> void:
	var relogio := ClockService.clock
	if _relogio == null or relogio == null:
		return
	var fase := int(relogio.current_phase())
	var luz := BandLight.of(_relogio, Band.Kind.AERIAL, fase, relogio.phase_progress())
	if paint_sky:
		TerrainArt.sky(self, view_width, luz)
	var onde := course(relogio.elapsed, _relogio.phase_durations)
	var ponto := arc(onde.t, view_width)
	if onde.moon:
		draw_circle(ponto, LUA_RAIO, TerrainArt.paint(LUA, luz))
	else:
		draw_circle(ponto, SOL_RAIO, TerrainArt.paint(TerrainArt.WINDOW, luz))
