# src/world/under_props.gd — o que ha em cada sala do subsolo, pelo tipo dela (Q-186,
# ADR 0046; docs/recovery/PESQUISA-SUBSOLO-2026-10-02.md).
#
# Um tipo, uma coisa em que o olho pousa (§21): o armazem tem caixotes e sacas; a adega,
# pipas deitadas; o celeiro, grao e anforas; a galeria, escoras e veios; a camara da
# Semente Real, raizes; a sala secreta, o estandarte e a arca; o tesouro, arcas e
# moedas; a fuga, as frestas; a cripta, nichos e um sarcofago; o desabamento, pedra
# caida; a cisterna, agua entre colunas; o ossario, caveiras. Formas lisas escritas como
# dados (ShapeArt), em px a contar do pe, a espera de arte a serio.
class_name UnderProps
extends RefCounted

const R := ShapeArt.Forma.RECT
const P := ShapeArt.Forma.POLY
const L := ShapeArt.Forma.LINE
const C := ShapeArt.Forma.CIRCLE

const MADEIRA := WildSubjects.MADEIRA
const ESCURA := WildSubjects.MADEIRA_ESCURA
const PEDRA := WildSubjects.PEDRA
const PEDRA_CLARA := WildSubjects.PEDRA_CLARA
const PEDRA_ESCURA := WildSubjects.PEDRA_ESCURA
const SACA := Color("a58d62")
const GRAO := Color("c9a959")
const BARRO := Color("9b5a3a")
const OURO := Color("e2b54a")
const PANO := Color("7a2f2a")
const VEIO := Color("9fb7c4")
const RAIZ := RootCellars.ROOT
const NICHO := Color("17130f")
const OSSO := Color("d8cfb8")
const AGUA := Color("2c4a55")
const AGUA_CLARA := Color("4f7a86")
const FRESTA := Color("f2d39a")

## O recheio fica perto do meio da sala, a fugir dele ate esta fraccao do que sobra.
const FUGA := 0.5
const RECHEIO_PX := 100.0
const MEIO := 0.5
const COGUMELO := 0.2

const PECAS := {
	&"stair":
	[
		[R, MADEIRA, 30, -16, 16, 16],
		[R, ESCURA, 30, -16, 16, 3],
		[R, MADEIRA, 34, -28, 10, 12],
	],
	&"storage":
	[
		[R, MADEIRA, -40, -22, 22, 22],
		[R, ESCURA, -40, -22, 22, 3],
		[L, ESCURA, 2, -40, -2, -18, -20],
		[R, MADEIRA, -34, -40, 16, 18],
		[P, SACA, 4, 0, 6, -15, 13, -21, 20, -15, 22, 0],
		[P, SACA, 20, 0, 22, -12, 29, -18, 36, -12, 38, 0],
	],
	&"wine":
	[
		[R, ESCURA, -46, -4, 92, 4],
		[C, MADEIRA, -30, -13, 9],
		[C, MADEIRA, -10, -13, 9],
		[C, MADEIRA, 10, -13, 9],
		[C, MADEIRA, 30, -13, 9],
		[C, MADEIRA, -20, -30, 9],
		[C, MADEIRA, 0, -30, 9],
		[C, MADEIRA, 20, -30, 9],
		[C, ESCURA, -30, -13, 3],
		[C, ESCURA, -10, -13, 3],
		[C, ESCURA, 10, -13, 3],
		[C, ESCURA, 30, -13, 3],
		[C, ESCURA, -20, -30, 3],
		[C, ESCURA, 0, -30, 3],
		[C, ESCURA, 20, -30, 3],
	],
	&"granary":
	[
		[P, GRAO, -44, 0, -32, -16, -18, -22, -4, -15, 6, 0],
		[P, BARRO, 16, 0, 13, -10, 15, -22, 19, -27, 23, -22, 25, -10, 22, 0],
		[P, BARRO, 32, 0, 29, -8, 31, -18, 35, -22, 39, -18, 41, -8, 38, 0],
	],
	&"mine":
	[
		[R, MADEIRA, -34, -58, 6, 58],
		[R, MADEIRA, 28, -58, 6, 58],
		[R, ESCURA, -38, -62, 72, 6],
		[C, VEIO, -14, -40, 2],
		[C, VEIO, 6, -48, 2],
		[C, VEIO, 16, -30, 2],
		[C, VEIO, -4, -22, 2],
	],
	&"seed":
	[
		[L, RAIZ, 3, -22, -90, -26, -46],
		[L, RAIZ, 3, 0, -96, 3, -54],
		[L, RAIZ, 3, 20, -92, 25, -50],
		[L, RAIZ, 2, -10, -94, -14, -62],
		[L, RAIZ, 2, 10, -95, 12, -66],
	],
	&"vault":
	[
		[R, PANO, -30, -62, 12, 26],
		[P, PANO, -30, -36, -24, -30, -18, -36],
		[R, MADEIRA, 10, -14, 28, 14],
		[R, ESCURA, 10, -16, 28, 4],
		[R, OURO, 22, -12, 4, 4],
	],
	&"treasury":
	[
		[R, MADEIRA, -42, -14, 26, 14],
		[R, ESCURA, -42, -16, 26, 4],
		[R, OURO, -31, -12, 4, 4],
		[P, OURO, -10, 0, -4, -7, 4, -9, 12, -5, 16, 0],
		[C, OURO, 22, -3, 3],
		[C, OURO, 27, -2, 3],
		[R, MADEIRA, 26, -14, 20, 14],
		[R, ESCURA, 26, -16, 20, 4],
		[R, PANO, -4, -62, 12, 26],
	],
	&"escape":
	[
		[R, FRESTA, -30, -60, 3, 14],
		[R, FRESTA, 28, -60, 3, 14],
		[L, ESCURA, 2, -2, -44, -2, -36],
		[C, FRESTA, -2, -48, 3],
	],
	&"crypt":
	[
		[R, NICHO, -44, -58, 24, 12],
		[R, NICHO, -12, -58, 24, 12],
		[R, NICHO, 20, -58, 24, 12],
		[R, OSSO, -40, -51, 14, 3],
		[R, OSSO, 24, -51, 12, 3],
		[R, PEDRA, -22, -16, 44, 16],
		[R, PEDRA_CLARA, -24, -19, 48, 4],
	],
	&"collapsed":
	[
		[P, PEDRA_ESCURA, -46, 0, -36, -14, -22, -20, -6, -12, 4, -24, 18, -10, 30, -16, 44, 0],
		[P, PEDRA, 22, -16, 34, -16, 40, -44, 28, -46],
	],
	&"cistern":
	[
		[R, AGUA, -48, -6, 96, 6],
		[L, AGUA_CLARA, 1, -40, -4, -12, -4],
		[L, AGUA_CLARA, 1, 8, -3, 30, -3],
		[R, PEDRA, -36, -64, 8, 58],
		[R, PEDRA, 28, -64, 8, 58],
		[R, PEDRA_CLARA, -39, -66, 14, 4],
		[R, PEDRA_CLARA, 25, -66, 14, 4],
	],
	&"ossuary":
	[
		[R, NICHO, -44, -60, 88, 34],
		[C, OSSO, -34, -50, 4],
		[C, OSSO, -22, -50, 4],
		[C, OSSO, -10, -50, 4],
		[C, OSSO, 2, -50, 4],
		[C, OSSO, 14, -50, 4],
		[C, OSSO, 26, -50, 4],
		[C, OSSO, -28, -36, 4],
		[C, OSSO, -16, -36, 4],
		[C, OSSO, -4, -36, 4],
		[C, OSSO, 8, -36, 4],
		[C, OSSO, 20, -36, 4],
		[C, OSSO, 32, -36, 4],
	],
}
## Os tipos onde nasce um cogumelo com o lume dele, se o sorteio da sala o quiser.
const COM_COGUMELOS := [&"crypt", &"collapsed", &"cistern", &"ossuary", &"mine", &"seed", &"hall"]


## O recheio da sala, perto do meio dela e a fugir para um lado pelo sorteio da sala.
static func draw(canvas: CanvasItem, sala: Dictionary, chao: float) -> void:
	var a: float = sala[UndergroundSites.A]
	var b: float = sala[UndergroundSites.B]
	var u: float = sala[UndergroundSites.ROLL]
	var tipo: StringName = sala[UndergroundSites.KIND]
	var sobra := maxf(0.0, (b - a) - RECHEIO_PX)
	var x := (a + b) * MEIO + (u - MEIO) * sobra * FUGA
	ShapeArt.draw(canvas, PECAS.get(tipo, []), Vector2(x, chao))
	if tipo in COM_COGUMELOS and u < MEIO:
		RootCellars.shroom(canvas, lerpf(a, b, COGUMELO + u))
