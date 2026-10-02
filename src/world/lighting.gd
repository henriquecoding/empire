# src/world/lighting.gd — quanta luz chega a cada coisa (§22, §74, §80).
#
# Ate aqui havia um so mecanismo: o `modulate` da faixa, com a cor da fase. Um
# `modulate` multiplica TUDO o que o no desenha, e por isso multiplicava tres
# coisas que nao sao a mesma:
#
#   1 · O CENARIO. Leva o ambiente, e leva-o com o tecto de valores do plano
#       dele (§80 §1). Isto estava certo.
#   2 · Os CORPOS — tropas, criaturas, moedas, obras. O §80 §1 escreve
#       "inalterado" na linha do plano de jogo, e o §80 §3 diz o que os muda:
#       "perto da luz ve-se cor e volume; longe ve-se silhueta".
#   3 · As LUZES. Estas nunca deviam ter levado nada. Uma candeia multiplicada
#       pela noite dava, medido, uma mancha de luminancia 26 contra um ceu de
#       34: a fonte de luz ficava MAIS ESCURA do que o fundo. O §80 diz o
#       contrario, e diz-lo em duas palavras — "ambar e luz".
#
# Isto e o sitio onde as tres se separam. Nao ha aqui `draw_` nenhum: o ambiente
# sai do clock.tres pelo BandLight, as luzes do LightField, as paragens do
# rot.tres.
#
# ADR 0048: o ambiente e o que o olho VE (BandLight.seen), e nao a tinta crua da
# noite, e ja nao ha uma candeia so — ha todas as luzes da faixa, e somam-se. A
# conta de cada uma e a do Glow, e e a mesma que o shader do cenario faz.
class_name Lighting
extends RefCounted

## Quanto uma luz soma ao ambiente na noite funda. As cores sao as do rot.csv;
## isto e a exposicao delas. Passa de 1 para o nucleo de uma fogueira sair mais
## claro do que o que o rodeia mesmo com forca 0,5 — "ambar e luz" (§80).
const GANHO := 1.25
## Duas luzes somadas nao queimam a cor em branco.
const TETO := 1.6
## A altura do meio de um corpo, a contar do chao: e la que a luz o apanha.
const CORPO := 24.0

## O que o olho ve da hora do dia (§22 degrau 3, ADR 0048). Igual em todo o ecra.
var ambient: Color = Color.WHITE
## Quanto as luzes contam: 0 ao meio-dia, 1 na noite funda. Uma fogueira ao sol
## nao alumia nada que se veja.
var dark := 0.0
## As luzes desta faixa, ja a cintilar (LightField).
var glows: Array[Glow] = []
var _chao := float(Band.GROUND_LINE)


## O ambiente da fase. `progresso` e o phase_progress() do relogio.
func set_phase(dados: ClockData, fase: int, progresso: float) -> void:
	ambient = BandLight.seen(dados, fase, progresso)
	dark = darkness(dados, ambient)


## A fase e as luzes de uma faixa, de uma vez: e o que cada desenho pede.
func light(dados: ClockData, faixa: int, fase: int, progresso: float) -> void:
	set_phase(dados, fase, progresso)
	set_glows(LightField.of(faixa), WorldPalette.ground_of(faixa))


func set_glows(lista: Array[Glow], chao: float) -> void:
	glows = lista
	_chao = chao


## 0 com o dia inteiro, 1 com o olho no piso da noite.
static func darkness(dados: ClockData, vista: Color) -> float:
	var piso := dados.night_vision
	if piso >= 1.0:
		return 0.0
	return clampf((1.0 - vista.v) / (1.0 - piso), 0.0, 1.0)


## A luz que chega ao CENARIO de um plano. O `plano` e o tecto de valores do
## §80 §1, que o BandLight ja conta por faixa.
func scenery(plano: float) -> Color:
	return WorldPalette.dim(ambient, plano)


## A luz num ponto do mundo: o ambiente, mais o que cada luz la deixa.
func at(p: Vector2) -> Color:
	var soma := Vector3(ambient.r, ambient.g, ambient.b)
	var ganho := GANHO * dark
	for luz in glows:
		var cor := luz.light_at(p)
		soma += Vector3(cor.r, cor.g, cor.b) * ganho
	return Color(minf(soma.x, TETO), minf(soma.y, TETO), minf(soma.z, TETO))


## A luz que chega a um CORPO em x, a meia altura dele.
func on(x: float) -> Color:
	return at(Vector2(x, _chao - CORPO))


## Quanto um corpo em x esta dentro de uma luz: 1 no nucleo, 0 fora de todas.
func reach(x: float) -> float:
	var p := Vector2(x, _chao - CORPO)
	var perto := 0.0
	for luz in glows:
		perto = maxf(perto, luz.reach_at(p))
	return perto


## A cor com que um corpo se ve. O §80 da duas respostas e esta funcao e as
## duas: PERTO da luz ve-se cor e volume — a cor dele, com a luz que la chega —,
## e LONGE ve-se silhueta, que e um valor escuro so, igual para toda a gente.
##
## A segunda metade nao e gosto, e o defeito que a obrigou mede-se: escurecer a
## cor de cada um pelo ambiente deixava um vagabundo (0,93 0,85 0,61) a
## luminancia 31 contra um ceu a 34. A mesma mancha, e nao se via. Com a
## silhueta ve-se a FORMA, e a forma e que diz o que ele e (§22). Quem se
## aproxima de uma luz recupera a cor, e e isso que faz da luz o assunto da
## noite em vez de um efeito.
func body(cor: Color, x: float) -> Color:
	var iluminado := WorldPalette.tint(cor, on(x))
	return WorldPalette.SILHUETA.lerp(iluminado, maxf(ambient.v, reach(x)))


## A luz de uma LUZ: ela propria, a qualquer hora. Existe como funcao e nao como
## ausencia de chamada para que se veja, no sitio onde se desenha uma chama, que
## nao levar ambiente e uma decisao e nao um esquecimento (§80).
func source() -> Color:
	return Color.WHITE
