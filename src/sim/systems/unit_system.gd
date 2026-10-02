# src/sim/systems/unit_system.gd — as tropas em colunas, nao em objetos (§52, §63).
#
# PackedArrays: memoria contigua, sem alocacao por tick (§63).
# Puro: nao e Node, nao conhece o Registry nem o EventBus. Os campos quentes de
# UnitData sao COPIADOS para colunas no spawn — assim o ciclo de cada tick nao
# faz uma unica pesquisa de recurso.
#
# tick_decisions() e o passo 4 do §43, fatiado; tick_movement() e o passo 5 (ADR 0020).
class_name UnitSystem
extends RefCounted

## Um id que nunca e valido. O -1 do §45 para "sem trabalho" e "sem alvo".
const NENHUM := -1

# ── As colunas. A ordem e sempre a mesma: o indice i e a mesma unidade em todas.
var ids: PackedInt32Array = PackedInt32Array()
var data_ids: Array[StringName] = []
var owners: PackedInt32Array = PackedInt32Array()
var xs: PackedFloat32Array = PackedFloat32Array()
var bands: PackedByteArray = PackedByteArray()
var healths: PackedInt32Array = PackedInt32Array()
var max_healths: PackedInt32Array = PackedInt32Array()
var speeds: PackedFloat32Array = PackedFloat32Array()
var states: PackedByteArray = PackedByteArray()
var job_ids: PackedInt32Array = PackedInt32Array()
var target_ids: PackedInt32Array = PackedInt32Array()
var target_xs: PackedFloat32Array = PackedFloat32Array()
var has_targets: PackedByteArray = PackedByteArray()
var cooldowns: PackedFloat32Array = PackedFloat32Array()
var carried_coins: PackedInt32Array = PackedInt32Array()
var loyalties: PackedFloat32Array = PackedFloat32Array()
# Frios no dossie, quentes no ciclo: a apanha (F1-04) le-os a cada tick. Do spawn.
var coin_capacities: PackedInt32Array = PackedInt32Array()
var recruit_costs: PackedInt32Array = PackedInt32Array()

## O passo de quem e conduzido: 1, ou o king_run_mult com a tecla de correr (Q-149).
var piloted_pace: float = 1.0
## O corpo de classe que o jogador conduz, ou NENHUM quando conduz o rei (§08, Q-162):
## os sistemas de IA deixam-no em paz. Grava-se no SimSave.
var pilot: int = NENHUM
var _por_id: Dictionary = {}


func count() -> int:
	return ids.size()


## O indice de uma unidade, ou NENHUM. Dicionario: procurar num array de 300 nao.
func index_of(unit_id: int) -> int:
	return _por_id.get(unit_id, NENHUM)


func alive(i: int) -> bool:
	return states[i] != UnitFsm.State.DEAD


## Nasce uma unidade. O id vem do contador do GameState — e o unico sitio onde
## ids nascem (§45). Devolve o id.
func spawn(estado: GameState, dados: UnitData, dono: int, x: float) -> int:
	var unit_id := estado.take_id()
	ids.append(unit_id)
	data_ids.append(dados.id)
	owners.append(dono)
	xs.append(x)
	bands.append(int(dados.band))
	healths.append(dados.max_health)
	max_healths.append(dados.max_health)
	speeds.append(dados.move_speed)
	states.append(UnitFsm.State.WORK)
	job_ids.append(NENHUM)
	target_ids.append(NENHUM)
	target_xs.append(x)
	has_targets.append(0)
	cooldowns.append(0.0)
	carried_coins.append(0)
	loyalties.append(1.0)
	coin_capacities.append(dados.coin_capacity)
	recruit_costs.append(dados.recruit_cost)
	_por_id[unit_id] = ids.size() - 1
	return unit_id


## Remove uma unidade. Troca com a ultima em vez de deslocar tudo — remover do
## meio de 300 colunas seria mover 300 elementos por morte.
##
## Isto MUDA a ordem das colunas, e por isso nada que afete a simulacao pode
## iterar por indice e esperar estabilidade: itera-se por id crescente (§42).
func remove(unit_id: int) -> bool:
	var i := index_of(unit_id)
	if i == NENHUM:
		return false
	var ultimo := ids.size() - 1
	if i != ultimo:
		_copiar(ultimo, i)
		_por_id[ids[i]] = i
	_encolher()
	_por_id.erase(unit_id)
	return true


## Repoe uma unidade guardada por Columns.row(), com o mesmo id. Devolve o indice.
func restore(linha: Dictionary) -> int:
	Columns.append_row(self, linha)
	_por_id[ids[-1]] = ids.size() - 1
	return ids.size() - 1


## Para onde esta unidade anda. Enquanto nao ha JobSystem (F1-05), e quem chama
## que o diz; depois sera o posto atribuido a decidi-lo.
func set_target_x(unit_id: int, x: float) -> void:
	var i := index_of(unit_id)
	if i != NENHUM:
		target_xs[i] = x
		has_targets[i] = 1


func clear_target(unit_id: int) -> void:
	var i := index_of(unit_id)
	if i != NENHUM:
		has_targets[i] = 0


func damage(unit_id: int, quanto: int) -> void:
	var i := index_of(unit_id)
	if i != NENHUM:
		healths[i] = maxi(0, healths[i] - quanto)


## Passo 4 do §43. So uma unidade em cada AI_SLICE reavalia (§52). Devolve as
## mudancas de estado para quem chama enfileirar — a simulacao nao emite.
func tick_decisions(tick: int) -> Array[Dictionary]:
	var mudancas: Array[Dictionary] = []
	for i in ids.size():
		var antes := states[i] as UnitFsm.State

		# A morte NAO e fatiada, e a §52 nao o diz porque nao lhe chama decisao:
		# "o movimento e o combate continuam a correr todos os ticks — e so a
		# DECISAO que e fatiada". Morrer nao e uma escolha, e uma consequencia.
		# Fatia-la deixava uma unidade com vida a zero a agir durante ate seis
		# ticks — o defeito que o §43 descreve por palavras suas: "uma tropa
		# morre e ainda ataca no mesmo tick".
		if healths[i] <= 0:
			if antes != UnitFsm.State.DEAD:
				states[i] = UnitFsm.State.DEAD
				mudancas.append({&"unit_id": ids[i], &"from": antes, &"to": UnitFsm.State.DEAD})
			continue

		if not UnitFsm.decides(ids[i], tick):
			continue
		var chegou := is_equal_approx(xs[i], target_xs[i])
		var depois := UnitFsm.next(antes, healths[i], has_targets[i] == 1, chegou)
		if depois != antes:
			states[i] = depois
			mudancas.append({&"unit_id": ids[i], &"from": antes, &"to": depois})
	return mudancas


## Passo 5 do §43, todos os ticks. O mundo e uma linha: o movimento e em X e aterra
## exatamente no alvo, e a FSM nao precisa de tolerancia para saber que chegou.
##
## Quem esta em FIGHT nao anda (§52: "resolucao de combate", nenhum movimento),
## mesmo com um posto do outro lado do mapa. Quem esta em DEAD tambem nao.
##
## `piloted` e a excepcao: e conduzido por uma pessoa, e o §24 da ao "Mover" o
## contexto **Sempre** (Q-085) — o rei, ou o corpo de classe em `pilot` (§08).
## `frente` e a luz do amanhecer (§24, DawnCascade): quem tem posto e a luz ainda
## nao apanhou espera por ela. Quem foge nao espera por luz nenhuma (§07).
func tick_movement(
	delta: float, piloted: int = NENHUM, frente: float = INF, class_pace: float = 1.0
) -> void:
	for i in ids.size():
		cooldowns[i] = maxf(0.0, cooldowns[i] - delta)
		if walking(i, piloted, frente):
			var passo := piloted_pace * class_pace if ids[i] == piloted else 1.0
			xs[i] = move_toward(xs[i], target_xs[i], speeds[i] * passo * delta)


## Se esta unidade anda neste tick. Um alvo por alcancar nao chega: o rei parado
## guarda o dele (clear_target so desliga), e baloicava como se andasse (GB-10).
func walking(i: int, piloted: int = NENHUM, frente: float = INF) -> bool:
	if has_targets[i] == 0 or xs[i] == target_xs[i] or states[i] == UnitFsm.State.DEAD:
		return false
	if ids[i] == piloted:
		return true
	if job_ids[i] != NENHUM and xs[i] > frente and states[i] != UnitFsm.State.FLEE:
		return false
	return states[i] != UnitFsm.State.FIGHT


## As colunas em tipos base, para o save (§62). Sem Object nenhum.
func to_dict() -> Dictionary:
	return Columns.to_dict(self)


## Repoe do save. Reindexa no fim: o dicionario de ids e derivado das colunas e
## nao vem no ficheiro — guarda-lo era guardar duas vezes a mesma coisa.
func from_dict(d: Dictionary) -> void:
	Columns.from_dict(self, d)
	_reindexar()


func _copiar(de: int, para: int) -> void:
	ids[para] = ids[de]
	data_ids[para] = data_ids[de]
	owners[para] = owners[de]
	xs[para] = xs[de]
	bands[para] = bands[de]
	healths[para] = healths[de]
	max_healths[para] = max_healths[de]
	speeds[para] = speeds[de]
	states[para] = states[de]
	job_ids[para] = job_ids[de]
	target_ids[para] = target_ids[de]
	target_xs[para] = target_xs[de]
	has_targets[para] = has_targets[de]
	cooldowns[para] = cooldowns[de]
	carried_coins[para] = carried_coins[de]
	loyalties[para] = loyalties[de]
	coin_capacities[para] = coin_capacities[de]
	recruit_costs[para] = recruit_costs[de]


func _encolher() -> void:
	var n := ids.size() - 1
	ids.resize(n)
	data_ids.resize(n)
	owners.resize(n)
	xs.resize(n)
	bands.resize(n)
	healths.resize(n)
	max_healths.resize(n)
	speeds.resize(n)
	states.resize(n)
	job_ids.resize(n)
	target_ids.resize(n)
	target_xs.resize(n)
	has_targets.resize(n)
	cooldowns.resize(n)
	carried_coins.resize(n)
	loyalties.resize(n)
	coin_capacities.resize(n)
	recruit_costs.resize(n)


## O dicionario de ids a partir das colunas, depois de repor um save; no jogo o
## spawn, o remove e o restore mantem-no a par.
func _reindexar() -> void:
	_por_id.clear()
	for i in ids.size():
		_por_id[ids[i]] = i
