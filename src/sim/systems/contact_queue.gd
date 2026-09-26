# src/sim/systems/contact_queue.gd — os slots de contacto e a fila (§50, §07).
#
# O §07 da a regra de design numa frase: "so N atacantes engajam". Sem ela, vinte
# Rastejantes batem no mesmo muro ao mesmo tempo e o combate deixa de se ler —
# e a §50 poe a legibilidade antes da emocao de proposito.
#
# A fila e a parte que parece detalhe e nao e. O §50 escreve-a assim:
#
#   "A fila tem posicoes estaveis entre 30 e 120 px — ATRIBUIDAS, nao
#    emergentes. Uma regra de dados, nao de fisica. Sem colisao entre aliados."
#
# Posicoes atribuidas por id crescente nao vibram e nao se empurram. Emergentes
# — com repulsao entre vizinhos — dao uma multidao que treme, e a §53 ja recusou
# pagar colisao por isso.
#
# Puro: nao e Node, nao conhece o catalogo de eventos, e nao sorteia nada. Os
# numeros sao todos da curva: queue_min_px, queue_max_px, queue_spacing_px e o
# slot_replace_time dos 0,4 s de "transicao visivel" do §50.
class_name ContactQueue
extends RefCounted

const NENHUM := -1

## De que lado fica quem esta exatamente em cima do muro. Nao e balanceamento:
## e uma direccao — o lado de fora, que num mundo de uma linha e a esquerda.
const FORA := -1.0

## Metade. Nao e afinacao: e onde fica a face de uma coisa com largura.
const MEIO := 0.5

## Os acontecimentos devolvidos. Chaves de dicionario e nao nomes de sinal: a
## simulacao nao conhece a §46 e quem chama e que traduz.
const EV_OCUPADO := 0
const EV_LIVRE := 1

## Chave propria e nao `kind`: quem chama poe o `kind` dele por cima para levar
## isto ate ao catalogo, e duas chaves iguais faziam a de dentro desaparecer.
const CHAVE := &"contact"
const VAGA := &"slot"
const LUGAR := &"index"
const QUEM := &"id"

var _curva: EconomyCurve


func _init(curva: EconomyCurve) -> void:
	assert(curva != null, "a ContactQueue precisa de um EconomyCurve")
	_curva = curva


## Uma passagem por muro. Escreve os slots e o x de cada atacante, e devolve o
## que mudou de maos. `atacantes` vem por id crescente (§42).
func assign(
	obra: BuildSlot, criaturas: CreatureSystem, atacantes: PackedInt32Array
) -> Array[Dictionary]:
	var eventos: Array[Dictionary] = []
	_ajustar(obra, eventos)
	_libertar(obra, criaturas, atacantes, eventos)
	_ocupar(obra, criaturas, atacantes, eventos)
	_lugares(obra, criaturas, atacantes)
	return eventos


## Verdadeiro se este atacante tem slot — e so quem tem e que bate.
func holds(obra: BuildSlot, creature_id: int) -> bool:
	return obra.contact.has(creature_id)


## A que distancia do CENTRO do muro esta a ultima posicao da fila. Quem esta
## mais longe do que isto nem chega a ser atacante deste muro.
func reach(obra: BuildSlot) -> float:
	return obra.width * MEIO + _curva.queue_max_px


## O array de slots acompanha o nivel: subir de muro abre slots, e uma brecha
## fecha-os. Sem isto, um muro que subiu continuava com os slots do nivel 1.
func _ajustar(obra: BuildSlot, eventos: Array[Dictionary]) -> void:
	var quantos := obra.contact_slots() if obra.holds() else 0
	if obra.contact.size() == quantos:
		return
	for i in range(quantos, obra.contact.size()):
		if obra.contact[i] != NENHUM:
			eventos.append({CHAVE: EV_LIVRE, VAGA: obra.id, LUGAR: i})
	var antes := obra.contact.size()
	obra.contact.resize(quantos)
	for i in range(antes, quantos):
		obra.contact[i] = NENHUM


## Sai quem morreu, quem desapareceu e quem deixou de atacar este muro. Quem
## continua la FICA: um slot que mudasse de dono todos os ticks era a mesma
## multidao a tremer que as posicoes atribuidas existem para evitar.
func _libertar(
	obra: BuildSlot,
	criaturas: CreatureSystem,
	atacantes: PackedInt32Array,
	eventos: Array[Dictionary]
) -> void:
	for i in obra.contact.size():
		var quem := obra.contact[i]
		if quem == NENHUM:
			continue
		var c := criaturas.index_of(quem)
		if c != NENHUM and criaturas.alive(c) and atacantes.has(quem):
			continue
		obra.contact[i] = NENHUM
		eventos.append({CHAVE: EV_LIVRE, VAGA: obra.id, LUGAR: i})


## §50: "slots libertados sao preenchidos pelo atacante mais proximo da fila,
## com 0,4 s de transicao visivel". A transicao e o cooldown: quem acaba de
## entrar no slot nao bate no mesmo instante em que entrou.
func _ocupar(
	obra: BuildSlot,
	criaturas: CreatureSystem,
	atacantes: PackedInt32Array,
	eventos: Array[Dictionary]
) -> void:
	for i in obra.contact.size():
		if obra.contact[i] != NENHUM:
			continue
		var quem := _mais_proximo(obra, criaturas, atacantes)
		if quem == NENHUM:
			return
		obra.contact[i] = quem
		criaturas.cooldowns[criaturas.index_of(quem)] = _curva.slot_replace_time
		eventos.append({CHAVE: EV_OCUPADO, VAGA: obra.id, LUGAR: i, QUEM: quem})


func _mais_proximo(obra: BuildSlot, criaturas: CreatureSystem, atacantes: PackedInt32Array) -> int:
	var melhor := NENHUM
	var melhor_d := INF
	for quem in atacantes:
		if obra.contact.has(quem):
			continue
		var c := criaturas.index_of(quem)
		if c == NENHUM or not criaturas.alive(c):
			continue
		var d := absf(criaturas.xs[c] - obra.x)
		if d < melhor_d:
			melhor_d = d
			melhor = quem
	return melhor


## Onde cada um fica. Quem tem slot vai a FACE do muro; quem espera fica na fila
## do §50 — `base + i * espacamento`, por id crescente, com tecto.
##
## O §50 escreve as distancias a partir de `wall.x`, e o modelo dele nao tem
## largura de muro. Estes tem: 30 px medidos do centro de uma estacaria de 64
## punham o primeiro da fila DENTRO dela. Medem-se da face, que e onde se bate e
## onde se espera (Q-071).
func _lugares(obra: BuildSlot, criaturas: CreatureSystem, atacantes: PackedInt32Array) -> void:
	var lugar := 0
	for quem in atacantes:
		var c := criaturas.index_of(quem)
		if c == NENHUM:
			continue
		var lado := _lado(criaturas.xs[c], obra.x)
		var face := obra.width * MEIO
		if obra.contact.has(quem):
			criaturas.target_xs[c] = obra.x + lado * face
			continue
		var recuo := _curva.queue_min_px + lugar * _curva.queue_spacing_px
		criaturas.target_xs[c] = obra.x + lado * (face + minf(recuo, _curva.queue_max_px))
		lugar += 1


func _lado(x: float, muro_x: float) -> float:
	if is_equal_approx(x, muro_x):
		return FORA
	return signf(x - muro_x)
