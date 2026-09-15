# src/core/verbs.gd — os dois verbos onde eles tocam na simulacao (§02, §61).
#
# "Tudo o que o jogador faz passa pela moeda" e o Verbo 1, e esse vive no
# SimLoop porque precisa do estado, do sorteio e de um id novo. Aqui ficam os
# outros dois gestos: o Verbo 2 e o gatilho direito do §24.
#
# Sao estaticos e recebem tudo o que tocam. A razao e a mesma de sempre: a
# simulacao nao pode conhecer o catalogo de eventos nem o indice de recursos, e
# estas funcoes precisam dos dois — logo vivem em src/core/ e nao em src/sim/.
class_name Verbs
extends RefCounted

const TABELA_TROPAS := &"units"


## Tirar do saco para largar. O Verbo 1 nao cria moeda do nada: sai do que o
## monarca transporta, e o §24 mostra isso no proprio sprite — "o saco do
## personagem enche visivelmente". Devolve falso quando nao ha.
static func spend(unidades: UnitSystem, unit_id: int, quanto: int) -> bool:
	var i := unidades.index_of(unit_id)
	if i == UnitSystem.NENHUM or unidades.carried_coins[i] < quanto:
		return false
	unidades.carried_coins[i] -= quanto
	return true


## Quem pisa uma moeda apanha-a: o monarca e quem tiver a tag `collects_coins`
## (o escudeiro do §08). Nao e o mesmo que a apanha do F1-04 — aquela e de quem
## FOI buscar uma moeda em concreto; esta e de quem passou por cima.
static func sweep(unidades: UnitSystem, moedas: CoinSystem, king_id: int) -> void:
	if moedas.count() == 0:
		return
	for i in unidades.count():
		if unidades.owners[i] == RecruitSystem.SEM_DONO or not unidades.alive(i):
			continue
		var espaco := unidades.coin_capacities[i] - unidades.carried_coins[i]
		if espaco <= 0 or not _apanha_do_chao(unidades, i, king_id):
			continue
		var faixa := unidades.bands[i] as Band.Kind
		var levado := collect(moedas, unidades.ids[i], unidades.xs[i], faixa, espaco)
		unidades.carried_coins[i] += levado


static func _apanha_do_chao(unidades: UnitSystem, i: int, king_id: int) -> bool:
	if unidades.ids[i] == king_id:
		return true
	var dados := Registry.entry(TABELA_TROPAS, unidades.data_ids[i]) as UnitData
	return dados.tags.has(&"collects_coins")


## Apanhar a mao, pelo catalogo. `espaco` e o que falta encher no saco, e vem de
## UnitData.coin_capacity — a capacidade nao esta escrita em lado nenhum aqui.
## E o lado de fora do Verbo 1: largar e do SimLoop, que tem o estado e o
## sorteio; apanhar so precisa das moedas.
static func collect(
	moedas: CoinSystem, unit_id: int, x: float, faixa: Band.Kind, espaco: int
) -> int:
	var valores := moedas.amounts_by_id()
	var apanhadas := moedas.collect(x, faixa, espaco)
	var total := moedas.value_of(apanhadas, valores)
	if total > 0:
		EventBus.queue(&"coin_collected", [unit_id, total])
	return total


## O Verbo 2 onde ele ja tem onde acontecer: uma passagem entre faixas (§11).
## Trocar de classe, montar e subir em criatura sao os outros tres usos do §24, e
## nenhum deles tem sistema ainda.
##
## Devolve verdadeiro se alguem mudou mesmo de faixa.
static func assume(unidades: UnitSystem, king_id: int, passagens: PackedFloat32Array) -> bool:
	var i := unidades.index_of(king_id)
	if i == UnitSystem.NENHUM or passagens.is_empty():
		return false
	var dados := Registry.entry(TABELA_TROPAS, unidades.data_ids[i]) as UnitData
	if not dados.can_change_band:
		return false
	for x in passagens:
		if absf(unidades.xs[i] - x) > SimFactory.PASSAGEM_PX:
			continue
		var de := int(unidades.bands[i])
		var para := int(Band.Kind.SURFACE)
		if de == int(Band.Kind.SURFACE):
			para = int(Band.Kind.UNDERGROUND)
		unidades.bands[i] = para
		EventBus.queue(&"passage_used", [king_id, de, para])
		return true
	return false


## O gatilho direito do §24: marca a criatura mais proxima deste x para todos os
## teus. O §50 poe o alvo marcado no topo da prioridade de escolha.
static func mark(
	unidades: UnitSystem, bichos: CreatureSystem, combate: CombatSystem, x: float, king_id: int
) -> void:
	var alvo := UnitSystem.NENHUM
	var perto := INF
	for c in bichos.count():
		var d := absf(bichos.xs[c] - x)
		if d < perto:
			perto = d
			alvo = bichos.ids[c]
	if alvo == UnitSystem.NENHUM:
		return
	for i in unidades.count():
		if unidades.owners[i] != RecruitSystem.SEM_DONO:
			combate.mark(unidades.ids[i], alvo)
	EventBus.queue(&"target_marked", [alvo, king_id])
