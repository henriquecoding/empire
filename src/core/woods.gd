# src/core/woods.gd — a densidade do bosque, uma so para o cenario e para as arvores
# (ADR 0070).
#
# Ate aqui so o Wilds (cenario) lia este ruido. As arvores da simulacao nascem onde ele
# e alto, e por isso o feto, o arbusto e o carvalho ficam no mesmo bosque e a clareira
# fica vazia dos tres. A regiao N le o ruido a partir de N * TROCO: atravessar e chegar
# a terra nova (Q-135).
class_name Woods
extends RefCounted

const SAL := 11
const TROCO := 100000.0
## O ruido do motor anda em [-0,75, 0,65]; isto abre-o a [0, 1].
const RUIDO := {"frequencia": 0.0021, "oitavas": 3, "ganho": 0.8}
const MEIO := 0.5


## O ruido do bosque para esta semente.
static func noise() -> FastNoiseLite:
	return RngService.noise(SAL, RUIDO.frequencia, RUIDO.oitavas)


## A densidade do bosque em `x`, de 0 a 1, para `ruido` ja semeado.
static func density(ruido: Noise, x: float) -> float:
	return clampf(MEIO + ruido.get_noise_1d(x) * RUIDO.ganho, 0.0, 1.0)
