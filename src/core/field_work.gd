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

var _economia: EconomySystem
var _moral: MoraleSystem
var _dia := 0


func _init(economia: EconomySystem = null, moral: MoraleSystem = null) -> void:
	hunting = HuntingSystem.new(
		SimFactory.by_id(&"units"), Registry.entry(&"wildlife", &"rabbit") as WildlifeData
	)
	training = SimFactory.training()
	crown = SimFactory.crown()
	_economia = economia
	_moral = moral
	if _economia != null:
		_economia.crown = crown


## Passo 3: o dia novo abre as clareiras e cobra o que os impulsos de ontem
## deixaram a pagar (§15).
func prepare(
	dia: int, core_x: float, largura: float, unidades: UnitSystem = null, fase: int = 0
) -> void:
	HuntWatch.prepare(hunting, dia, core_x, largura, fase)
	if dia != _dia and unidades != null:
		_dia = dia
		crown.dawn(dia, unidades)
	if _economia != null:
		_economia.today = dia
	if _moral != null:
		_moral.steadfast = crown.steadfast(dia)


## A intencao do §61 que a roda do rei enfileira: um impulso por dia (§15, §24).
func impulse(id: StringName, unidades: UnitSystem, rei: int) -> void:
	var custo := (Registry.entry(&"crown/impulses", id) as ImpulseData).coin_cost
	if crown.use(id, ClockService.clock.day, unidades, rei):
		EventBus.queue(&"royal_impulse_used", [id])
		EventBus.queue(&"coin_spent", [custo, &"impulse"])


## Passo 4: quem caca e quem treina escrevem alvo por cima de seguir o rei.
func plan(unidades: UnitSystem, luz: bool) -> void:
	hunting.plan(unidades, luz)
	training.plan(unidades)


## Passo 5, a seguir as obras: as moedas pousadas numa casa de oficio.
func absorb(moedas: CoinSystem, obras: BuildSystem, unidades: UnitSystem) -> void:
	EventRelay.training(training.absorb(moedas, obras, unidades))


## Passos 6 e 8: a caca rende moeda; o treino corre com quem esta la dentro, e a
## defesa que os construtores dao as muralhas acompanha quem esta vivo.
## A caca do cacador teu vai para o saco dele e chega ao rei quando ele passa
## perto (Q-111); a de quem nao e de ninguem cai no chao, que e o 1:10 do §25.
func resolve(
	unidades: UnitSystem, obras: BuildSystem, delta: float, luz: bool, relogio: GameClock, rei: int
) -> Array[Dictionary]:
	obras.wall_defense = training.wall_defense(unidades)
	EventRelay.training(training.tick(delta, unidades, obras, relogio.day_seconds()))
	var caca := hunting.resolve(unidades, luz, relogio.elapsed >= HuntWatch.INTRO_SECONDS)
	var chao := hunting.bag(unidades, caca)
	for d in caca:
		if not d in chao:
			EventBus.queue(&"coin_collected", [d[&"hunter"], d[&"amount"]])
	var entregue := hunting.deliver(unidades, rei, SimFactory.curve().recruit_notice_px)
	if entregue > 0:
		EventBus.queue(&"coin_collected", [rei, entregue])
	return chao


func to_dict() -> Dictionary:
	return {
		&"hunting": hunting.to_dict(), &"training": training.to_dict(), &"crown": crown.to_dict()
	}


func from_dict(mundo: Dictionary) -> void:
	hunting.from_dict(mundo.get(&"hunting", {}))
	training.from_dict(mundo.get(&"training", {}))
	crown.from_dict(mundo.get(&"crown", {}))
	_dia = ClockService.clock.day if ClockService.clock != null else 0
