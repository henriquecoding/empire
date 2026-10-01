# src/sim/systems/thieves.gd — o Alado rouba galinhas (§06, §07; auditoria P-J).
#
# O §07 diz que o Alado "obriga a torre alta" e o §06 da ao galinheiro "galinhas
# roubaveis a noite". Medido, nenhum dos dois acontecia: para quem voa nenhuma
# obra de superficie e barreira, e o Alado atravessava a muralha, pousava no
# castelo e o castelo perdia 0% (Q-077). A resposta e a das duas linhas juntas:
#
#   quem voa (`flyer`) vai ao galinheiro de pe mais perto dele (`stealable_at_night`),
#   leva UMA galinha e volta para a borda de onde a noite veio. Se chegar vivo a
#   alvorada, o galinheiro rende menos no dia seguinte — nunca mais do que um
#   dia. Abatido pelo caminho, nao leva nada. Sem galinheiro de pe, segue para o
#   nucleo como antes. Q-129.
#
# Puro e estatico: escreve alvos, como o Muster, e corre no passo 2 do §43.
class_name Thieves
extends RefCounted

const NENHUM := -1
const QUEM_VOA := &"flyer"
const ROUBAVEL := &"stealable_at_night"
const METADE := 0.5

## Chaves do que escape() devolve, para quem chama traduzir no material_consumed.
const OBRA := &"slot"
const QUANTO := &"amount"


## Um tick. `criaturas` e `edificios` sao CreatureData e BuildingData por id;
## `borda` e o x por onde quem leva sai (a borda do lado da noite).
static func plan(
	bichos: CreatureSystem,
	criaturas: Dictionary,
	obras: BuildSystem,
	edificios: Dictionary,
	borda: float
) -> void:
	var alvos := _roubaveis(obras, edificios)
	for creature_id in TargetPicker.ids_por_ordem(bichos.ids):
		if bichos.allies.has(creature_id):
			continue
		var c := bichos.index_of(creature_id)
		var dados: CreatureData = criaturas.get(bichos.data_ids[c])
		if not bichos.alive(c) or dados == null or not dados.tags.has(QUEM_VOA):
			continue
		if bichos.loot_slots[c] != NENHUM:
			_ir(bichos, c, borda)
			continue
		var alvo := _mais_perto(alvos, bichos.xs[c])
		if alvo == null:
			continue
		if absf(bichos.xs[c] - alvo.x) <= alvo.width * METADE:
			bichos.loot_slots[c] = alvo.id
			_ir(bichos, c, borda)
		else:
			_ir(bichos, c, alvo.x)


## A alvorada: quem esta vivo e leva alguma coisa, levou-a. Tira `materia` ao
## stock da obra, sem a deixar abaixo de menos um dia de rendimento. Devolve o
## que se perdeu, por obra, para quem chama anunciar.
static func escape(bichos: CreatureSystem, obras: BuildSystem, materia: float) -> Array[Dictionary]:
	var perdas: Array[Dictionary] = []
	for creature_id in TargetPicker.ids_por_ordem(bichos.ids):
		if bichos.allies.has(creature_id):
			continue
		var c := bichos.index_of(creature_id)
		var i := obras.index_of(bichos.loot_slots[c])
		if not bichos.alive(c) or i == NENHUM:
			continue
		var obra := obras.slots[i]
		var antes := obra.stock
		obra.stock = maxf(-obra.yield_per_day, obra.stock - materia)
		if antes > obra.stock:
			perdas.append({OBRA: obra.id, QUANTO: antes - obra.stock})
	return perdas


static func _ir(bichos: CreatureSystem, c: int, x: float) -> void:
	bichos.target_xs[c] = x
	bichos.goal_xs[c] = x


static func _roubaveis(obras: BuildSystem, edificios: Dictionary) -> Array[BuildSlot]:
	var saida: Array[BuildSlot] = []
	for obra in obras.standing():
		var dados: BuildingData = edificios.get(obra.kind)
		if dados != null and dados.tags.has(ROUBAVEL):
			saida.append(obra)
	return saida


static func _mais_perto(alvos: Array[BuildSlot], x: float) -> BuildSlot:
	var melhor: BuildSlot = null
	for obra in alvos:
		if melhor == null or absf(obra.x - x) < absf(melhor.x - x):
			melhor = obra
	return melhor
