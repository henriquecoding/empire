# src/world/beasts_small.gd — os tres pequenos da noite (§07, §25, ADR 0049).
#
# O Rastejante, o Alado e o Cavador, em tracos de pixeis de criatura (BeastPen): x
# para a frente, y a subir dos pes. Cada um le-se por uma coisa so, a qualquer
# distancia:
#
#   Rastejante — rente ao chao e de patas arqueadas por cima do corpo, como uma
#                aranha. Sao muitos, e o que se ve e o enxame a tremer.
#   Alado      — as asas de membrana. Batem depressa, e e o unico que nao toca no
#                chao; a asa nunca fica de lado ao ponto de desaparecer.
#   Cavador    — a broca no focinho a rodar e as garras de cavar. Vem de baixo, e
#                atira terra para tras quando anda.
#
# Um numero animado e [base, sinal, k...] (BeastPen.value): a pata anda com o passo,
# a asa bate com a onda, a mandibula abre com a arma.
class_name BeastsSmall
extends RefCounted

const S := BeastPen.Stroke
const T := BeastPen.Tone
const PA := BeastPen.Sinal.PASSO
const CO := BeastPen.Sinal.CONTRA
const ON := BeastPen.Sinal.ONDA
const O2 := BeastPen.Sinal.ONDA2
const AR := BeastPen.Sinal.ARMA
const BA := BeastPen.Sinal.BATE
const CI := BeastPen.Sinal.CICLO
const C2 := BeastPen.Sinal.CICLO2
const AN := BeastPen.Sinal.ANDA

## As patas de la no escuro, o corpo aos aneis, a cabeca, as mandibulas que abrem a
## armar, e as patas de ca, que apanham a luz. Os joelhos ficam por cima do corpo.
const CRAWLER := [
	[S.LINE, T.DARK, -7, 5, [-5.5, CO, 1], 11],
	[S.LINE, T.DARK, [-5.5, CO, 1], 11, [-4, CO, 2], 0],
	[S.LINE, T.DARK, -2, 5, [-0.5, PA, 1], 11],
	[S.LINE, T.DARK, [-0.5, PA, 1], 11, [1, PA, 2], 0],
	[S.LINE, T.DARK, 3, 5, [4.5, CO, 1], 11],
	[S.LINE, T.DARK, [4.5, CO, 1], 11, [6, CO, 2], 0],
	[S.BLOB, T.BODY, -6, 5, 6.5, 4],
	[S.BLOB, T.LIGHT, -6, 7, 5, 1.5],
	[S.BLOB, T.BODY, 1.5, 5, 4, 3],
	[S.BLOB, T.LIGHT, 1.5, 6.5, 3, 1],
	[S.RECT, T.DARK, -8, 2, 1, 6],
	[S.RECT, T.DARK, -4, 2, 1, 6],
	[S.RECT, T.DARK, -1, 2, 1, 6],
	[S.RECT, T.DARK, -11, 1, 11, 1],
	[S.RECT, T.BONE, -9, 9, 1, 2],
	[S.RECT, T.BONE, -6, 8, 1, 2],
	[S.RECT, T.BONE, -3, 9, 1, 2],
	[S.RECT, T.BONE, 0, 8, 1, 2],
	[S.BLOB, T.DARK, 7, 4.5, 3, 2.5],
	[S.LINE, T.BONE, 9, 5, 12.5, [6, AR, 2]],
	[S.LINE, T.BONE, 9, 3, 12.5, [2, AR, -2]],
	[S.LINE, T.LIGHT, -8, 5, [-6.5, PA, 1], 11],
	[S.LINE, T.LIGHT, [-6.5, PA, 1], 11, [-5, PA, 2], 0],
	[S.LINE, T.LIGHT, -3, 5, [-1.5, CO, 1], 11],
	[S.LINE, T.LIGHT, [-1.5, CO, 1], 11, [0, CO, 2], 0],
	[S.LINE, T.LIGHT, 2, 5, [3.5, PA, 1], 11],
	[S.LINE, T.LIGHT, [3.5, PA, 1], 11, [5, PA, 2], 0],
	[S.GLOW, T.DARK, 8, 5],
	[S.GLOW, T.DARK, 9, 3],
]

## A asa: ombro, pulso e ponta pela frente, e tres pontos de tras em arco. O y de cada
## ponto vai com a onda — ON a de ca, O2 a de la, um pouco atras.
const ASA_CA := [
	1, 13, -8, [13, ON, 6], -18, [14, ON, 10], -15, [10, ON, 5], -10, [9, ON, 2], -4, 11
]
const ASA_LA := [
	1, 13, -8, [13, O2, 6], -18, [14, O2, 10], -15, [10, O2, 5], -10, [9, O2, 2], -4, 11
]

## A asa de la, a cauda com farpa, as garras que batem para a frente, o corpo, a
## cabeca de orelhas e a asa de ca, com os dedos de osso.
const WINGED := [
	[S.POLY, T.DARK] + ASA_LA,
	[S.LINE, T.DARK, -4, 12, -12, [11, O2, 2]],
	[S.RECT, T.BONE, -13, [10, O2, 2], 2, 2],
	[S.LINE, T.DARK, 0, 9, [-1, BA, 3], 4],
	[S.LINE, T.DARK, 2, 9, [2, BA, 3], 4],
	[S.RECT, T.BONE, [-1, BA, 3], 3, 1, 1],
	[S.RECT, T.BONE, [2, BA, 3], 3, 1, 1],
	[S.BLOB, T.BODY, 0, 12, 5, 3.5],
	[S.BLOB, T.LIGHT, 0, 14, 3.5, 1],
	[S.BLOB, T.DARK, 6, 13, 3, 2.5],
	[S.LINE, T.DARK, 5, 15, 4, 18],
	[S.LINE, T.DARK, 7, 15, 8, 18],
	[S.RECT, T.BONE, 8, 11, 1, 2],
	[S.POLY, T.BODY] + ASA_CA,
	[S.LINE, T.LIGHT, 1, 13, -8, [13, ON, 6]],
	[S.LINE, T.LIGHT, -8, [13, ON, 6], -18, [14, ON, 10]],
	[S.LINE, T.LIGHT, -8, [13, ON, 6], -15, [10, ON, 5]],
	[S.LINE, T.LIGHT, -8, [13, ON, 6], -10, [9, ON, 2]],
	[S.GLOW, T.DARK, 7, 14],
]

## A pata de tras, o corpo, as placas do dorso, o braco que cava (a andar ou a
## armar), as tres garras, a broca, as espiras que rodam com o ciclo, o olho
## pequeno, e a terra que voa para tras so quando anda.
const BURROWER := [
	[S.RECT, T.DARK, -10, 0, 4, 4],
	[S.BLOB, T.BODY, -2, 9, 10, 8],
	[S.BLOB, T.DARK, -2, 4, 8, 3],
	[S.BLOB, T.LIGHT, -8, 13.8, 2.5, 1.2],
	[S.BLOB, T.LIGHT, -4, 14.6, 2.5, 1.2],
	[S.BLOB, T.LIGHT, 0, 14.6, 2.5, 1.2],
	[S.BLOB, T.LIGHT, 4, 13.8, 2.5, 1.2],
	[S.RECT, T.DARK, -6, 12, 1, 4],
	[S.RECT, T.DARK, -2, 12, 1, 4],
	[S.RECT, T.DARK, 2, 12, 1, 4],
	[S.LINE, T.DARK, 5, 8, 10, [3, PA, 2, AR, 2], 2],
	[S.LINE, T.BONE, 10, [3, PA, 2, AR, 2], 12, [1, PA, 2, AR, 2]],
	[S.LINE, T.BONE, 10, [3, PA, 2, AR, 2], 12.5, [3, PA, 2, AR, 2]],
	[S.LINE, T.BONE, 10, [3, PA, 2, AR, 2], 12, [5, PA, 2, AR, 2]],
	[S.POLY, T.BONE, 7, 7, 15, 10, 7, 13],
	[S.RECT, T.DARK, [8, CI, 2], 7.75, 1, 4.5],
	[S.RECT, T.DARK, [10, CI, 2], 8.5, 1, 3],
	[S.RECT, T.DARK, [12, CI, 2], 9.25, 1, 1.5],
	[S.GLOW, T.DARK, 6, 12],
	[S.RECT, T.DARK, [9, C2, -10], [2, C2, 3], 1, [0, AN, 1]],
	[S.RECT, T.DARK, [7, CI, -6], [3, CI, 2], 1, [0, AN, 1]],
]
