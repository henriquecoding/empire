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
## O tipo do segment_entered que diz que o rei atravessou para a regiao seguinte.
const CROSSING := &"crossing"


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
				if not assume(unidades, king_id, passagens) and not cross(unidades, king_id):
					if not choose_mode(unidades, king_id, obras, campo):
						choose_wall(unidades, king_id, obras)
			IntentQueue.Kind.MARK_TARGET:
				if campo == null or campo.classes.marks():  # so quem tem arco (Q-086)
					mark(unidades, bichos, combate, args[&"x"], king_id)
			IntentQueue.Kind.DAY_LENGTH:
				day_length(args[&"seconds"])
			IntentQueue.Kind.IMPULSE:
				if campo != null:
					campo.impulse(args[&"id"], unidades, king_id)
	return larga


## O Verbo 2 numa casa de conversao de pe: escolhe o outro modo (Q-115).
static func choose_mode(
	units: UnitSystem, king: int, builds: BuildSystem, campo: FieldWork
) -> bool:
	var i := units.index_of(king)
	if builds == null or campo == null or i < 0 or not units.alive(i):
		return false
	for slot in builds.slots:
		if slot.band != units.bands[i] or absf(slot.x - units.xs[i]) > slot.width * HALF:
			continue
		if campo.conversion.craft_of(slot) != null and slot.standing():
			return campo.conversion.choose(slot)
	return false


## A escolha A/B do §10, antes de pagar o segundo degrau; E partilha o Verbo 2. E
## a variante de uma melhoria (P-N, Q-136), antes da primeira moeda.
static func choose_wall(units: UnitSystem, king: int, builds: BuildSystem) -> bool:
	var i := units.index_of(king)
	if builds == null or i < 0 or not units.alive(i):
		return false
	for slot in builds.slots:
		if slot.band != units.bands[i] or absf(slot.x - units.xs[i]) > slot.width * HALF:
			continue
		if SlotVariant.choose(slot):
			return true
		if not wall_choice_open(slot):
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


## Quem pisa uma moeda apanha-a (Gleaning). A caca e o que as tuas tropas apanham
## vai para o saco delas e para o rei quando ele passa (Q-107, Q-111).
static func sweep(unidades: UnitSystem, moedas: CoinSystem, king_id: int) -> void:
	var guarda: Dictionary = SimLoop.hunting.bagged if SimLoop.hunting != null else {}
	var escudeiro := SimLoop.field.classes.squire if SimLoop.field != null else null
	Gleaning.sweep(unidades, moedas, king_id, guarda, escudeiro)


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


## O Verbo 2 onde ele ja tem onde acontecer: uma passagem entre faixas (§11). Trocar
## de classe, montar e subir em criatura (§24) nao tem sistema ainda. Verdadeiro se
## alguem mudou mesmo de faixa.
static func assume(unidades: UnitSystem, king_id: int, passagens: PackedFloat32Array) -> bool:
	var para := destination(unidades, king_id, passagens)
	if para == NENHUMA:
		return false
	var i := unidades.index_of(king_id)
	var de := int(unidades.bands[i])
	unidades.bands[i] = para
	EventBus.queue(&"passage_used", [king_id, de, para])
	return true


## A travessia (P-K, Q-135): o Verbo 2 na bifurcacao, de dia, a partir do dia
## `crossing_day`, acaba a regiao (o game.gd ouve o segment_entered).
static func cross(unidades: UnitSystem, king_id: int) -> bool:
	if not crossing_open(unidades, king_id):
		return false
	SimLoop.state.crossed = true
	var ordem := SimLoop.state.region + 1
	var regioes := SimLoop.state.chapters.regions
	var a_seguir := regioes[ordem] if ordem < regioes.size() else ""
	EventBus.queue(&"segment_entered", [StringName(a_seguir), CROSSING])
	return true


## Se o rei esta onde a travessia pega, e ela ja abriu.
static func crossing_open(unidades: UnitSystem, king_id: int) -> bool:
	var i := unidades.index_of(king_id)
	if i == UnitSystem.NENHUM or not unidades.alive(i) or SimLoop.state.crossed:
		return false
	if unidades.bands[i] != int(Band.Kind.SURFACE) or not at_fork(unidades.xs[i]):
		return false
	var dia := ClockService.clock.day
	var de_dia := ClockService.clock.current_phase() < GameClock.Phase.DUSK
	return de_dia and dia >= SimFactory.curve().crossing_day


static func at_fork(x: float) -> bool:
	return Passages.near(x, SimLoop.secrets.chapters)


## Para onde o Verbo 2 leva este corpo AGORA, ou NENHUMA: e o gesto e o sinal (GB-14).
## De baixo, a boca escorada tambem serve — a escora fecha por cima (N4, Q-138).
static func destination(unidades: UnitSystem, unit_id: int, passagens: PackedFloat32Array) -> int:
	var i := unidades.index_of(unit_id)
	if i == UnitSystem.NENHUM or not unidades.alive(i):
		return NENHUMA
	var dados := Registry.entry(TABELA_TROPAS, unidades.data_ids[i]) as UnitData
	var em_baixo := int(unidades.bands[i]) == int(Band.Kind.UNDERGROUND)
	var x := unidades.xs[i]
	var boca := Passages.near(x, passagens) or em_baixo and Passages.near(x, SimLoop.passages)
	if not dados.can_change_band or not boca:
		return NENHUMA
	return int(Band.Kind.SURFACE) if em_baixo else int(Band.Kind.UNDERGROUND)


## §26: o slider do dia (240–540 s) nos limites do clock.csv; zero e o dia dele.
static func day_length(segundos: float) -> void:
	var dados := Registry.entry(&"economy", &"clock") as ClockData
	var alvo := segundos if segundos > 0.0 else dados.day_seconds
	ClockService.clock.set_day_seconds(clampf(alvo, dados.day_seconds_min, dados.day_seconds_max))


## O gatilho direito do §24: marca a criatura mais proxima deste x para todos os
## teus, no topo da prioridade do §50. So uma classe de arco marca (Q-086).
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
