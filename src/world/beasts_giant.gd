# src/world/beasts_giant.gd — o Devorador e o Zelador (§74, §75, ADR 0049).
#
# Os dois que nao sao para matar como os outros, em tracos de pixeis de criatura
# (BeastPen):
#
#   Devorador — o colosso: quase duas vezes o rei de alto, em quatro patas como
#               pilares, com uma bocarra a frente e um dorso que se le como
#               terreno — e `climbable` (§74), e sobe-se a ele. Anda devagar, a
#               boca abre e fecha, e os olhos sao muitos e pequenos, por cima dela.
#   Zelador   — alto e fino, de capuz e sem cara: dois olhos so. Nao bate em
#               ninguem; paira um pouco acima do chao, o manto baloica, e leva um
#               nomeado (§75).
class_name BeastsGiant
extends RefCounted

const S := BeastPen.Stroke
const T := BeastPen.Tone
const PA := BeastPen.Sinal.PASSO
const ON := BeastPen.Sinal.ONDA
const O2 := BeastPen.Sinal.ONDA2
const AR := BeastPen.Sinal.ARMA
const BA := BeastPen.Sinal.BATE
const CI := BeastPen.Sinal.CICLO

## Quanto a boca do Devorador esta aberta, para baixo: respira com a segunda onda,
## escancara a armar e fecha a morder. A queixada, a lingua e os dentes vao com ela.
const QUEIXADA := [31.5, O2, -1.5, AR, -6, BA, 4]
const LINGUA_Y := [39.25, O2, -0.75, AR, -3, BA, 2]
const LINGUA_RY := [4.9, O2, 0.9, AR, 3.6, BA, -2.4]
const DENTE := [34.5, O2, -1.5, AR, -6, BA, 4]

## As patas de la, o corpo que respira, o dorso, a barriga, as saliencias por onde
## se sobe, a crista de espinhos, o que lhe cresce, a pele pisada, as patas de ca
## com os dedos, a bocarra com os dentes e a baba, e os cinco olhos.
const DEVOURER := [
	[S.RECT, T.DARK, -20, 0, 6, [22, PA, -1.5]],
	[S.BLOB, T.DARK, -17, [20, PA, -1.5], 6, 5],
	[S.RECT, T.DARK, -21, 0, 10, 3],
	[S.RECT, T.DARK, 21, 0, 6, [24, PA, 1.5]],
	[S.BLOB, T.DARK, 24, [22, PA, 1.5], 6, 5],
	[S.RECT, T.DARK, 20, 0, 10, 3],
	[S.BLOB, T.BODY, -4, 44, 34, [24, ON, 0.6]],
	[S.BLOB, T.LIGHT, -8, 58, 26, 10],
	[S.BLOB, T.DARK, -2, 28, 26, 8],
	[S.RECT, T.LIGHT, -28, 52, 6, 2],
	[S.RECT, T.LIGHT, -17, 58, 6, 2],
	[S.RECT, T.LIGHT, -6, 52, 6, 2],
	[S.RECT, T.LIGHT, 5, 58, 6, 2],
	[S.LINE, T.BONE, -30, 60, -33, 68, 2],
	[S.LINE, T.BONE, -22, 64, -25, 74, 2],
	[S.LINE, T.BONE, -14, 67, -17, 79, 2],
	[S.LINE, T.BONE, -6, 68, -9, 76, 2],
	[S.LINE, T.BONE, 2, 67, -1, 77, 2],
	[S.LINE, T.BONE, 10, 64, 7, 76, 2],
	[S.LINE, T.BONE, 18, 60, 15, 68, 2],
	[S.BLOB, T.FLESH, -20, 63, 3, 2],
	[S.BLOB, T.FLESH, -6, 66, 3, 2],
	[S.BLOB, T.FLESH, 8, 63, 3, 2],
	[S.LINE, T.DARK, -24, 40, -14, 36],
	[S.LINE, T.DARK, -10, 46, 2, 43],
	[S.LINE, T.DARK, 6, 38, 14, 34],
	[S.RECT, T.BODY, -30, 0, 7, [24, PA, 1.5]],
	[S.BLOB, T.BODY, -26.5, [22, PA, 1.5], 6.5, 5],
	[S.RECT, T.BODY, -31, 0, 11, 3],
	[S.RECT, T.BODY, 12, 0, 8, [26, PA, -1.5]],
	[S.BLOB, T.BODY, 16, [24, PA, -1.5], 7, 5],
	[S.RECT, T.BODY, 11, 0, 12, 3],
	[S.RECT, T.BONE, -31, 0, 2, 2],
	[S.RECT, T.BONE, -27, 0, 2, 2],
	[S.RECT, T.BONE, 11, 0, 2, 2],
	[S.RECT, T.BONE, 15, 0, 2, 2],
	[S.RECT, T.BONE, 19, 0, 2, 2],
	[S.BLOB, T.DARK, 33, 49, 12, 8],
	[S.BLOB, T.FLESH, 34, LINGUA_Y, 9, LINGUA_RY],
	[S.BLOB, T.DARK, 32, QUEIXADA, 11, 5],
	[S.RECT, T.BONE, 25, 39, 1, 3],
	[S.RECT, T.BONE, 28, 39, 1, 3],
	[S.RECT, T.BONE, 31, 39, 1, 3],
	[S.RECT, T.BONE, 34, 39, 1, 3],
	[S.RECT, T.BONE, 37, 39, 1, 3],
	[S.RECT, T.BONE, 40, 39, 1, 3],
	[S.RECT, T.BONE, 26, DENTE, 1, 2],
	[S.RECT, T.BONE, 29, DENTE, 1, 2],
	[S.RECT, T.BONE, 32, DENTE, 1, 2],
	[S.RECT, T.BONE, 35, DENTE, 1, 2],
	[S.RECT, T.BONE, 38, DENTE, 1, 2],
	[S.RECT, T.LIGHT, 36, [33.5, O2, -1.5, AR, -6, BA, 4, CI, -6], 1, [2, CI, 4]],
	[S.GLOW, T.DARK, 28, 58, 2],
	[S.GLOW, T.DARK, 32, 61, 1],
	[S.GLOW, T.DARK, 35, 58, 2],
	[S.GLOW, T.DARK, 31, 55, 1],
	[S.GLOW, T.DARK, 38, 55, 1],
]

## A bainha baloica com a segunda onda; a mao vai com ela.
const BAINHA := [6.5, O2, 1]
const MAO_X := [5, O2, 0.5]

## O manto, a prega do meio, a bainha rota, o capuz bicudo, o buraco onde devia
## estar a cara, o braco comprido de dedos de osso, e os dois olhos.
const TENDER := [
	[S.POLY, T.BODY, -3.5, 37, 3.5, 37, BAINHA, 3, [-6.5, O2, 1], 3],
	[S.RECT, T.DARK, 0, 7, 1, 26],
	[S.RECT, T.BODY, [-6, O2, 1], 1, 1, 2],
	[S.RECT, T.BODY, [-4, O2, 1], 1, 1, 3],
	[S.RECT, T.BODY, [-2, O2, 1], 1, 1, 2],
	[S.RECT, T.BODY, [0, O2, 1], 1, 1, 3],
	[S.RECT, T.BODY, [2, O2, 1], 1, 1, 2],
	[S.RECT, T.BODY, [4, O2, 1], 1, 1, 3],
	[S.POLY, T.LIGHT, -3, 37, -5, 47, 1, 45, 4, 38],
	[S.BLOB, T.DARK, 1.5, 40.5, 2, 2.5],
	[S.LINE, T.LIGHT, 2, 35, MAO_X, 16],
	[S.LINE, T.BONE, MAO_X, 16, [6, O2, 0.5], 12],
	[S.LINE, T.BONE, MAO_X, 16, [4, O2, 0.5], 12],
	[S.GLOW, T.DARK, 1, 41],
	[S.GLOW, T.DARK, 3, 41],
]
