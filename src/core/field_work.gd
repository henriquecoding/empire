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
	training = SimFactory.training()
	crown = SimFactory.crown()
	conversion = SimFactory.conversion()
	var monarca := Registry.entry(&"classes", &"monarch") as ClassData
	classes = ClassSystem.new(monarca, SimFactory.by_id(&"units"))
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


func to_dict() -> Dictionary:
	return {
		&"hunting": hunting.to_dict(),
		&"training": training.to_dict(),
		&"crown": crown.to_dict(),
		&"conversion": conversion.to_dict(),
		&"classes": classes.to_dict(),
		&"upkeep": upkeep.to_dict(),
		&"succession": succession.to_dict(),
		&"realm": realm.to_dict(),
		&"spirit": spirit.to_dict(),
	}


func from_dict(mundo: Dictionary) -> void:
	hunting.from_dict(mundo.get(&"hunting", {}))
	training.from_dict(mundo.get(&"training", {}))
	crown.from_dict(mundo.get(&"crown", {}))
	conversion.from_dict(mundo.get(&"conversion", {}))
	classes.from_dict(mundo.get(&"classes", {}))
	upkeep.from_dict(mundo.get(&"upkeep", {}))
	succession.from_dict(mundo.get(&"succession", {}))
	realm.from_dict(mundo.get(&"realm", {}))
	spirit.from_dict(mundo.get(&"spirit", {}))
	_dia = ClockService.clock.day if ClockService.clock != null else 0


## A alvorada de um dia que nao e o primeiro: a manutencao do dia que acabou, e o
## vagabundo novo no acampamento do lado do dia (Q-122, Q-124).
func _alvorada(dia: int, unidades: UnitSystem, estado: GameState) -> void:
	if _obras != null:
		_coroar(unidades, estado)
		var treino := succession.dawn(_obras, unidades, _rei)
		if treino > 0:
			EventBus.queue(&"coin_spent", [treino, &"heir"])
	if _economia != null:
		for e in upkeep.dawn(unidades, _rei, _economia, dia):
			if e[UpkeepSystem.CHAVE] == UpkeepSystem.EV_PAGA:
				EventBus.queue(&"coin_spent", [e[UpkeepSystem.QUANTO], &"upkeep"])
			else:
				EventBus.queue(&"unit_fled", [e[UpkeepSystem.UNIDADE], &"upkeep"])
	SpiritWatch.dawn(spirit, dia, upkeep.arrears())  # o soldo em atraso pesa (Q-102)
	Camps.dawn(camps, dia, unidades, estado, spirit.level(dia))
	var fork := (
		SimLoop.secrets.chapters[0] if not SimLoop.secrets.chapters.is_empty() else _nucleo.x
	)
	realm.dawn(dia, unidades, estado, _rei, Vector2(_nucleo.x, fork))  # marcha e tributo (Q-103)


## §16: "se houver sucessor, ele assume no amanhecer". O rei novo nasce no castelo
## (Q-137), sem moedas, e a ganancia sorteia-se de novo (§15, Q-133).
func _coroar(unidades: UnitSystem, estado: GameState) -> void:
	var i := unidades.index_of(_rei)
	if _rei == UnitSystem.NENHUM or (i != UnitSystem.NENHUM and unidades.healths[i] > 0):
		return
	var monarca := Registry.entry(&"units", &"monarch") as UnitData
	var novo := succession.crown(estado, unidades, _obras, monarca)
	if novo == UnitSystem.NENHUM:
		return
	var x := unidades.xs[unidades.index_of(novo)]
	EventBus.queue(&"unit_spawned", [novo, monarca.id, x, int(Band.Kind.SURFACE)])
	EventBus.queue(&"king_died", [succession.owner, novo])
	EventBus.queue(&"succession_started", [novo])
	SimFactory.draw_greed(estado)
	SimLoop.king_id = novo  # quem manda passa a ser ele: o Verbo, a camara, o Defeat
	_rei = novo


func _do_nucleo(obras: BuildSystem) -> Vector2:
	for vaga in obras.slots:
		if vaga.kind == BuildSlot.NUCLEO:
			return Vector2(vaga.x, vaga.width * BuildSystem.METADE)
	return _nucleo
