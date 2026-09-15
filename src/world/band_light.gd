# src/world/band_light.gd — a luz de cada faixa, por fase do dia (F1-13, §80).
#
# O ticket chama-lhe "CanvasModulate por faixa" e e essa a unica coisa que nao
# se pode fazer: o Godot aceita UM CanvasModulate por canvas, e por isso um por
# faixa e uma contradicao nos termos. O que se usa e o `modulate` de um no por
# faixa, que multiplica pela mesma conta e ao contrario do CanvasModulate pode
# existir tres vezes na mesma arvore (Q-069).
#
# As seis cores vem de data/economy/clock.tres — matiz, saturacao e valor por
# fase — e interpolam ENTRE fases, com o phase_progress() do relogio. Sem isso o
# ecra dava um salto de cor de 15 em 15 segundos, e o §23 pede o contrario: a
# luz e o relogio do jogador, e um relogio nao anda aos saltos.
#
# A noite e castanha e nao azul: 32° · 0,22 · 0,16 (ADR 0011, §80, Q-037).
class_name BandLight
extends RefCounted

## O matiz vem em graus no CSV e a Color quer a volta inteira em 1,0.
const VOLTA := 360.0

## O meio de uma fase. Nao e afinacao: e onde a cor dela e ela propria.
const MEIO := 0.5


## A cor do ambiente — o ceu, e a faixa aerea que vive nele.
##
## A cor de uma fase e a cor do MEIO dela, e nao do principio: entre dois meios
## faz-se a passagem. Interpolar do principio ao fim punha a noite a clarear
## desde o primeiro segundo — aos 62% da noite ela ja estava a 62% do caminho
## para a alvorada, e a noite nunca chegava a ser noite.
##
## Nao ha aqui janela de transicao nenhuma para afinar: o meio de cada fase e o
## unico ponto que a tabela do §80 fixa, e a duracao de cada uma ja esta no
## clock.tres. Uma alvorada de 15 s muda depressa e uma noite de 105 s muda
## devagar, sem que ninguem escreva isso em lado nenhum.
static func ambient(dados: ClockData, fase: int, progresso: float) -> Color:
	var fases := dados.phase_durations.size()
	var t := clampf(progresso, 0.0, 1.0)
	if t < MEIO:
		return _cor(dados, (fase - 1 + fases) % fases).lerp(_cor(dados, fase), t + MEIO)
	return _cor(dados, fase).lerp(_cor(dados, (fase + 1) % fases), t - MEIO)


## A cor do TERRENO desta faixa. O §80 da UM numero para isto — "o chao da noite
## desce abaixo do ambiente: 0,11" contra os 0,16 do ambiente — e nao da outro.
##
## Dai sai uma RAZAO, e nao tres valores escritos a mao: o chao vale
## night_value_floor / valor_da_noite do ambiente, e vale isso em todas as fases,
## porque uma sombra e uma fraccao da luz que a faz e nao uma cor propria. O
## subsolo leva a mesma razao outra vez, pela mesma razao de nao haver segundo
## numero: inventar-lhe um era escrever balanceamento em codigo (Q-069).
static func of(dados: ClockData, faixa: Band.Kind, fase: int, progresso: float) -> Color:
	return ambient(dados, fase, progresso) * plane(dados, faixa)


## Quanto da luz do ambiente chega ao PLANO desta faixa. E so para o cenario: a
## tabela do §80 poe tecto de valores na distancia, no plano medio e no primeiro
## plano, e escreve "inalterado" na linha do PLANO DE JOGO — que e onde as
## tropas, as moedas e as criaturas estao. Baixar tambem essas era pintar de
## preto aquilo que a §22 manda deixar com a paleta toda.
static func plane(dados: ClockData, faixa: Band.Kind) -> float:
	var razao := ground_ratio(dados)
	match faixa:
		Band.Kind.SURFACE:
			return razao
		Band.Kind.UNDERGROUND:
			return razao * razao
	return 1.0


## A fraccao da luz do ambiente que chega ao chao. Lida dos dois numeros do §80,
## e nao escrita: mudar o night_value_floor no CSV muda isto sozinho.
static func ground_ratio(dados: ClockData) -> float:
	var noite := dados.phase_tint_val[GameClock.Phase.NIGHT]
	if noite <= 0.0:
		return 1.0
	return clampf(dados.night_value_floor / noite, 0.0, 1.0)


static func _cor(dados: ClockData, fase: int) -> Color:
	return Color.from_hsv(
		dados.phase_tint_hue[fase] / VOLTA, dados.phase_tint_sat[fase], dados.phase_tint_val[fase]
	)
