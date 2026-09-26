# src/core/field_work.gd — o trabalho do dia que nao e obra: a caca (§25) e as
# casas de oficio (§09, §10).
#
# Existe para o SimLoop ficar com a ORDEM dos onze passos e nao com os detalhes
# de cada sistema (ADR 0020): cada funcao aqui e o bocado de um passo do §43, e
# o comentario diz qual.
class_name FieldWork
extends RefCounted

var hunting: HuntingSystem
var training: TrainingSystem
var crown: CrownSystem
var conversion: ConversionSystem
## A classe do rei (§08): a aura do Monarca e a evolucao.
var classes: ClassSystem
## A manutencao do exercito, paga a alvorada (§06, Q-124).
var upkeep: UpkeepSystem
## Os acampamentos da regiao, de onde chega um vagabundo por alvorada (Q-122).
## Escritos por quem monta o mundo.
var camps: PackedFloat32Array = PackedFloat32Array()

var _economia: EconomySystem
var _moral: MoraleSystem
var _dia := 0
var _rei := UnitSystem.NENHUM


func _init(
	economia: EconomySystem = null, moral: MoraleSystem = null, combate: CombatSystem = null
) -> void:
	hunting = HuntingSystem.new(
		SimFactory.by_id(&"units"), Registry.entry(&"wildlife", &"rabbit") as WildlifeData
	)
	training = SimFactory.training()
	crown = SimFactory.crown()
	conversion = SimFactory.conversion()
	var monarca := Registry.entry(&"classes", &"monarch") as ClassData
	classes = ClassSystem.new(monarca, SimFactory.by_id(&"units"))
	upkeep = UpkeepSystem.new(SimFactory.by_id(&"units"))
	if combate != null:
		combate.guard = classes
	_economia = economia
	_moral = moral
	if _economia != null:
		_economia.crown = crown
		_economia.conversion = conversion


## Passo 3: o dia novo abre as clareiras, cobra o que os impulsos de ontem
## deixaram a pagar (§15) e a manutencao (§06), e traz um vagabundo (Q-122).
func prepare(
	dia: int,
	core_x: float,
	largura: float,
	unidades: UnitSystem = null,
	fase: int = 0,
	estado: GameState = null
) -> void:
	HuntWatch.prepare(hunting, dia, core_x, largura, fase)
	if dia != _dia and unidades != null:
		_dia = dia
		crown.dawn(dia, unidades)
		classes.dawn()
		if dia > 1 and estado != null:
			_alvorada(dia, unidades, estado)
	if _economia != null:
		_economia.today = dia
		_economia.greed = estado.greed if estado != null else 0
	if _moral != null:
		_moral.steadfast = crown.steadfast(dia)


## A intencao do §61 que a roda do rei enfileira: um impulso por dia (§15, §24).
func impulse(id: StringName, unidades: UnitSystem, rei: int) -> void:
	var custo := (Registry.entry(&"crown/impulses", id) as ImpulseData).coin_cost
	if crown.use(id, ClockService.clock.day, unidades, rei):
		EventBus.queue(&"royal_impulse_used", [id])
		EventBus.queue(&"coin_spent", [custo, &"impulse"])


## Uma moeda do rei com outro alvo que o chao: uma arvore a consagrar (§74) ou
## o nucleo, para a classe evoluir (§08, Q-114). Nos dois a moeda volta ao saco.
func claims(
	largada: Dictionary,
	estado: GameState,
	noite: NightWatch,
	obras: BuildSystem,
	unidades: UnitSystem,
	rei: int
) -> bool:
	if noite.consecrate_at(estado, largada, rei):
		return true
	if not classes.can_evolve(estado.royal_seeds) or not _no_nucleo(largada, obras):
		return false
	classes.evolve(estado)
	var i := unidades.index_of(rei)
	if i != UnitSystem.NENHUM:
		unidades.carried_coins[i] += int(largada[EventRelay.QUANTO])
	return true


func _no_nucleo(largada: Dictionary, obras: BuildSystem) -> bool:
	var x: float = largada[EventRelay.ONDE]
	for vaga in obras.slots:
		if vaga.kind == BuildSlot.NUCLEO and vaga.band == int(largada[EventRelay.FAIXA]):
			return absf(vaga.x - x) <= vaga.width * BuildSystem.METADE
	return false


## Passo 4: quem caca e quem treina escrevem alvo por cima de seguir o rei.
func plan(unidades: UnitSystem, luz: bool) -> void:
	hunting.plan(unidades, luz)
	training.plan(unidades)


## Passo 5, a seguir as obras: as moedas pousadas numa casa de oficio.
func absorb(moedas: CoinSystem, obras: BuildSystem, unidades: UnitSystem) -> void:
	EventRelay.training(training.absorb(moedas, obras, unidades))
	if conversion.absorb(moedas, obras, unidades):
		EventBus.queue(&"coin_spent", [1, &"conversion"])


## Passos 6 e 8: a caca rende moeda; o treino corre com quem esta la dentro, e a
## defesa que os construtores dao as muralhas acompanha quem esta vivo.
## A caca do cacador teu vai para o saco dele e chega ao rei quando ele passa
## perto (Q-111); a de quem nao e de ninguem cai no chao, que e o 1:10 do §25.
func resolve(
	unidades: UnitSystem, obras: BuildSystem, delta: float, luz: bool, relogio: GameClock, rei: int
) -> Array[Dictionary]:
	_rei = rei
	obras.wall_defense = training.wall_defense(unidades)
	classes.watch(unidades, rei, not luz)
	conversion.bind(unidades)
	conversion.apply(unidades, conversion.active)
	EventRelay.training(training.tick(delta, unidades, obras, relogio.day_seconds()))
	var intro := relogio.elapsed >= HuntWatch.intro_at(relogio.day_seconds())
	var caca := hunting.resolve(unidades, luz, intro)
	var chao := hunting.bag(unidades, caca)
	for d in caca:
		if not d in chao:
			EventBus.queue(&"coin_collected", [d[&"hunter"], d[&"amount"]])
	var alcance := SimFactory.curve().recruit_notice_px
	var entregue := (
		hunting.deliver(unidades, rei, alcance) + classes.hand_over(unidades, rei, alcance)
	)
	if entregue > 0:
		EventBus.queue(&"coin_collected", [rei, entregue])
	return chao


func to_dict() -> Dictionary:
	return {
		&"hunting": hunting.to_dict(),
		&"training": training.to_dict(),
		&"crown": crown.to_dict(),
		&"conversion": conversion.to_dict(),
		&"classes": classes.to_dict(),
		&"upkeep": upkeep.to_dict(),
	}


func from_dict(mundo: Dictionary) -> void:
	hunting.from_dict(mundo.get(&"hunting", {}))
	training.from_dict(mundo.get(&"training", {}))
	crown.from_dict(mundo.get(&"crown", {}))
	conversion.from_dict(mundo.get(&"conversion", {}))
	classes.from_dict(mundo.get(&"classes", {}))
	upkeep.from_dict(mundo.get(&"upkeep", {}))
	_dia = ClockService.clock.day if ClockService.clock != null else 0


## A alvorada de um dia que nao e o primeiro: a manutencao do dia que acabou, e o
## vagabundo novo no acampamento do lado do dia (Q-122, Q-124).
func _alvorada(dia: int, unidades: UnitSystem, estado: GameState) -> void:
	if _economia != null:
		for e in upkeep.dawn(unidades, _rei, _economia):
			if e[UpkeepSystem.CHAVE] == UpkeepSystem.EV_PAGA:
				EventBus.queue(&"coin_spent", [e[UpkeepSystem.QUANTO], &"upkeep"])
			else:
				EventBus.queue(&"unit_fled", [e[UpkeepSystem.UNIDADE], &"upkeep"])
	if camps.is_empty():
		return
	var curva := SimFactory.curve()
	var vagabundo := Registry.entry(&"units", &"vagrant") as UnitData
	var livres := 0
	for i in unidades.count():
		if unidades.owners[i] == RecruitSystem.SEM_DONO and unidades.alive(i):
			livres += 1 if unidades.data_ids[i] == vagabundo.id else 0
	for k in mini(curva.vagrants_per_dawn, maxi(0, curva.vagrant_camp_cap - livres)):
		var x := camps[(dia + k) % camps.size()]
		var novo := unidades.spawn(estado, vagabundo, RecruitSystem.SEM_DONO, x)
		EventBus.queue(&"unit_spawned", [novo, vagabundo.id, x, int(Band.Kind.SURFACE)])
