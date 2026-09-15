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

## Metade. Nao e afinacao: e onde fica a face de uma coisa com largura.
const MEIO := 0.5

## A fila de contacto do §50: quem engaja e quem espera.
var fila: ContactQueue

var _postos: JobBoard
var _unidades: Dictionary = {}
var _criaturas: Dictionary = {}
var _alvos: Dictionary = {}
var _marcados: Dictionary = {}


func _init(
	unidades: Dictionary, criaturas: Dictionary, contacto: ContactQueue, postos: JobBoard
) -> void:
	assert(contacto != null, "o TargetPicker precisa de uma ContactQueue (§50)")
	_unidades = unidades
	_criaturas = criaturas
	fila = contacto
	_postos = postos


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
	unidades: UnitSystem,
	criaturas: CreatureSystem,
	obras: BuildSystem,
	passagens: PackedFloat32Array = PackedFloat32Array()
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
	for subiu in Passages.surface(criaturas, _criaturas, passagens):
		(
			eventos
			. append(
				{
					CombatSystem.CHAVE: CombatSystem.EV_FAIXA,
					CombatSystem.DE: subiu[Passages.QUEM],
					CombatSystem.PARA: [subiu[Passages.DE], subiu[Passages.PARA]],
				}
			)
		)
	eventos.append_array(_das_criaturas(unidades, criaturas, obras))
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
	if not Posts.reaches(_postos, unidades, i, dados, int(criaturas.bands[c])):
		return false
	return absf(criaturas.xs[c] - unidades.xs[i]) <= Posts.range_px(_postos, unidades, i, dados)


func _mais_proxima(unidades: UnitSystem, i: int, dados: UnitData, criaturas: CreatureSystem) -> int:
	var melhor := NENHUM
	var melhor_d := Posts.range_px(_postos, unidades, i, dados)
	for c in criaturas.count():
		if not criaturas.alive(c):
			continue
		if not Posts.reaches(_postos, unidades, i, dados, int(criaturas.bands[c])):
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
##
## Duas passagens e nao uma: a fila do §50 e uma decisao POR MURO — quantos
## engajam e quem espera — e nao se pode tomar uma criatura de cada vez. A
## primeira agrupa quem vai a cada muro; a segunda reparte os slots.
func _das_criaturas(
	unidades: UnitSystem, criaturas: CreatureSystem, obras: BuildSystem
) -> Array[Dictionary]:
	var por_muro := {}
	for creature_id in ids_por_ordem(criaturas.ids):
		var c := criaturas.index_of(creature_id)
		if not criaturas.alive(c):
			continue
		var dados: CreatureData = _criaturas.get(criaturas.data_ids[c])
		criaturas.target_ids[c] = NENHUM
		criaturas.target_slots[c] = NENHUM
		if dados == null or dados.damage <= SEM_DANO:
			continue
		var muro := _muro_que_trava(criaturas, c, obras)
		if muro == null:
			if dados.target_priority == MAIS_PROXIMO:
				criaturas.target_ids[c] = _tropa_mais_proxima(unidades, criaturas, c, dados)
			continue
		if not por_muro.has(muro.id):
			por_muro[muro.id] = [muro, PackedInt32Array()]
		por_muro[muro.id][1].append(creature_id)
	return _repartir(criaturas, por_muro)


## Por id de obra crescente (§42), e por muro de cada vez. Quem tem slot bate
## quando chegar ao alcance; quem espera anda para o lugar dele e mais nada.
func _repartir(criaturas: CreatureSystem, por_muro: Dictionary) -> Array[Dictionary]:
	var eventos: Array[Dictionary] = []
	var ids := PackedInt32Array(por_muro.keys())
	ids.sort()
	for slot_id in ids:
		var muro: BuildSlot = por_muro[slot_id][0]
		var atacantes: PackedInt32Array = por_muro[slot_id][1]
		for e in fila.assign(muro, criaturas, atacantes):
			e[CombatSystem.CHAVE] = CombatSystem.EV_CONTACTO
			eventos.append(e)
		for quem in atacantes:
			var c := criaturas.index_of(quem)
			var dados: CreatureData = _criaturas.get(criaturas.data_ids[c])
			if fila.holds(muro, quem) and _a_jeito(criaturas, c, muro, dados):
				criaturas.target_slots[c] = muro.id
	return eventos


## A obra de pe que trava quem vai para o nucleo, se ela estiver ao alcance da
## FILA — e nao so ao alcance da arma. Quem vem de longe tem de poder tomar
## lugar antes de bater, senao nunca chega a haver fila nenhuma.
func _muro_que_trava(criaturas: CreatureSystem, c: int, obras: BuildSystem) -> BuildSlot:
	if obras == null:
		return null
	var faixa := criaturas.bands[c] as Band.Kind
	var muro := obras.barrier(criaturas.xs[c], criaturas.goal_xs[c], faixa)
	if muro == null:
		return null
	return muro if absf(muro.x - criaturas.xs[c]) <= fila.reach(muro) else null


## Bate-se na FACE do muro e nao no centro dele: um muro tem largura, e o
## alcance de uma arma mede-se ate onde ela toca.
func _a_jeito(criaturas: CreatureSystem, c: int, muro: BuildSlot, dados: CreatureData) -> bool:
	var face := absf(muro.x - criaturas.xs[c]) - muro.width * MEIO
	return face <= dados.range_px


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
