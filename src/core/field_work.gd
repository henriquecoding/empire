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


func _init() -> void:
	hunting = HuntingSystem.new(
		SimFactory.by_id(&"units"), Registry.entry(&"wildlife", &"rabbit") as WildlifeData
	)
	training = SimFactory.training()


## Passo 3: o dia novo abre as clareiras.
func prepare(dia: int, core_x: float, largura: float) -> void:
	HuntWatch.prepare(hunting, dia, core_x, largura)


## Passo 4: quem caca e quem treina escrevem alvo por cima de seguir o rei.
func plan(unidades: UnitSystem, luz: bool) -> void:
	hunting.plan(unidades, luz)
	training.plan(unidades)


## Passo 5, a seguir as obras: as moedas pousadas numa casa de oficio.
func absorb(moedas: CoinSystem, obras: BuildSystem, unidades: UnitSystem) -> void:
	EventRelay.training(training.absorb(moedas, obras, unidades))


## Passos 6 e 8: a caca rende moeda; o treino corre com quem esta la dentro, e a
## defesa que os construtores dao as muralhas acompanha quem esta vivo.
func resolve(
	unidades: UnitSystem, obras: BuildSystem, delta: float, luz: bool, relogio: GameClock
) -> Array[Dictionary]:
	obras.wall_defense = training.wall_defense(unidades)
	EventRelay.training(training.tick(delta, unidades, obras, relogio.day_seconds()))
	return hunting.resolve(unidades, luz, relogio.elapsed >= HuntWatch.INTRO_SECONDS)


func to_dict() -> Dictionary:
	return {&"hunting": hunting.to_dict(), &"training": training.to_dict()}


func from_dict(mundo: Dictionary) -> void:
	hunting.from_dict(mundo.get(&"hunting", {}))
	training.from_dict(mundo.get(&"training", {}))
