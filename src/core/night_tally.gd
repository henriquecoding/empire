# src/core/night_tally.gd — quem conta a noite, para o night_survived da §46.
#
# O sinal esta no catalogo desde o F0-07 e nunca teve quem o emitisse: a §46
# da-lhe `deaths` e `walls_lost` e o F0-06 registou, por escrito, que o emissor
# "entra com o F1-12 e o F1-15". E este ficheiro. Nao e telemetria a mais — e o
# unico numero que o §32 aceita como resposta a "a curva de dificuldade esta
# certa?", e e o mesmo numero que o PLAYTEST_PLAN mede a mao.
#
# Conta do crepusculo ao amanhecer, e nao do dia inteiro: uma tropa que morreu
# de tarde nao e uma tropa que a noite levou. O §48 emite ao virar do dia, com o
# dia que acabou — por isso o balcao zera ao crepusculo e nao ao amanhecer, ou o
# sinal saia sempre com zero.
#
# Nao e Node e nao e autoload: quem o liga ao EventBus e o SimLoop, uma vez, no
# _ready(). Assim nao ha um autoload novo no project.godot nem uma ordem nova
# para ninguem adivinhar (ADR 0020, regra 8b).
class_name NightTally
extends RefCounted

## O dia 1 nao tem noite atras dele. Sem isto o primeiro amanhecer anunciava uma
## noite que nunca aconteceu — e um zero a mais estraga uma serie de telemetria
## tao bem como um numero errado.
const PRIMEIRO_DIA := 1

var deaths: int = 0
var walls_lost: int = 0


## Liga-se ao catalogo. Chamado uma vez, pelo dono: ligar duas vezes contava
## cada morte duas vezes, e um balcao que conta a dobrar e pior do que nenhum.
func listen() -> void:
	EventBus.unit_died.connect(_morreu)
	EventBus.wall_breached.connect(_rompeu)
	EventBus.dusk_fell.connect(_crepusculo)


## Zera. O crepusculo faz isto sozinho; isto e para quem comeca um jogo novo a
## meio de uma noite — um teste, uma ferramenta, um save.
func reset() -> void:
	deaths = 0
	walls_lost = 0


## Os tres argumentos do night_survived, na ordem da §46. Devolve vazio no dia
## em que nao ha noite para contar, e quem chama le isso como "nao anuncies".
func of_night(dia: int) -> Array:
	if dia <= PRIMEIRO_DIA:
		return []
	return [dia - 1, deaths, walls_lost]


func _morreu(_unit_id: int, _x: float, _band: int, _drops: PackedStringArray) -> void:
	deaths += 1


func _rompeu(_wall_id: int) -> void:
	walls_lost += 1


func _crepusculo(_dia: int) -> void:
	reset()
