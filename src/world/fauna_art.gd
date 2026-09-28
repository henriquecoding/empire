# src/world/fauna_art.gd — o que um bicho de cenario E, em pixeis (§22).
#
# O Fauna diz onde esta e o que faz; isto desenha-o como o HuntView desenha o
# coelho: rectangulos a escala inteira, a partir do pe, virados para onde o
# bicho olha. Cada bicho tem dois fotogramas — asa em cima e asa em baixo,
# pousado e a saltar —, e o fotograma sai da fase dele.
#
# A luz e a dos corpos (Lighting.body): de dia a cor, de noite a silhueta do
# §80. O pirilampo nao leva luz nenhuma: e ele a luz (ambar, a cor que o §80
# da a luz).
class_name FaunaArt
extends RefCounted

const ESCALA := 2.0
const ESPELHO := -1.0
const FOTOGRAMAS := 2.0
## Quantos fotogramas por segundo bate uma asa, por bicho (Wilds.Animal).
const BATER := [3.0, 5.0, 9.0, 2.0, 6.0, 10.0, 2.0]

## Cor de cada bicho: corpo, sombra e o pormenor (bico, peito, asa).
const CORES := [
	[Color("ece5cf"), Color("b9b09a"), Color("d98b3e")],
	[Color("1f1c1f"), Color("0f0d0f"), Color("4a4448")],
	[Color("e6c65a"), Color("b0802f"), Color("3a2e20")],
	[Color("f2b35a"), Color("f2b35a"), Color("f2b35a")],
	[Color("2a2622"), Color("1a1714"), Color("2a2622")],
	[Color("2e2420"), Color("1b1512"), Color("5a463a")],
	[Color("ece5cf"), Color("9f9a8c"), Color("d98b3e")],
]

## Os sprites: [fotograma 0, fotograma 1], cada um (x, y, largo, alto, tom).
const SPRITES := [
	[
		[[-2, -3, 4, 3, 0], [1, -5, 2, 2, 0], [3, -4, 1, 1, 2], [-3, -2, 1, 1, 1]],
		[[-2, -5, 4, 3, 0], [1, -7, 2, 2, 0], [3, -6, 1, 1, 2], [-4, -7, 3, 1, 1]],
	],
	[
		[
			[-3, -4, 6, 3, 0],
			[2, -6, 2, 2, 0],
			[4, -5, 2, 1, 2],
			[-4, -3, 1, 1, 1],
			[0, -1, 1, 1, 1]
		],
		[
			[-3, -4, 6, 2, 0],
			[2, -5, 2, 2, 0],
			[4, -4, 2, 1, 2],
			[-5, -8, 4, 3, 2],
			[1, -8, 4, 3, 2]
		],
	],
	[
		[[-3, -2, 2, 3, 0], [1, -2, 2, 3, 0], [0, -2, 1, 3, 2]],
		[[-1, -3, 1, 3, 1], [1, -3, 1, 3, 1], [0, -2, 1, 3, 2]]
	],
	[[[0, 0, 1, 1, 0]], [[0, 0, 1, 1, 0]]],
	[
		[[-3, -2, 2, 1, 0], [-1, -1, 2, 1, 0], [1, -2, 2, 1, 0]],
		[[-3, 0, 2, 1, 0], [-1, -1, 2, 1, 0], [1, 0, 2, 1, 0]]
	],
	[
		[
			[-1, -1, 2, 2, 0],
			[-4, -2, 3, 1, 2],
			[1, -2, 3, 1, 2],
			[-5, -1, 1, 1, 2],
			[4, -1, 1, 1, 2]
		],
		[[-1, -1, 2, 2, 0], [-4, 0, 3, 1, 2], [1, 0, 3, 1, 2], [-5, 1, 1, 1, 2], [4, 1, 1, 1, 2]],
	],
	[
		[
			[-2, -1, 4, 2, 0],
			[2, -2, 2, 1, 0],
			[4, -2, 1, 1, 2],
			[-6, -3, 4, 1, 1],
			[2, -3, 4, 1, 1]
		],
		[[-2, -1, 4, 2, 0], [2, -2, 2, 1, 0], [4, -2, 1, 1, 2], [-6, 1, 4, 1, 1], [2, 1, 4, 1, 1]],
	],
]

## O halo do pirilampo: raio em px, e o ritmo do piscar.
const HALO := {"raio": 5.0, "alfa": 0.3, "piscar": 1.7}


static func draw_on(
	canvas: CanvasItem, b: Fauna.Bicho, luz: Lighting, alfa: float, tempo: float
) -> void:
	if alfa <= 0.0:
		return
	var pe := Vector2(floorf(b.x), floorf(b.y))
	if b.kind == Wilds.Animal.FIREFLY:
		var piscar := (sin(tempo * HALO.piscar * TAU + b.variant * TAU) + 1.0) / 2
		var cor: Color = CORES[b.kind][0]
		canvas.draw_circle(pe, HALO.raio, Color(cor, HALO.alfa * piscar * alfa))
		canvas.draw_rect(Rect2(pe, Vector2(ESCALA, ESCALA)), Color(cor, piscar * alfa))
		return
	var fotograma := frame(b, tempo)
	var cores: Array = CORES[b.kind]
	var lado := b.facing if b.facing != 0.0 else 1.0
	canvas.draw_set_transform(pe, 0.0, Vector2(ESCALA * lado, ESCALA))
	for r: Array in SPRITES[b.kind][fotograma]:
		var cor := luz.body(cores[r[FloraArt.TOM]], b.x)
		cor.a *= alfa
		canvas.draw_rect(FloraArt.rect(r), cor)
	canvas.draw_set_transform(Vector2.ZERO)


## Qual dos dois fotogramas. Pousado, o pardal so salta de vez em quando, e o
## corvo no chao esta quieto; o que voa bate a asa ao ritmo dele.
static func frame(b: Fauna.Bicho, tempo: float) -> int:
	var ritmo: float = BATER[b.kind]
	var batendo := int(fposmod(tempo * ritmo + b.variant, FOTOGRAMAS))
	match b.kind:
		Wilds.Animal.SONGBIRD:
			if b.state != Fauna.State.IDLE:
				return batendo
			return 1 if fposmod(tempo + b.variant * ritmo, ritmo) < 1.0 / ritmo else 0
		Wilds.Animal.CROW:
			return batendo if b.y < b.home.y - 1.0 else 0
	return batendo
