# src/sim/systems/target_picker.gd — "Escolher alvos", que e o passo do §50 com
# regra propria, e por isso e ficheiro proprio.
#
# A ordem de prioridade e a da §50, tal e qual, e nao se reordena:
#
#   alvo marcado pelo Arqueiro > alvo atual se ainda vivo e em alcance >
#   mais proximo em faixa atingivel
#
# O termo do meio e o que interessa: "nunca reescolher se o alvo atual serve —
# e o que evita o desperdicio de flechas que o Kingdom tem". E por isso que a
# escolha tem memoria e nao e uma funcao de uma linha.
#
# Corre no passo 4 do §43, que e o passo que escreve "estado, alvo, intencao de
# movimento" — e um alvo e exatamente isso. Quem resolve os golpes e o
# CombatSystem, no passo 6.
#
# Puro e determinista: nao sorteia nada. Por id crescente (§42).
class_name TargetPicker
extends RefCounted

const NENHUM := -1
const SEM_DANO := 0
## O "alvo preferido" da §44. So o Aríete de lodo nao e `nearest`: ele so ataca
## muralha, e por isso nem olha para quem esta atras dela.
const MAIS_PROXIMO := &"nearest"

var _unidades: Dictionary = {}
var _criaturas: Dictionary = {}
var _alvos: Dictionary = {}
var _marcados: Dictionary = {}


func _init(unidades: Dictionary, criaturas: Dictionary) -> void:
	_unidades = unidades
	_criaturas = criaturas


func target_of(unit_id: int) -> int:
	return _alvos.get(unit_id, NENHUM)


## O gatilho direito do §24, e so o Arqueiro o tem. Marcar nao dispara: escreve
## a preferencia, e a escolha seguinte e que a le.
func mark(unit_id: int, creature_id: int) -> void:
	_marcados[unit_id] = creature_id


func forget(unit_id: int) -> void:
	_alvos.erase(unit_id)
	_marcados.erase(unit_id)


## Quem bate em quem, neste tick. Devolve as entradas e saidas de FIGHT da
## tabela da §52 — as unicas mudancas de estado que o combate decide.
func choose(
	unidades: UnitSystem, criaturas: CreatureSystem, obras: BuildSystem
) -> Array[Dictionary]:
	var eventos: Array[Dictionary] = []
	for unit_id in ids_por_ordem(unidades.ids):
		var i := unidades.index_of(unit_id)
		if not unidades.alive(i) or unidades.owners[i] == RecruitSystem.SEM_DONO:
			continue
		var dados: UnitData = _unidades.get(unidades.data_ids[i])
		if dados == null or dados.damage <= SEM_DANO:
			continue
		_alvos[unit_id] = _da_tropa(unidades, i, dados, criaturas)
		_estado(unidades, i, _alvos[unit_id] != NENHUM, eventos)
	_das_criaturas(unidades, criaturas, obras)
	return eventos


## Por id crescente (§42): a ordem das colunas nao e estavel — o remove() troca
## com a ultima — e uma noite que dependesse dela nao se reproduzia.
static func ids_por_ordem(ids: PackedInt32Array) -> PackedInt32Array:
	var ordem := ids.duplicate()
	ordem.sort()
	return ordem


func _da_tropa(unidades: UnitSystem, i: int, dados: UnitData, criaturas: CreatureSystem) -> int:
	var unit_id := unidades.ids[i]
	var marcado: int = _marcados.get(unit_id, NENHUM)
	if _serve(unidades, i, dados, criaturas, marcado):
		return marcado
	_marcados.erase(unit_id)
	var atual: int = _alvos.get(unit_id, NENHUM)
	if _serve(unidades, i, dados, criaturas, atual):
		return atual
	return _mais_proxima(unidades, i, dados, criaturas)


func _serve(
	unidades: UnitSystem, i: int, dados: UnitData, criaturas: CreatureSystem, alvo: int
) -> bool:
	if alvo == NENHUM:
		return false
	var c := criaturas.index_of(alvo)
	if c == NENHUM or not criaturas.alive(c):
		return false
	if not dados.targets_bands.has(int(criaturas.bands[c])):
		return false
	return absf(criaturas.xs[c] - unidades.xs[i]) <= dados.range_px


func _mais_proxima(unidades: UnitSystem, i: int, dados: UnitData, criaturas: CreatureSystem) -> int:
	var melhor := NENHUM
	var melhor_d := float(dados.range_px)
	for c in criaturas.count():
		if not criaturas.alive(c) or not dados.targets_bands.has(int(criaturas.bands[c])):
			continue
		var d := absf(criaturas.xs[c] - unidades.xs[i])
		if melhor != NENHUM and d >= melhor_d:
			continue
		if d <= melhor_d:
			melhor_d = d
			melhor = criaturas.ids[c]
	return melhor


func _estado(unidades: UnitSystem, i: int, luta: bool, eventos: Array[Dictionary]) -> void:
	var antes := unidades.states[i] as UnitFsm.State
	var depois := antes
	if luta:
		depois = UnitFsm.State.FIGHT
	elif antes == UnitFsm.State.FIGHT:
		depois = UnitFsm.State.WORK
	if depois == antes:
		return
	unidades.states[i] = depois
	eventos.append({CombatSystem.CHAVE: CombatSystem.EV_ESTADO, CombatSystem.DE: unidades.ids[i]})


## A obra que a trava ganha a tropa que esta atras dela — e o que faz um muro
## valer o que custa (§10). Quem so ataca muralhas nem olha para as tropas.
func _das_criaturas(unidades: UnitSystem, criaturas: CreatureSystem, obras: BuildSystem) -> void:
	for creature_id in ids_por_ordem(criaturas.ids):
		var c := criaturas.index_of(creature_id)
		if not criaturas.alive(c):
			continue
		var dados: CreatureData = _criaturas.get(criaturas.data_ids[c])
		criaturas.target_ids[c] = NENHUM
		criaturas.target_slots[c] = NENHUM
		if dados == null or dados.damage <= SEM_DANO:
			continue
		var muro := _muro_que_trava(criaturas, c, dados, obras)
		if muro != null:
			criaturas.target_slots[c] = muro.id
		elif dados.target_priority == MAIS_PROXIMO:
			criaturas.target_ids[c] = _tropa_mais_proxima(unidades, criaturas, c, dados)


func _muro_que_trava(
	criaturas: CreatureSystem, c: int, dados: CreatureData, obras: BuildSystem
) -> BuildSlot:
	if obras == null:
		return null
	var faixa := criaturas.bands[c] as Band.Kind
	var muro := obras.barrier(criaturas.xs[c], criaturas.target_xs[c], faixa)
	if muro == null or absf(muro.x - criaturas.xs[c]) > dados.range_px:
		return null
	return muro


func _tropa_mais_proxima(
	unidades: UnitSystem, criaturas: CreatureSystem, c: int, dados: CreatureData
) -> int:
	var melhor := NENHUM
	var melhor_d := float(dados.range_px)
	for i in unidades.count():
		if not unidades.alive(i) or unidades.owners[i] == RecruitSystem.SEM_DONO:
			continue
		if not dados.targets_bands.has(int(unidades.bands[i])):
			continue
		var d := absf(unidades.xs[i] - criaturas.xs[c])
		if melhor != NENHUM and d >= melhor_d:
			continue
		if d <= melhor_d:
			melhor_d = d
			melhor = unidades.ids[i]
	return melhor
