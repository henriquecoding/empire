class_name BuildSystem
extends RefCounted

const NENHUM := -1

const EV_PAGA := 0
const EV_INICIADA := 1
const EV_PROGRESSO := 2
const EV_COMPLETA := 3
const EV_DANO := 4
const EV_DESTRUIDA := 5
const EV_ROMPIDA := 6
const EV_REPARADA := 7

const CHAVE := &"kind"
const VAGA := &"slot"
const QUANTO := &"amount"
const RACIO := &"ratio"
const NIVEL := &"level"

const METADE := 0.5

var slots: Array[BuildSlot] = []
var workforce: UnitSystem
var crew_owner: int = 0
var work_owners: Dictionary = {}
var foundation_committed := true
var maturity_ready := true
var repair_speed := 1.0
var work_day := 1
var reserved := PackedInt32Array()
var wall_defense := 0.0


func count() -> int:
	return slots.size()


func index_of(slot_id: int) -> int:
	for i in slots.size():
		if slots[i].id == slot_id:
			return i
	return NENHUM


func post(vaga: BuildSlot) -> BuildSlot:
	vaga.id = slots.size()
	slots.append(vaga)
	return vaga


func clear() -> void:
	slots = []


func absorb(
	moedas: CoinSystem, estado: GameState = null, madeira: AmargueiroSystem = null
) -> Array[Dictionary]:
	var eventos: Array[Dictionary] = []
	for vaga in slots:
		if vaga.state in [BuildSlot.State.DAMAGED, BuildSlot.State.RUIN]:
			eventos.append_array(RepairWork.absorb(moedas, vaga, _moedas_na_obra(moedas, vaga)))
			continue
		if Ward.wants(vaga):  # o sino carrega-se com moedas (Q-100)
			Ward.absorb(moedas, vaga, _moedas_na_obra(moedas, vaga))
			continue
		var custo := vaga.next_cost()
		if custo == NENHUM or not _aceita(vaga) or not can_climb(vaga, estado, madeira):
			continue
		var apanhadas := _moedas_na_obra(moedas, vaga)
		if apanhadas.is_empty():
			continue
		var valor := 0
		for coin_id in apanhadas:
			valor += moedas.amounts[moedas.index_of(coin_id)]
			moedas.remove(coin_id)
		vaga.paid += valor
		eventos.append({CHAVE: EV_PAGA, VAGA: vaga, QUANTO: valor})
		if vaga.paid >= custo:
			if estado != null and madeira != null:
				madeira.bitter_wood -= vaga.woods_for_next(estado.conquests)
			vaga.paid -= custo
			vaga.progress = 0.0
			vaga.state = BuildSlot.State.SCAFFOLD
			eventos.append({CHAVE: EV_INICIADA, VAGA: vaga})
	return eventos


func can_climb(vaga: BuildSlot, estado: GameState, madeira: AmargueiroSystem) -> bool:
	var seat := RealmLadder.seat(self)
	var closed := (
		vaga.kind == BuildSlot.NUCLEO
		and (
			(vaga.level == 0 and not foundation_committed)
			or (vaga.level > 0 and not maturity_ready)
		)
	)
	closed = (
		closed or (vaga.kind == &"cellar_excavation" and seat != null and vaga.level >= seat.level)
	)
	var crew := workforce == null or not (vaga.two_paths() or vaga.builder_work)
	crew = crew or WallCrew.available(workforce, vaga.band, crew_owner)
	# Uma estatua por achar (Q-016), ou a sede num estagio abaixo do que a abre (ADR 0059).
	if (
		closed
		or not Discoveries.known(estado, vaga.kind)
		or not RealmLadder.allows(self, vaga)
		or not RealmGrowth.allows(self, vaga)
		or not crew
	):
		return false
	if estado == null or madeira == null:
		return true
	var lenho := vaga.woods_for_next(estado.conquests)
	if lenho == NENHUM or lenho > madeira.bitter_wood:
		return false
	if not vaga.next_unique():
		return true
	for outra in slots:
		if outra == vaga or not outra.two_paths():
			continue
		var a_subir := outra.state in [BuildSlot.State.SCAFFOLD, BuildSlot.State.BUILDING]
		if outra.level > vaga.level or (a_subir and outra.level == vaga.level):
			return false
	return true


func tick(delta: float, unidades: UnitSystem) -> Array[Dictionary]:
	var eventos: Array[Dictionary] = []
	for vaga in slots:
		var owner := int(work_owners.get(vaga.territory, crew_owner if vaga.territory == 0 else 0))
		if vaga.mending:
			var quem := RepairWork.hands(unidades, vaga, RepairWork.REPAIRER, owner, reserved)
			if quem > 0:
				vaga.rest_day = work_day
			var speed := repair_speed if vaga.state == BuildSlot.State.DAMAGED else 1.0
			eventos.append_array(RepairWork.tick(vaga, delta * quem * speed))
			continue
		if vaga.state != BuildSlot.State.SCAFFOLD and vaga.state != BuildSlot.State.BUILDING:
			continue
		var maos := RepairWork.hands(
			unidades,
			vaga,
			RepairWork.REPAIRER if vaga.two_paths() or vaga.builder_work else &"",
			owner if vaga.two_paths() or vaga.builder_work else 0,
			reserved
		)
		if maos == 0:
			continue
		var trabalho := vaga.works[vaga.level]
		vaga.state = BuildSlot.State.BUILDING
		vaga.progress += delta * maos
		if vaga.progress < trabalho:
			eventos.append({CHAVE: EV_PROGRESSO, VAGA: vaga, RACIO: vaga.progress / trabalho})
			continue
		var antes := vaga.max_health()
		vaga.level += 1
		vaga.progress = 0.0
		vaga.state = BuildSlot.State.DONE
		vaga.health = vaga.raised_health(antes)  # a sede sobe sem se curar (ADR 0059)
		vaga.fit()
		vaga.charge = Ward.cap(vaga) if vaga.kind == Ward.SINO else vaga.charge
		eventos.append({CHAVE: EV_COMPLETA, VAGA: vaga, NIVEL: vaga.level})
	return eventos


func damage(slot_id: int, quanto: int) -> Array[Dictionary]:
	var i := index_of(slot_id)
	if i == NENHUM or not slots[i].holds():
		return []
	var vaga := slots[i]
	vaga.health -= vaga.soak(quanto, wall_defense)
	if vaga.health > 0:
		vaga.state = vaga.state if vaga.upgrading() else BuildSlot.State.DAMAGED
		return [{CHAVE: EV_DANO, VAGA: vaga, RACIO: float(vaga.health) / vaga.max_health()}]

	vaga.health = 0
	vaga.state = BuildSlot.State.RUIN
	vaga.mending = false
	var eventos: Array[Dictionary] = [{CHAVE: EV_DESTRUIDA, VAGA: vaga}]
	# §24: a brecha e o unico acontecimento com direito a tremor de ecra.
	if vaga.blocks:
		eventos.append({CHAVE: EV_ROMPIDA, VAGA: vaga})
	return eventos


func barrier(de: float, para: float, faixa: Band.Kind) -> BuildSlot:
	var achada: BuildSlot = null
	var mais_perto := INF
	for vaga in slots:
		if not vaga.blocks or not vaga.holds() or vaga.band != faixa:
			continue
		if vaga.x < minf(de, para) or vaga.x > maxf(de, para):
			continue
		var d := absf(vaga.x - de)
		if d < mais_perto:
			mais_perto = d
			achada = vaga
	return achada


func fallen(kind: StringName) -> bool:
	for vaga in slots:
		if vaga.kind == kind and vaga.level > 0 and not vaga.holds():
			return true
	return false


func standing() -> Array[BuildSlot]:
	var saida: Array[BuildSlot] = []
	for vaga in slots:
		if vaga.standing():
			saida.append(vaga)
	return saida


func to_dict() -> Array:
	var saida := []
	for vaga in slots:
		saida.append(vaga.to_dict())
	return saida


func from_dict(guardadas: Array) -> void:
	for d in guardadas:
		var i := index_of(d.get(&"id", NENHUM))
		if i != NENHUM:
			slots[i].from_dict(d)


func _aceita(vaga: BuildSlot) -> bool:
	return vaga.state == BuildSlot.State.EMPTY or vaga.state == BuildSlot.State.DONE


func _moedas_na_obra(moedas: CoinSystem, vaga: BuildSlot) -> PackedInt32Array:
	var apanhadas := PackedInt32Array()
	for c in moedas.count():
		if CoinTarget.pays(moedas, c, vaga):
			apanhadas.append(moedas.ids[c])
	return apanhadas
