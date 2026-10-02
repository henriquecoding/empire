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
#
# A lua diz tambem a noite funda (Q-126; relatorio Kingdom, K8): na vespera nasce
# cheia, e na propria noite vem vermelha, como a Lua de Sangue do Kingdom. A noite
# funda nao e sorteio — o RotSystem sabe-a de vespera —, e o ceu passa a dize-la.
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
## A lua cheia da vespera e da noite funda, e a cor da noite funda: vermelho de
## brasa, que a luz da faixa escurece como escurece o resto.
const LUA_CHEIA := 1.4
const LUA_FUNDA := Color(0.80, 0.30, 0.24)
## A lua tambem e uma luz: brilha por si, e o ambiente so lhe tira esta fraccao.
const LUA_PROPRIA := 0.6
## As estrelas da noite: quantas, ate que fraccao do horizonte descem, o tamanho
## e o ritmo do piscar. Sem sorteio (§42): o lugar de cada uma e a sequencia de
## Weyl do indice dela, e fica igual de noite para noite.
const ESTRELAS := {"quantas": 46, "ate": 0.78, "lado": 2.0, "piscar": 1.3}
const ESTRELA := Color(0.93, 0.89, 0.78)
const WEYL := Vector2(0.6180339, 0.7548777)
const RAIO := &"radius"
const COR := &"color"
const MEIA := 0.5

@export var paint_sky := true
var view_width: float = 0.0
var _relogio: ClockData
var _tempo := 0.0


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


## A lua da noite do dia `dia`: cheia na vespera da noite funda, e cheia e vermelha
## nela. Sem mancha (`rot` nulo) e a de sempre.
static func moon(rot: RotSystem, dia: int) -> Dictionary:
	if rot != null and rot.deep(dia):
		return {RAIO: LUA_RAIO * LUA_CHEIA, COR: LUA_FUNDA}
	if rot != null and rot.deep(dia + 1):
		return {RAIO: LUA_RAIO * LUA_CHEIA, COR: LUA}
	return {RAIO: LUA_RAIO, COR: LUA}


func _process(delta: float) -> void:
	_tempo += delta
	var camara := get_viewport().get_camera_2d()
	if camara != null:
		global_position.x = camara.get_screen_center_position().x - view_width * MEIA
	queue_redraw()


func _draw() -> void:
	var relogio := ClockService.clock
	if _relogio == null or relogio == null:
		return
	var fase := int(relogio.current_phase())
	var luz := BandLight.seen_of(_relogio, Band.Kind.AERIAL, fase, relogio.phase_progress())
	if paint_sky:
		TerrainArt.sky(self, view_width, luz)
	var onde := course(relogio.elapsed, _relogio.phase_durations)
	var ponto := arc(onde.t, view_width)
	if onde.moon:
		_estrelas(Lighting.darkness(_relogio, luz))
		var noite := SimLoop.night
		var lua := moon(noite.rot if noite != null else null, relogio.day)
		draw_circle(
			ponto, lua[RAIO], TerrainArt.paint(lua[COR], luz.lerp(Color.WHITE, LUA_PROPRIA))
		)
	else:
		draw_circle(ponto, SOL_RAIO, TerrainArt.paint(TerrainArt.WINDOW, luz))


## As estrelas, tanto mais quanto mais escuro (ADR 0048): sao o que diz "noite" sem
## escurecer o que se joga. O cenario do fundo tapa-as, como tapa a lua.
func _estrelas(escuro: float) -> void:
	if escuro <= 0.0:
		return
	var fundo := float(Band.HORIZON) * ESTRELAS.ate
	for i in ESTRELAS.quantas:
		var x := fposmod(float(i) * WEYL.x, 1.0) * view_width
		var y := fposmod(float(i) * WEYL.y + MEIA, 1.0) * fundo
		var brilho := MEIA + MEIA * sin(_tempo * ESTRELAS.piscar + float(i) * TAU * WEYL.x)
		var lado: float = ESTRELAS.lado
		var cor := Color(ESTRELA, escuro * brilho)
		draw_rect(Rect2(snappedf(x, lado), snappedf(y, lado), lado, lado), cor)
