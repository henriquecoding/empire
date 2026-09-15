# src/world/world_palette.gd — as cores e a geometria do greybox, num sitio so.
#
# Tres vistas de faixa desenham a mesma coisa em sitios diferentes (§11), e a
# unica maneira de elas nao divergirem e nao repetirem nenhuma constante. Aqui
# nao ha `draw_` nenhum: sao cores e contas, e quem desenha e o BandView.
#
# Nao ha aqui um sprite. E de proposito: a arte e o ART-01 e a composicao por
# slots e a §58. Isto e o greybox que deixa jogar e medir antes de existir um
# unico pixel desenhado — e o §67 diz que e o greybox que fecha os numeros que a
# arte depois respeita.
class_name WorldPalette
extends RefCounted

const CEU := Color(0.87, 0.92, 0.94)
const SOLO := Color(0.42, 0.29, 0.16)
const SUBSOLO := Color(0.16, 0.12, 0.09)
const AR := Color(0.53, 0.67, 0.76, 0.18)
const LINHA := Color(0.0, 0.0, 0.0, 0.25)

const VAGABUNDO := Color(0.93, 0.85, 0.61)
const MEU := Color(0.45, 0.56, 0.29)
const CHAPEU := Color(0.85, 0.72, 0.28)
const REI := Color(0.82, 0.66, 0.22)
const MORTO := Color(0.35, 0.33, 0.30, 0.6)
const LUTA := Color(0.78, 0.31, 0.24)
const FUGA := Color(0.62, 0.55, 0.78)
const BICHO := Color(0.35, 0.16, 0.22)
const MOEDA := Color(0.96, 0.82, 0.29)
## §80, a regra das duas excecoes: violeta e A Podridao e so A Podridao.
const MANCHA := Color(0.35, 0.22, 0.42, 0.55)
const OBRA := Color(0.55, 0.52, 0.48)
const ANDAIME := Color(0.72, 0.62, 0.42, 0.55)
const VAZIO := Color(0.35, 0.33, 0.30, 0.45)
const PASSAGEM := Color(0.36, 0.55, 0.62, 0.7)
const VIDA := Color(0.35, 0.65, 0.35)

## A escala do §01: um degrau sao 16 px de altura, e a largura e metade.
const DEGRAU := 16.0
const MEIA := 0.5
const MOEDA_R := 3.0
const CONTORNO := 2.0
const BARRA := 3.0
const PASSAGEM_W := 8.0
const ALTURA_OBRA := 14.0
const VIVO_MIN := 0.08


## A linha de chao de cada faixa, em y. A do meio e a do §11; a aerea assenta no
## fundo do plano aereo e a subterranea a meio do corte de solo.
static func ground_of(faixa: int) -> float:
	match faixa:
		int(Band.Kind.AERIAL):
			return float(Band.AERIAL_BOTTOM)
		int(Band.Kind.UNDERGROUND):
			return float(Band.GROUND_LINE + Band.SOIL_CUT * MEIA)
	return float(Band.GROUND_LINE)


## A caixa de um corpo pousado na linha de chao da sua faixa.
static func body(x: float, faixa: int, alto: float) -> Rect2:
	var largo := alto * MEIA
	return Rect2(x - largo * MEIA, ground_of(faixa) - alto, largo, alto)


## A cor de uma tropa: o que ela e, e o que esta a fazer. O chapeu e outra coisa
## e desenha-se por cima — "ele apanha-a e ganha um chapeu" (§25).
static func unit_color(unidades: UnitSystem, i: int) -> Color:
	if not unidades.alive(i):
		return MORTO
	match unidades.states[i]:
		UnitFsm.State.FIGHT:
			return LUTA
		UnitFsm.State.FLEE:
			return FUGA
	return MEU if unidades.owners[i] != RecruitSystem.SEM_DONO else VAGABUNDO
