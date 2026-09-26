# src/sim/systems/rot_system.gd — a Podridao, que e uma entidade e nao um
# spawner (§51, F1-08).
#
# Tem posicao continua, um orcamento de massa e e a UNICA fonte de criaturas do
# jogo. E essa a diferenca que a §05 defende: um spawner produz inimigos por
# relogio; isto gasta um orcamento que o jogador escreveu de dia — fortalezas
# conquistadas, Amargueiros deixados de pe, ofertas recusadas (§74, §75).
#
# Puro, e com a mesma consequencia que o CoinSystem ja tinha: o sorteio do
# intervalo entre invocacoes vem de FORA, ja tirado do fluxo `rot`. A simulacao
# nao pode pedir um numero ao acaso (§42, §70) e o portao G2 chumbava aqui um
# randf_range. Por isso ha duas funcoes onde o dossie so ve uma: needs_interval()
# diz que esta por armar e arm() entrega o numero. O tick() fica com a
# assinatura que o F1-08 escreve.
#
# O que NAO esta aqui: o Zelador, que nasce da Divida da Candeia e nao da massa
# (§75) e por isso nem entra na escolha; a arte da mancha (F1-17); a Oferta
# (XIII-04).
class_name RotSystem
extends RefCounted

## next_summon_at abaixo de zero e "por armar". Nao e afinacao: e a sentinela
## que separa "ainda faltam 3 s" de "ninguem me deu o intervalo".
const NAO_ARMADA := -1.0

## O tecto de recusas que contam para a massa (§74: min(recusas, 5)).
const RECUSAS_MAX := 5

const SEM_CRIATURA := &""

var state := RotState.new()

## O que o jogador escreveu de dia, e que a noite le (§74). Fica em campos
## publicos porque muda de dia para dia e o spawn() do F1-08 so recebe tres
## argumentos — acrescenta-los a assinatura era mudar o contrato do ticket.
var fortresses: int = 0
var amargueiros: int = 0
var named_amargueiros: int = 0
var refusals: int = 0
## O lado desta noite, sorteado a tarde e dito no mundo antes do crepusculo (Q-125).
## Zero e ainda nao dito.
var announced: int = 0

var _perfil: RotProfile
var _tabela: Array[CreatureData] = []
var _dia: int = 0
var _direcao: float = 0.0


## A tabela de criaturas entra ordenada por custo DECRESCENTE, uma vez. "A mais
## cara que cabe" percorre-a de cima para baixo e a primeira que serve e a
## resposta — sem ordenar 30 vezes por segundo.
func _init(perfil: RotProfile, criaturas: Array[CreatureData]) -> void:
	assert(perfil != null, "o RotSystem precisa de um RotProfile")
	_perfil = perfil
	for c in criaturas:
		if c.mass_cost > 0 and c.from_debt == 0:
			_tabela.append(c)
	_tabela.sort_custom(
		func(a: CreatureData, b: CreatureData) -> bool: return a.mass_cost > b.mass_cost
	)


## Nasce no crepusculo, na borda mais distante do lado ameacado (§51).
func spawn(day: int, side: int, map_width: float) -> void:
	assert(side != 0, "uma mancha tem um lado; o dia 12 sao duas manchas (§51)")
	_dia = day
	_direcao = float(-side)
	state.active = true
	state.side = side
	state.width = _perfil.width_start
	state.mass = _massa_do_dia()
	state.x = map_width if side > 0 else 0.0
	state.next_summon_at = NAO_ARMADA
	state.trail_from = state.x
	state.trail_to = state.x


## Verdadeiro quando falta o intervalo ate a proxima invocacao. Quem chama tira-o
## do fluxo `rot` e entrega-o em arm() — e assim a sequencia de uma noite
## reproduz-se com a semente, sem que a simulacao toque no gerador.
func needs_interval() -> bool:
	return state.active and state.next_summon_at < 0.0


func arm(segundos: float) -> void:
	state.next_summon_at = maxf(0.0, segundos)


## Um passo. Avanca, deixa rasto, e devolve o que quer ver invocado.
##
## `consecrated` sao intervalos [inicio, fim] em x de terreno consagrado. Sobre
## eles a mancha anda a (1 - consecrated_slowdown) da velocidade, e cada segundo
## de atraso e uma invocacao a menos — o orcamento gasta-se por TEMPO e nao por
## distancia, que e o que torna abrandar uma tactica e nao um adiamento (§51).
func tick(delta: float, consecrated: Array[Vector2]) -> Array[SpawnRequest]:
	var pedidos: Array[SpawnRequest] = []
	if not state.active:
		return pedidos

	var v := speed()
	if _sobre_consagrado(state.x, consecrated):
		v *= 1.0 - _perfil.consecrated_slowdown
	state.x += _direcao * v * delta
	state.trail_to = state.x

	if state.next_summon_at < 0.0:
		return pedidos
	state.next_summon_at -= delta
	if state.next_summon_at > 0.0:
		return pedidos

	# Gastou o intervalo: ou ha massa para alguma coisa, ou fica a espera do
	# proximo. Em qualquer dos casos volta a precisar de intervalo — senao uma
	# mancha sem orcamento tentava invocar a cada tick, para sempre.
	state.next_summon_at = NAO_ARMADA
	var escolhida := _escolher()
	if escolhida != null:
		state.mass -= escolhida.mass_cost
		pedidos.append(SpawnRequest.new(escolhida.id, state.x, escolhida.band))
	return pedidos


## A velocidade do dia, sem abrandamentos (§51).
func speed() -> float:
	return _perfil.speed_base + _perfil.speed_per_day * _dia


func mass() -> float:
	return state.mass


func position_x() -> float:
	return state.x


func active() -> bool:
	return state.active


## Quem a alimenta compra tempo: 0,5 de massa por moeda, mais por animal ou
## tropa (§51). Nunca desce abaixo de zero — uma mancha com massa negativa
## acumulava credito e a noite seguinte vinha de graca.
func feed(amount: float) -> void:
	state.mass = maxf(0.0, state.mass - amount)


## O amanhecer. Nao morre: recua, e as criaturas vivas dissolvem-se (§51).
func retreat() -> void:
	state.active = false


## O que ela invocaria agora, ou SEM_CRIATURA. Publico porque e a regra que o
## §51 mais explica — "a mais cara que cabe" — e uma regra explicada assim tem
## de poder ser perguntada sem se esperar por um tick.
func pick() -> StringName:
	var escolhida := _escolher()
	return escolhida.id if escolhida != null else SEM_CRIATURA


## Verdadeiro se este x ja foi atravessado. O §49 le isto: plantacoes no rasto
## sao destruidas, o resto so para de produzir.
func trail_covers(x: float) -> bool:
	return (
		x >= minf(state.trail_from, state.trail_to) and x <= maxf(state.trail_from, state.trail_to)
	)


## O que se grava: o estado da mancha, o dia em que ela nasceu, e o que o
## jogador escreveu de dia (§74). A direccao deriva do lado e nao vai no save.
func to_dict() -> Dictionary:
	return {
		&"state": state.to_dict(),
		&"day": _dia,
		&"fortresses": fortresses,
		&"amargueiros": amargueiros,
		&"named": named_amargueiros,
		&"refusals": refusals,
		&"announced": announced,
	}


func from_dict(d: Dictionary) -> void:
	state.from_dict(d.get(&"state", {}))
	_dia = d.get(&"day", _dia)
	fortresses = d.get(&"fortresses", fortresses)
	amargueiros = d.get(&"amargueiros", amargueiros)
	named_amargueiros = d.get(&"named", named_amargueiros)
	refusals = d.get(&"refusals", refusals)
	announced = d.get(&"announced", announced)
	_direcao = float(-state.side)


## A massa da §74, termo a termo. O dossie desceu a base e o termo do dia de
## proposito: o que a noite tem de duro deixa de vir do calendario e passa a vir
## de como jogaste.
func _massa_do_dia() -> float:
	var base := (
		_perfil.mass_base + _perfil.mass_per_day * _dia + _perfil.mass_per_fortress * fortresses
	)
	var arvores := (
		_perfil.mass_per_amargueiro * amargueiros
		+ _perfil.mass_per_named_amargueiro * named_amargueiros
	)
	var recusas := _perfil.refusal_mass * mini(refusals, RECUSAS_MAX)
	return (base + arvores + minf(recusas, _perfil.refusal_cap)) * rhythm(_dia)


## O ritmo da noite (Q-126): de peak_every em peak_every noites uma funda, e a
## seguinte calma. Nao e sorteio: a noite funda sabe-se de vespera.
func rhythm(dia: int) -> float:
	if _perfil.peak_every <= 0 or dia <= 0:
		return 1.0
	if dia % _perfil.peak_every == 0:
		return _perfil.peak_mass_mult
	if dia > 1 and (dia - 1) % _perfil.peak_every == 0:
		return _perfil.calm_mass_mult
	return 1.0


## Se a noite deste dia e funda (Q-126).
func deep(dia: int) -> bool:
	return rhythm(dia) > 1.0


## A mais cara que cabe e cujo dia minimo ja passou (§51, Q-019). A tabela ja
## esta por custo decrescente, por isso a primeira que serve e a escolhida.
func _escolher() -> CreatureData:
	for c in _tabela:
		if c.min_day <= _dia and c.mass_cost <= state.mass:
			return c
	return null


func _sobre_consagrado(x: float, faixas: Array[Vector2]) -> bool:
	for f in faixas:
		if x >= f.x and x <= f.y:
			return true
	return false
