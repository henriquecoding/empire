# src/core/foundation_watch.gd — a fundacao do reino, no jogo (ADR 0059).
#
# ADR 0065: o estandarte funda; a reserva abre depois da escolha.
# A companhia exige contratacao; ferramentas aparecem quando o Acampamento acaba.
# O alvo pago de evolucao conserva compatibilidade com campanhas anteriores.
class_name FoundationWatch
extends RefCounted

const CONSTRUTOR := &"builder"
const BANCA := &"bow_rack"
const MARTELOS := &"hammer_rack"
## A chave da sede no save do mundo.
const SEDE := &"seat"
## Onde fica a carroca e onde chega o pioneiro, a partir do nucleo. Sao autoria de nivel,
## como as posicoes do Greybox: a carroca a oeste do marco, o pioneiro a leste.
const CARROCA_X := -150.0
const PIONEIRO_X := 120.0


## O jogo novo, depois da gente do Greybox: o pioneiro e a carroca. Os ids dos que ja la
## estavam nao mudam (§45): o pioneiro nasce por ultimo.
static func arrive(rei: int) -> void:
	var regras := RulesFactory.rules()
	var i := SimLoop.units.index_of(rei)
	if i == UnitSystem.NENHUM:
		return
	var dono := SimLoop.units.owners[i]
	var construtor := Registry.entry(&"units", CONSTRUTOR) as UnitData
	for _k in regras.founder_pioneers:
		SimLoop.units.spawn(SimLoop.state, construtor, dono, SimLoop.core_x + PIONEIRO_X)
	SimLoop.seat.place_cart(SimLoop.core_x + CARROCA_X, regras.founder_provisions)


## Ao retomar uma sede fundada, completa bancas antigas vazias sem repetir treinos.
static func founded_tools() -> void:
	if RealmLadder.founded(SimLoop.builds):
		_bancada()


## O monarca passa pela carroca e leva o que lhe cabe no saco. E apanhar, e por isso
## corre no passo 5, ao lado de quem apanha moedas.
static func collect() -> void:
	var i := SimLoop.units.index_of(SimLoop.king_id)
	if i == UnitSystem.NENHUM or not SimLoop.units.alive(i):
		return
	if int(SimLoop.units.bands[i]) != int(Band.Kind.SURFACE):
		return
	var espaco := SimLoop.units.coin_capacities[i] - SimLoop.units.carried_coins[i]
	var alcance := RulesFactory.rules().provisions_grab_px
	var levou := SimLoop.seat.take_cart(SimLoop.units.xs[i], alcance, espaco)
	if levou > 0:
		SimLoop.units.carried_coins[i] += levou
		EventBus.queue(&"coin_collected", [SimLoop.king_id, levou])


## Os acontecimentos das obras deste tick, e o que a fundacao lhes acrescenta: a sede que
## chega ao Acampamento ergue as duas bancas de graca (plano §6.3). Acontece uma vez:
## o nucleo so passa pelo nivel 1 uma vez, e carregar um save nao repete o acontecimento.
static func after(eventos: Array[Dictionary]) -> Array[Dictionary]:
	var mais: Array[Dictionary] = []
	for e in eventos:
		var vaga: BuildSlot = e[BuildSystem.VAGA]
		if int(e[BuildSystem.CHAVE]) != BuildSystem.EV_COMPLETA or vaga.kind != BuildSlot.NUCLEO:
			continue
		if vaga.level == RealmLadder.FUNDADO and RulesFactory.rules().founder_bow_rack > 0:
			mais.append_array(_bancada())
	eventos.append_array(mais)
	return eventos


## O Verbo 2 no marco da sede, com o monarca a poder evoluir: troca o alvo da moeda entre
## a sede e o monarca. Verdadeiro se trocou; sem escolha, o Verbo 2 segue para o resto.
static func toggle(unidades: UnitSystem, rei: int, obras: BuildSystem, campo: FieldWork) -> bool:
	if SimLoop.arrival.active or campo == null or not at_seat(unidades, rei, obras):
		return false
	var pode := MonarchWatch.can_evolve(campo, SimLoop.state.royal_seeds)
	if not pode:
		return false
	SimLoop.seat.toggle_aim(pode)
	return true


## Se o monarca esta no marco da sede: onde a moeda dele paga a sede, ou o evolui.
static func at_seat(unidades: UnitSystem, rei: int, obras: BuildSystem) -> bool:
	var i := unidades.index_of(rei)
	var sede := RealmLadder.seat(obras)
	if i == UnitSystem.NENHUM or sede == null or int(unidades.bands[i]) != int(sede.band):
		return false
	return absf(unidades.xs[i] - sede.x) <= sede.catch_half()


## Se a moeda do monarca no marco vai evoluir o monarca, e nao pagar a sede.
static func aims_monarch() -> bool:
	var pode := MonarchWatch.can_evolve(SimLoop.field, SimLoop.state.royal_seeds)
	return SimLoop.seat.aims_monarch(pode)


## As duas bancas por levantar passam a estar de pe, sem moeda, depois da fundacao.
static func _bancada() -> Array[Dictionary]:
	var eventos: Array[Dictionary] = []
	for vaga in SimLoop.builds.slots:
		if (
			vaga.territory != 0
			or vaga.kind not in [BANCA, MARTELOS, CompanionWatch.POST]
			or vaga.level != 0
		):
			continue
		if vaga.state != BuildSlot.State.EMPTY or vaga.paid != 0:
			continue
		if not RealmGrowth.visible(SimLoop.builds, vaga):
			continue
		vaga.raise_to(RealmLadder.FUNDADO)
		(
			eventos
			. append(
				{
					BuildSystem.CHAVE: BuildSystem.EV_COMPLETA,
					BuildSystem.VAGA: vaga,
					BuildSystem.NIVEL: vaga.level,
				}
			)
		)
	return eventos
