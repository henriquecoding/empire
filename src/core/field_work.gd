class_name FieldWork
extends RefCounted

var settlements := Settlements.new()
var local_homes: Dictionary = {}
var underground_sight := UndergroundSight.new()
var under := UndergroundSites.new()  # o subsolo e um sitio, e acaba (Q-186)
var camp_life := CampLife.new()
var seasons := Seasons.new(RulesFactory.rules())
var hunting: HuntingSystem
var training: TrainingSystem
var crown: CrownSystem
var conversion: ConversionSystem
var classes: ClassSystem
var hero_progress := HeroProgress.new(SimFactory.by_id(&"classes"))
var focus := ArcherFocus.new(Registry.entry(&"classes", &"archer"), SimFactory.by_id(&"units"))
var song := BardSong.new(
	Registry.entry(&"classes", &"bard"), SimFactory.by_id(&"units"), SimFactory.by_id(&"creatures")
)
var upkeep: UpkeepSystem
var succession: Succession
var camps: PackedFloat32Array = PackedFloat32Array()
var realm := Realm.new()
var spirit: Spirit
var wilds := WildSegments.new(RulesFactory.segment_kits(), RulesFactory.biome_peoples())
var crown_drop := CrownDrop.new()
var supply := Supply.new()
var mount := Mount.new(
	Registry.entry(&"mounts", &"draft_horse") as MountData,
	Registry.entry(&"classes/storages", &"saddlebags") as StorageData
)
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
	upkeep.mercenary_wage = RulesFactory.rules().mercenary_daily_wage
	var curva := SimFactory.curve()
	var niveis := curva.spirit_levels
	spirit = Spirit.new(niveis[1], niveis[0], niveis[2])
	succession = Succession.new(curva.heir_training_days, curva.heir_cost_per_day)
	if combate != null:
		combate.guard = classes
		combate.supply = supply
	_combate = combate
	_economia = economia
	_moral = moral
	if _economia != null:
		_economia.crown = crown
		_economia.seasons = seasons
		_economia.conversion = conversion
		conversion.jobs = _economia.jobs


func prepare(
	dia: int,
	core_x: float,
	largura: float,
	unidades: UnitSystem = null,
	fase: int = 0,
	estado: GameState = null
) -> void:
	hunting.season_mult = seasons.hunt_mult(dia)
	CampWatch.tick(self)
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
		_moral.refuges = local_homes
		_moral.steadfast = crown.steadfast(dia)
		_moral.spirit = spirit.level(dia)
		_moral.perks = perks
	if _combate != null:
		_combate.perks = perks
		_combate.refuges = local_homes
		_combate.refuge = core_x  # quem larga a arma foge para o nucleo (Q-168)


func impulse(id: StringName, unidades: UnitSystem, rei: int) -> void:
	var perfil := RulesFactory.impulse_cost_mult(_economia.greed if _economia != null else 0)
	var custo := crown.price(id, ClockService.clock.day, perfil)  # o preco de hoje (Q-014)
	if crown.use(id, ClockService.clock.day, unidades, rei, custo):
		EventBus.queue(&"royal_impulse_used", [id])
		EventBus.queue(&"coin_spent", [custo, &"impulse"])


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
	SettlementWatch.plan(self)
	Assume.plan(unidades, _rei, _nucleo, self)  # quem se conduz, e o rei largado (§08)


func absorb(moedas: CoinSystem, obras: BuildSystem, unidades: UnitSystem) -> void:
	EventRelay.training(training.absorb(moedas, obras, unidades))
	var cavalo := mount.absorb(moedas, obras)  # o cavalo, no estabulo (Q-169)
	if cavalo > 0:
		EventBus.queue(&"coin_spent", [cavalo, &"mount"])
	mount.tick(unidades, Assume.driven(), obras)
	Assume.saddle(unidades, self)  # os alforges vao com quem monta, save incluido
	conversion.staff(obras)  # a capacidade pede o cozinheiro la dentro (Q-145)


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


func parts() -> Dictionary:
	return {
		&"settlements": settlements,
		&"underground_sight": underground_sight,
		&"under": under,
		&"camp_life": camp_life,
		&"seasons": seasons,
		&"hunting": hunting,
		&"training": training,
		&"crown": crown,
		&"conversion": conversion,
		&"classes": classes,
		&"hero_progress": hero_progress,
		&"focus": focus,
		&"song": song,
		&"upkeep": upkeep,
		&"succession": succession,
		&"realm": realm,
		&"spirit": spirit,
		&"wilds": wilds,
		&"roster": roster,
		&"crown_drop": crown_drop,
		&"supply": supply,
		&"mount": mount,
	}


func to_dict() -> Dictionary:
	var saida := {}
	var partes := parts()
	for chave: StringName in partes:
		saida[chave] = partes[chave].to_dict()
	return saida


func from_dict(mundo: Dictionary) -> void:
	var partes := parts()
	for chave: StringName in partes:
		partes[chave].from_dict(mundo.get(chave, {}))
	Frontier.reapply(self, SimLoop.world_width)
	SettlementWatch.plan(self)  # os acampamentos e as masmorras voltam
	_dia = ClockService.clock.day if ClockService.clock != null else 0


func _alvorada(dia: int, unidades: UnitSystem, estado: GameState) -> void:
	_rei = DawnWork.run(self, dia, unidades, estado, _obras, _economia, _rei, _nucleo)


func _do_nucleo(obras: BuildSystem) -> Vector2:
	for vaga in obras.slots:
		if vaga.kind == BuildSlot.NUCLEO:
			return Vector2(vaga.x, vaga.width * BuildSystem.METADE)
	return _nucleo
