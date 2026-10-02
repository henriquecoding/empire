# src/world/beasts_large.gd — os dois pesados da noite (§07, §51, ADR 0049).
#
# O Bruto e o Ariete de lodo, em tracos de pixeis de criatura (BeastPen). Os dois
# sao massa, e a massa le-se de maneira diferente em cada um:
#
#   Bruto  — alto e corcunda, maior do que uma tropa e mais baixo do que o rei:
#            anda nos nos dos dedos, e o braco e a arma — arma-se por cima da
#            cabeca e cai. Leva no dorso o que a Podridao lhe fez crescer.
#   Ariete — comprido e baixo, uma lesma de lodo que ondula e pinga, com um cranio
#            de carneiro a frente. Nao olha para ninguem: o cranio e para o muro
#            (§07), e recua antes de investir.
class_name BeastsLarge
extends RefCounted

const S := BeastPen.Stroke
const T := BeastPen.Tone
const PA := BeastPen.Sinal.PASSO
const ON := BeastPen.Sinal.ONDA
const O2 := BeastPen.Sinal.ONDA2
const AR := BeastPen.Sinal.ARMA
const BA := BeastPen.Sinal.BATE
const CI := BeastPen.Sinal.CICLO
const C2 := BeastPen.Sinal.CICLO2

## O punho de ca: em descanso a frente e no chao, armado por cima da cabeca, a
## bater mais a frente. E o cotovelo vai com ele.
const PUNHO_X := [15, PA, 2, AR, -9, BA, 4]
const PUNHO_Y := [2, AR, 34, BA, 2]
const COTOVELO_X := [13, AR, -2]
const COTOVELO_Y := [13, AR, 18]

## O braco de la, as pernas curtas, a anca, o peito que respira, a corcunda, os
## espinhos e o fungo, a cabeca baixa com a boca que abre a armar, e o braco de ca.
const BRUTE := [
	[S.LINE, T.DARK, 4, 24, [14, PA, -2], 2, 3],
	[S.BLOB, T.DARK, [14, PA, -2], 2, 2.5, 2],
	[S.LINE, T.DARK, -9, 12, [-11, PA, -1], 0, 4],
	[S.BLOB, T.BODY, -6, 15, 7, 7],
	[S.LINE, T.BODY, -6, 12, [-6, PA, 1], 0, 4],
	[S.RECT, T.DARK, [-8, PA, 1], 0, 5, 2],
	[S.BLOB, T.BODY, 1, 23, 11, [10, ON, 0.4]],
	[S.BLOB, T.LIGHT, -1, 29, 8, 4],
	[S.BLOB, T.DARK, 2, 15, 7, 4],
	[S.LINE, T.BONE, -6, 30, -8, 36],
	[S.LINE, T.BONE, -2, 32, -3, 38],
	[S.LINE, T.BONE, 2, 32, 3, 37],
	[S.BLOB, T.FLESH, -4, 33, 3, 2],
	[S.RECT, T.BONE, -5, 33, 1, 1],
	[S.RECT, T.BONE, -3, 34, 1, 1],
	[S.BLOB, T.DARK, 11, 21, 4, 3.5],
	[S.RECT, T.BODY, 9, 23, 6, 1],
	[S.RECT, T.DARK, 11, [17, AR, -2], 4, 2],
	[S.RECT, T.BONE, 12, [18, AR, -2], 1, 1],
	[S.RECT, T.BONE, 14, [18, AR, -2], 1, 1],
	[S.GLOW, T.DARK, 13, 21],
	[S.LINE, T.LIGHT, 5, 23, COTOVELO_X, COTOVELO_Y, 4],
	[S.LINE, T.LIGHT, COTOVELO_X, COTOVELO_Y, PUNHO_X, PUNHO_Y, 3],
	[S.BLOB, T.DARK, PUNHO_X, PUNHO_Y, 3, 2.5],
	[S.RECT, T.BONE, [16, PA, 2, AR, -9, BA, 4], [1, AR, 34, BA, 2], 1, 1],
	[S.RECT, T.BONE, [16, PA, 2, AR, -9, BA, 4], [3, AR, 34, BA, 2], 1, 1],
]

## O cranio recua a armar e investe a bater: o x de tudo o que e da cabeca.
const CRANIO := [25, BA, 3, AR, -2]

## O lodo em seis bocados que ondulam desencontrados, o brilho por cima, o fundo, o
## que ele engoliu, o que lhe cresce no dorso, o que pinga, e a cabeca: o chifre de
## la, o cranio, o focinho, a orbita com o olho, o chifre de ca enrolado, e o lodo
## que escorre do focinho.
const SLIME_RAM := [
	[S.BLOB, T.BODY, -26, [6, ON, 0.8], 6.5, [6, ON, 0.8]],
	[S.BLOB, T.BODY, -18, [7.2, O2, 0.8], 6.5, [7.2, O2, 0.8]],
	[S.BLOB, T.BODY, -10, [8.4, ON, 0.8], 6.5, [8.4, ON, 0.8]],
	[S.BLOB, T.BODY, -2, [9.6, O2, 0.8], 6.5, [9.6, O2, 0.8]],
	[S.BLOB, T.BODY, 6, [10.8, ON, 0.8], 6.5, [10.8, ON, 0.8]],
	[S.BLOB, T.BODY, 14, [12, O2, 0.8], 6.5, [12, O2, 0.8]],
	[S.BLOB, T.LIGHT, -26, [9.3, ON, 1.24], 4.5, 1.5],
	[S.BLOB, T.LIGHT, -18, [11.16, O2, 1.24], 4.5, 1.5],
	[S.BLOB, T.LIGHT, -10, [13.02, ON, 1.24], 4.5, 1.5],
	[S.BLOB, T.LIGHT, -2, [14.88, O2, 1.24], 4.5, 1.5],
	[S.BLOB, T.LIGHT, 6, [16.74, ON, 1.24], 4.5, 1.5],
	[S.BLOB, T.LIGHT, 14, [18.6, O2, 1.24], 4.5, 1.5],
	[S.RECT, T.DARK, -31, 0, 54, 2],
	[S.LINE, T.BONE, -18, 7, -14, 10],
	[S.LINE, T.BONE, -6, 12, -3, 9],
	[S.RECT, T.BONE, -10, 5, 2, 2],
	[S.BLOB, T.FLESH, -22, 13, 2, 1.5],
	[S.BLOB, T.FLESH, -13, 14.4, 2, 1.5],
	[S.BLOB, T.FLESH, -4, 15.8, 2, 1.5],
	[S.BLOB, T.FLESH, 5, 17.2, 2, 1.5],
	[S.RECT, T.LIGHT, -20, [3, CI, -3], 1, [1, CI, 2]],
	[S.RECT, T.LIGHT, -8, [3, C2, -3], 1, [1, C2, 2]],
	[S.RECT, T.LIGHT, 4, [3, CI, -3], 1, [1, CI, 2]],
	[S.LINE, T.DARK, [22, BA, 3, AR, -2], 18, [17, BA, 3, AR, -2], 23, 3],
	[S.BLOB, T.BONE, CRANIO, 13, 6, 6],
	[S.RECT, T.BONE, [28, BA, 3, AR, -2], 7, 5, 6],
	[S.RECT, T.DARK, [31, BA, 3, AR, -2], 10, 1, 1],
	[S.BLOB, T.DARK, [26, BA, 3, AR, -2], 15, 1.5, 1.5],
	[S.GLOW, T.DARK, [26, BA, 3, AR, -2], 15],
	[S.LINE, T.LIGHT, [23, BA, 3, AR, -2], 18, [18, BA, 3, AR, -2], 24, 3],
	[S.LINE, T.LIGHT, [18, BA, 3, AR, -2], 24, [15, BA, 3, AR, -2], 21, 2],
	[S.LINE, T.LIGHT, [15, BA, 3, AR, -2], 21, [17, BA, 3, AR, -2], 17, 2],
	[S.RECT, T.BODY, [29, BA, 3, AR, -2], [6, CI, -4], 1, [2, CI, 3]],
	[S.RECT, T.BODY, [31, BA, 3, AR, -2], [6, C2, -4], 1, [2, C2, 3]],
]
