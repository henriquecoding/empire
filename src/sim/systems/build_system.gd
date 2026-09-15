# src/sim/systems/build_system.gd — construir e pagar com moeda fisica (§55).
#
# O contrato do §55 numa frase: "uma obra existe quando uma moeda cai num
# BuildSlot". Nao ha menu de construcao, nao ha caixa de dialogo e nao ha
# confirmacao — ha uma moeda no chao, e e o mesmo Verbo 1 que recruta (§61).
#
# A segunda frase e a que torna os construtores um recurso a serio: o progresso
# avanca enquanto alguem estiver PRESENTE, e nao por tempo decorrido. Uma obra
# paga e abandonada fica em andaime para sempre, e isso e informacao.
#
# Puro: nao e Node, nao conhece o catalogo de eventos e nao sorteia nada.
# Devolve o que aconteceu; quem chama e que anuncia (§43, passo 11).
#
# O que NAO esta aqui, e nao e esquecimento: reparar uma obra DAMAGED com moeda
# e o posto `repair` do F1-05 mais a habilidade do construtor (§09); a
# apresentacao dos seis estados e ART-01; os slots de contacto do muro sao o
# F1-06. Ver docs/QUESTIONS.md, Q-064.
class_name BuildSystem
extends RefCounted

const NENHUM := -1

## Os tipos de acontecimento devolvidos. Sao chaves de dicionario e nao nomes de
## sinal: a simulacao nao conhece a §46, e quem chama e que traduz.
const EV_PAGA := 0
const EV_INICIADA := 1
const EV_PROGRESSO := 2
const EV_COMPLETA := 3
const EV_DANO := 4
const EV_DESTRUIDA := 5
const EV_ROMPIDA := 6

const CHAVE := &"kind"
const VAGA := &"slot"
const QUANTO := &"amount"
const RACIO := &"ratio"
const NIVEL := &"level"

## O raio de uma obra e meia largura: uma moeda cai "nela" quando cai em cima
## dela, e quem constroi tem de estar la. A largura vem de data/, por peca.
const METADE := 0.5

var slots: Array[BuildSlot] = []


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
## So absorve o que ainda falta pagar, e so em EMPTY (a obra por comecar) ou
## DONE (o degrau seguinte). Uma obra a meio nao aceita moeda: pagar mais nao a
## faz andar mais depressa — quem a faz andar e quem esta la.
func absorb(moedas: CoinSystem) -> Array[Dictionary]:
	var eventos: Array[Dictionary] = []
	for vaga in slots:
		var custo := vaga.next_cost()
		if custo == NENHUM or not _aceita(vaga):
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
			vaga.paid -= custo
			vaga.progress = 0.0
			vaga.state = BuildSlot.State.SCAFFOLD
			eventos.append({CHAVE: EV_INICIADA, VAGA: vaga})
	return eventos


## Passo 8 do §43, todos os ticks. Avanca as obras que tem gente em cima.
func tick(delta: float, unidades: UnitSystem) -> Array[Dictionary]:
	var eventos: Array[Dictionary] = []
	for vaga in slots:
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
	vaga.health -= quanto
	if vaga.health > 0:
		vaga.state = BuildSlot.State.DAMAGED
		return [{CHAVE: EV_DANO, VAGA: vaga, RACIO: float(vaga.health) / vaga.max_health()}]

	vaga.health = 0
	vaga.state = BuildSlot.State.RUIN
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


## Verdadeiro se existe uma obra deste tipo e ja nao esta de pe. Serve o §10 na
## unica frase em que o nucleo e diferente de tudo o resto: "se cair, cai a
## partida". A derrota le-se do mundo, e nao de um estado a parte que pudesse
## divergir dele (§45).
func fallen(kind: StringName) -> bool:
	for vaga in slots:
		if vaga.kind == kind and not vaga.standing():
			return true
	return false


## As obras de pe, por id crescente. Quem produz, quem publica posto e quem se
## desenha le por aqui em vez de filtrar a lista por sua conta.
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
## bonus do construtor e a habilidade do §09, que entra com o F1-05 — dar-lhe
## aqui um numero era inventar um que o dossie nao escreve (Q-064).
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
