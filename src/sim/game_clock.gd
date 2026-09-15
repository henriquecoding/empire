# src/sim/game_clock.gd — o relogio, e mais nada (§48, §30, ADR 0006).
#
# Tudo o resto no jogo pergunta ao relogio; o relogio nao pergunta a ninguem.
# E puro: nao e Node, nao emite sinais, nao sabe o que e um EventBus. tick()
# DEVOLVE as transicoes e o src/core/clock_service.gd e que as traduz — e o que
# permite testar seis fases e a viragem do dia em milissegundos, sem abrir o
# motor, e o que mantem a I1 de pe.
#
# As duracoes vem de data/economy/clock.tres, gerado de data/source/clock.csv.
# Nenhuma esta escrita aqui: mudar a tarde de 85 para 95 segundos e mudar uma
# celula de um CSV, e mais nada no jogo se apercebe (a regra da fase, §48).
class_name GameClock
extends RefCounted

enum Phase { DAWN, MORNING, NOON, AFTERNOON, DUSK, NIGHT }

## As chaves dos dicionarios que o tick() devolve. Quem traduz le estas, nao
## strings soltas espalhadas por tres ficheiros.
const EVENTO := &"type"
const EVENTO_DIA := &"day"
const EVENTO_FASE := &"phase"
const CAMPO_DIA := &"day"
const CAMPO_DE := &"from"
const CAMPO_PARA := &"to"

var day: int = 1
var elapsed: float = 0.0

var _durations: PackedFloat32Array
var _day_length: float
var _day_min: float
var _day_max: float


func _init(cfg: ClockData) -> void:
	assert(cfg != null, "o GameClock precisa de um ClockData (§30)")
	assert(cfg.phase_durations.size() == Phase.size(), "faltam fases em phase_durations")
	_durations = cfg.phase_durations.duplicate()
	_day_min = cfg.day_seconds_min
	_day_max = cfg.day_seconds_max
	_day_length = _soma(_durations)


## Avanca o relogio e devolve as transicoes deste passo, pela ordem em que
## aconteceram. Quem chama e que emite os sinais do §46 — aqui nao ha EventBus.
func tick(delta: float) -> Array[Dictionary]:
	var eventos: Array[Dictionary] = []
	var antes := current_phase()
	elapsed += delta
	while elapsed >= _day_length:
		elapsed -= _day_length
		day += 1
		eventos.append({EVENTO: EVENTO_DIA, CAMPO_DIA: day})
	var depois := current_phase()
	if depois != antes:
		eventos.append({EVENTO: EVENTO_FASE, CAMPO_DE: antes, CAMPO_PARA: depois})
	return eventos


## A fase agora. A fronteira e fechada a esquerda: aos 15,0 s exatos ja e
## MORNING, nao DAWN — senao o ultimo instante de cada fase pertence a duas.
func current_phase() -> Phase:
	var acumulado := 0.0
	for i in _durations.size():
		acumulado += _durations[i]
		if elapsed < acumulado:
			return i as Phase
	return Phase.NIGHT


## 0,0 a 1,0 dentro da fase atual.
func phase_progress() -> float:
	var acumulado := 0.0
	for i in _durations.size():
		if elapsed < acumulado + _durations[i]:
			return (elapsed - acumulado) / _durations[i]
		acumulado += _durations[i]
	return 1.0


## Quantos segundos faltam para a proxima entrada em p. Se p ja passou hoje,
## conta pela volta ao dia seguinte.
func seconds_until(p: Phase) -> float:
	var inicio := 0.0
	for i in int(p):
		inicio += _durations[i]
	var falta := inicio - elapsed
	return falta if falta >= 0.0 else falta + _day_length


## O dia inteiro, em segundos.
func day_seconds() -> float:
	return _day_length


## Quanto dura uma fase, agora. Muda com set_day_seconds().
func phase_duration(p: Phase) -> float:
	return _durations[int(p)]


## Os limites do slider de acessibilidade (§26), para quem o desenhar. O relogio
## NAO os aplica: quem escolhe o valor e que decide se os respeita, e um teste
## que queira um dia de 180 s tem de o conseguir.
func day_seconds_bounds() -> Vector2:
	return Vector2(_day_min, _day_max)


## Muda a duracao do dia escalando as seis fases na mesma proporcao (§26). O
## elapsed escala com elas para que a fase e o progresso nao saltem no instante
## em que o jogador mexe no slider.
func set_day_seconds(segundos: float) -> void:
	assert(segundos > 0.0, "um dia tem de durar alguma coisa")
	var fator := segundos / _day_length
	for i in _durations.size():
		_durations[i] = _durations[i] * fator
	elapsed = elapsed * fator
	_day_length = segundos


func _soma(valores: PackedFloat32Array) -> float:
	var total := 0.0
	for v in valores:
		total += v
	return total
