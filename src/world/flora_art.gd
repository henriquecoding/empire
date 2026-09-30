# src/world/flora_art.gd — o que cresce nas terras bravias, em pixeis (§22).
#
# O Wilds diz o que ha e onde; isto diz como e. Cada planta e um pequeno sprite
# escrito como rectangulos (x, y, largo, alto, tom) a partir do pe, a escala
# inteira — como o coelho do HuntView —, para que o campo tenha o mesmo pixel
# que a arte do resto do segmento e nao circulos lisos de greybox.
#
# O tom e um indice na paleta da planta: 0 sombra, 1 meio, 2 luz, 3 a cor
# propria (a flor, a cabeca do junco, o chapeu do cogumelo). A variante escolhe
# a cor propria das flores e vira o sprite ao espelho: duas iguais lado a lado
# nao se leem como carimbo.
#
# O que esta mais para tras mistura-se com a cor do campo (perspectiva do ar,
# §22): e o `fundo` do Wilds que o diz. Violeta nao entra — e da Podridao (§80).
class_name FloraArt
extends RefCounted

const ESCALA := 2.0
## Quanto do campo entra na cor de uma planta no fundo dele.
const NEVOA := 0.55
const MEIO := 0.5
const ESPELHO := -1.0
## Onde, em cada rectangulo de sprite, esta o tom (os quatro primeiros sao a caixa).
const TOM := 4

const VERDE := [Color("3f4a2c"), Color("5a6a38"), Color("86955a")]
const SECO := [Color("5b4f33"), Color("7a6a45"), Color("9a8660")]
const PEDRA := [Color("5d594a"), Color("8b8570"), Color("b0a98f")]
const CASCA := [Color("4a3522"), Color("6e4a2a"), Color("8a6440")]
const LONGE := [Color("333b2b"), Color("3f4834"), Color("3f4834")]
const FLORES := [Color("c9553e"), Color("e6c65a"), Color("ece5cf"), Color("d98b3e")]
const CHAPEU := Color("b0492f")
const JUNCO := Color("6e4a2a")

const SPRITES := {
	Wilds.Plant.GRASS: [[-2, -3, 1, 3, 1], [-1, -5, 1, 5, 2], [0, -4, 1, 4, 1], [1, -2, 1, 2, 0]],
	Wilds.Plant.TALL_GRASS:
	[
		[-3, -5, 1, 5, 1],
		[-2, -8, 1, 8, 2],
		[-1, -6, 1, 6, 1],
		[0, -9, 1, 9, 2],
		[1, -7, 1, 7, 1],
		[2, -4, 1, 4, 0],
	],
	Wilds.Plant.FLOWER:
	[[0, -6, 1, 6, 0], [-1, -3, 1, 1, 1], [1, -4, 1, 1, 1], [-1, -8, 3, 1, 3], [0, -9, 1, 3, 3]],
	Wilds.Plant.FERN:
	[
		[0, -8, 1, 8, 0],
		[-3, -7, 3, 1, 1],
		[1, -7, 3, 1, 1],
		[-4, -5, 4, 1, 1],
		[1, -5, 4, 1, 1],
		[-3, -3, 3, 1, 2],
		[1, -3, 3, 1, 2],
		[-1, -9, 3, 1, 2],
	],
	Wilds.Plant.BUSH:
	[
		[-7, -5, 14, 5, 0],
		[-6, -8, 12, 3, 1],
		[-4, -10, 8, 2, 1],
		[-3, -9, 3, 1, 2],
		[1, -8, 3, 1, 2],
		[-5, -6, 2, 1, 2],
	],
	Wilds.Plant.REED:
	[
		[-2, -10, 1, 10, 1],
		[0, -13, 1, 13, 1],
		[2, -9, 1, 9, 0],
		[0, -16, 1, 3, 3],
		[-2, -12, 1, 2, 3]
	],
	Wilds.Plant.ROCK: [[-5, -4, 10, 4, 0], [-4, -6, 8, 2, 1], [-2, -7, 4, 1, 2], [-3, -5, 2, 1, 2]],
	Wilds.Plant.DRY_SHRUB:
	[
		[0, -6, 1, 6, 0],
		[-3, -5, 3, 1, 1],
		[1, -7, 3, 1, 1],
		[-4, -8, 1, 3, 1],
		[3, -9, 1, 2, 2],
		[-1, -9, 1, 3, 1],
	],
	Wilds.Plant.MUSHROOM:
	[[-1, -4, 2, 4, 2], [-3, -6, 6, 2, 3], [-2, -7, 4, 1, 3], [-2, -6, 1, 1, 2], [1, -7, 1, 1, 2]],
	Wilds.Plant.STUMP:
	[[-4, -6, 8, 6, 0], [-4, -7, 8, 1, 2], [-2, -7, 4, 1, 1], [-5, -1, 1, 1, 0], [4, -2, 1, 2, 0]],
	Wilds.Plant.SAPLING:
	[
		[0, -14, 1, 14, 3],
		[-4, -19, 9, 5, 1],
		[-3, -21, 7, 2, 1],
		[-2, -20, 3, 1, 2],
		[-4, -15, 3, 1, 0]
	],
	Wilds.Plant.FAR_PINE:
	[
		[0, -4, 1, 4, 0],
		[-4, -8, 9, 4, 0],
		[-3, -12, 7, 4, 0],
		[-2, -16, 5, 4, 1],
		[-1, -19, 3, 3, 1],
		[0, -21, 1, 2, 1],
	],
	Wilds.Plant.FAR_OAK:
	[[0, -6, 2, 6, 0], [-5, -13, 12, 7, 0], [-4, -16, 10, 3, 1], [-2, -18, 6, 2, 1]],
}


## As plantas do Wilds, com o pe entre `frente` (fundo 0) e `tras` (fundo 1) em
## y, e a `nevoa` que o fundo lhes mistura.
static func draw_all(
	canvas: CanvasItem, plantas: PackedFloat32Array, frente: float, tras: float, nevoa: Color
) -> void:
	for i in range(0, plantas.size(), Wilds.PLANTA):
		var fundo := plantas[i + 2]
		var pe := Vector2(plantas[i + 1], floorf(lerpf(frente, tras, fundo)))
		draw_one(canvas, int(plantas[i]), pe, plantas[i + Wilds.PLANTA - 1], nevoa, fundo * NEVOA)
	canvas.draw_set_transform(Vector2.ZERO)


## Uma planta com o pe em `pe`. Deixa a transformacao posta: quem desenha muitas repoe-na
## no fim, como o draw_all.
static func draw_one(
	canvas: CanvasItem,
	tipo: int,
	pe: Vector2,
	variante: float,
	nevoa: Color,
	mistura: float,
	escala: float = ESCALA
) -> void:
	var cores := palette(tipo, variante)
	var lado := 1.0 if variante < MEIO else ESPELHO
	canvas.draw_set_transform(pe, 0.0, Vector2(escala * lado, escala))
	for r: Array in SPRITES[tipo]:
		var cor: Color = cores[r[TOM]]
		canvas.draw_rect(rect(r), cor.lerp(nevoa, mistura))


## Quantos pixeis de sprite a planta sobe acima do pe (a escala 1).
static func height(tipo: int) -> float:
	var alto := 0.0
	for r: Array in SPRITES[tipo]:
		alto = maxf(alto, -float(r[1]))
	return alto


## A caixa de um rectangulo de sprite (x, y, largo, alto, tom).
static func rect(r: Array) -> Rect2:
	return Rect2(r[0], r[1], r[2], r[TOM - 1])


## As quatro cores de uma planta: sombra, meio, luz, e a cor propria.
static func palette(tipo: int, variante: float) -> Array:
	var flor: Color = FLORES[mini(int(variante * FLORES.size()), FLORES.size() - 1)]
	match tipo:
		Wilds.Plant.ROCK:
			return PEDRA + [PEDRA[2]]
		Wilds.Plant.DRY_SHRUB:
			return SECO + [SECO[2]]
		Wilds.Plant.STUMP:
			return CASCA + [CASCA[2]]
		Wilds.Plant.MUSHROOM:
			return CASCA + [CHAPEU]
		Wilds.Plant.REED:
			return VERDE + [JUNCO]
		Wilds.Plant.SAPLING:
			return VERDE + [CASCA[1]]
		Wilds.Plant.FAR_PINE, Wilds.Plant.FAR_OAK:
			return LONGE + [LONGE[1]]
	return VERDE + [flor]
