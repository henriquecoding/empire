# src/sim/systems/build_system.gd — construir e pagar com moeda fisica (§55).
#
# "Uma obra existe quando uma moeda cai num BuildSlot": sem menu nem dialogo, o
# mesmo Verbo 1 que recruta (§61). O progresso avanca enquanto alguem estiver
# PRESENTE, e nao por tempo: uma obra paga e abandonada fica em andaime.
#
# Puro: nao e Node, nao conhece o catalogo de eventos e nao sorteia nada.
# Devolve o que aconteceu; quem chama e que anuncia (§43, passo 11). Reparar
# esta no RepairWork (Q-108); quem conta como presente, na Q-064.
class_name BuildSystem
extends RefCounted

const NENHUM := -1

## Os acontecimentos devolvidos: chaves, e nao sinais — quem chama traduz (§46).
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

## O raio de uma obra e meia largura: uma moeda cai "nela" quando cai em cima
## dela, e quem constroi tem de estar la. A largura vem de data/, por peca.
const METADE := 0.5

var slots: Array[BuildSlot] = []
## A defesa das muralhas que um construtor teu da (§09); escrita a cada tick.
var wall_defense := 0.0


func count() -> int:
	return slots.size()


func index_of(slot_id: int) -> int:
	for i in slots.size():
		if slots[i].id == slot_id:
			return i
	return NENHUM


## Publica um sitio onde se pode construir. Os slots sao autorados (§21): e o
## segmento que decide onde, e por isso e de fora que eles entram.
func post(vaga: BuildSlot) -> BuildSlot:
	vaga.id = slots.size()
	slots.append(vaga)
	return vaga


func clear() -> void:
	slots = []


## As moedas pousadas que cairam numa obra passam a ser dela. E o §55 inteiro:
## nao ha outro caminho para pagar uma construcao.
##
## So em EMPTY ou DONE (o degrau seguinte), ou tocada e em ruina (a reparacao).
## Uma obra a meio nao aceita moeda: quem a faz andar e quem esta la.
##
## `estado` traz as conquistas e `madeira` o Lenho (§74); sem eles, so contam as
## moedas. Um degrau que pede Lenho gasta-o quando a obra comeca.
func absorb(
	moedas: CoinSystem, estado: GameState = null, madeira: AmargueiroSystem = null
) -> Array[Dictionary]:
	var eventos: Array[Dictionary] = []
	for vaga in slots:
		if vaga.state in [BuildSlot.State.DAMAGED, BuildSlot.State.RUIN]:
			eventos.append_array(RepairWork.absorb(moedas, vaga, _moedas_na_obra(moedas, vaga)))
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


## Se o degrau seguinte desta obra se pode pagar ja: o Lenho que pede esta
## guardado e, sendo unico por imperio, nenhuma outra muralha o tem nem o esta a
## levantar (§10, §74). Uma moeda largada num degrau que nao sobe fica no chao.
func can_climb(vaga: BuildSlot, estado: GameState, madeira: AmargueiroSystem) -> bool:
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


## Passo 8 do §43, todos os ticks. Avanca as obras que tem gente em cima.
func tick(delta: float, unidades: UnitSystem) -> Array[Dictionary]:
	var eventos: Array[Dictionary] = []
	for vaga in slots:
		if vaga.mending:
			eventos.append_array(RepairWork.tick(vaga, delta * _presentes(unidades, vaga)))
			continue
		if vaga.state != BuildSlot.State.SCAFFOLD and vaga.state != BuildSlot.State.BUILDING:
			continue
		var maos := _presentes(unidades, vaga)
		if maos == 0:
			continue
		var trabalho := vaga.works[vaga.level]
		vaga.state = BuildSlot.State.BUILDING
		vaga.progress += delta * maos
		if vaga.progress < trabalho:
			eventos.append({CHAVE: EV_PROGRESSO, VAGA: vaga, RACIO: vaga.progress / trabalho})
			continue
		vaga.level += 1
		vaga.progress = 0.0
		vaga.state = BuildSlot.State.DONE
		vaga.health = vaga.max_health()
		eventos.append({CHAVE: EV_COMPLETA, VAGA: vaga, NIVEL: vaga.level})
	return eventos


## Bater numa obra. So o que esta de pe leva dano — uma ruina ja caiu.
func damage(slot_id: int, quanto: int) -> Array[Dictionary]:
	var i := index_of(slot_id)
	if i == NENHUM or not slots[i].standing():
		return []
	var vaga := slots[i]
	vaga.health -= vaga.soak(quanto, wall_defense)
	if vaga.health > 0:
		vaga.state = BuildSlot.State.DAMAGED
		return [{CHAVE: EV_DANO, VAGA: vaga, RACIO: float(vaga.health) / vaga.max_health()}]

	vaga.health = 0
	vaga.state = BuildSlot.State.RUIN
	vaga.mending = false
	var eventos: Array[Dictionary] = [{CHAVE: EV_DESTRUIDA, VAGA: vaga}]
	# §24: a brecha e o unico acontecimento com direito a tremor de ecra.
	if vaga.blocks:
		eventos.append({CHAVE: EV_ROMPIDA, VAGA: vaga})
	return eventos


## A primeira obra de pe que trava quem vai de `de` para `para` nesta faixa, ou
## null. E o que faz um muro valer o que custa: sem isto uma criatura atravessa
## a muralha como se ela fosse um desenho.
func barrier(de: float, para: float, faixa: Band.Kind) -> BuildSlot:
	var achada: BuildSlot = null
	var mais_perto := INF
	for vaga in slots:
		if not vaga.blocks or not vaga.standing() or vaga.band != faixa:
			continue
		if vaga.x < minf(de, para) or vaga.x > maxf(de, para):
			continue
		var d := absf(vaga.x - de)
		if d < mais_perto:
			mais_perto = d
			achada = vaga
	return achada


## Uma obra deste tipo ja nao esta de pe: "se o nucleo cair, cai a partida" (§10).
func fallen(kind: StringName) -> bool:
	for vaga in slots:
		if vaga.kind == kind and not vaga.standing():
			return true
	return false


## As obras de pe, por id crescente: quem produz, publica posto ou desenha.
func standing() -> Array[BuildSlot]:
	var saida: Array[BuildSlot] = []
	for vaga in slots:
		if vaga.standing():
			saida.append(vaga)
	return saida


## O estado de cada obra, por id. As obras em si sao autoradas e voltam a ser
## postas por quem monta o mundo; o que o save leva e o que aconteceu a elas.
func to_dict() -> Array:
	var saida := []
	for vaga in slots:
		saida.append(vaga.to_dict())
	return saida


## Repoe sobre as obras JA POSTAS. Uma obra que o save tem e o mundo nao e
## ignorada — e o mesmo degradar do §62, e nao um save recusado.
func from_dict(guardadas: Array) -> void:
	for d in guardadas:
		var i := index_of(d.get(&"id", NENHUM))
		if i != NENHUM:
			slots[i].from_dict(d)


func _aceita(vaga: BuildSlot) -> bool:
	return vaga.state == BuildSlot.State.EMPTY or vaga.state == BuildSlot.State.DONE


## Os ids das moedas pousadas que cairam em cima desta obra. Recolhidos antes de
## remover nenhuma: o remove() do CoinSystem troca com a ultima e mexe na ordem.
func _moedas_na_obra(moedas: CoinSystem, vaga: BuildSlot) -> PackedInt32Array:
	var apanhadas := PackedInt32Array()
	var raio := vaga.width * METADE
	for c in moedas.count():
		if moedas.settled[c] == 0 or moedas.bands[c] != int(vaga.band):
			continue
		if absf(moedas.xs[c] - vaga.x) <= raio:
			apanhadas.append(moedas.ids[c])
	return apanhadas


## Quantas maos estao em cima da obra. Qualquer tropa tua conta, e por igual: o
## bonus do construtor e do §09, e o dossie nao lhe da numero (Q-064).
func _presentes(unidades: UnitSystem, vaga: BuildSlot) -> int:
	var maos := 0
	var raio := vaga.width * METADE
	for i in unidades.count():
		if unidades.owners[i] == RecruitSystem.SEM_DONO or not unidades.alive(i):
			continue
		if unidades.bands[i] != int(vaga.band):
			continue
		if absf(unidades.xs[i] - vaga.x) <= raio:
			maos += 1
	return maos
