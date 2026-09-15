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
# Isto e o sitio onde as tres se separam. Nao ha aqui `draw_` nenhum e nao ha
# nenhum numero: o ambiente sai do clock.tres pelo BandLight, o raio e as
# paragens saem do rot.tres pelo WorldLight.
class_name Lighting
extends RefCounted

## O LUT de hora do dia (§22 degrau 3). Igual em todo o ecra, a qualquer hora.
var ambient: Color = Color.WHITE

## A luz pontual que domina o ecra (§80 §3: "uma luz domina por ecra"). Hoje e
## sempre a candeia da Podridao — o farol e Fase 6, e a Q-078 e sobre qual das
## duas ganha quando as duas existirem.
var lamp_x: float = 0.0
var lamp_radius: float = 0.0
var lamp_core: Color = Color.WHITE


## O ambiente da fase. `progresso` e o phase_progress() do relogio.
func set_phase(dados: ClockData, fase: int, progresso: float) -> void:
	ambient = BandLight.ambient(dados, fase, progresso)


## Onde esta a luz que domina, e que raio tem. Sem luz nenhuma o alcance e zero
## em todo o lado, e entao so ha ambiente — que e o que um dia e.
func set_lamp(x: float, raio: float, nucleo: Color) -> void:
	lamp_x = x
	lamp_radius = raio
	lamp_core = nucleo


func clear_lamp() -> void:
	set_lamp(0.0, 0.0, Color.WHITE)


## A luz que chega ao CENARIO de um plano. O `plano` e o tecto de valores do
## §80 §1, que o BandLight ja conta por faixa.
func scenery(plano: float) -> Color:
	return WorldPalette.dim(ambient, plano)


## A luz que chega a um CORPO em x. No centro da candeia e a candeia; no bordo e
## o ambiente; pelo meio e a passagem de uma para o outro.
func on(x: float) -> Color:
	return ambient.lerp(lamp_core, WorldLight.reach(x, lamp_x, lamp_radius))


## A cor com que um corpo se ve. O §80 §3 da duas respostas e esta funcao e as
## duas: PERTO da luz ve-se cor e volume — a cor dele, com a luz que la chega —,
## e LONGE ve-se silhueta, que e um valor escuro so, igual para toda a gente.
##
## A segunda metade nao e gosto, e o defeito que a obrigou mede-se: escurecer a
## cor de cada um pelo ambiente deixava um vagabundo (0,93 0,85 0,61) a
## luminancia 31 contra um ceu a 34. A mesma mancha, e nao se via. Com a
## silhueta fica a 16 contra 34 — ve-se a FORMA, e a forma e que diz o que ele e
## (§22). Quem se aproxima da candeia recupera a cor, e e isso que faz da luz o
## assunto da noite em vez de um efeito.
func body(cor: Color, x: float) -> Color:
	var perto := WorldLight.reach(x, lamp_x, lamp_radius)
	var iluminado := WorldPalette.tint(cor, ambient.lerp(lamp_core, perto))
	return WorldPalette.SILHUETA.lerp(iluminado, maxf(ambient.v, perto))


## A luz de uma LUZ: ela propria, a qualquer hora. Existe como funcao e nao como
## ausencia de chamada para que se veja, no sitio onde se desenha uma chama, que
## nao levar ambiente e uma decisao e nao um esquecimento (§80).
func source() -> Color:
	return Color.WHITE
