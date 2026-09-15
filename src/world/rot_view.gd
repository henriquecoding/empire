# src/world/rot_view.gd — a arte da mancha: a Podridao, o rasto e a candeia
# (F1-17, §74, §80).
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


## O rasto, a candeia e a mancha, por esta ordem — que e a ordem em que se veem:
## por onde ela passou, a luz que ela traz, e ela por cima da luz.
##
## A mancha vem DEPOIS da candeia e nao antes, e e a diferenca entre ler-se e
## nao se ler: ao dia 1 a luz tem 154 px de raio e a mancha 160 de largura, por
## isso a luz cobre-a inteira. Por cima, a mancha e uma coluna violeta contra o
## ambar — que e o §74 tal e qual: "alguem a atravessar o campo com uma
## lanterna", e nao uma lanterna sozinha.
static func draw_on(
	canvas: CanvasItem, rot: RotSystem, perfil: RotProfile, dia: int, luz: Lighting
) -> void:
	if not rot.active():
		return
	_rasto(canvas, rot, luz)
	# A candeia NAO leva ambiente: e a luz, e o §80 diz que ela e o assunto.
	_candeia(canvas, rot, perfil, dia)
	_mancha(canvas, rot, luz)


## §74: "uma so, quente, no meio da mancha". §80: tres paragens e nunca um
## gradiente, e depois um dither a dissolver para o ambiente.
##
## Pinta-se de fora para dentro — bordo, meio, nucleo — porque e uma luz e nao
## tres discos. O dither vem por ultimo, por cima do bordo.
static func lamp(canvas: CanvasItem, centro: Vector2, raio: float, cores: PackedColorArray) -> void:
	for i in cores.size():
		canvas.draw_circle(centro, WorldLight.stop_radius(raio, i), cores[i])


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


static func _candeia(canvas: CanvasItem, rot: RotSystem, perfil: RotProfile, dia: int) -> void:
	var centro := Vector2(rot.position_x(), WorldPalette.ground_of(int(Band.Kind.SURFACE)))
	var raio := WorldLight.radius(perfil, dia)
	var cores := WorldLight.stops(perfil)
	lamp(canvas, centro, raio, cores)
	var celula := perfil.lantern_dither_px
	for canto in WorldLight.dither(centro, raio, celula):
		canvas.draw_rect(Rect2(canto, Vector2(celula, celula)), cores[0])
