# src/world/tree_art.gd — as arvores da floresta, em pixeis (ADR 0070).
#
# Cada especie tem uma silhueta propria (flora.csv, `crown`): a copa larga do carvalho,
# o cone do pinheiro, a copa caida do salgueiro, o pinheiro baixo e inclinado da costa e
# as raizes altas do charco. Tirada a cor, ainda se distinguem (§7.1 do relatorio de
# vegetacao): e a forma que diz o lugar.
#
# A estacao muda a copa e nao a arvore: a caducifolia fica despida no inverno, ruiva no
# outono e clara na primavera; a perene fica igual. O vento mexe so a copa, com uma fase
# estavel por arvore, e nunca o tronco nem o sitio dela. Uma arvore abatida e um cepo; uma
# limpa pela fundacao ou por uma obra ja nao esta. Nada disto entra na simulacao.
class_name TreeArt
extends RefCounted

## Os tons de cada rectangulo: 0..2 copa (sombra, meio, luz), 3..4 casca, 5 a fita.
enum Tom { SOMBRA, MEIO, LUZ, CASCA_ESCURA, CASCA, FITA }

const ALTURA_DO_SPRITE := 44.0
const ESCALA_MINIMA := 2.0
const ESPELHO := -1.0
## Onde, em cada rectangulo, esta o tom (os quatro primeiros sao a caixa).
const TOM := 4
const VENTO := {"rad_s": 1.3, "px": 1.0, "fase": 0.37}
const CASCA := [Color("4a3522"), Color("6e4a2a")]
const FITA := Color("e3c877")
const PRIMAVERA := [Color("4f6b33"), Color("6f8f45"), Color("9cbc63")]
const VERAO := [Color("3f4a2c"), Color("5a6a38"), Color("86955a")]
const OUTONO := [Color("6b3f1f"), Color("9a5e2a"), Color("c99044")]
const PERENE := [Color("2f3f2a"), Color("41573a"), Color("5f7a50")]

const COPAS := {
	&"round":
	[
		[-2, -20, 4, 20, 4],
		[-2, -20, 1, 20, 3],
		[-5, -24, 3, 2, 4],
		[2, -26, 3, 2, 4],
		[-11, -36, 22, 12, 0],
		[-12, -32, 24, 8, 1],
		[-9, -42, 18, 8, 1],
		[-6, -44, 12, 4, 2],
		[-8, -38, 6, 4, 2],
		[3, -34, 6, 3, 2],
	],
	&"cone":
	[
		[-1, -10, 3, 10, 4],
		[-10, -14, 20, 4, 0],
		[-8, -20, 16, 6, 1],
		[-7, -26, 14, 6, 0],
		[-5, -32, 10, 6, 1],
		[-3, -38, 6, 6, 1],
		[-1, -44, 2, 6, 2],
		[-6, -18, 4, 2, 2],
	],
	&"droop":
	[
		[-2, -22, 4, 22, 4],
		[-10, -38, 20, 10, 1],
		[-12, -30, 24, 6, 0],
		[-12, -24, 2, 10, 0],
		[-8, -24, 2, 14, 1],
		[-3, -26, 2, 12, 0],
		[2, -24, 2, 14, 1],
		[7, -25, 2, 12, 0],
		[10, -24, 2, 9, 1],
		[-6, -42, 12, 4, 2],
	],
	&"low":
	[
		[-1, -8, 3, 8, 4],
		[1, -14, 3, 6, 4],
		[3, -18, 3, 4, 4],
		[-6, -24, 26, 6, 0],
		[-3, -28, 20, 4, 1],
		[2, -30, 10, 2, 2],
	],
	&"roots":
	[
		[-8, -8, 2, 8, 4],
		[-5, -12, 2, 12, 3],
		[4, -12, 2, 12, 3],
		[7, -8, 2, 8, 4],
		[-6, -14, 12, 3, 4],
		[-2, -30, 4, 16, 4],
		[-8, -38, 16, 8, 0],
		[-6, -42, 12, 4, 1],
		[-3, -44, 6, 2, 2],
		[-4, -36, 1, 1, 2],
		[3, -39, 1, 1, 2],
	],
}
## Os ramos de uma caducifolia despida, no lugar da copa.
const RAMOS := [
	[-8, -34, 1, 10, 3],
	[7, -36, 1, 12, 3],
	[-4, -40, 1, 12, 3],
	[3, -42, 1, 10, 3],
	[-9, -30, 6, 1, 3],
	[3, -32, 6, 1, 3],
]
const CEPO := [[-3, -5, 6, 5, 4], [-3, -6, 6, 1, 3]]
const MARCA := [[-3, -14, 6, 2, 5]]


## A arvore com o pe em `pe`, no `estado` do Woodland, na `estacao` do Seasons.
static func draw(
	canvas: CanvasItem,
	pe: Vector2,
	especie: FloraData,
	estado: int,
	estacao: int,
	tempo: float,
	id: int,
	luz: Lighting
) -> void:
	if estado == Woodland.State.CLEARED:
		return
	var escala := scale_of(especie)
	var lado := 1.0 if id % 2 == 0 else ESPELHO
	canvas.draw_set_transform(pe, 0.0, Vector2(escala * lado, escala))
	var cores := colors(especie, estacao)
	if estado == Woodland.State.FELLED:
		_rects(canvas, CEPO, cores, 0.0, luz, pe.x)
		canvas.draw_set_transform(Vector2.ZERO)
		return
	var vento := roundf(sin(tempo * VENTO.rad_s + float(id) * VENTO.fase) * VENTO.px)
	var copa: Array = COPAS.get(especie.crown, COPAS[&"round"])
	if bare(especie, estacao):
		_rects(
			canvas,
			copa.filter(func(r: Array) -> bool: return r[TOM] >= Tom.CASCA_ESCURA),
			cores,
			0.0,
			luz,
			pe.x
		)
		_rects(canvas, RAMOS, cores, vento, luz, pe.x)
	else:
		_rects(canvas, copa, cores, vento, luz, pe.x)
	if estado == Woodland.State.MARKED:
		_rects(canvas, MARCA, cores, 0.0, luz, pe.x)
	canvas.draw_set_transform(Vector2.ZERO)


## As seis cores de uma especie numa estacao: tres de copa, duas de casca e a fita.
static func colors(especie: FloraData, estacao: int) -> Array:
	var copa: Array = PERENE
	if not especie.evergreen:
		match estacao:
			Seasons.SPRING:
				copa = PRIMAVERA
			Seasons.AUTUMN:
				copa = OUTONO
			_:
				copa = VERAO
	return copa + CASCA + [FITA]


## Se a copa caiu: so as caducifolias, so no inverno.
static func bare(especie: FloraData, estacao: int) -> bool:
	return not especie.evergreen and estacao == Seasons.WINTER


## A altura a que a arvore chega acima do pe, em px do mundo.
static func height(especie: FloraData) -> float:
	return scale_of(especie) * ALTURA_DO_SPRITE


## Quantos px do mundo vale um pixel do sprite desta especie: inteiro, para o pixel.
static func scale_of(especie: FloraData) -> float:
	return maxf(ESCALA_MINIMA, roundf(especie.height_px / ALTURA_DO_SPRITE))


static func _rects(
	canvas: CanvasItem, rects: Array, cores: Array, vento: float, luz: Lighting, x: float
) -> void:
	for r: Array in rects:
		var dx := vento if int(r[TOM]) <= Tom.LUZ else 0.0
		var cor: Color = cores[int(r[TOM])]
		var caixa := FloraArt.rect(r)
		caixa.position.x += dx
		canvas.draw_rect(caixa, luz.body(cor, x))
