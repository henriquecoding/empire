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

## A origem que o coin_dropped leva quando a moeda sai da mao do jogador.
const JOGADOR := &"player"

## Sem faixa para onde ir: longe de uma passagem, ou um corpo que nao muda.
const NENHUMA := -1
const HALF := 0.5


## §61: as intencoes sao consumidas no inicio do tick, pela ordem em que
## chegaram, e nenhuma delas mudou estado nenhum quando foi enfileirada. E o que
## faz a partida determinista apesar de haver um humano dentro dela.
##
## Devolve as moedas a largar, porque largar precisa do estado, do sorteio e de
## um id novo — e isso e do SimLoop, que tem o Verbo 1.
static func consume(
	fila: IntentQueue,
	unidades: UnitSystem,
	bichos: CreatureSystem,
	combate: CombatSystem,
	king_id: int,
	passagens: PackedFloat32Array,
	obras: BuildSystem = null,
	campo: FieldWork = null
) -> Array[Dictionary]:
	var larga: Array[Dictionary] = []
	for intencao in fila.take():
		var args: Dictionary = intencao[1]
		match int(intencao[0]):
			IntentQueue.Kind.DROP_COIN:
				if spend(unidades, king_id, args[&"amount"]):
					larga.append(args)
			IntentQueue.Kind.ASSUME:
				if not assume(unidades, king_id, passagens):
					choose_wall(unidades, king_id, obras)
			IntentQueue.Kind.MARK_TARGET:
				mark(unidades, bichos, combate, args[&"x"], king_id)
			IntentQueue.Kind.DAY_LENGTH:
				day_length(args[&"seconds"])
			IntentQueue.Kind.IMPULSE:
				if campo != null:
					campo.impulse(args[&"id"], unidades, king_id)
	return larga


## A escolha A/B do §10, antes de pagar o segundo degrau; E partilha o Verbo 2.
static func choose_wall(units: UnitSystem, king: int, builds: BuildSystem) -> bool:
	var i := units.index_of(king)
	if builds == null or i < 0 or not units.alive(i):
		return false
	for slot in builds.slots:
		if slot.band != units.bands[i] or not wall_choice_open(slot):
			continue
		if absf(slot.x - units.xs[i]) > slot.width * HALF:
			continue
		var path := (
			BuildSlot.Path.GUARNICAO
			if slot.path == BuildSlot.Path.FORTIFICACAO
			else BuildSlot.Path.FORTIFICACAO
		)
		return slot.choose_path(path)
	return false


## Se a escolha A/B ainda se faz nesta obra. O painel de contexto pergunta isto
## mesmo, para nunca anunciar um gesto que o verbo depois recusa.
static func wall_choice_open(slot: BuildSlot) -> bool:
	if not slot.two_paths() or slot.level > 1 or slot.paid > 0:
		return false
	return slot.state in [BuildSlot.State.EMPTY, BuildSlot.State.DONE]


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
		# So o rei leva as que ele proprio largou; o escudeiro apanha as caidas (Q-114).
		var caidas := unidades.ids[i] != king_id
		var levado := collect(moedas, unidades.ids[i], unidades.xs[i], faixa, espaco, caidas)
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
	moedas: CoinSystem, unit_id: int, x: float, faixa: Band.Kind, espaco: int, so_caidas := false
) -> int:
	var valores := moedas.amounts_by_id()
	var apanhadas := moedas.collect(x, faixa, espaco, so_caidas)
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
	var para := destination(unidades, king_id, passagens)
	if para == NENHUMA:
		return false
	var i := unidades.index_of(king_id)
	var de := int(unidades.bands[i])
	unidades.bands[i] = para
	EventBus.queue(&"passage_used", [king_id, de, para])
	return true


## Para que faixa o Verbo 2 levava este corpo AGORA, ou NENHUMA. E a conta do
## gesto e a do sinal que o PassageCue desenha, e por isso e uma so (GB-14): se o
## sinal aparece, o E pega; se o E nao pega, nao ha sinal.
static func destination(unidades: UnitSystem, unit_id: int, passagens: PackedFloat32Array) -> int:
	var i := unidades.index_of(unit_id)
	if i == UnitSystem.NENHUM or passagens.is_empty() or not unidades.alive(i):
		return NENHUMA
	var dados := Registry.entry(TABELA_TROPAS, unidades.data_ids[i]) as UnitData
	if not dados.can_change_band or not Passages.near(unidades.xs[i], passagens):
		return NENHUMA
	if int(unidades.bands[i]) == int(Band.Kind.SURFACE):
		return int(Band.Kind.UNDERGROUND)
	return int(Band.Kind.SURFACE)


## §26: "slider de duracao do dia (240–540 s)". Os limites sao os do clock.csv e
## aplicam-se aqui, onde a intencao chega a simulacao; zero e o dia do clock.csv.
## O relogio escala as seis fases e o decorrido juntos, e a fase nao salta.
static func day_length(segundos: float) -> void:
	var dados := Registry.entry(&"economy", &"clock") as ClockData
	var alvo := segundos if segundos > 0.0 else dados.day_seconds
	ClockService.clock.set_day_seconds(clampf(alvo, dados.day_seconds_min, dados.day_seconds_max))


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
