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
## Por onde ela ja passou (§51). O mesmo violeta, mais fundo e mais fino: e uma
## marca no chao e nao uma massa, e o §80 nao deixa entrar aqui uma terceira cor
## fria — o rasto e a mancha sao a mesma coisa em dois momentos.
const TRILHO := Color(0.35, 0.22, 0.42, 0.28)
const OBRA := Color(0.55, 0.52, 0.48)
const ANDAIME := Color(0.72, 0.62, 0.42, 0.55)
const VAZIO := Color(0.35, 0.33, 0.30, 0.45)
const PASSAGEM := Color(0.36, 0.55, 0.62, 0.7)
const VIDA := Color(0.35, 0.65, 0.35)
## A sombra de contacto do §22. Nao e uma cor nova: e o valor de silhueta do §80
## com opacidade, porque uma sombra e o chao visto por baixo de uma coisa e nao
## uma mancha por cima dele.
const SOMBRA := Color(0.063, 0.051, 0.035, 0.45)

## §24: "Impacto — flash branco de 80 ms". Branco, e nao a cor mais clara da
## paleta: e feedback e nao cenario, como os instrumentos do Gauge (Q-080), e o
## que ele tem de fazer e ler-se contra qualquer corpo a qualquer hora do dia.
const FLASH := Color(1.0, 1.0, 1.0, 0.85)

## §80 §1, a linha do primeiro plano: "#100D09 e #14140F. Sobrepoe-se as tropas e
## nao compete com elas." E o valor mais escuro que a paleta do dossie usa para
## PREENCHER — o §80 abre a seccao a dizer que ate ai o mais escuro so servia de
## contorno, e que passam a existir tres valores de silhueta.
##
## Aqui e a cor de um corpo longe de qualquer luz (§80 §3: "perto da luz ve-se
## cor e volume; longe ve-se silhueta"). Sem ela, "longe" era a cor de cada um
## multiplicada pelo ambiente — e isso deixava um vagabundo a luminancia 31
## contra um ceu a 34, que e a mesma mancha e nao se ve.
const SILHUETA := Color(0.063, 0.051, 0.035)

## A escala do §01: um degrau sao 16 px de altura, e a largura e metade.
const DEGRAU := 16.0
const MEIA := 0.5
const MOEDA_R := 3.0
const CONTORNO := 2.0
const BARRA := 3.0
const PASSAGEM_W := 8.0
## Que fatia do corpo o saco ocupa quando esta cheio (§24). Enche de baixo para
## cima, como um saco enche — e nao e uma barra de recurso ao contrario.
const SACO := 0.35
## A altura do rasto, em px. Um degrau de silhueta e meio: ve-se de longe e nao
## tapa quem esta em cima dele.
const RASTO := DEGRAU * MEIA


## Escurecer uma cor sem lhe tirar opacidade.
##
## Existe por causa de um defeito que custou a noite inteira: em GDScript,
## `Color * float` multiplica QUATRO componentes, e a quarta e o alfa. O chao era
## desenhado com `SOLO * plane()` — 0,6875 — e por isso saia a 69% de opacidade
## sobre o cinzento por omissao do motor. De noite o solo dava (32, 29, 26) em
## vez de (12, 7, 4), a um passo do ceu em (36, 34, 30): sem horizonte, e sem
## horizonte nao ha §11 nenhum. Escurecer sao TRES componentes.
static func dim(cor: Color, luz: float) -> Color:
	return Color(cor.r * luz, cor.g * luz, cor.b * luz, cor.a)


## A mesma regra com uma COR de luz em vez de um numero: tres componentes, e a
## opacidade da coisa fica a ser a dela. E o que o `modulate` fazia ao no todo, e
## que agora se aplica onde ele manda — no cenario e nos corpos, nao nas luzes.
static func tint(cor: Color, luz: Color) -> Color:
	return Color(cor.r * luz.r, cor.g * luz.g, cor.b * luz.b, cor.a)


## A linha de chao de cada faixa, em y. A do meio e a do §11; a aerea assenta no
## fundo do plano aereo e a subterranea a meio do corte de solo.
static func ground_of(faixa: int) -> float:
	match faixa:
		int(Band.Kind.AERIAL):
			return float(Band.AERIAL_BOTTOM)
		int(Band.Kind.UNDERGROUND):
			return float(Band.GROUND_LINE + Band.SOIL_CUT * MEIA)
	return float(Band.GROUND_LINE)


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
