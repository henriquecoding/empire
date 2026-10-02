# src/world/rot_view.gd — a arte da mancha: a Podridao, o rasto e o Lume roxo na
# base dela (F1-17, §74, §80, ADR 0034).
#
# Nao e um no. E o BandView da superficie que chama isto a meio do `_draw()`, e
# tem de ser assim: a mancha vai por baixo das obras e das tropas, e um no filho
# desenha sempre por cima do pai. O que se ganha em ficheiro proprio e o limite
# das 250 linhas do §28 — e que a arte da mancha se le num sitio so.
#
# Nao ha aqui um numero de balanceamento: o raio, as tres paragens e o dither
# saem do RotProfile, as cores do WorldPalette, e o horizonte do Band.
class_name RotView
extends RefCounted

## O aviso da tarde: a chama do Lume no horizonte, em vezes a de uma fogueira —
## maior numa noite funda. A luz dela no ceu e do LightField. Greybox.
const AVISO := 0.8
const AVISO_FUNDO := 1.3
## O Lume: o fogo roxo na base, maior do que qualquer fogueira tua (§80).
const LUME := 2.0
## O braseiro do Lume, em greybox: um poste com a chama no topo (ADR 0034).
const FISSURE := [
	Vector2(-46, 0),
	Vector2(-24, -5),
	Vector2(-8, 2),
	Vector2(10, -4),
	Vector2(30, 3),
	Vector2(48, -2)
]
const FISSURE_LINE := 6.0
const BRASEIRO := Vector2(8.0, 28.0)


## O Lume, o rasto e a mancha, por esta ordem. O Lume arde na base de onde ela
## nasceu e fica la (ADR 0034): a mancha que atravessa o campo e escuridao, e a
## unica luz dela e o fogo roxo la atras — o unico que a aquece.
static func draw_on(
	canvas: CanvasItem,
	rot: RotSystem,
	perfil: RotProfile,
	dia: int,
	luz: Lighting,
	tempo: float = 0.0
) -> void:
	if not rot.active():
		_aviso(canvas, rot, perfil, dia, tempo)
		return
	# O Lume NAO leva ambiente: e uma luz, e o §80 diz que a luz e o assunto.
	_candeia(canvas, rot, perfil, tempo)
	_rasto(canvas, rot, luz)
	_mancha(canvas, rot, luz)


## A massa que atravessa o campo, do HORIZONTE a LINHA DE CHAO — que e o plano
## medio do §80 tal e qual, "y 420-517". Antes ia do topo do ecra ao fundo dele:
## punha violeta num ceu que o §80 quer de terra, e atravessava o subsolo como se
## fosse uma coluna e nao uma coisa que anda no chao. Os dois numeros sao os do
## `Band`, e o de cima chama-se HORIZON — "onde as camadas distantes se
## encontram" —, que e onde o F1-17 promete que ela se ve chegar.
static func _mancha(canvas: CanvasItem, rot: RotSystem, luz: Lighting) -> void:
	var largura := maxf(rot.state.width, WorldPalette.DEGRAU)
	var alto := float(Band.GROUND_LINE - Band.HORIZON)
	var canto := Vector2(rot.position_x() - largura * WorldPalette.MEIA, float(Band.HORIZON))
	var cor := WorldPalette.tint(WorldPalette.MANCHA, luz.scenery(1.0))
	canvas.draw_rect(Rect2(canto, Vector2(largura, alto)), cor)


## Por onde ela ja passou (§51). E o rasto que o §49 ja le para saber que um
## edificio nao produz hoje, e ate agora nao se via: quem chegasse ao ecra
## depois do crepusculo nao tinha como saber de que lado ela vinha.
static func _rasto(canvas: CanvasItem, rot: RotSystem, luz: Lighting) -> void:
	var de := minf(rot.state.trail_from, rot.state.trail_to)
	var ate := maxf(rot.state.trail_from, rot.state.trail_to)
	if ate - de <= 0.0:
		return
	var y := WorldPalette.ground_of(int(Band.Kind.SURFACE))
	var caixa := Rect2(de, y - WorldPalette.RASTO, ate - de, WorldPalette.RASTO)
	canvas.draw_rect(caixa, WorldPalette.tint(WorldPalette.TRILHO, luz.scenery(1.0)))


## O Lume: o fogo roxo na base dela (ADR 0034), e a fissura de onde ela sai. A
## luz que ele da ao mundo — as tres paragens e o dither do §80 — esta no
## LightField, e e o cenario e os corpos que a recebem; aqui fica so o fogo.
static func _candeia(canvas: CanvasItem, rot: RotSystem, perfil: RotProfile, tempo: float) -> void:
	var centro := Vector2(WorldLight.nest_x(rot), WorldPalette.ground_of(int(Band.Kind.SURFACE)))
	var cores := WorldLight.stops(perfil)
	fissure(canvas, centro.x, cores[2])
	FlameArt.draw_on(canvas, centro, LUME, cores, tempo)


## A tarde diz de que lado vem a noite (Q-125): o Lume acende-se na base dela, no
## horizonte dessa borda, antes de a mancha nascer (ADR 0034) — ve-se de longe e nao
## diz um numero. Numa noite funda (Q-126) arde maior.
static func _aviso(
	canvas: CanvasItem, rot: RotSystem, perfil: RotProfile, dia: int, tempo: float
) -> void:
	if rot.announced == 0:
		return
	var x := SimLoop.world_width if rot.announced > 0 else 0.0
	var escala := AVISO_FUNDO if rot.deep(dia) else AVISO
	FlameArt.draw_on(
		canvas, Vector2(x, float(Band.HORIZON)), escala, WorldLight.stops(perfil), tempo
	)


static func fissure(canvas: CanvasItem, x: float, color: Color) -> void:
	var points := PackedVector2Array()
	for point: Vector2 in FISSURE:
		points.append(Vector2(x, WorldPalette.ground_of(int(Band.Kind.SURFACE))) + point)
	canvas.draw_polyline(points, color, FISSURE_LINE)
