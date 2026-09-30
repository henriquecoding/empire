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
## O herdeiro: forma-se a alvorada e assume a coroa na seguinte a morte do rei (Q-133).
var succession: Succession
## Os acampamentos da regiao, de onde chega um vagabundo por alvorada (Q-122).
## Escritos por quem monta o mundo.
var camps: PackedFloat32Array = PackedFloat32Array()
## A marcha e os vassalos (§13; Q-103, Q-146): o reino que fica.
var realm := Realm.new()
## O animo do reino (Q-102): memorias com prazo, que mexem na fuga, na producao e
## em quem chega aos acampamentos.
var spirit: Spirit
## As terras entre os povos, geradas ao andar e guardadas (Q-173, ADR 0038).
var wilds := WildSegments.new(SimFactory.segment_kit())
## Quem o jogador pode assumir alem do rei (§08; Q-150, Q-162, Q-178).
var roster := Roster.new(
	SimFactory.by_id(&"classes"), SimFactory.by_id(&"units"), SimFactory.by_id(&"classes/storages")
)

var _economia: EconomySystem
var _moral: MoraleSystem
var _dia := 0
var _rei := UnitSystem.NENHUM
var _noite: NightWatch
var _combate: CombatSystem
var _nucleo := Vector2.ZERO
var _perfis: Dictionary
var _obras: BuildSystem


func _init(
	economia: EconomySystem = null,
	moral: MoraleSystem = null,
	combate: CombatSystem = null,
	noite: NightWatch = null
) -> void:
	_noite = noite
	_perfis = SimFactory.by_id(&"units")
	Discoveries.gates = RulesFactory.discovery_gates()  # as estatuas (Q-016)
	hunting = HuntingSystem.new(
		SimFactory.by_id(&"units"), Registry.entry(&"wildlife", &"rabbit") as WildlifeData
	)
	hunting.wildlife = SimFactory.by_id(&"wildlife")  # o bicho de cada toca (Q-150)
	training = SimFactory.training()
	crown = SimFactory.crown()
	conversion = SimFactory.conversion()
	var monarca := Registry.entry(&"classes", &"monarch") as ClassData
	classes = ClassSystem.new(monarca, SimFactory.by_id(&"units"), SimFactory.storage(monarca))
	if noite != null:
		noite.dark.torch.storage = classes.storage  # os archotes vao no cinto (Q-153)
		noite.names.away = realm.march.away  # quem marcha nao e chorado (Q-146)
	upkeep = UpkeepSystem.new(SimFactory.by_id(&"units"), SimFactory.curve())
	var curva := SimFactory.curve()
	var niveis := curva.spirit_levels
	spirit = Spirit.new(niveis[1], niveis[0], niveis[2])
	succession = Succession.new(curva.heir_training_days, curva.heir_cost_per_day)
	if combate != null:
		combate.guard = classes
	_combate = combate
	_economia = economia
	_moral = moral
	if _economia != null:
		_economia.crown = crown
		_economia.conversion = conversion
		conversion.jobs = _economia.jobs


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
	if unidades != null:
		Frontier.grow(self, unidades, SimLoop.king_id, largura)  # o que se ve a frente (Q-173)
	if dia != _dia and unidades != null:
		_dia = dia
		crown.dawn(dia, unidades)
		classes.dawn()
		if dia > 1 and estado != null:
			_alvorada(dia, unidades, estado)
	if _economia != null:
		_economia.today = dia
		_economia.greed = estado.greed if estado != null else 0
		_economia.spirit = spirit.level(dia)
	var perks: Dictionary = _noite.names.grants() if _noite != null else {}  # §76, Q-102
	if _moral != null:
		_moral.steadfast = crown.steadfast(dia)
		_moral.spirit = spirit.level(dia)
		_moral.perks = perks
	if _combate != null:
		_combate.perks = perks


## A intencao do §61 que a roda do rei enfileira: um impulso por dia (§15, §24).
func impulse(id: StringName, unidades: UnitSystem, rei: int) -> void:
	var perfil := RulesFactory.impulse_cost_mult(_economia.greed if _economia != null else 0)
	var custo := crown.price(id, ClockService.clock.day, perfil)  # o preco de hoje (Q-014)
	if crown.use(id, ClockService.clock.day, unidades, rei, custo):
		EventBus.queue(&"royal_impulse_used", [id])
		EventBus.queue(&"coin_spent", [custo, &"impulse"])


## Passo 4: quem caca, quem se forma para a noite (Q-128) e quem treina escrevem
## alvo por cima de seguir o rei — por esta ordem, e o treino ganha.
func plan(unidades: UnitSystem, luz: bool) -> void:
	hunting.plan(unidades, luz)
	var lado := 0
	if not luz and _noite != null:
		var rot := _noite.rot
		lado = rot.state.side if rot.active() else rot.announced
		var passo := SimFactory.curve().follow_spacing_px
		Muster.plan(unidades, _perfis, _rei, _nucleo, lado, passo)
	classes.escort(unidades, lado)
	training.plan(unidades)
	Assume.plan(unidades, _rei, _nucleo, self)  # quem se conduz, e o rei largado (§08)


## Passo 5, a seguir as obras: as moedas pousadas numa casa de oficio. A casa de
## conversao ja nao troca de modo com a moeda: escolhe-se (Q-115, Verbs).
func absorb(moedas: CoinSystem, obras: BuildSystem, unidades: UnitSystem) -> void:
	EventRelay.training(training.absorb(moedas, obras, unidades))
	conversion.staff(obras)  # a capacidade pede o cozinheiro la dentro (Q-145)


## Passos 6 e 8: a caca rende moeda; o treino corre com quem esta la dentro, e a
## defesa que os construtores dao as muralhas acompanha quem esta vivo.
## A caca do cacador teu vai para o saco dele e chega ao rei quando ele passa
## perto (Q-111); a de quem nao e de ninguem cai no chao, que e o 1:10 do §25.
func resolve(
	unidades: UnitSystem, obras: BuildSystem, delta: float, luz: bool, relogio: GameClock, rei: int
) -> Array[Dictionary]:
	_rei = rei
	_obras = obras
	_nucleo = _do_nucleo(obras)
	obras.wall_defense = training.wall_defense(unidades)
	classes.watch(unidades, rei, not luz)
	conversion.bind(unidades)
	conversion.apply(unidades, conversion.active)
	EventRelay.training(training.tick(delta, unidades, obras, relogio.day_seconds()))
	var intro := relogio.elapsed >= HuntWatch.intro_at(relogio.day_seconds())
	hunting.grow(delta, luz, HuntWatch.period(relogio.day_seconds()))
	var caca := hunting.resolve(unidades, luz, intro)
	var chao := hunting.bag(unidades, caca)
	for d in caca:
		if not d in chao:
			EventBus.queue(&"coin_collected", [d[&"hunter"], d[&"amount"]])
	var alcance := SimFactory.curve().recruit_notice_px
	var entregue := hunting.deliver(unidades, rei, alcance)  # o escudeiro guarda (Q-114)
	if entregue > 0:
		EventBus.queue(&"coin_collected", [rei, entregue])
	return chao


## O que vai no save, pela chave de cada parte. Uma parte nova entra por estar aqui.
func parts() -> Dictionary:
	return {
		&"hunting": hunting,
		&"training": training,
		&"crown": crown,
		&"conversion": conversion,
		&"classes": classes,
		&"upkeep": upkeep,
		&"succession": succession,
		&"realm": realm,
		&"spirit": spirit,
		&"wilds": wilds,
		&"roster": roster,
	}


func to_dict() -> Dictionary:
	var saida := {}
	var partes := parts()
	for chave: StringName in partes:
		saida[chave] = partes[chave].to_dict()
	return saida


## Uma parte que o save nao tem fica como um jogo novo a deixa (§62).
func from_dict(mundo: Dictionary) -> void:
	var partes := parts()
	for chave: StringName in partes:
		partes[chave].from_dict(mundo.get(chave, {}))
	Frontier.reapply(self, SimLoop.world_width)  # os acampamentos e as masmorras voltam
	_dia = ClockService.clock.day if ClockService.clock != null else 0


## A alvorada de um dia que nao e o primeiro (DawnWork): o rei e o novo, se houve sucessao.
func _alvorada(dia: int, unidades: UnitSystem, estado: GameState) -> void:
	_rei = DawnWork.run(self, dia, unidades, estado, _obras, _economia, _rei, _nucleo)


func _do_nucleo(obras: BuildSystem) -> Vector2:
	for vaga in obras.slots:
		if vaga.kind == BuildSlot.NUCLEO:
			return Vector2(vaga.x, vaga.width * BuildSystem.METADE)
	return _nucleo
